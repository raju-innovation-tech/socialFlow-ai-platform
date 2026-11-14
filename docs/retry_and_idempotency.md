# SocialFlow AI – Retry & Idempotency Strategy

## 1. Idempotency & Duplicate Prevention

Duplicate publishing can cause severe brand damage. SocialFlow AI protects against accidental double publishing at multiple layers:

### A. Idempotency Key Architecture
- Each publishing job is assigned a unique idempotency key:
  `SHA-256("{post_id}_{target_id}_{timestamp}")`
- A unique database constraint on `publishing_jobs.idempotency_key` guarantees that the same job cannot be created twice.

### B. Distributed Locking (Redis + PostgreSQL Row Locking)
- When a publishing task begins for a target account, a temporary lock is established:
  `lock:pub:{post_id}:{target_id}` with a 120-second TTL.
- Concurrent publish requests for the same target are rejected with `CONCURRENT_PUBLISHING_BLOCKED`.

### C. Atomic Job Claiming
- Workers claim due jobs using `SELECT ... FOR UPDATE SKIP LOCKED`.
- When multiple worker processes or containers run in parallel, each job is exclusively claimed by exactly one worker.

---

## 2. Retry Policy & Failure Management

### A. Classification of Errors

| Error Category | Examples | Retry Action |
| :--- | :--- | :--- |
| **Temporary / Transient** | Network timeout, 502/503 Bad Gateway, rate limit (429) | **Retry with exponential backoff & jitter** |
| **Permanent / Fatal** | Invalid credentials (401), missing permissions (403), aspect ratio invalid | **Do NOT retry automatically**. Mark failed with clear error message. |
| **Uncertain Outcome** | Connection dropped after HTTP request was dispatched | **Flag for manual reconciliation**. Do not blindly retry to avoid duplicate post. |

### B. Exponential Backoff Formula
$$\text{delay} = \min(\text{max\_delay}, \text{base\_delay} \times 2^{\text{attempt} - 1}) + \text{jitter}$$
- `base_delay`: 30 seconds
- `max_delay`: 3,600 seconds (1 hour)
- `max_retries`: 3 attempts
- `jitter`: Random uniform delay between 0 and 20% of the bounded delay to prevent thundering herd spikes against platform APIs.

