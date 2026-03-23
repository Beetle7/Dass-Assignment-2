#!/bin/bash

# Wallet Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

BASE_URL="http://localhost:8080/api/v1"
HEADERS="-H 'X-Roll-Number: 2024101139' -H 'X-User-ID: 1' -H 'Content-Type: application/json'"
ROLL="2024101139"
USER_ID="1"

echo "---- Wallet Tests ----"

# Helper
req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Get Wallet Balance
echo "1. Get Wallet Balance"
req "$BASE_URL/wallet"
echo -e "\n"

# 2. Add Money - Invalid Amount (0)
echo "2. Add Money (0) - Should Fail 400"
req -X POST -d '{"amount": 0}' "$BASE_URL/wallet/add" -w " Status: %{http_code}"
echo -e "\n"

# 3. Add Money - Create Huge Balance (Invalid > 100000)
echo "3. Add Money (100001) - Should Fail 400"
req -X POST -d '{"amount": 100001}' "$BASE_URL/wallet/add" -w " Status: %{http_code}"
echo -e "\n"

# 4. Add Money - Negative Amount
echo "4. Add Money (-100) - Should Fail 400"
req -X POST -d '{"amount": -100}' "$BASE_URL/wallet/add" -w " Status: %{http_code}"
echo -e "\n"

# 5. Add Money - Valid Amount (5000)
echo "5. Add Money (5000) - Should Success 200"
req -X POST -d '{"amount": 5000}' "$BASE_URL/wallet/add" -w " Status: %{http_code}"
echo -e "\n"

# Verify Updated Balance
echo "Verifying Balance after adding 5000:"
req "$BASE_URL/wallet"
echo -e "\n"

# 6. Pay from Wallet - Insufficient Funds
# Assuming balance is ~5000. Try paying 1000000.
echo "6. Pay from Wallet (1000000) - Should Fail 400 (Insufficient Funds)"
req -X POST -d '{"amount": 1000000}' "$BASE_URL/wallet/pay" -w " Status: %{http_code}"
echo -e "\n"

# 7. Pay from Wallet - Valid Amount (100)
echo "7. Pay from Wallet (100) - Should Success 200"
req -X POST -d '{"amount": 100}' "$BASE_URL/wallet/pay" -w " Status: %{http_code}"
echo -e "\n"

# Verify Updated Balance
echo "Verifying Balance after paying 100:"
req "$BASE_URL/wallet"
echo -e "\n"

# 8. Pay from Wallet - Negative Amount
echo "8. Pay from Wallet (-100) - Should Fail 400"
req -X POST -d '{"amount": -100}' "$BASE_URL/wallet/pay" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Wallet Tests ----"
