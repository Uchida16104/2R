from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime, timedelta
from typing import Optional
import asyncpg
import os
import logging
import math

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://postgres:secret@postgres:5432/reservations",
)

app = FastAPI(title="2R Analytics", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_pool: Optional[asyncpg.Pool] = None


async def get_pool() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(DATABASE_URL, min_size=1, max_size=5)
    return _pool


@app.on_event("startup")
async def startup():
    await get_pool()
    logger.info("Analytics service started")


@app.on_event("shutdown")
async def shutdown():
    if _pool:
        await _pool.close()


@app.get("/health")
def health():
    return {"status": "ok", "service": "analytics_python"}


@app.get("/analytics/usage")
async def usage(
    from_date: str = Query(..., alias="from"),
    to_date:   str = Query(..., alias="to"),
):
    pool = await get_pool()

    try:
        rows = await pool.fetch(
            """
            SELECT
                room_id,
                COUNT(*)                                    AS booking_count,
                AVG(EXTRACT(EPOCH FROM (end_time - start_time)) / 3600.0) AS avg_hours
            FROM reservations
            WHERE status      = 'confirmed'
              AND deleted_at  IS NULL
              AND start_time >= $1::timestamptz
              AND end_time   <= $2::timestamptz
            GROUP BY room_id
            ORDER BY booking_count DESC
            """,
            from_date,
            to_date,
        )
    except Exception as exc:
        logger.exception("Usage query failed: %s", exc)
        raise HTTPException(status_code=500, detail="Database error")

    return [
        {
            "room_id":   row["room_id"],
            "count":     row["booking_count"],
            "avg_hours": round(float(row["avg_hours"] or 0), 2),
        }
        for row in rows
    ]


@app.get("/analytics/forecast")
async def forecast(
    room_id: str = Query(...),
    days:    int = Query(14, ge=1, le=90),
):
    pool = await get_pool()

    try:
        rows = await pool.fetch(
            """
            SELECT
                DATE(start_time) AS day,
                COUNT(*)         AS cnt
            FROM reservations
            WHERE (room_id = $1 OR $1 = 'ALL')
              AND status     = 'confirmed'
              AND deleted_at IS NULL
              AND start_time >= NOW() - INTERVAL '60 days'
            GROUP BY DATE(start_time)
            ORDER BY day
            """,
            room_id,
        )
    except Exception as exc:
        logger.exception("Forecast query failed: %s", exc)
        raise HTTPException(status_code=500, detail="Database error")

    history = {str(row["day"]): int(row["cnt"]) for row in rows}
    avg = sum(history.values()) / max(len(history), 1)

    result = []
    for i in range(days):
        future_date = (datetime.utcnow() + timedelta(days=i + 1)).date()
        dow = future_date.weekday()
        seasonal = 1.0 + 0.2 * math.sin(2 * math.pi * dow / 7)
        predicted = round(avg * seasonal, 1)
        result.append({"date": str(future_date), "predicted": predicted})

    return result


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
