#!/bin/bash

# Reviews Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

BASE_URL="http://localhost:8080/api/v1"
HEADERS="-H 'X-Roll-Number: 2024101139' -H 'X-User-ID: 1' -H 'Content-Type: application/json'"
ROLL="2024101139"
USER_ID="1"

echo "---- Reviews Tests ----"

# Helper
req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Get Reviews for a Product (Assume Product 103 exists from previous tests)
echo "1. Get Reviews for Product 103"
req "$BASE_URL/products/103/reviews"
echo -e "\n"

# 2. Add Valid Review
echo "2. Add Valid Review (Rating 5, Comment 'Great!')"
req -X POST -d '{"rating": 5, "comment": "Great!"}' "$BASE_URL/products/103/reviews" -w " Status: %{http_code}"
echo -e "\n"

# Verify review added and average rating updated
echo "Verifying Reviews (Avg Rating should be 5):"
req "$BASE_URL/products/103/reviews"
echo -e "\n"

# 3. Add Invalid Review - Rating > 5
echo "3. Add Invalid Review (Rating 6) - Should Fail 400"
req -X POST -d '{"rating": 6, "comment": "Too good!"}' "$BASE_URL/products/103/reviews" -w " Status: %{http_code}"
echo -e "\n"

# 4. Add Invalid Review - Rating < 1
echo "4. Add Invalid Review (Rating 0) - Should Fail 400"
req -X POST -d '{"rating": 0, "comment": "Too bad!"}' "$BASE_URL/products/103/reviews" -w " Status: %{http_code}"
echo -e "\n"

# 5. Add Invalid Review - Comment Missing or Too Short?
# Docs: Comment must be between 1 and 200 chars.
echo "5. Add Invalid Review (Rating 3, Empty Comment) - Should Fail 400"
req -X POST -d '{"rating": 3, "comment": ""}' "$BASE_URL/products/103/reviews" -w " Status: %{http_code}"
echo -e "\n"

# 6. Add Another Valid Review (Rating 1)
echo "6. Add Valid Review (Rating 1, Comment 'Bad!')"
req -X POST -d '{"rating": 1, "comment": "Bad!"}' "$BASE_URL/products/103/reviews" -w " Status: %{http_code}"
echo -e "\n"

# Verify Average Rating Calculation
# Avg: (5 + 1) / 2 = 3.0.
# Check for integer division bug (e.g. 3) vs float (3.0).
# Let's add Rating 4. Total: 5+1+4=10. Count 3. Avg = 3.33.
echo "7. Add Valid Review (Rating 4) - Check for Decimal Avg"
req -X POST -d '{"rating": 4, "comment": "Okay"}' "$BASE_URL/products/103/reviews"
echo -e "\n"

echo "Verifying Final Reviews (Avg should be ~3.33):"
req "$BASE_URL/products/103/reviews"
echo -e "\n"

echo "---- End Reviews Tests ----"
