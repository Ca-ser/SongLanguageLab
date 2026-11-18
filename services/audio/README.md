# 本机音频转写服务

Python 3.12、FastAPI、faster-whisper。运行 uv sync --locked 安装依赖，再执行 uv run --locked python -m unittest -v。

从仓库根目录运行 scripts/run-test.ps1 可以同时提供 Flutter Web 构建和同源 API。默认只监听 127.0.0.1:8787。GET /api/health 可检查服务，POST /api/transcribe 接收 application/octet-stream 格式的原始音频，返回带毫秒位置的歌词草稿。

默认模型为 tiny（CPU int8），首次加载时从公开仓库下载。可设置 SONG_WHISPER_MODEL 更换模型或指定本地模型目录。歌唱转写受伴奏和发音影响。音频请求最多 25 MB，只在内存中处理。
