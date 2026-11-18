import asyncio
from functools import lru_cache
from io import BytesIO
import logging
import os
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from fastapi.concurrency import run_in_threadpool
from fastapi.staticfiles import StaticFiles
from starlette.middleware.trustedhost import TrustedHostMiddleware

MAX_AUDIO_BYTES = 25 * 1024 * 1024
APP_ROOT = Path(__file__).resolve().parents[2]
LOGGER = logging.getLogger(__name__)


@lru_cache(maxsize=1)
def load_model():
    from faster_whisper import WhisperModel

    return WhisperModel(
        os.environ.get("SONG_WHISPER_MODEL", "tiny"),
        device="cpu",
        compute_type="int8",
        cpu_threads=min(os.cpu_count() or 2, 4),
    )


def transcribe(data: bytearray) -> list[dict]:
    try:
        model = load_model()
    except Exception as exc:
        LOGGER.exception("Unable to load the local transcription model")
        raise HTTPException(503, "无法加载本机转写模型。请检查模型缓存或下载连接。") from exc
    try:
        segments, _ = model.transcribe(
            BytesIO(data),
            beam_size=3,
            condition_on_previous_text=False,
            vad_filter=False,
        )
        return [
            {"startMs": round(segment.start * 1000), "text": segment.text.strip()}
            for segment in segments
            if segment.text.strip()
        ]
    except Exception as exc:
        LOGGER.exception("Unable to decode or transcribe audio")
        raise HTTPException(422, "无法读取或识别该音频，请试用 MP3 或 WAV。") from exc


def create_app(web_root: Path | None = None, transcriber=transcribe) -> FastAPI:
    app = FastAPI(title="Song Language Lab", docs_url=None, redoc_url=None, openapi_url=None)
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=["127.0.0.1", "localhost", "testserver"])
    model_lock = asyncio.Lock()

    @app.get("/api/health")
    def health() -> dict:
        return {"status": "ok", "model": os.environ.get("SONG_WHISPER_MODEL", "tiny")}

    @app.post("/api/transcribe")
    async def extract(request: Request) -> dict:
        origin = request.headers.get("origin")
        if origin is not None and origin != f"{request.url.scheme}://{request.url.netloc}":
            raise HTTPException(403, "仅允许测试页面调用本机转写服务。")
        if request.headers.get("content-type", "").split(";")[0].strip().lower() != "application/octet-stream":
            raise HTTPException(415, "请发送音频文件。")
        if model_lock.locked():
            raise HTTPException(429, "转写服务正在处理另一首歌曲。请稍后重试。")
        async with model_lock:
            data = bytearray()
            async for chunk in request.stream():
                if len(data) + len(chunk) > MAX_AUDIO_BYTES:
                    raise HTTPException(413, "音频不能超过 25 MB。")
                data.extend(chunk)
            if not data:
                raise HTTPException(400, "音频为空。")
            lines = await run_in_threadpool(transcriber, data)
        if not lines:
            raise HTTPException(422, "未识别到可用歌词。")
        return {"lines": lines}

    if web_root is not None and web_root.is_dir():
        app.mount("/", StaticFiles(directory=web_root, html=True), name="web")
    return app


app = create_app(Path(os.environ.get("SONG_WEB_ROOT", APP_ROOT / "client" / "build" / "web")))
