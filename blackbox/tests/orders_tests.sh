#!/bin/bash

# Orders API Tests
BASE_URL="http://localhost:8080/api/v1"
ROLL="2024101139"
USER_ID="1"

echo "---- Orders API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# Setup: create an order to work with
echo "0. Setup: clear cart, add product, checkout (COD)"
req -X DELETE "$BASE_URL/cart/clear"
req -X POST -d '{"product_id": 103, "quantity": 1}' "$BASE_URL/cart/add"
CHECKOUT=$(req -X POST -d '{"payment_method": "COD"}' "$BASE_URL/checkout")
echo "$CHECKOUT"
ORDER_ID=$(echo "$CHECKOUT" | grep -oP '"order_id":\s*\K\d+')
echo "Order ID: $ORDER_ID"
echo -e "\n"

# 1. Get all orders
echo "1. GET /orders"
req "$BASE_URL/orders"
echo -e "\n"

# 2. Get one order by ID
echo "2. GET /orders/$ORDER_ID"
req "$BASE_URL/orders/$ORDER_ID"
echo -e "\n"

# 3. Get invoice - check subtotal, GST, and total math
# FAILED: invoice total does not equal subtotal + GST
echo "3. GET /orders/$ORDER_ID/invoice [Bug Test - total may not match subtotal+GST]"
req "$BASE_URL/orders/$ORDER_ID/invoice"
echo -e "\n"

# 4. Note stock of product 103 before cancel
echo "4. GET /admin/products - note stock of product 103 before cancel"
curl -s -H "X-Roll-Number: $ROLL" "$BASE_URL/admin/products"
echo -e "\n"

# 5. Cancel order - stock should restore
# FAILED: stock does not increase after cancellation
echo "5. POST /orders/$ORDER_ID/cancel [Bug Test - stock should restore by +1]"
req -X POST "$BASE_URL/orders/$ORDER_ID/cancel"
echo "Stock after cancel:"
curl -s -H "X-Roll-Number: $ROLL" "$BASE_URL/admin/products"
echo -e "\n"

# 6. Cancel already-cancelled order -> should not return 200
# FAILED: server returns 200 "Order cancelled successfully" on repeat cancel
echo "6. POST /orders/$ORDER_ID/cancel again (expect 400/409) [Bug Test]"
req -X POST "$BASE_URL/orders/$ORDER_ID/cancel" -w " Status: %{http_code}"
echo -e "\n"

# 7. Cancel non-existent order -> 404
echo "7. POST /orders/999999/cancel (expect 404)"
req -X POST "$BASE_URL/orders/999999/cancel" -w " Status: %{http_code}"
echo -e "\n"

# 8. Try to cancel a DELIVERED order -> 400
echo "8. GET /admin/orders - find a DELIVERED order then attempt cancel (expect 400)"
curl -s -H "X-Roll-Number: $ROLL" "$BASE_URL/admin/orders"
echo "(Manually pick a delivered order_id from above and cancel it to verify 400)"
echo -e "\n"

echo "---- End Orders API Tests ----"
