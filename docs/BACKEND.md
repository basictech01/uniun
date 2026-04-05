# uniun-backend — Relay Server

This is the Go server that sits between the internet and the Flutter app. It is a **Nostr relay** — meaning it speaks the Nostr WebSocket protocol and stores events. The Flutter app's EmbeddedServer connects to it and syncs data.

---

## What Is a Nostr Relay in Simple Terms?

Think of it like a post office. Users (Flutter apps) send letters (Nostr events). The relay stores them and delivers them to anyone subscribed to that sender. The relay does not know what the letters mean — it just stores and routes them.

The relay speaks a simple protocol over WebSocket:
- `["EVENT", {...}]` — "store this event"
- `["REQ", "sub-id", {...filter}]` — "give me all events matching this filter"
- `["CLOSE", "sub-id"]` — "stop sending me those events"

---

## Tech Stack

| Component | What it is | Why |
|-----------|-----------|-----|
| **Go** | Language | Fast, low memory, good for network servers |
| **Khatru** (`github.com/fiatjaf/khatru`) | Nostr relay framework | Handles all WebSocket + NIP-01 protocol so we don't write it from scratch |
| **BadgerDB** | Primary storage | Embedded key-value store — no separate database process needed |
| **MySQL** | Optional mirror | For extra durability or analytics. BadgerDB is primary, MySQL gets a copy |
| **Blossom** | Media blob storage protocol | How the Flutter app uploads images (Brahma feature) |
| **Azure Blob Storage** | Where media files live | Cloud storage for photos uploaded by users |
| **zerolog** | Logging | Fast structured logging |

---

## File Map

```
uniun-backend/
├── main.go        — starts everything: relay config, BadgerDB, MySQL, Blossom, graceful shutdown
├── config.go      — reads all settings from environment variables
├── logger.go      — sets up zerolog structured logger
└── azure_blob.go  — wires Azure Blob Storage as the Blossom upload/download backend
```

### main.go — the heart

Sets up the Khatru relay, connects storage backends, registers event hooks, starts the WebSocket server.

Two important placeholder functions that need real logic:
- `RejectEvent` — currently accepts every event from anyone. Needs kind allowlist + rate limiting.
- `RejectFilter` — currently allows any subscription query. Needs protection against queries that dump the entire database.

### config.go — all settings from environment variables

Nothing is hardcoded. Every setting comes from an env var with a sensible default.

Key variables:
```
RELAY_URL       — the public WebSocket URL of this relay (e.g. wss://relay.uniun.app)
RELAY_PORT      — port to listen on (default: 8080)
WORKING_DIR     — where BadgerDB files are stored (default: current dir)
MYSQL_DSN       — MySQL connection string (empty = MySQL disabled)
AZURE_FOR_BLOSSOM — true/false, enables Azure for media storage
```

### azure_blob.go — media storage

When `AZURE_FOR_BLOSSOM=true`, images uploaded from the Flutter app's Brahma (create note) feature go to Azure Blob Storage instead of local disk.

Upload flow:
1. Flutter app calls `PUT /upload` on this relay (Blossom protocol)
2. `azure_blob.go` receives the file bytes + SHA-256 hash
3. Stores as `{sha256}.{ext}` in the Azure container
4. Returns the public Azure URL
5. Flutter embeds that URL in the Nostr event's `imeta` tag

---

## How the Flutter App Connects

```
Flutter App
  └─ EmbeddedServer (Dart isolate)
        └─ RelayConnector
              └─ WebSocket connection → ws://localhost:8080 (dev)
                                      → wss://relay.uniun.app (prod)
```

The Flutter app **never** calls this relay directly from Dart UI code. Only the EmbeddedServer (running in a background isolate) handles the WebSocket connection.

---

## What Events This Relay Handles

The relay should only accept these Nostr event kinds (defined in `RejectEvent`):

| Kind | What it is | Used by |
|------|-----------|---------|
| 0 | User profile (name, avatar, bio) | Settings, profile display |
| 1 | Short text note | Vishnu feed, threads |
| 6 | Repost | Feed reposts |
| 7 | Reaction (like/emoji) | Note reactions |
| 13 | Seal (DM encryption layer 2) | DMs |
| 14 | DM chat message (inner content) | DMs |
| 40 | Channel creation | Channels |
| 41 | Channel metadata update | Channels |
| 42 | Channel message | Channels |
| 1059 | Gift wrap (DM encryption outer layer) | DMs |
| 10063 | User's Blossom server list | Media uploads |
| 24242 | Blossom auth token | Media upload authorization |

Everything else should be rejected.

---

## What Needs To Be Built

### Priority 1 — Make it safe to run (without this the relay is wide open)

**`RejectEvent` rules** (currently a stub that accepts everything):

```go
func RejectEvent(ctx context.Context, event *nostr.Event) (reject bool, msg string) {
    // 1. Only accept kinds we actually use
    allowedKinds := map[int]bool{
        0: true, 1: true, 6: true, 7: true, 13: true, 14: true,
        40: true, 41: true, 42: true, 1059: true, 10063: true, 24242: true,
    }
    if !allowedKinds[event.Kind] {
        return true, "blocked: kind not supported"
    }

    // 2. No giant content (spam protection)
    if len(event.Content) > 65536 { // 64KB max
        return true, "blocked: content too large"
    }

    // 3. No events too far in the future (clock manipulation)
    if event.CreatedAt.Time().After(time.Now().Add(time.Hour)) {
        return true, "blocked: event timestamp too far in future"
    }

    return false, ""
}
```

**`RejectFilter` rules** (currently a stub that allows everything):

```go
func RejectFilter(ctx context.Context, filter nostr.Filter) (reject bool, msg string) {
    // Don't allow completely open queries — would return the entire database
    if filter.Authors == nil && filter.IDs == nil && len(filter.Tags) == 0 {
        return true, "blocked: filter too broad — add authors, ids, or tags"
    }
    return false, ""
}
```

### Priority 2 — Local development setup

- [ ] Create `.env.example` — document every env var with example values
- [ ] Create `Dockerfile` — so the relay can run in a container
- [ ] Create `docker-compose.yml` — relay + optional MySQL, one command startup
- [ ] Verify `go mod download && go build ./...` succeeds

**`.env.example`:**
```
RELAY_BIND=0.0.0.0
RELAY_PORT=8080
RELAY_URL=ws://localhost:8080
WORKING_DIR=./data
MYSQL_DSN=
RELAY_NAME=Uniun Relay
RELAY_DESCRIPTION=Uniun social relay
RELAY_CONTACT=
RELAY_PUBKEY=
RELAY_ICON=
RELAY_BANNER=
AZURE_FOR_BLOSSOM=false
AZURE_STORAGE_ACCOUNT_NAME=
AZURE_STORAGE_ACCOUNT_KEY=
AZURE_BLOSSOM_CONTAINER=blossom
LOG_LEVEL=info
```

### Priority 3 — Health check endpoint

Add a `/health` route so monitoring tools can check if the relay is alive:

```go
// In main.go, before relay.Start():
http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]any{
        "status":      "ok",
        "uptime":      time.Since(startTime).String(),
        "connections": liveConnections,
    })
})
```

### Priority 4 — NIP-11 relay info

Khatru automatically serves relay metadata at `GET /` with `Accept: application/nostr+json`. Just make sure `RELAY_PUBKEY` is set to the operator's actual pubkey hex.

Test with:
```bash
curl -H "Accept: application/nostr+json" http://localhost:8080/
```

Should return JSON with name, description, pubkey, etc.

### Priority 5 — Rate limiting (future, before public launch)

Add per-pubkey rate limiting in `RejectEvent`: max 60 events per minute. Use a simple in-memory map with a sliding window counter. Not needed for development, needed before public.

### Priority 6 — Production deployment

- [ ] Nginx reverse proxy for TLS (relay must be `wss://` in prod, not `ws://`)
- [ ] Set `RELAY_URL=wss://relay.yourdomain.com`
- [ ] Enable `AZURE_FOR_BLOSSOM=true` and set Azure credentials
- [ ] Set `MYSQL_DSN` for durable event mirror
- [ ] Docker container with restart policy
- [ ] Set `LOG_LEVEL=warn` (reduce log noise in prod)

---

## Quick Start (Local Development)

```bash
cd uniun-backend

# 1. Copy env file and fill in values
cp .env.example .env

# 2. Download Go dependencies
go mod download

# 3. Run the relay
go run .

# Relay is now at ws://localhost:8080
# Test NIP-11: curl -H "Accept: application/nostr+json" http://localhost:8080/
```

With Docker (once Dockerfile exists):
```bash
docker-compose up
```

---

## Architecture Position

```
Flutter App (Vishnu feed, Brahma create, Channels, DMs)
      ↕ WebSocket NIP-01
uniun-backend  (this relay — Khatru + BadgerDB)
      ↕ optional write mirror
MySQL

Flutter Brahma (attach image)
      → PUT /upload  (Blossom BUD-01 protocol)
uniun-backend Blossom handler
      → Azure Blob Storage → returns public URL → embedded in Nostr event
```

---

## What NOT to Change

- Do not modify `EmbeddedServer` on the Flutter side — that is a separate team's code.
- Do not add custom REST endpoints for app-specific logic — the relay speaks only Nostr protocol.
- Do not store user private keys anywhere on the relay — the relay only sees public keys and signed events.
