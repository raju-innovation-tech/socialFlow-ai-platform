# SocialFlow AI – Invoices & GST Tax Compliance (Phase 7)

## 1. Indian GST Specification

In compliance with Indian Goods and Services Tax (GST) provisions for SaaS software services:
- **Applicable GST Rate**: 18% standard rate.
- **Inclusive Calculation Formula**:
  - `Total Amount Paid` = Customer charged amount.
  - `Taxable Subtotal` = `Total / 1.18`.
  - `GST Tax Amount` = `Total - Taxable Subtotal`.

---

## 2. Invoice Fields & Download Format

Each invoice record (`Invoice`) contains:
- Unique sequential invoice number (`INV-YYYYMM-DDHHMMSS`).
- Taxable subtotal, tax amount, and total paid.
- Currency code (`INR`).
- Payment method (`razorpay`) and gateway payment ID.
- Line items breakdown with billing period start and end dates.
- Downloadable receipt endpoint: `GET /api/v1/billing/invoices/{id}/download`.

