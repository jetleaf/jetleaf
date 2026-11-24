# Jetleaf Benchmarks — Full Blueprint

> **Status:** Phase 1 infrastructure complete; Jetleaf reference implementation complete. Other framework implementations pending.
> **Scope:** A standalone, reproducible, open-source benchmark repository that compares Jetleaf against the major backend ecosystems on identical hardware, identical workloads, and identical resource limits.
> **Location:** A new top-level `benchmark/` folder (the `jetleaf-benchmarks` repository). It is deliberately a sibling of the `jetleaf/` repository, not a folder inside it, so benchmark results cannot be influenced by framework source changes and the repository can be published independently.
> **Primary output:** One command — `./run-benchmarks.sh` — producing raw JSON, a generated `SUMMARY.md`, and a reproducible environment record.

---

## 1. Executive summary

The goal is not to "win" a benchmark. The goal is to produce a result that senior engineers accept as fair: every framework implements the same four endpoints idioms-first, runs under the same CPU/memory limits, connects to the same PostgreSQL instance with the same pool size, is warmed up before measurement, is measured with the same k6 scripts, and publishes the raw artifacts so anyone can reproduce or challenge the numbers.

If the methodology is defensible, the content writes itself. If the methodology is sloppy, every number is dismissible. Therefore the benchmark plan spends most of its effort on **parity, repeatability, and transparency**.

---

## 2. Goals and non-goals

### Goals

1. **One-command reproducibility** on a clean Linux host: build, run, measure, aggregate, report.
2. **Strict resource parity**: 2 vCPU and 1 GiB per framework container, one framework active at a time, Postgres with identical connection pool limits.
3. **Four realistic endpoints** covering DI/routing, JSON + CPU work, indexed DB read, and transactional DB write.
4. **Five published metrics per framework**: production image size, cold start, idle RSS, throughput/latency under load (RPS, avg, p95, p99), peak RSS under load.
5. **Idiomatic implementations**: each framework uses its own recommended enterprise patterns, not hand-optimised toy handlers.
6. **Raw artifacts retained**: k6 JSON, docker stats samples, commit hashes, image digests, host details, and the exact scripts used.
7. **Publishable content pipeline**: one run generates material for multiple posts and an upstream pull request.

### Non-goals

- Microbenchmarking individual framework internals (reflection, serializer, allocator).
- Declaring a single "winner"; results are reported per workload.
- Benchmarking development-mode servers, hot reload, or debug logging.
- Running frameworks concurrently (would invalidate CPU comparisons).
- Synthetic "hello world" routes without DI or data access.

---

## 3. Repository layout

```text
jetleaf-benchmarks/                  (folder: benchmark/, sibling to jetleaf/)
├── README.md                        # Purpose, rules, how to reproduce, results summary
├── LICENSE
├── docker-compose.yml               # Postgres + one profile per framework
├── .env.example                     # Host/tuning knobs, all documented
├── run-benchmarks.sh                # One-command orchestrator
├── report/
│   ├── summarize.py                 # k6 JSON -> SUMMARY.md + charts data
│   ├── environment.sh               # Host CPU/kernel/Docker/version fingerprint
│   └── CHECKLIST.md                 # Fairness review checklist for contributors
├── db/
│   ├── init.sql                     # Schema, indexes, 10,000 seeded rows
│   └── seed.sql                     # Deterministic data generator (fixed seed)
├── k6/
│   ├── common.js                    # Thresholds, checks, base URL, header helpers
│   ├── 01-plaintext.js              # GET /api/v1/ping
│   ├── 02-json-validation.js        # POST /api/v1/orders/validate (12 fields)
│   ├── 03-db-read.js                # GET /api/v1/users/:id
│   └── 04-db-write-tx.js            # POST /api/v1/audit (transactional insert)
├── frameworks/
│   ├── jetleaf/                     # Dart AOT native binary
│   ├── serverpod/                   # Dart ecosystem comparison
│   ├── dart-frog/                   # Dart micro-framework baseline
│   ├── spring-boot-jvm/             # Spring Boot 3.x/4.x on JVM
│   ├── spring-boot-native/          # Spring Boot GraalVM native image
│   ├── nestjs-node/                 # NestJS on Node.js LTS
│   ├── nestjs-bun/                  # NestJS on Bun
│   ├── aspnet-core/                 # ASP.NET Core (.NET 10)
│   ├── go-gin/                      # Go + Gin
│   └── fastapi/                     # Python + FastAPI (Uvicorn workers)
└── results/
    ├── raw/                         # k6 JSON, docker stats samples, metrics.log
    ├── charts/                      # Generated chart data (CSV)
    └── SUMMARY.md                   # Auto-generated comparison tables
```

Every `frameworks/<name>/` directory contains:

```text
Dockerfile                 # Production-only, multi-stage, pinned base images
README.md                  # How to build/run, framework version, design choices
src/…                      # Idiomatic implementation of the four endpoints
```

No framework directory imports code from another. Shared configuration lives only in `docker-compose.yml`, `db/`, and `k6/`.

---

## 4. The four standardized endpoints

All endpoints listen on `0.0.0.0:8080`. All responses are `application/json`. No framework enables access logs, debug logging, or metrics exporters.

| # | Endpoint | Method | What it measures |
|---|---|---|---|
| 1 | `/api/v1/ping` | GET | HTTP routing plus DI resolution of `SystemService`. Returns `{"status":"ok","timestamp":<unix seconds>}`. No DB. |
| 2 | `/api/v1/orders/validate` | POST | JSON deserialization of a 12-field order, annotation/DTO validation, service-layer total calculation. CPU-bound business logic. |
| 3 | `/api/v1/users/:id` | GET | Single indexed PostgreSQL lookup, mapped to a DTO. Async I/O, pooling, ORM overhead. |
| 4 | `/api/v1/audit` | POST | Insert an audit event inside a real transaction, return the generated ID. Write throughput and p95/p99 under contention. |

### 4.1 Payload contracts

`POST /api/v1/orders/validate` — exactly 12 fields, invalid payloads rejected with 400:

```json
{
  "orderId": "ORD-100001",
  "customerId": "CUST-9001",
  "currency": "USD",
  "status": "PENDING",
  "createdAt": "2026-11-24T10:00:00Z",
  "items": [
    {"sku": "SKU-1", "quantity": 2, "unitPrice": 19.99},
    {"sku": "SKU-2", "quantity": 1, "unitPrice": 5.50}
  ],
  "shippingCountry": "US",
  "shippingCity": "Austin",
  "shippingZip": "78701",
  "couponCode": "SAVE10",
  "notes": "benchmark payload",
  "priority": 2
}
```

Response `200`: `{"orderId":"…","total":45.44,"itemCount":2,"valid":true}` (total after coupon logic; the exact formula is defined once in `k6/common.js` documentation and mirrored in each framework).

`GET /api/v1/users/:id` — `id` is an integer in `[1, 10000]`. Response `200`: `{"id":42,"name":"User 42","email":"user42@example.com","active":true}`. Unknown id → `404`.

`POST /api/v1/audit` — body `{"actor":"k6","action":"BENCHMARK","metadata":"run-1"}`. Response `201`: `{"id":<generated integer>}`.

### 4.2 Idiomatic implementation requirement

Each framework must use its normal enterprise layering:

- Jetleaf and Spring Boot: `@RestController` → `@Service` → `@Repository`, DTOs with validation annotations, container-managed dependencies.
- NestJS: `@Controller` → `@Injectable` provider → data service, DTO validation pipe.
- ASP.NET Core: controller → service → repository with DI.
- Go/Gin: handler → service → repository.
- FastAPI: router → service → repository dependency.

No framework may bypass its DI container, hand-roll JSON parsing, disable validation, or cache results. Implementations are reviewed against `report/CHECKLIST.md` before a result is published.

---

## 5. Data and resource parity

### 5.1 Database

- PostgreSQL 17 Alpine, one shared container.
- Schema: `users(id SERIAL PRIMARY KEY, name TEXT, email TEXT, active BOOLEAN)` and `audit_events(id SERIAL PRIMARY KEY, actor TEXT, action TEXT, metadata TEXT, created_at TIMESTAMPTZ)`.
- Indexes: primary keys plus `CREATE INDEX idx_users_email ON users(email)`.
- Seed: exactly 10,000 users, deterministic fixed seed, loaded by `db/init.sql` on first container start.
- Every framework uses a connection pool with **maximum 20 connections**, the same statements, and no statement caching differences that are not idiomatic for that driver.

### 5.2 Container limits

```yaml
deploy:
  resources:
    limits:
      cpus: "2.0"
      memory: 1G
```

- Only one framework container runs at a time (Compose profiles).
- Postgres has its own 2 vCPU / 2 GiB limit and a healthcheck.
- Base images pinned by digest; versions recorded in `results/raw/environment.json`.
- Logging disabled in production config (no access log, no debug, no metrics endpoint).

### 5.3 Host requirements

- Dedicated 4 vCPU / 8 GiB Linux VPS, no desktop applications.
- Docker Engine with Compose v2, CPU governor `performance`.
- Record kernel, CPU model, Docker version, and available memory in `environment.json`.
- Swap disabled for the measurement host.

---

## 6. Measurement methodology

The original script is a good start; the following changes make its numbers defensible.

### 6.1 Metrics

| Metric | How measured |
|---|---|
| Image size | `docker image inspect --format '{{.Size}}'` on the tagged production image. |
| Cold start (ms) | `START` immediately before `docker compose --profile … up -d`; tight poll of `/api/v1/ping` with `curl -fsS --max-time 1`; `STOP` on first `200`. Hard timeout 120 s; timeout is a failure, not a number. |
| Idle RSS (MB) | Sample `docker stats --no-stream` three times, 1 s apart, after readiness and before warmup; take the median. |
| Throughput/latency | k6 `--summary-export`; 10 s warmup at 50 VU (discarded), then 30 s at 100 VU and 30 s at 500 VU for each of the four scripts. Record RPS, avg, p95, p99, and error rate. |
| Peak load RSS (MB) | Sample `docker stats --no-stream` every 1 s during the 500-VU run; take the maximum, not a single end-of-run snapshot. |

### 6.2 Repeatability

- Three full runs per framework; publish the median and the range.
- Two load levels (100 and 500 VU) so results show behaviour under both moderate and heavy contention.
- Warmup is mandatory so JIT-based runtimes are not unfairly penalised and so connection pools are primed.
- Failures (non-2xx above 0.1%, timeouts, container OOM) invalidate that run and are recorded, not hidden.

### 6.3 Anti-noise rules

- No other containers running except Postgres and the one framework.
- `docker system prune` between frameworks.
- Pin CPU with `--cpuset-cpus` where the host allows, or document that Compose CPU quotas are used.
- Use host networking for k6 so Docker bridge overhead does not dominate.
- All k6 scripts use the same think time (0), same payload sizes, and the same `Content-Type`.

### 6.4 Script responsibilities (`run-benchmarks.sh`)

1. Preflight: verify Docker, k6 image, host resources, free disk, and that all framework Dockerfiles exist.
2. Start Postgres, wait for healthcheck, load seed data.
3. For each framework in a fixed order:
   - build production image (time recorded separately, not counted as cold start);
   - record image size and digest;
   - start container, measure cold start with hard timeout;
   - record idle RSS (3 samples, median);
   - run 10 s discarded warmup;
   - run four k6 scripts at 100 VU and 500 VU, saving raw JSON;
   - sample RSS during each 500-VU run, record peak;
   - stop and remove the container, prune images/layers as needed;
   - append a row to `results/raw/metrics.log`.
4. Call `report/summarize.py` to generate `results/SUMMARY.md` and `results/charts/*.csv`.
5. Write `results/raw/environment.json` with host and version fingerprints.
6. `trap` on EXIT to guarantee teardown of all containers.

The script must be idempotent, fail loudly, and never silently skip a framework.

---

## 7. Framework implementations

### 7.1 Jetleaf reference implementation

- Multi-stage Dockerfile: `dart:stable` builder → `debian:bookworm-slim` runtime with `ca-certificates`.
- Build step: run Jetleaf's AOT code generation (`jl build`) then `dart compile exe` to produce a native executable.
- The compiled binary is the only runtime artifact — no Dart SDK in the final image.
- Endpoints use `@RestController` + injected `@Service` + repository, with validation annotations on DTOs.
- Connection pool configured to 20 via environment variables.

```dockerfile
# Build context is the Jetleaf parent directory so local pubspec path
# overrides to the framework source resolve inside the image.
FROM dart:3.9.0-sdk AS build
WORKDIR /workspace
COPY jetleaf/ /workspace/jetleaf/
COPY benchmark/frameworks/jetleaf/ /workspace/benchmark/frameworks/jetleaf/
WORKDIR /workspace/benchmark/frameworks/jetleaf
RUN dart pub get \
 && dart run jetleaf_tools build \
 && dart compile exe bin/main.dart -o /workspace/server

FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /workspace/server /usr/local/bin/server
COPY --from=build /workspace/benchmark/frameworks/jetleaf/resources /app/resources
WORKDIR /app
EXPOSE 8080
CMD ["/usr/local/bin/server"]
```

> Verified during Phase 1. The current toolchain has no `--release` flag; the
> real commands are `dart run jetleaf_tools build` followed by
> `dart compile exe bin/main.dart`. The compiled binary requires the generated
> AOT registrar, so generation must precede compilation. The benchmark app uses
> a thin `postgres` `Pool` pod with a hard cap of 20 connections because
> `jetleaf_data` ships the dialect/repository layer but no live wire driver.
>
> **Image-size caveat (disclosed, not hidden):** Jetleaf's AOT binary still
> needs the project source tree at runtime — its type materializer resolves pod
> classes from the generated registry and package sources. The final image
> removes the Dart SDK but keeps `/app/project`. This is reported as-is in the
> image-size column; do not strip the sources to game that metric.

### 7.1.1 Verified startup behaviour

The compiled binary was booted locally (without Docker) and the endpoints were
exercised end to end:

- `GET /api/v1/ping` → `200 {"status":"ok"}` (no database required).
- `POST /api/v1/orders/validate` → `200` with a priced result using the
  `SAVE10` coupon; invalid payloads return `400`.
- `GET /api/v1/users/:id` and `POST /api/v1/audit` require the seeded
  PostgreSQL instance (verified to reach the driver; the local smoke test had
  no database available).

Two framework-level issues were discovered and fixed during verification:

1. **Synthetic pod types triggered false conversions.** The AOT generator emits
   a synthetic `Class` for a type from a package outside the scanned component
   set, such as `Pool` from `postgres`. `AbstractPodFactory.convertIfNecessary`
   treated that unresolved type as a real conversion target and threw
   `ConverterNotFoundException` for a valid pod instance. Fixed in
   `jetleaf_core`: when the required type is synthetic, the instance is returned
   unchanged. The benchmark now declares the pod as `Pool<void>` directly with
   no wrapper class.
2. **`context.close()` in `main()` shut the server down immediately.** The
   benchmark entry point leaves the context open so the HTTP server stays up.

### 7.2 Other frameworks

Each directory pins its runtime version in its Dockerfile and documents why that version was chosen. GraalVM native image is built in a separate stage and measured separately from the JVM build. Uvicorn worker count is set so the Python process uses the same 2 vCPU budget rather than oversubscribing.

---

## 8. Results and reporting

### 8.1 Raw artifacts

- `results/raw/<framework>_<test>_<vu>.json` — k6 summary exports.
- `results/raw/<framework>_stats.csv` — timestamped docker stats samples.
- `results/raw/metrics.log` — one line per framework per run.
- `results/raw/environment.json` — host and version fingerprint.
- `results/raw/runs.json` — machine-readable combined dataset used by `summarize.py`.

### 8.2 Generated summary

`results/SUMMARY.md` contains:

1. A fairness statement and link to the checklist.
2. Environment table (host, kernel, Docker, CPU, RAM).
3. Per-workload tables: framework, RPS, avg, p95, p99, error rate.
4. Resource table: image size, cold start, idle RSS, peak RSS.
5. A "how to reproduce" block with the exact command and commit hash.
6. Notes on invalidated runs and caveats.

Charts are generated as CSV so anyone can redraw them; no proprietary chart service is required.

---

## 9. Credibility and review

Before publishing any result:

- `report/CHECKLIST.md` is completed for every framework implementation.
- Each implementation is reviewed for accidental shortcuts (caching, disabled validation, reduced pool size).
- All raw JSON is committed; no hand-edited numbers.
- The benchmark commit hash and container digests are recorded in `SUMMARY.md`.
- A second person reproduces at least one framework run on a different host before publication.

---

## 10. Content plan — one run, six posts

1. **Master thread (X/LinkedIn):** "I built the same REST + PostgreSQL API across ten frameworks. Here is what happens when you compile Spring-style DI to native Dart." Link to the repository and `SUMMARY.md`.
2. **Cold-start and RAM chart (r/java, r/SpringBoot):** JVM vs GraalVM native vs Jetleaf — build time, cold start, RSS. Emphasise measurement method.
3. **TypeScript comparison (r/node, r/typescript):** NestJS on Node and Bun vs Jetleaf on the CPU/validation endpoint.
4. **Dart showdown (r/FlutterDev, r/dartlang):** Serverpod vs Dart Frog vs Jetleaf — micro-router speed versus enterprise architecture.
6. **Deep-dive engineering post (Hacker News / dev.to):** "How Jetleaf achieves container-managed DI and REST controllers in AOT Dart without mirrors — and how it compares to Go and .NET."
7. **Upstream pull request:** submit the `frameworks/jetleaf/` implementation to `the-benchmarker/web-frameworks` so Jetleaf appears permanently on their public leaderboard, using their required endpoint and JSON conventions.

Each post links back to the raw artifacts; no chart is published without its source data.

---

## 11. Execution phases

| Phase | Deliverable | Exit criteria |
|---|---|---|
| 0 | This roadmap approved; benchmark folder created; repository skeleton | Folder exists; `README.md`, `docker-compose.yml`, `.env.example` present |
| 1 | Database + k6 scripts + orchestrator | `./run-benchmarks.sh --help` works; seed loads; one framework completes a full dry run |
| 2 | Jetleaf reference implementation | Idiomatic four endpoints; AOT image builds; cold start and RSS measured |
| 3 | Parallel framework implementations | All ten frameworks pass `CHECKLIST.md` and return correct payloads |
| 4 | Reporting pipeline | `SUMMARY.md`, charts CSV, environment fingerprint generated automatically |
| 5 | Verification run | Three clean runs on dedicated host; second-host reproduction of one framework |
| 6 | Publication | Six posts drafted from raw data; upstream PR opened |

---

## 12. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Noisy host skews results | Dedicated VPS, pinned resources, three runs, median reporting, raw samples |
| Unfair framework implementations | Mandatory idiomatic patterns, checklist review, public source |
| Cold start polluted by image pull/build | Build before timing; time only container start to first 200 |
| JVM penalised by no warmup | Mandatory 10 s discarded warmup at 50 VU |
| Python/Node oversubscribe 2 CPUs | Pin worker count and document it |
| GraalVM native build time misreported | Record build time separately from cold start |
| Docker stats snapshot misleading | Sample every second during load; report maximum |
| Benchmark perceived as marketing | Publish raw data, checklist, commit hash, and caveats; never hide invalid runs |

---

## 13. Definition of done

- [ ] `benchmark/` folder exists as a sibling of the `jetleaf/` repository.
- [ ] `./run-benchmarks.sh` completes on a clean Linux host with no manual steps.
- [ ] All ten frameworks implement the four endpoints idiomatically and pass the fairness checklist.
- [ ] `results/SUMMARY.md` is generated from raw JSON, not hand-written.
- [ ] Three full runs with median/range and a second-host reproduction are recorded.
- [ ] Six content pieces drafted and the upstream PR opened.
