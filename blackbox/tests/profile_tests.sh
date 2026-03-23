#!/bin/bash

# Profile API Tests
BASE_URL="http://localhost:8080/api/v1/profile"
ROLL="2024101139"
USER_ID="1"

echo "---- Profile API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Get profile
echo "1. GET /profile"
req "$BASE_URL"
echo -e "\n"

# 2. Update profile (valid)
echo "2. PUT /profile (valid name + phone)"
req -X PUT -d '{"name": "Kavi Updated", "phone": "9876543210"}' "$BASE_URL"
echo -e "\n"

# 3. Name too short (< 2 chars) -> 400
echo "3. PUT /profile - name too short (expect 400)"
req -X PUT -d '{"name": "A", "phone": "9876543210"}' "$BASE_URL" -w " Status: %{http_code}"
echo -e "\n"

# 4. Name too long (> 50 chars) -> 400
echo "4. PUT /profile - name too long (expect 400)"
req -X PUT -d '{"name": "ThisNameIsWayTooLongAndHasMoreThanFiftyCharactersWhichIsForbidden", "phone": "9876543210"}' "$BASE_URL" -w " Status: %{http_code}"
echo -e "\n"

# 5. Phone not 10 digits -> 400
echo "5. PUT /profile - phone too short (expect 400)"
req -X PUT -d '{"name": "Valid Name", "phone": "123"}' "$BASE_URL" -w " Status: %{http_code}"
echo -e "\n"

# 6. Phone with letters -> 400
echo "6. PUT /profile - phone with letters (expect 400)"
req -X PUT -d '{"name": "Valid Name", "phone": "98765abcde"}' "$BASE_URL" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Profile API Tests ----"
