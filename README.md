# 2R — Room Reservation System

A formally verified, offline-first, polyglot room booking application.

## Architecture Overview

```
2R/
├── Dockerfile                              # PHP 8.2-FPM image
├── docker-compose.yml                      # Full service orchestration
├── nginx/
│   └── default.conf                        # Nginx reverse proxy config
├── backend/
│   └── laravel_2r/                         # Laravel 11 API gateway
│       ├── app/
│       │   ├── Http/Controllers/
│       │   │   ├── AuthController.php
│       │   │   ├── ReservationController.php
│       │   │   ├── AvailabilityController.php
│       │   │   └── AnalyticsController.php
│       │   ├── Models/
│       │   │   └── Reservation.php
│       │   ├── Services/
│       │   │   ├── AvailabilityService.php
│       │   │   └── VerificationService.php
│       │   └── Providers/
│       │       └── AppServiceProvider.php
│       ├── bootstrap/
│       │   └── app.php
│       ├── config/
│       │   ├── cors.php
│       │   └── services.php
│       ├── database/
│       │   ├── migrations/
│       │   │   └── 2024_01_01_000000_create_reservations_table.php
│       │   └── seeders/
│       │       └── DatabaseSeeder.php
│       ├── routes/
│       │   └── api.php
│       ├── composer.json
│       └── .env.example
├── frontend/
│   └── vue_app/                            # Vue 3 + Pinia + PouchDB SPA
│       ├── src/
│       │   ├── components/
│       │   │   ├── OfflineStatus.vue
│       │   │   ├── ReservationForm.vue
│       │   │   └── ReservationList.vue
│       │   ├── lib/
│       │   │   ├── api.ts
│       │   │   └── pouchdb.ts
│       │   ├── router/
│       │   │   └── index.ts
│       │   ├── stores/
│       │   │   ├── auth.ts
│       │   │   └── reservation.ts
│       │   ├── types/
│       │   │   └── index.ts
│       │   ├── views/
│       │   │   ├── AnalyticsView.vue
│       │   │   ├── AvailabilityView.vue
│       │   │   ├── DashboardView.vue
│       │   │   ├── LoginView.vue
│       │   │   └── ReservationsView.vue
│       │   ├── App.vue
│       │   ├── main.ts
│       │   └── style.css
│       ├── index.html
│       ├── package.json
│       ├── postcss.config.js
│       ├── tailwind.config.js
│       ├── tsconfig.json
│       └── vite.config.ts
├── microservices/
│   ├── auth_rust/                          # Rust/Axum — availability cache
│   │   ├── src/main.rs
│   │   ├── Cargo.toml
│   │   └── Dockerfile
│   ├── booking_dotnet/                     # ASP.NET 8 — enterprise calendar
│   │   ├── Program.cs
│   │   ├── booking_dotnet.csproj
│   │   └── Dockerfile
│   ├── verify_dafny/                       # Dafny + Python bridge
│   │   ├── Reservation.dfy
│   │   ├── server.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   ├── analytics_python/                   # FastAPI — usage & forecast
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   ├── perf_cpp/                           # C++20 — slot conflict resolver
│   │   ├── slot_resolver.cpp
│   │   └── Dockerfile
│   ├── sys_zig/                            # Zig 0.13 — system validator
│   │   ├── main.zig
│   │   ├── build.zig
│   │   └── Dockerfile
│   ├── ai_mojo/                            # Mojo / Python — AI forecast
│   │   ├── forecast.mojo
│   │   ├── server.py
│   │   └── Dockerfile
│   ├── formal_fstar/                       # F* — proof specification
│   │   └── Reservation.fst
│   ├── legacy_gas/                         # Google Apps Script adapter
│   │   └── Code.gs
│   └── legacy_vba/                         # VBA Office adapter
│       └── ReservationAdapter.bas
└── docs/
    ├── ARCHITECTURE.mmd
    ├── OFFLINE_SYNC_FLOW.mmd
    └── BOOKING_LIFECYCLE.mmd
```

---

## Technology Stack

| Layer | Technology | Port | Purpose |
|---|---|---|---|
| Frontend | Vue 3, Pinia, PouchDB, Tailwind | 5173 | Reactive offline-first SPA |
| Proxy | Nginx | 80 | Reverse proxy to PHP-FPM |
| API Gateway | Laravel 11, Sanctum | 9000 | Auth, routing, orchestration |
| Database | PostgreSQL 16 | 5432 | Authoritative store |
| Performance | Rust/Axum | 3001 | Availability cache |
| Enterprise | ASP.NET 8 / C# | 5001 | Calendar integration |
| Verification | Dafny + Python | 3002 | Formal proof bridge |
| Analytics | Python/FastAPI | 8001 | Usage & demand forecast |
| Slot Resolve | C++20 | 9001 | In-memory conflict check |
| Validation | Zig 0.13 | 9002 | Field & system validation |
| AI Forecast | Mojo / Python | 8002 | Seasonal prediction |
| Proof Spec | F* | — | Offline mathematical spec |
| Legacy | GAS / VBA | — | Google & Office adapters |

---

## Quick Start

### Prerequisites

- Docker Desktop 4.x+
- Docker Compose v2+

### 1. Clone and configure

```bash
git clone https://github.com/Uchida16104/2R.git
cd 2R
cp backend/laravel_2r/.env.example backend/laravel_2r/.env
```

### 2. Build and start all services

```bash
docker compose up --build -d
```

### 3. Run Laravel migrations and seed

```bash
docker compose exec laravel php artisan migrate --seed
```

### 4. Start the Vue frontend (development)

```bash
cd frontend/vue_app
npm install
npm run dev
```

Open http://localhost:5173

Default credentials: `admin@2r.local` / `password`

---

## Frontend Development (without Docker)

```bash
cd frontend/vue_app
npm install
npm run dev
```

The Vite dev server proxies `/api/*` to `http://localhost:80` (Nginx).

---

## Individual Service Development

### Laravel only

```bash
cd backend/laravel_2r
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### Rust service

```bash
cd microservices/auth_rust
cargo run
```

### Python analytics

```bash
cd microservices/analytics_python
pip install -r requirements.txt
uvicorn main:app --reload --port 8001
```

### C++ slot resolver

```bash
cd microservices/perf_cpp
g++ -std=c++20 -O3 -pthread -o slot_resolver slot_resolver.cpp
./slot_resolver
```

### Zig system service

```bash
cd microservices/sys_zig
zig build run
```

---

## Offline Sync

The Vue frontend uses **PouchDB** to queue reservations locally when offline.

When connectivity is restored, the store's `syncOfflineQueue()` method batches all pending records and sends them to `POST /api/reservations/sync`. The backend processes each record inside a transaction, returning `created`, `conflict`, or `already_exists` per record. The frontend updates PouchDB accordingly.

---

## Formal Verification

`microservices/verify_dafny/Reservation.dfy` contains the Dafny proof of booking invariants. The `Room.Book()` method has a `requires !isBooked` precondition — this makes double-booking a compile-time impossibility for any state passing through the verifier.

`microservices/formal_fstar/Reservation.fst` provides the F* specification of the `no_double_booking` property as a dependent type-level proposition.

---

## Legacy Adapters

### Google Apps Script

1. Open script.google.com
2. Create a new project
3. Paste `microservices/legacy_gas/Code.gs`
4. Set Script Properties: `BACKEND_URL`, `API_TOKEN`
5. Run `syncReservationsToCalendar()` to push confirmed bookings to Google Calendar

### VBA (Excel / Word)

1. Open Excel → Alt+F11 → Insert Module
2. Paste `microservices/legacy_vba/ReservationAdapter.bas`
3. Set `BACKEND_URL` and `API_TOKEN` constants, or add a `Config` sheet with token in `B1`
4. Run `SyncReservationsFromSheet()` to batch-create reservations from rows

---

## Deployment

### Vercel (Frontend)

```
Framework: Vite
Root Directory: frontend/vue_app
Build Command: npm run build
Output Directory: dist
Environment: VITE_API_BASE_URL=https://your-backend.onrender.com
```

### Render (Backend — Laravel)

```
Type: Web Service
Root Directory: backend/laravel_2r
Build Command: composer install --no-dev --optimize-autoloader && php artisan migrate --force
Start Command: php artisan serve --host=0.0.0.0 --port=$PORT
Environment Variables: (copy from .env.example)
```

### Render (Microservices)

Each service under `microservices/` has its own `Dockerfile` and can be deployed as an independent Render Web Service pointing to its subdirectory.
