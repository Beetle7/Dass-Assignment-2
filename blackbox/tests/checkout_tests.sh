#!/bin/bash

# Checkout API Tests
BASE_URL="http://localhost:8080/api/v1"
ROLL="2024101139"
USER_ID="1"

echo "---- Checkout API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Checkout with empty cart -> 400
echo "1. POST /checkout - empty cart (expect 400)"
req -X DELETE "$BASE_URL/cart/clear"
req -X POST -d '{"payment_method": "COD"}' "$BASE_URL/checkout" -w " Status: %{http_code}"
echo -e "\n"

# 2. Invalid payment method -> 400
echo "2. POST /checkout - payment_method 'CASH' (expect 400)"
req -X POST -d '{"product_id": 101, "quantity": 1}' "$BASE_URL/cart/add" > /dev/null
req -X POST -d '{"payment_method": "CASH"}' "$BASE_URL/checkout" -w " Status: %{http_code}"
req -X DELETE "$BASE_URL/cart/clear"
echo -e "\n"

# 3. COD with total > 5000 -> 400
echo "3. POST /checkout - COD on cart > 5000 (expect 400)"
req -X POST -d '{"product_id": 102, "quantity": 5}' "$BASE_URL/cart/add"
req -X POST -d '{"payment_method": "COD"}' "$BASE_URL/checkout" -w " Status: %{http_code}"
req -X DELETE "$BASE_URL/cart/clear"
echo -e "\n"

# 4. COD checkout -> payment_status must be PENDING
# FAILED: server sets payment_status to PAID for COD
echo "4. POST /checkout - COD (payment_status must be PENDING) [Bug Test]"
req -X POST -d '{"product_id": 101, "quantity": 1}' "$BASE_URL/cart/add"
req -X POST -d '{"payment_method": "COD"}' "$BASE_URL/checkout"
echo -e "\n"

# 5. WALLET checkout -> payment_status must be PENDING
# FAILED: server sets payment_status to PAID for WALLET
echo "5. POST /checkout - WALLET (payment_status must be PENDING) [Bug Test]"
req -X POST -d '{"amount": 10000}' "$BASE_URL/wallet/add" > /dev/null
req -X POST -d '{"product_id": 101, "quantity": 1}' "$BASE_URL/cart/add"
req -X POST -d '{"payment_method": "WALLET"}' "$BASE_URL/checkout"
echo -e "\n"

# 6. CARD checkout -> payment_status must be PAID
echo "6. POST /checkout - CARD (payment_status must be PAID)"
req -X POST -d '{"product_id": 101, "quantity": 1}' "$BASE_URL/cart/add"
req -X POST -d '{"payment_method": "CARD"}' "$BASE_URL/checkout"
echo -e "\n"

# 7. Verify GST is 5% applied exactly once
echo "7. POST /checkout - verify total = subtotal * 1.05"
req -X POST -d '{"product_id": 101, "quantity": 1}' "$BASE_URL/cart/add"
req -X POST -d '{"payment_method": "COD"}' "$BASE_URL/checkout"
echo -e "\n"

echo "---- End Checkout API Tests ----"
