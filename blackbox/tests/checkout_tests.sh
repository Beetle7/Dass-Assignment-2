#!/bin/bash

# Checkout Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

BASE_URL="http://localhost:8080/api/v1"
HEADERS="-H 'X-Roll-Number: 2024101139' -H 'X-User-ID: 1' -H 'Content-Type: application/json'"
ROLL="2024101139"
USER_ID="1"

echo "---- Checkout Tests ----"

# Helper
req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

echo "0. Setup: Clear Cart"
req -X DELETE "$BASE_URL/cart/clear"
echo -e "\n"

# 1. Checkout Empty Cart
echo "1. Checkout Empty Cart (Should Fail 400)"
req -X POST -d '{"payment_method": "COD"}' "$BASE_URL/checkout" -w " Status: %{http_code}"
echo -e "\n"

# 2. Setup: Cart Value > 5000
# Product 102 (Price ~2500) Qty 3 => 7500.
echo "2. Setup: Add High Value Items (Prod 102, Qty 3)"
req -X POST -d '{"product_id": 102, "quantity": 3}' "$BASE_URL/cart/add"
echo -e "\n"

echo "Verifying Cart Total (Check for Overflow Bug):"
req "$BASE_URL/cart"
echo -e "\n"

# 3. Checkout COD > 5000
# Expected: 400 (Allocated limit exceeded).
# If Cart Total is bugged (0 or negative), this might PASS (Bug).
echo "3. Checkout COD with Total > 5000 (Should Fail 400)"
req -X POST -d '{"payment_method": "COD"}' "$BASE_URL/checkout" -w " Status: %{http_code}"
echo -e "\n"

# 4. Checkout Invalid Payment Method
echo "4. Checkout Invalid Method 'BITCOIN' (Should Fail 400)"
req -X POST -d '{"payment_method": "BITCOIN"}' "$BASE_URL/checkout" -w " Status: %{http_code}"
echo -e "\n"

# 5. Successful Checkout CARD (> 5000 allowed)
echo "5. Checkout CARD (> 5000 allowed) - Should be PAID"
req -X POST -d '{"payment_method": "CARD"}' "$BASE_URL/checkout" -w " Status: %{http_code}"
echo -e "\n"

# Cart should be empty after successful checkout?
echo "Verifying Cart Empty after Checkout:"
req "$BASE_URL/cart"
echo -e "\n"

# 6. Setup: Low Value Cart < 5000
# Product 103 (Price ~500) Qty 1
echo "6. Setup: Add Low Value Item (Prod 103, Qty 1)"
req -X POST -d '{"product_id": 103, "quantity": 1}' "$BASE_URL/cart/add"
echo -e "\n"

# 7. Successful Checkout COD (< 5000)
echo "7. Checkout COD (< 5000) - Should be PENDING"
req -X POST -d '{"payment_method": "COD"}' "$BASE_URL/checkout" -w " Status: %{http_code}"
echo -e "\n"

# 8. Setup: Wallet Payment
# Add item again
req -X POST -d '{"product_id": 103, "quantity": 1}' "$BASE_URL/cart/add"
# Ensure wallet has funds (Wallet Tests should be run before this, or we rely on default balance?)
# Let's add funds just in case.
echo "Adding 1000 to Wallet for test..."
req -X POST -d '{"amount": 1000}' "$BASE_URL/wallet/add"

echo "8. Checkout WALLET (< 5000) - Should be PENDING/PAID depending on implementation (Docs say PENDING)"
req -X POST -d '{"payment_method": "WALLET"}' "$BASE_URL/checkout" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Checkout Tests ----"
