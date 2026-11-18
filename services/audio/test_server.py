from unittest import TestCase

from fastapi.testclient import TestClient

from server import create_app


class AudioApiTest(TestCase):
    def setUp(self):
        self.client = TestClient(create_app(transcriber=self.extract))
        self.headers = {"Content-Type": "application/octet-stream"}
        self.received = []

    def extract(self, data):
        self.received.append(bytes(data))
        if data == b"silent":
            return []
        return [{"startMs": 1200, "text": "A little light"}]

    def test_health(self):
        self.assertEqual(self.client.get("/api/health").json()["status"], "ok")

    def test_audio_and_timestamps_are_returned(self):
        response = self.client.post("/api/transcribe", content=b"audio", headers=self.headers)
        self.assertEqual(response.json(), {"lines": [{"startMs": 1200, "text": "A little light"}]})
        self.assertEqual(self.received, [b"audio"])

    def test_invalid_and_foreign_requests_never_reach_transcriber(self):
        self.assertEqual(self.client.post("/api/transcribe", headers=self.headers).status_code, 400)
        self.assertEqual(self.client.post("/api/transcribe", content=b"audio").status_code, 415)
        self.assertEqual(self.client.post(
            "/api/transcribe", content=b"audio",
            headers={**self.headers, "Origin": "https://other.example"},
        ).status_code, 403)
        self.assertEqual(self.received, [])

    def test_empty_result_is_reported(self):
        response = self.client.post("/api/transcribe", content=b"silent", headers=self.headers)
        self.assertEqual(response.status_code, 422)
