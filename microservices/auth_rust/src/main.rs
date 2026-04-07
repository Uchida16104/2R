use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use chrono::{Duration, Utc};
use serde::{Deserialize, Serialize};
use sqlx::{PgPool, postgres::PgPoolOptions};
use std::sync::Arc;
use tower_http::cors::{Any, CorsLayer};
use tracing::info;

#[derive(Clone)]
struct AppState {
    db: PgPool,
    jwt_secret: String,
}

#[derive(Deserialize)]
struct AvailabilityQuery {
    date: String,
}

#[derive(Serialize)]
struct SlotEntry {
    room_id: String,
    start:   String,
    end:     String,
    available: bool,
}

#[derive(Serialize)]
struct AvailabilityResponse {
    date:  String,
    slots: Vec<SlotEntry>,
}

#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
}

async fn health() -> Json<HealthResponse> {
    Json(HealthResponse { status: "ok" })
}

async fn get_availability(
    State(state): State<Arc<AppState>>,
    Query(params): Query<AvailabilityQuery>,
) -> Result<Json<Vec<SlotEntry>>, (StatusCode, String)> {
    let date = params.date.clone();
    let start_of_day = format!("{date} 00:00:00");
    let end_of_day   = format!("{date} 23:59:59");

    let rows = sqlx::query!(
        r#"
        SELECT room_id, start_time::text as start_time, end_time::text as end_time
        FROM reservations
        WHERE status = 'confirmed'
          AND deleted_at IS NULL
          AND start_time >= $1::timestamp
          AND end_time   <= $2::timestamp
        ORDER BY room_id, start_time
        "#,
        start_of_day,
        end_of_day,
    )
    .fetch_all(&state.db)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let slots: Vec<SlotEntry> = rows
        .into_iter()
        .map(|r| SlotEntry {
            room_id:   r.room_id,
            start:     r.start_time.unwrap_or_default(),
            end:       r.end_time.unwrap_or_default(),
            available: false,
        })
        .collect();

    Ok(Json(slots))
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    tracing_subscriber::fmt::init();

    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://postgres:secret@localhost:5432/reservations".into());

    let jwt_secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "2r-jwt-secret-change-in-production".into());

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    info!("Connected to database");

    let state = Arc::new(AppState { db: pool, jwt_secret });

    let cors = CorsLayer::new().allow_origin(Any).allow_methods(Any).allow_headers(Any);

    let app = Router::new()
        .route("/health",       get(health))
        .route("/availability", get(get_availability))
        .layer(cors)
        .with_state(state);

    let addr = "0.0.0.0:3001";
    info!("Auth/Availability service listening on {addr}");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
