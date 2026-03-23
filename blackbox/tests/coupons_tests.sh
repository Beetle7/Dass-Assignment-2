#!/bin/bash

# Coupons Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

BASE_URL="http://localhost:8080/api/v1"
HEADERS="-H 'X-Roll-Number: 2024101139' -H 'X-User-ID: 1' -H 'Content-Type: application/json'"
ROLL="2024101139"
USER_ID="1"

echo "---- Coupons Tests ----"

# Setup: Clear Cart & Add Item
# We assume Product 102 exists and has a price (e.g. 2500).
# If Product 102 does not exist, this script might fail. 
# Ideally we'd fetch a product ID first, but for now we rely on previous context.

echo "0. Setup: Clearing Cart..."
curl -s -X DELETE -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" "$BASE_URL/cart/clear"
echo -e "\n"

echo "Adding Product 102 (Qty 2) to cart..."
curl -s -X POST -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" -d '{"product_id": 102, "quantity": 2}' "$BASE_URL/cart/add"
echo -e "\n"

echo "Verifying Cart Total:"
curl -s -X GET -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" "$BASE_URL/cart"
echo -e "\n"


# 1. EXPIRATION TEST
# Coupon: BIGDEAL500 (Expired 2026-03-20)
echo "1. Applying Expired Coupon 'BIGDEAL500' (Should Fail 400)"
curl -s -X POST -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" \
    -d '{"coupon_code": "BIGDEAL500"}' "$BASE_URL/coupon/apply" \
    -w " Status: %{http_code}"
echo -e "\n"


# 2. MINIMUM CART VALUE TEST
# Coupon: MEGA500 (Min Cart 10000). Current Cart approx 5000.
echo "2. Applying 'MEGA500' (Min 10000) on cart ~5000 (Should Fail 400)"
curl -s -X POST -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" \
    -d '{"coupon_code": "MEGA500"}' "$BASE_URL/coupon/apply" \
    -w " Status: %{http_code}"
echo -e "\n"


# 3. SUCCESSFUL FIXED DISCOUNT
# Coupon: SAVE200 (Min 2000, Fixed 200). Current Cart > 2000.
echo "3. Applying Valid Coupon 'SAVE200' (Should Success 200)"
curl -s -X POST -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" \
    -d '{"coupon_code": "SAVE200"}' "$BASE_URL/coupon/apply" \
    -w " Status: %{http_code}"
echo -e "\n"

# Verify Discount applied
echo "Verifying Cart after SAVE200:"
curl -s -X GET -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" "$BASE_URL/cart"
echo -e "\n"


# 4. REMOVE COUPON
echo "4. Removing Coupon"
curl -s -X POST -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" "$BASE_URL/coupon/remove"
echo -e "\n"


# 5. SUCCESSFUL PERCENT DISCOUNT (CAPPED)
# Coupon: PERCENT20 (20%, Max 200). Cart ~5000. 20% = 1000. Cap = 200.
echo "5. Applying 'PERCENT20' (Should Success, Capped at 200)"
curl -s -X POST -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" \
    -d '{"coupon_code": "PERCENT20"}' "$BASE_URL/coupon/apply" \
    -w " Status: %{http_code}"
echo -e "\n"

# Verify Cap
echo "Verifying Cart after PERCENT20 (Check discount=200):"
curl -s -X GET -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" "$BASE_URL/cart"
echo -e "\n"


# 6. INVALID COUPON
echo "6. Applying Invalid Coupon 'FAKE123' (Should Fail 400/404)"
curl -s -X POST -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" \
    -d '{"coupon_code": "FAKE123"}' "$BASE_URL/coupon/apply" \
    -w " Status: %{http_code}"
echo -e "\n"


# 7. PERCENT DISCOUNT (UNCAPPED)
# Setup: Smaller Cart
echo "7. Setup: Reduce Cart for uncapped percent test"
curl -s -X DELETE -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" "$BASE_URL/cart/clear"

# Add Product 103 (Qty 1) - Assuming price 500
echo "Adding Product 103 (Qty 1) to cart..."
curl -s -X POST -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" -d '{"product_id": 103, "quantity": 1}' "$BASE_URL/cart/add"

# Coupon: PERCENT10 (10%, Max 100). Cart 500. 10% = 50. Below Cap.
echo "Applying 'PERCENT10' on 500 cart (Should Success, Discount 50)"
curl -s -X POST -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" \
    -d '{"coupon_code": "PERCENT10"}' "$BASE_URL/coupon/apply" \
    -w " Status: %{http_code}"
echo -e "\n"

echo "Verifying Cart Final State:"
curl -s -X GET -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" "$BASE_URL/cart"
echo -e "\n"
