#!/bin/bash

# Products API Tests
BASE_URL="http://localhost:8080/api/v1"
ROLL="2024101139"
USER_ID="1"

echo "---- Products API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. List all active products
echo "1. GET /products - list (inactive products must not appear)"
req "$BASE_URL/products"
echo -e "\n"

# 2. Get single product (valid)
echo "2. GET /products/101 - valid product"
req "$BASE_URL/products/101"
echo -e "\n"

# 3. Get single product (non-existent) -> 404
echo "3. GET /products/999999 - non-existent (expect 404)"
req "$BASE_URL/products/999999" -w " Status: %{http_code}"
echo -e "\n"

# 4. Filter by category
echo "4. GET /products?category=Electronics"
req "$BASE_URL/products?category=Electronics"
echo -e "\n"

# 5. Search by name
echo "5. GET /products?search=phone"
req "$BASE_URL/products?search=phone"
echo -e "\n"

# 6. Sort by price ascending
echo "6. GET /products?sort=price_asc"
req "$BASE_URL/products?sort=price_asc"
echo -e "\n"

# 7. Sort by price descending
echo "7. GET /products?sort=price_desc"
req "$BASE_URL/products?sort=price_desc"
echo -e "\n"

# 8. Verify price shown matches stored value
echo "8. GET /products/102 - confirm price matches DB value"
req "$BASE_URL/products/102"
echo -e "\n"

echo "---- End Products API Tests ----"
