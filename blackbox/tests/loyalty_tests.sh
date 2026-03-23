#!/bin/bash

# Loyalty Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

BASE_URL="http://localhost:8080/api/v1"
HEADERS="-H 'X-Roll-Number: 2024101139' -H 'X-User-ID: 1' -H 'Content-Type: application/json'"
ROLL="2024101139"
USER_ID="1"

echo "---- Loyalty Tests ----"

# Helper
req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Get Loyalty Points
echo "1. Get Loyalty Points"
req "$BASE_URL/loyalty"
echo -e "\n"

# 2. Redeem Points (0) - Should Fail 400
echo "2. Redeem Points (0) - Should Fail 400"
req -X POST -d '{"amount": 0}' "$BASE_URL/loyalty/redeem" -w " Status: %{http_code}"
echo -e "\n"

# 3. Redeem Points (Negative) - Should Fail 400
echo "3. Redeem Points (-10) - Should Fail 400"
req -X POST -d '{"amount": -10}' "$BASE_URL/loyalty/redeem" -w " Status: %{http_code}"
echo -e "\n"

# 4. Redeem Points (Insufficient)
# Attempt to redeem 100000. Assuming current is low (we likely have 0 unless orders earned points).
echo "4. Redeem Points (100000) - Should Fail 400"
req -X POST -d '{"amount": 100000}' "$BASE_URL/loyalty/redeem" -w " Status: %{http_code}"
echo -e "\n"

# 5. Check if we have points to redeem
# (Assuming orders in checkout may have added points - but logic is unclear in docs)
# Let's try redeeming 1 point if possible or fail gracefully.
echo "5. Redeem Points (1) - Expect failure if 0 balance, success if earned."
req -X POST -d '{"amount": 1}' "$BASE_URL/loyalty/redeem" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Loyalty Tests ----"
