# Pocket NOC

A production-ready network diagnostics and infrastructure toolkit for iOS and Android.

Pocket NOC helps engineers and IT professionals diagnose network issues, check connectivity, and inspect infrastructure from their mobile device.

## Features

- **Ping** - Latency testing with min/max/avg/packet loss
- **Traceroute** - Network path analysis with per-hop latency
- **DNS Lookup** - Query A, AAAA, CNAME, MX, TXT, NS records
- **Reverse DNS** - PTR record lookup from IP addresses
- **Port Check** - TCP connection test with latency measurement
- **HTTP Headers** - Inspect response headers and status codes
- **TLS Certificate** - Check certificate validity, issuer, expiry
- **Subnet Calculator** - CIDR math: network, broadcast, usable range
- **Diagnostic Report** - Run multiple checks on one target, export as text
- **AI Explanation** - Get beginner-friendly analysis of diagnostic results
- **Saved Targets** - Save servers, routers, devices with tags and notes

## Tech Stack

### Mobile App
- Flutter 3.x with Dart
- Riverpod for state management
- GoRouter for navigation
- Hive for local storage
- Dio for HTTP client
- Platform channels for native networking (Swift/Kotlin)

### Backend
- FastAPI (Python)
- PostgreSQL with SQLModel
- Docker Compose for local development

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart SDK 3.x
- Xcode (for iOS)
- Android Studio (for Android)
- Docker and Docker Compose (for backend)

### Run the Flutter app

```bash
# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run -d ios

# Run on Android emulator
flutter run -d android

# Run tests
flutter test
```

### Run the backend

```bash
# Copy environment file
cp backend/.env.example backend/.env

# Start with Docker Compose
docker compose up -d

# API will be available at http://localhost:8000
# Health check: GET http://localhost:8000/api/health
```

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | Health check |
| POST | `/api/ai/explain` | Get AI explanation of diagnostic results |
| POST | `/api/reports/save` | Save a diagnostic report |
| GET | `/api/reports` | List saved reports |

## Project Structure

```
lib/
  core/
    constants/     # App constants
    models/        # Data models (Target, DiagnosticResult)
    providers/     # Riverpod providers
    router/        # GoRouter configuration
    services/      # API, storage, networking services
    theme/         # App theme (dark/light)
    utils/         # Subnet calculator, utilities
    widgets/       # Shared widgets
  features/
    onboarding/    # First-launch flow
    dashboard/     # Main dashboard with tools grid
    targets/       # Saved targets CRUD
    ping/          # Ping tool
    traceroute/    # Traceroute tool
    dns/           # DNS lookup tool
    reverse_dns/   # Reverse DNS tool
    port_check/    # Port check tool
    http_headers/  # HTTP headers tool
    tls_check/     # TLS certificate tool
    subnet_calc/   # Subnet calculator
    report/        # Diagnostic report generator
    ai_explain/    # AI explanation screen
    settings/      # App settings

ios/Runner/
  NetworkChannelHandler.swift   # Native iOS networking

android/app/src/main/kotlin/
  NetworkChannelHandler.kt      # Native Android networking

backend/
  app/
    api/routes.py       # API endpoints
    models/report.py    # Database models
    services/           # Business logic
    main.py             # FastAPI app
  Dockerfile
  requirements.txt
```

## Security and Compliance

This app performs standard network diagnostics only:
- No packet sniffing
- No vulnerability scanning or exploitation
- No aggressive or offensive scanning
- No VPN interception
- All operations are read-only and non-intrusive
- All user data is stored locally and can be exported or deleted

## App Store Description

Pocket NOC is a professional network diagnostics toolkit for engineers and IT professionals. Test connectivity, inspect certificates, look up DNS records, check ports, and calculate subnets from your phone. Clean interface, fast results, no clutter.

## License

Proprietary. All rights reserved.
