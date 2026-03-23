#!/bin/bash

# Loyalty API Tests
BASE_URL="http://localhost:8080/api/v1"
ROLL="2024101139"
USER_ID="1"

echo "---- Loyalty API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Get loyalty points
echo "1. GET /loyalty"
req "$BASE_URL/loyalty"
echo -e "\n"

# 2. Redeem 0 points -> 400
echo "2. POST /loyalty/redeem - amount 0 (expect 400)"
req -X POST -d '{"amount": 0}' "$BASE_URL/loyalty/redeem" -w " Status: %{http_code}"
echo -e "\n"

# 3. Redeem negative points -> 400
echo "3. POST /loyalty/redeem - amount -10 (expect 400)"
req -X POST -d '{"amount": -10}' "$BASE_URL/loyalty/redeem" -w " Status: %{http_code}"
echo -e "\n"

# 4. Redeem more than balance -> 400
echo "4. POST /loyalty/redeem - amount 100000 (expect 400 insufficient)"
req -X POST -d '{"amount": 100000}' "$BASE_URL/loyalty/redeem" -w " Status: %{http_code}"
echo -e "\n"

# 5. Redeem 1 point (valid if balance >= 1)
# FAILED: returns 'Points must be >= 1' even for valid input
echo "5. POST /loyalty/redeem - amount 1 [Bug Test if fails with >= 1 balance]"
req -X POST -d '{"amount": 1}' "$BASE_URL/loyalty/redeem" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Loyalty API Tests ----"
