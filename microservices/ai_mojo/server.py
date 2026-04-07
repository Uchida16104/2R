import json
import math
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

history_store: dict = {}


def mojo_seasonal_forecast(history: list, horizon: int) -> list:
    base = sum(history) / len(history) if history else 1.0
    result = []
    for i in range(horizon):
        dow      = i % 7
        seasonal = 1.0 + 0.2 * math.sin(2.0 * math.pi * dow / 7.0)
        trend    = 1.0 + 0.005 * i
        result.append(round(base * seasonal * trend, 2))
    return result


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def send_json(self, code: int, data: object) -> None:
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type",             "application/json")
        self.send_header("Content-Length",           str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)

        if parsed.path == "/health":
            self.send_json(200, {"status": "ok", "service": "ai_mojo_py_fallback"})
            return

        if parsed.path == "/forecast":
            room_id = params.get("room_id", ["ALL"])[0]
            horizon = int(params.get("horizon", ["14"])[0])
            history = history_store.get(room_id, [3.0, 4.0, 2.0, 5.0, 3.5, 4.2, 3.8])
            result  = mojo_seasonal_forecast(history, horizon)
            self.send_json(200, {"room_id": room_id, "horizon": horizon, "predictions": result})
            return

        self.send_json(404, {"error": "not found"})

    def do_POST(self) -> None:
        length = int(self.headers.get("Content-Length", 0))
        body   = json.loads(self.rfile.read(length)) if length else {}

        if self.path == "/history":
            room_id = body.get("room_id", "ALL")
            counts  = body.get("counts", [])
            history_store[room_id] = counts
            self.send_json(200, {"stored": len(counts), "room_id": room_id})
            return

        self.send_json(404, {"error": "not found"})


if __name__ == "__main__":
    print("ai_mojo Python fallback server starting on :8002")
    HTTPServer(("0.0.0.0", 8002), Handler).serve_forever()
