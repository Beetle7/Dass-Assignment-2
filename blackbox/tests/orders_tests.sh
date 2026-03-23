#!/bin/bash

# Orders Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

BASE_URL="http://localhost:8080/api/v1"
HEADERS="-H 'X-Roll-Number: 2024101139' -H 'X-User-ID: 1' -H 'Content-Type: application/json'"
ROLL="2024101139"
USER_ID="1"

echo "---- Orders Tests ----"

# Helper
req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Get All Orders
echo "1. Get All Orders"
req "$BASE_URL/orders"
echo -e "\n"

# Verify functionality: List orders. (Should show 3001, 3002, 3003 from checkout tests).

# 2. Get Specific Order (Using 3003 as our latest)
echo "2. Get Order 3003 - Should Succeed 200"
req "$BASE_URL/orders/3003" -w " Status: %{http_code}"
echo -e "\n"

# 3. Get Non-Existent Order
echo "3. Get Order 9999 - Should Fail 404"
req "$BASE_URL/orders/9999" -w " Status: %{http_code}"
echo -e "\n"

# 4. Get Invoice for Order
echo "4. Get Invoice for Order 3003 - Should Succeed 200"
req "$BASE_URL/orders/3003/invoice" -w " Status: %{http_code}"
echo -e "\n"

# 5. Cancel Order (Valid)
# Order 3002 was COD and PLACED. (However, checkout showed PAID, which might imply 'Delivered' later or just paid).
# Docs: "A delivered order cannot be cancelled."
# If PLACED/PAID != DELIVERED, cancel should work.
echo "5. Cancel Order 3002 (PLACED/PAID) - Should Succeed 200"
req -X POST "$BASE_URL/orders/3002/cancel" -w " Status: %{http_code}"
echo -e "\n"

# 6. Verify Cancelled Status
echo "Verifying Order 3002 Status after Cancel:"
req "$BASE_URL/orders/3002"
echo -e "\n"

# 7. Cancel Already Cancelled Order (3002) - Should Fail 400
echo "7. Cancel Order 3002 (Already Cancelled) - Should Fail 400"
req -X POST "$BASE_URL/orders/3002/cancel" -w " Status: %{http_code}"
echo -e "\n"

# 8. Cancel Non-Existent Order
echo "8. Cancel Order 9999 - Should Fail 404"
req -X POST  "$BASE_URL/orders/9999/cancel" -w " Status: %{http_code}"
echo -e "\n"

# 9. Cancel Delivered Order
# From test 1, we saw Order 2038 is DELIVERED.
echo "9. Cancel Delivered Order 2038 - Should Fail 400"
req -X POST "$BASE_URL/orders/2038/cancel" -w " Status: %{http_code}"
echo -e "\n"

# 10. Verify Stock Update after Cancellation & Invoice Calculation Bug
# Verify stock for Product 103 (in Order 3003)
echo "10. Stock Update Verification (Order 3003, Product 103)"
echo "Current Product 103 Info (Before Cancel):"
req "$BASE_URL/products/103"
echo -e "\n"

echo "Cancelling Order 3003..."
req -X POST "$BASE_URL/orders/3003/cancel"
echo -e "\n"

echo "Product 103 Info After Cancellation (Stock should inc):"
req "$BASE_URL/products/103"
echo -e "\n"

# 11. Invoice Calculation Check
# Order 3003 Invoice: Subtotal 80, GST 4. Expected Total 84.
# Previous test output showed 94.
echo "11. Invoice Calculation Verification (Order 3003)"
req "$BASE_URL/orders/3003/invoice"
echo -e "\n"

echo "---- End Orders Tests ----"
