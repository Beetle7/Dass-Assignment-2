#!/bin/bash

# Admin API Tests
BASE_URL="http://localhost:8080/api/v1"
ROLL="2024101139"

echo "---- Admin API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "Content-Type: application/json" "$@"
}

# 1. Missing X-Roll-Number -> 401
echo "1. No X-Roll-Number header (expect 401)"
curl -s "http://localhost:8080/api/v1/admin/users" -w " Status: %{http_code}"
echo -e "\n"

# 2. Invalid X-Roll-Number (letters) -> 400
echo "2. Invalid X-Roll-Number 'abc' (expect 400)"
curl -s -H "X-Roll-Number: abc" "http://localhost:8080/api/v1/admin/users" -w " Status: %{http_code}"
echo -e "\n"

# 3. Get all users
echo "3. GET /admin/users"
req "$BASE_URL/admin/users"
echo -e "\n"

# 4. Get one specific user
echo "4. GET /admin/users/1"
req "$BASE_URL/admin/users/1"
echo -e "\n"

# 5. Get all carts
echo "5. GET /admin/carts"
req "$BASE_URL/admin/carts"
echo -e "\n"

# 6. Get all orders
echo "6. GET /admin/orders"
req "$BASE_URL/admin/orders"
echo -e "\n"

# 7. Get all products (including inactive)
echo "7. GET /admin/products (includes inactive)"
req "$BASE_URL/admin/products"
echo -e "\n"

# 8. Get all coupons (including expired)
echo "8. GET /admin/coupons (includes expired)"
req "$BASE_URL/admin/coupons"
echo -e "\n"

# 9. Get all support tickets
echo "9. GET /admin/tickets"
req "$BASE_URL/admin/tickets"
echo -e "\n"

# 10. Get all addresses
echo "10. GET /admin/addresses"
req "$BASE_URL/admin/addresses"
echo -e "\n"

echo "---- End Admin API Tests ----"
