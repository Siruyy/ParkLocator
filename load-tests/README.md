# ParkLocator Load Testing

This directory contains k6 load test scripts to validate the scalability of the ParkLocator API.

## Prerequisites

1. **k6 installed**: `brew install k6` (macOS)
2. **Docker running**: `docker-compose up -d` (Postgres + Redis)
3. **API running**: `cd apps/api && npm run start:dev`

## Test Scripts

### 1️⃣ Baseline Search Test
**File**: `1-baseline-search.js`  
**Purpose**: Test venue search under normal load  
**Load**: 500 concurrent users  
**Target**: P95 < 300ms, 0% errors

```bash
k6 run 1-baseline-search.js
```

**What it tests**:
- Venue search (`/venues/nearby`)
- Redis caching effectiveness
- Database query performance
- API responsiveness under normal traffic

### 2️⃣ Availability Spike Test
**File**: `2-availability-spike.js`  
**Purpose**: Simulate "concert ending" scenario with massive traffic spike  
**Load**: 0 → 1000 users in 10 seconds  
**Target**: P95 < 600ms, <5% errors

```bash
# IMPORTANT: Set VENUE_ID environment variable
export VENUE_ID="your-actual-venue-uuid"
k6 run 2-availability-spike.js
```

**What it tests**:
- Availability endpoint (`/venues/:id/availability`)
- Redis cache hit rate during spikes
- System stability under sudden load
- WebSocket broadcast performance

### 3️⃣ Reservation Contention Test
**File**: `3-reservation-contention.js`  
**Purpose**: Validate database locking prevents double-bookings  
**Load**: 100 users simultaneously booking same spot  
**Target**: Exactly 1 success, 99 conflicts, 0 errors

```bash
# CRITICAL: Must set auth token and IDs
export AUTH_TOKEN="your-jwt-token"
export VENUE_ID="your-venue-id"
export LEVEL_ID="your-level-id"
export SPOT_ID="your-spot-id"
k6 run 3-reservation-contention.js
```

**What it tests**:
- Database transaction locking
- Pessimistic write locks
- Conflict error handling
- **Zero double-bookings guarantee**

## Mac M2 Pro Limitations

Your Mac can realistically handle:
- ✅ **500 users**: Comfortable  
- ⚠️ **1000 users**: Push ing limits (monitor CPU/RAM)
- ❌ **10k+ users**: Requires cloud infrastructure

**Tips**:
- Close other apps during testing
- Monitor with Activity Monitor
- If Mac overheats, reduce `target` in test options

## Interpreting Results

### Success Criteria

**Test 1 (Baseline):**
```
✓ http_req_duration..............: avg=150ms p(95)=250ms p(99)=450ms
✓ http_req_failed................: 0.00%
✓ errors.........................: 0.50%
```

**Test 2 (Spike):**
```
✓ http_req_duration..............: p(95)=550ms p(99)=900ms
✓ http_req_failed................: 2.00% (acceptable during spike)
```

**Test 3 (Contention) - CRITICAL:**
```
✓ successful_bookings............: 1 (MUST be exactly 1)
✓ conflicts......................: 99 (MUST be 99)
✓ errors.........................: 0.00% (MUST be 0%)
```

If Test 3 shows `successful_bookings > 1`, you have a **double-booking bug**.

## Monitoring Redis Cache

While tests are running, monitor cache effectiveness:

```bash
# Open Redis CLI
docker exec -it parklocator-redis redis-cli

# Inside Redis CLI, monitor operations
> MONITOR

# Or check cache keys
> KEYS venues:*
> TTL venues:nearby:10.3157:123.8854:5
```

### Good Cache Performance:
- Cache hit rate > 80% during spikes
- TTL counts decrease properly (10s, 9s, 8s...)
- Keys appear with expected patterns

## Full Test Suite

Run all tests sequentially:

```bash
# 1. Baseline
k6 run 1-baseline-search.js

# 2. Wait 30s for cooldown
sleep 30

# 3. Spike test (set VENUE_ID first!)
export VENUE_ID="abc123..."
k6 run 2-availability-spike.js

# 4. Contention (CRITICAL - set all IDs)
export AUTH_TOKEN="eyJhbGc..."
export VENUE_ID="abc..."
export LEVEL_ID="def..."
export SPOT_ID="ghi..."
k6 run 3-reservation-contention.js
```

## Troubleshooting

### "Connection refused"
- Check API is running: `curl http://localhost:3333/api/v1/health`
- Check Docker: `docker ps | grep parklocator`

### "Redis connection failed"
- Start Redis: `docker-compose up -d redis`
- Check logs: `docker logs parklocator-redis`

### Mac overheating
- Reduce user count in test `options.stages`
- Add cooling breaks: `sleep 60` between tests
- Monitor: `top -o cpu`

## Cloud Testing (Future)

For 500k-1M user testing:
1. Deploy API to AWS/GCP
2. Use k6 Cloud or distributed k6
3. Budget: $100-300 for 1-day test

---

**Author**: Antigravity  
**Last Updated**: 2026-01-10
