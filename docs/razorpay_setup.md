# SocialFlow AI – Razorpay Gateway Setup & Integration (Phase 7)

## 1. Environment Configuration

Add the following credentials to your `.env` file:

```env
# Razorpay Payment Gateway
RAZORPAY_KEY_ID=rzp_test_your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
```

---

## 2. Checkout Workflow

1. **Order Creation**: Client calls `POST /api/v1/billing/checkout` with `plan_code` and `billing_cycle`.
   - Backend calls Razorpay `/orders` API with amount in sub-units (paise).
   - Returns `order_id`, `amount`, `currency`, `key_id`.
2. **Razorpay Modal**: Flutter Web / Mobile opens Razorpay Standard Checkout using `key_id` and `order_id`.
3. **Payment Verification**: Client receives `razorpay_payment_id`, `razorpay_order_id`, and `razorpay_signature` and sends them to `POST /api/v1/billing/verify-payment`.
4. **Server-Side Signature Check**:
   ```python
   message = f"{order_id}|{payment_id}".encode("utf-8")
   expected = hmac.new(key_secret.encode("utf-8"), message, hashlib.sha256).hexdigest()
   if not hmac.compare_digest(expected, signature):
       raise BadRequestException("Invalid payment signature")
   ```
5. **Activation & Invoice**: Upon verified signature, subscription status is set to `active` and tax invoice is generated.

