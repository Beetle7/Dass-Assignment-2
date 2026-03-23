#!/bin/bash

# Cart API Tests
BASE_URL="http://localhost:8080/api/v1/cart"
ROLL="2024101139"
USER_ID="1"

echo "---- Cart API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 0. Clear cart first
echo "0. DELETE /cart/clear - setup"
req -X DELETE "$BASE_URL/clear"
echo -e "\n"

# 1. Get empty cart
echo "1. GET /cart - empty"
req "$BASE_URL"
echo -e "\n"

# 2. Add item (valid, qty 1)
echo "2. POST /cart/add - Product 101, qty 1"
req -X POST -d '{"product_id": 101, "quantity": 1}' "$BASE_URL/add"
echo -e "\n"

# 3. Add same product again -> quantities must accumulate (not replace)
echo "3. POST /cart/add - Product 101, qty 2 again (total should be 3)"
req -X POST -d '{"product_id": 101, "quantity": 2}' "$BASE_URL/add"
req "$BASE_URL"
echo -e "\n"

# 4. Zero quantity -> 400
# FAILED: server accepts quantity 0
echo "4. POST /cart/add - qty 0 (expect 400) [Bug Test]"
req -X POST -d '{"product_id": 102, "quantity": 0}' "$BASE_URL/add" -w " Status: %{http_code}"
echo -e "\n"

# 5. Negative quantity -> 400
# FAILED: server accepts negative quantity and reduces cart total
echo "5. POST /cart/add - qty -1 (expect 400) [Bug Test]"
req -X POST -d '{"product_id": 102, "quantity": -1}' "$BASE_URL/add" -w " Status: %{http_code}"
echo -e "\n"

# 6. Non-existent product -> 404
echo "6. POST /cart/add - product 999999 (expect 404)"
req -X POST -d '{"product_id": 999999, "quantity": 1}' "$BASE_URL/add" -w " Status: %{http_code}"
echo -e "\n"

# 7. Subtotal overflow check: price 120 * qty 2 = 240, not -16
# FAILED: server returns subtotal -16 (signed 8-bit integer overflow)
echo "7. POST /cart/add - Product 13, qty 2 (subtotal must be 240, not -16) [Bug Test]"
req -X POST -d '{"product_id": 13, "quantity": 2}' "$BASE_URL/add"
echo "GET /cart - verify subtotals and total:"
req "$BASE_URL"
echo -e "\n"

# 8. Update item quantity
echo "8. POST /cart/update - Product 101 to qty 5"
req -X POST -d '{"product_id": 101, "quantity": 5}' "$BASE_URL/update"
echo -e "\n"

# 9. Update item to qty 0 -> 400
echo "9. POST /cart/update - Product 101 to qty 0 (expect 400)"
req -X POST -d '{"product_id": 101, "quantity": 0}' "$BASE_URL/update" -w " Status: %{http_code}"
echo -e "\n"

# 10. Remove item
echo "10. POST /cart/remove - Product 101"
req -X POST -d '{"product_id": 101}' "$BASE_URL/remove"
echo -e "\n"

# 11. Remove item not in cart -> 404
echo "11. POST /cart/remove - Product 999999 not in cart (expect 404)"
req -X POST -d '{"product_id": 999999}' "$BASE_URL/remove" -w " Status: %{http_code}"
echo -e "\n"

# 12. Verify cart total = sum of all item subtotals
echo "12. GET /cart - verify total matches sum of subtotals"
req "$BASE_URL"
echo -e "\n"

# 13. Clear cart
echo "13. DELETE /cart/clear"
req -X DELETE "$BASE_URL/clear"
echo -e "\n"

echo "---- End Cart API Tests ----"
