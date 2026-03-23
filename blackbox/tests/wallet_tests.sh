#!/bin/bash

# Wallet API Tests
BASE_URL="http://localhost:8080/api/v1/wallet"
ROLL="2024101139"
USER_ID="1"

echo "---- Wallet API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Get wallet balance
echo "1. GET /wallet"
req "$BASE_URL"
echo -e "\n"

# 2. Add money (0) -> 400
echo "2. POST /wallet/add - amount 0 (expect 400)"
req -X POST -d '{"amount": 0}' "$BASE_URL/add" -w " Status: %{http_code}"
echo -e "\n"

# 3. Add money (negative) -> 400
echo "3. POST /wallet/add - amount -100 (expect 400)"
req -X POST -d '{"amount": -100}' "$BASE_URL/add" -w " Status: %{http_code}"
echo -e "\n"

# 4. Add money (> 100000) -> 400
echo "4. POST /wallet/add - amount 100001 (expect 400)"
req -X POST -d '{"amount": 100001}' "$BASE_URL/add" -w " Status: %{http_code}"
echo -e "\n"

# 5. Add money (valid: 5000)
echo "5. POST /wallet/add - amount 5000 (expect 200)"
req -X POST -d '{"amount": 5000}' "$BASE_URL/add" -w " Status: %{http_code}"
echo "Balance after adding 5000:"
req "$BASE_URL"
echo -e "\n"

# 6. Pay from wallet (insufficient funds)
echo "6. POST /wallet/pay - amount 1000000 (expect 400 insufficient funds)"
req -X POST -d '{"amount": 1000000}' "$BASE_URL/pay" -w " Status: %{http_code}"
echo -e "\n"

# 7. Pay from wallet (valid: 100)
echo "7. POST /wallet/pay - amount 100 (expect 200)"
req -X POST -d '{"amount": 100}' "$BASE_URL/pay" -w " Status: %{http_code}"
echo "Balance after paying 100 (should be 4900):"
req "$BASE_URL"
echo -e "\n"

# 8. Pay from wallet (negative) -> 400
echo "8. POST /wallet/pay - amount -100 (expect 400)"
req -X POST -d '{"amount": -100}' "$BASE_URL/pay" -w " Status: %{http_code}"
echo -e "\n"

# 9. Pay from wallet (0) -> 400
echo "9. POST /wallet/pay - amount 0 (expect 400)"
req -X POST -d '{"amount": 0}' "$BASE_URL/pay" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Wallet API Tests ----"
