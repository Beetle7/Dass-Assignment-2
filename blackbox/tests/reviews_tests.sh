#!/bin/bash

# Reviews API Tests
BASE_URL="http://localhost:8080/api/v1/products"
ROLL="2024101139"
USER_ID="1"
PRODUCT_ID="101"

echo "---- Reviews API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Get reviews for a product (may be empty)
echo "1. GET /products/$PRODUCT_ID/reviews"
req "$BASE_URL/$PRODUCT_ID/reviews"
echo -e "\n"

# 2. Add valid review (rating 5)
echo "2. POST /products/$PRODUCT_ID/reviews - rating 5"
req -X POST -d '{"rating": 5, "comment": "Excellent product, very happy!"}' "$BASE_URL/$PRODUCT_ID/reviews" -w " Status: %{http_code}"
echo -e "\n"

# 3. Add valid review (rating 1)
echo "3. POST /products/$PRODUCT_ID/reviews - rating 1"
req -X POST -d '{"rating": 1, "comment": "Not great."}' "$BASE_URL/$PRODUCT_ID/reviews" -w " Status: %{http_code}"
echo -e "\n"

# 4. Verify average is decimal not integer (5+1)/2 = 3.0
echo "4. GET /products/$PRODUCT_ID/reviews - average of [5,1] should be 3.0"
req "$BASE_URL/$PRODUCT_ID/reviews"
echo -e "\n"

# 5. Rating 0 -> 400
# FAILED: server accepts rating 0
echo "5. POST /products/$PRODUCT_ID/reviews - rating 0 (expect 400) [Bug Test]"
req -X POST -d '{"rating": 0, "comment": "Zero rating"}' "$BASE_URL/$PRODUCT_ID/reviews" -w " Status: %{http_code}"
echo -e "\n"

# 6. Rating 6 -> 400
# FAILED: server accepts rating 6
echo "6. POST /products/$PRODUCT_ID/reviews - rating 6 (expect 400) [Bug Test]"
req -X POST -d '{"rating": 6, "comment": "Over max"}' "$BASE_URL/$PRODUCT_ID/reviews" -w " Status: %{http_code}"
echo -e "\n"

# 7. Comment empty (0 chars) -> 400
echo "7. POST /products/$PRODUCT_ID/reviews - empty comment (expect 400)"
req -X POST -d '{"rating": 3, "comment": ""}' "$BASE_URL/$PRODUCT_ID/reviews" -w " Status: %{http_code}"
echo -e "\n"

# 8. Comment too long (> 200 chars) -> 400
LONG_COMMENT=$(python3 -c "print('A' * 201)")
echo "8. POST /products/$PRODUCT_ID/reviews - 201 char comment (expect 400)"
req -X POST -d "{\"rating\": 3, \"comment\": \"$LONG_COMMENT\"}" "$BASE_URL/$PRODUCT_ID/reviews" -w " Status: %{http_code}"
echo -e "\n"

# 9. Reviews for non-existent product -> 404
echo "9. GET /products/999999/reviews (expect 404)"
req "$BASE_URL/999999/reviews" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Reviews API Tests ----"
