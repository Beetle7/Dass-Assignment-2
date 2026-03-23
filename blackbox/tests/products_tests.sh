#!/bin/bash

# Products Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

echo "---- Products Tests ----"

# 1. Get All Products (Success)
echo "1. Get All Products"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/products
echo -e "\n"

# 2. Search Product by ID (Success - assuming ID 101 exists)
echo "2. Get Product by ID (101)"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/products/101
echo -e "\n"

# 3. Search Non-Existent Product (Fail - Expect 404)
echo "3. Get Non-Existent Product (99999)"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/products/99999
echo -e "\n"

# 4. Search by Name
echo "4. Search by Name 'Smartphone'"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" "http://localhost:8080/api/v1/products?search=Smartphone"
echo -e "\n"

# 5. Filter by Category
echo "5. Filter by Category 'Electronics'"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" "http://localhost:8080/api/v1/products?category=Electronics"
echo -e "\n"

# 6. Sort Price Ascending
echo "6. Sort Price Ascending"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" "http://localhost:8080/api/v1/products?sort=price_asc"
echo -e "\n"

# 7. Sort Price Descending
echo "7. Sort Price Descending"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" "http://localhost:8080/api/v1/products?sort=price_desc"
echo -e "\n"
