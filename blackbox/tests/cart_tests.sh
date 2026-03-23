#!/bin/bash

# Cart Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

echo "---- Cart Tests ----"

# Clear Existing Cart
echo "0. Clearing Cart (Setup)"
curl -s -X DELETE -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/cart/clear
echo -e "\n"

# 1. View Empty Cart
echo "1. View Cart (Expect Empty)"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/cart
echo -e "\n"

# 2. Add New Item (Success)
# Modify PRODUCT_ID (101) if necessary
echo "2. Add Item (Product 101, Qty 2)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"product_id": 101, "quantity": 2}' http://localhost:8080/api/v1/cart/add
echo -e "\n"

# 3. Add Same Item Again (Merge Quantity)
echo "3. Add Same Item (Product 101, Qty 1) - Expect Qty 3"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"product_id": 101, "quantity": 1}' http://localhost:8080/api/v1/cart/add
echo -e "\n"

# 4. Add Another Item (Success)
# Modify PRODUCT_ID (102) if necessary
echo "4. Add Another Item (Product 102, Qty 1)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"product_id": 102, "quantity": 1}' http://localhost:8080/api/v1/cart/add
echo -e "\n"

# 5. Invalid Quantity (0) (Fail - Expect 400)
echo "5. Add Invalid Quantity (0)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"product_id": 101, "quantity": 0}' http://localhost:8080/api/v1/cart/add
echo -e "\n"

# 6. Invalid Quantity (Negative) (Fail - Expect 400)
echo "6. Add Invalid Quantity (-5)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"product_id": 101, "quantity": -5}' http://localhost:8080/api/v1/cart/add
echo -e "\n"

# 7. Add Non-Existent Product (Fail - Expect 404)
echo "7. Add Non-Existent Product (99999)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"product_id": 99999, "quantity": 1}' http://localhost:8080/api/v1/cart/add
echo -e "\n"

# 8. Update Quantity (Success)
echo "8. Update Item Quantity (Product 101 to 5)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"product_id": 101, "quantity": 5}' http://localhost:8080/api/v1/cart/update
echo -e "\n"

# 9. Remove Item (Success)
echo "9. Remove Item (Product 102)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"product_id": 102}' http://localhost:8080/api/v1/cart/remove
echo -e "\n"

# 10. Remove Non-Existent Item (Fail - Expect 404)
echo "10. Remove Non-Existent Item (Product 102 - already removed)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"product_id": 102}' http://localhost:8080/api/v1/cart/remove
echo -e "\n"

# 11. View Final Cart (Verify Totals)
echo "11. View Final Cart (Expect Product 101 with Qty 5)"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/cart
echo -e "\n"

# 12. Clear Cart (Success)
echo "12. Clear Cart"
curl -s -X DELETE -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/cart/clear
echo -e "\n"

# 13. Verify Empty Cart
echo "13. Verify Cart is Empty"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/cart
echo -e "\n"
