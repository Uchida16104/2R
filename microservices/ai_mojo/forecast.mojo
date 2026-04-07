from python import Python
from math import sin, cos, sqrt, exp

fn simple_moving_average(data: PythonObject, window: Int) -> PythonObject:
    var np = Python.import_module("numpy")
    var arr = np.array(data, dtype="float64")
    var kernel = np.ones(window) / window
    return np.convolve(arr, kernel, mode="valid")

fn seasonal_forecast(history: PythonObject, horizon: Int) -> PythonObject:
    var np      = Python.import_module("numpy")
    var math_py = Python.import_module("math")

    var hist_arr = np.array(history, dtype="float64")
    var n        = len(hist_arr)
    var base_avg: Float64 = float(np.mean(hist_arr)) if n > 0 else 1.0

    var result = Python.evaluate("[]")
    for i in range(horizon):
        var dow      = i % 7
        var seasonal = 1.0 + 0.2 * float(math_py.sin(2.0 * 3.14159 * dow / 7.0))
        var trend    = 1.0 + (0.005 * i)
        var predicted = round(base_avg * seasonal * trend, 2)
        _ = result.append(predicted)

    return result

fn main():
    var json   = Python.import_module("json")
    var sys    = Python.import_module("sys")
    var socket = Python.import_module("socket")
    var http   = Python.import_module("http.server")
    var np     = Python.import_module("numpy")

    print("Mojo AI forecast module initialised — embedding in Python HTTP server")

    var server_code = """
import json
import math
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

history_store = {}

def mojo_seasonal_forecast(history, horizon):
    if not history:
        base = 1.0
    else:
        base = sum(history) / len(history)
    result = []
    for i in range(horizon):
        dow = i % 7
        seasonal = 1.0 + 0.2 * math.sin(2.0 * math.pi * dow / 7.0)
        trend = 1.0 + 0.005 * i
        result.append(round(base * seasonal * trend, 2))
    return result

class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def send_json(self, code, data):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)

        if parsed.path == "/health":
            self.send_json(200, {"status": "ok", "service": "ai_mojo"})
            return

        if parsed.path == "/forecast":
            room_id = params.get("room_id", ["ALL"])[0]
            horizon = int(params.get("horizon", ["14"])[0])
            history = history_store.get(room_id, [3.0, 4.0, 2.0, 5.0, 3.5, 4.2, 3.8])
            forecast = mojo_seasonal_forecast(history, horizon)
            self.send_json(200, {"room_id": room_id, "horizon": horizon, "predictions": forecast})
            return

        self.send_json(404, {"error": "not found"})

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length)) if length else {}

        if self.path == "/history":
            room_id = body.get("room_id", "ALL")
            counts  = body.get("counts", [])
            history_store[room_id] = counts
            self.send_json(200, {"stored": len(counts), "room_id": room_id})
            return

        self.send_json(404, {"error": "not found"})

HTTPServer(("0.0.0.0", 8002), Handler).serve_forever()
"""
    var exec = Python.evaluate("exec")
    _ = exec(server_code)
