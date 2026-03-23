# Blackbox Testing Report

---

## Profile API
No bugs found. Retrieval and update (name/phone validation) work as documented.

---

## Addresses API

1. (Test 3) Multiple default addresses allowed — adding a second default address does not unset the first. Server returns both with `is_default: true`.
2. (Test 6) Pincode accepts non-digit characters — `"12345A"` is accepted without error. Should return 400.

---

## Products API
No bugs found. Active/inactive filtering, single-product lookup (404 on missing), category filter, name search, and price sort all work correctly.

---

## Cart API

1. (Test 4, 5) Zero and negative quantities accepted — `POST /cart/add` with `quantity: 0` or `quantity: -1` returns 200. Should return 400. Adding a negative quantity also reduces the cart total incorrectly.
2. (Test 7) Subtotal integer overflow — adding product with unit price 120, quantity 2 returns subtotal `-16` instead of `240`. The server appears to use a signed 8-bit integer for the calculation (`240` wraps to `-16`). Cart total is also wrong as a result.

---

## Coupons API

1. (Test 2) Minimum cart value not enforced — `MEGA500` (requires cart ≥ 10000) was applied to a cart worth ~5000. Should return 400.

---

## Checkout API

1. (Test 4, 5) COD and WALLET orders created with `payment_status: PAID` — should be `PENDING`. Only CARD should start as PAID.

---

## Wallet API
No bugs found. Balance retrieval, add (with 0/negative/overlimit rejection), and pay (with insufficient-funds check) all work as documented.

---

## Loyalty API

1. (Test 5) Redeeming 1 point fails with `"Points must be >= 1"` even when the input is `1`. This suggests the validation is checking `> 1` instead of `>= 1`, or there is an off-by-one error. 

---

## Orders API

1. (Test 3) Invoice total is wrong — observed: subtotal 80 + GST 4 = 84, but API returned total 94. Extra 10 is being added somewhere.
2. (Test 6) Cancelling an already-cancelled order returns 200 `"Order cancelled successfully"` instead of 400 or 409.
3. (Test 5) Stock not restored on cancellation — product stock does not increase after an order is cancelled. This will cause inventory to permanently deplete for every cancelled order.

---

## Reviews API

1. (Test 5, 6) Rating bounds not enforced — `rating: 0` and `rating: 6` both return 200. Should return 400.

---

## Support Tickets API
No bugs found. Ticket creation, subject/message validation, initial OPEN status, and state transitions (OPEN → IN_PROGRESS → CLOSED, with invalid transitions rejected) all work correctly.

---

## Admin API
No bugs found. All admin endpoints (`/users`, `/users/{id}`, `/carts`, `/orders`, `/products`, `/coupons`, `/tickets`, `/addresses`) return correct data.
