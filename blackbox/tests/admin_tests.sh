#!/bin/bash

# Admin Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 (No X-User-ID needed)

BASE_URL="http://localhost:8080/api/v1"
HEADERS="-H 'X-Roll-Number: 2024101139' -H 'Content-Type: application/json'"
ROLL="2024101139"

echo "---- Admin Tests ----"
echo "Note: These endpoints return ALL data in the system."

# Helper
req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "Content-Type: application/json" "$@"
}

# 1. Get All Users
echo "1. Get All Users"
req "$BASE_URL/admin/users"
echo -e "\n"

# 2. Get All Carts
echo "2. Get All Carts"
req "$BASE_URL/admin/carts"
echo -e "\n"

# 3. Get All Orders
echo "3. Get All Orders"
req "$BASE_URL/admin/orders"
echo -e "\n"

# 4. Get All Products (Including Inactive)
echo "4. Get All Products"
req "$BASE_URL/admin/products"
echo -e "\n"

# 5. Get All Coupons
echo "5. Get All Coupons"
req "$BASE_URL/admin/coupons"
echo -e "\n"

# 6. Get All Support Tickets
echo "6. Get All Support Tickets"
req "$BASE_URL/admin/tickets"
echo -e "\n"

# 7. Get All Addresses
echo "7. Get All Addresses"
req "$BASE_URL/admin/addresses"
echo -e "\n"

