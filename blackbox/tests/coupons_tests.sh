#!/bin/bash

# Coupons API Tests
BASE_URL="http://localhost:8080/api/v1"
ROLL="2024101139"
USER_ID="1"

echo "---- Coupons API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# Setup: clear cart and add product with known price
echo "0. Setup: clearing cart, adding Product 102 (qty 2)"
req -X DELETE "$BASE_URL/cart/clear"
req -X POST -d '{"product_id": 102, "quantity": 2}' "$BASE_URL/cart/add"
echo "Current cart:"
req "$BASE_URL/cart"
echo -e "\n"

# 1. Apply expired coupon -> 400
echo "1. POST /coupon/apply - expired 'BIGDEAL500' (expect 400)"
req -X POST -d '{"coupon_code": "BIGDEAL500"}' "$BASE_URL/coupon/apply" -w " Status: %{http_code}"
echo -e "\n"

# 2. Apply coupon when cart is below min value -> 400
# FAILED: server applies coupon even if cart < min_cart_value
echo "2. POST /coupon/apply - 'MEGA500' (min 10000) on cart ~5000 (expect 400) [Bug Test]"
req -X POST -d '{"coupon_code": "MEGA500"}' "$BASE_URL/coupon/apply" -w " Status: %{http_code}"
echo -e "\n"

# 3. Apply valid FIXED discount coupon
echo "3. POST /coupon/apply - 'SAVE200' (fixed -200, min 2000) (expect 200)"
req -X POST -d '{"coupon_code": "SAVE200"}' "$BASE_URL/coupon/apply" -w " Status: %{http_code}"
echo "Cart after SAVE200:"
req "$BASE_URL/cart"
echo -e "\n"

# 4. Remove coupon
echo "4. POST /coupon/remove"
req -X POST "$BASE_URL/coupon/remove"
echo -e "\n"

# 5. Apply PERCENT coupon with cap
echo "5. POST /coupon/apply - 'PERCENT20' (20%, max 200) on ~5000 cart (discount must cap at 200)"
req -X POST -d '{"coupon_code": "PERCENT20"}' "$BASE_URL/coupon/apply" -w " Status: %{http_code}"
echo "Cart after PERCENT20 (verify discount=200, not 1000):"
req "$BASE_URL/cart"
echo -e "\n"

req -X POST "$BASE_URL/coupon/remove"

# 6. Setup smaller cart for uncapped percent test
echo "6. Setup: clear cart, add Product 103 (qty 1, price ~500)"
req -X DELETE "$BASE_URL/cart/clear"
req -X POST -d '{"product_id": 103, "quantity": 1}' "$BASE_URL/cart/add"
echo "POST /coupon/apply - 'PERCENT10' (10%, max 100) on ~500 cart (discount must be 50)"
req -X POST -d '{"coupon_code": "PERCENT10"}' "$BASE_URL/coupon/apply" -w " Status: %{http_code}"
echo "Cart after PERCENT10 (verify discount=50):"
req "$BASE_URL/cart"
echo -e "\n"

# 7. Apply non-existent coupon -> 400/404
echo "7. POST /coupon/apply - 'FAKE999' (expect 400/404)"
req -X POST -d '{"coupon_code": "FAKE999"}' "$BASE_URL/coupon/apply" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Coupons API Tests ----"
