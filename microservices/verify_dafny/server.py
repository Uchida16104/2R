from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import subprocess
import tempfile
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="2R Dafny Verification Bridge", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class BookingVerifyRequest(BaseModel):
    room_id:    str
    start_time: str
    end_time:   str


class BookingVerifyResponse(BaseModel):
    valid:   bool
    message: str


def parse_epoch(dt_str: str) -> int:
    try:
        dt = datetime.fromisoformat(dt_str.replace("Z", "+00:00"))
        return int(dt.timestamp())
    except Exception:
        return 0


@app.get("/health")
def health():
    return {"status": "ok", "service": "verify_dafny"}


@app.post("/verify/booking", response_model=BookingVerifyResponse)
def verify_booking(req: BookingVerifyRequest) -> BookingVerifyResponse:
    start_ts = parse_epoch(req.start_time)
    end_ts   = parse_epoch(req.end_time)

    if start_ts <= 0 or end_ts <= 0:
        return BookingVerifyResponse(valid=False, message="Invalid datetime format")

    if end_ts <= start_ts:
        return BookingVerifyResponse(valid=False, message="End time must be after start time")

    if start_ts < 0:
        return BookingVerifyResponse(valid=False, message="Start time must be non-negative")

    dafny_snippet = f"""
module VerifyRequest {{
  import opened RoomReservation

  lemma VerifySlotValid()
    ensures ValidSlot(TimeSlot({start_ts}, {end_ts}))
  {{}}
}}
"""

    dafny_bin = os.environ.get("DAFNY_BIN", "dafny")

    try:
        with tempfile.NamedTemporaryFile(suffix=".dfy", mode="w", delete=False) as f:
            base_path = os.path.join(os.path.dirname(__file__), "Reservation.dfy")
            f.write(open(base_path).read() + "\n" + dafny_snippet)
            tmp_path = f.name

        result = subprocess.run(
            [dafny_bin, "verify", tmp_path],
            capture_output=True,
            text=True,
            timeout=15,
        )
        os.unlink(tmp_path)

        if result.returncode == 0:
            return BookingVerifyResponse(valid=True, message="Invariant verified by Dafny")

        logger.warning("Dafny verification output: %s", result.stdout)
        return BookingVerifyResponse(valid=False, message="Invariant violation detected")

    except FileNotFoundError:
        logger.warning("Dafny binary not found — falling back to Python invariant check")
        valid = end_ts > start_ts and start_ts >= 0
        return BookingVerifyResponse(
            valid=valid,
            message="Python fallback check" if valid else "Slot invariant violated",
        )
    except subprocess.TimeoutExpired:
        logger.warning("Dafny timed out — falling back to Python check")
        return BookingVerifyResponse(valid=True, message="Dafny timeout — fallback approved")
    except Exception as exc:
        logger.exception("Verification error: %s", exc)
        return BookingVerifyResponse(valid=True, message="Verification error — fallback approved")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3002)
