#!/bin/bash

# Addresses API Tests
BASE_URL="http://localhost:8080/api/v1/addresses"
ROLL="2024101139"
USER_ID="1"

echo "---- Addresses API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Add first address (default)
echo "1. POST /addresses - add default HOME address"
ADDR1=$(req -X POST -d '{"label": "HOME", "street": "123 Main Street", "city": "Hyderabad", "pincode": "500001", "is_default": true}' "$BASE_URL")
echo "$ADDR1"
ADDR1_ID=$(echo "$ADDR1" | grep -oP '"address_id":\s*\K\d+')
echo -e "\n"

# 2. Add second address also as default -> previous must unset
# FAILED: server keeps both addresses as default
echo "2. POST /addresses - add second address as default (ADDR1 should unset) [Bug Test]"
ADDR2=$(req -X POST -d '{"label": "OFFICE", "street": "456 Work Lane", "city": "Hyderabad", "pincode": "500002", "is_default": true}' "$BASE_URL")
echo "$ADDR2"
ADDR2_ID=$(echo "$ADDR2" | grep -oP '"address_id":\s*\K\d+')
echo -e "\n"

# 3. Verify only one default exists
# FAILED: both addresses appear with is_default=true
echo "3. GET /addresses - only one default allowed [Bug Test]"
req "$BASE_URL"
echo -e "\n"

# 4. Invalid label -> 400
echo "4. POST /addresses - label 'GARAGE' (expect 400)"
req -X POST -d '{"label": "GARAGE", "street": "789 Side Rd", "city": "Hyderabad", "pincode": "500003", "is_default": false}' "$BASE_URL" -w " Status: %{http_code}"
echo -e "\n"

# 5. Street too short (< 5 chars) -> 400
echo "5. POST /addresses - street 'AB' too short (expect 400)"
req -X POST -d '{"label": "HOME", "street": "AB", "city": "Hyderabad", "pincode": "500004", "is_default": false}' "$BASE_URL" -w " Status: %{http_code}"
echo -e "\n"

# 6. Pincode with non-digit -> 400
# FAILED: server accepts "12345A"
echo "6. POST /addresses - pincode '12345A' has letter (expect 400) [Bug Test]"
req -X POST -d '{"label": "OTHER", "street": "Valid Street Here", "city": "Hyderabad", "pincode": "12345A", "is_default": false}' "$BASE_URL" -w " Status: %{http_code}"
echo -e "\n"

# 7. Pincode wrong length (5 digits) -> 400
echo "7. POST /addresses - pincode '12345' only 5 digits (expect 400)"
req -X POST -d '{"label": "OTHER", "street": "Valid Street Here", "city": "Hyderabad", "pincode": "12345", "is_default": false}' "$BASE_URL" -w " Status: %{http_code}"
echo -e "\n"

# 8. City too short (< 2 chars) -> 400
echo "8. POST /addresses - city 'X' too short (expect 400)"
req -X POST -d '{"label": "OTHER", "street": "Valid Street Here", "city": "X", "pincode": "500005", "is_default": false}' "$BASE_URL" -w " Status: %{http_code}"
echo -e "\n"

# 9. Update address (only street and is_default allowed)
echo "9. PUT /addresses/$ADDR1_ID - update street and is_default"
req -X PUT -d '{"street": "Updated Street 99", "is_default": false}' "$BASE_URL/$ADDR1_ID"
echo -e "\n"

# 10. Verify update returns new data (not old)
echo "10. GET /addresses - verify updated data is shown"
req "$BASE_URL"
echo -e "\n"

# 11. Delete existing address
echo "11. DELETE /addresses/$ADDR2_ID"
req -X DELETE "$BASE_URL/$ADDR2_ID"
echo -e "\n"

# 12. Delete non-existent address -> 404
echo "12. DELETE /addresses/999999 - non-existent (expect 404)"
req -X DELETE "$BASE_URL/999999" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Addresses API Tests ----"
