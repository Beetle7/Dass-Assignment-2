#!/bin/bash

# Profile Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

echo "---- Profile Tests ----"

# 1. Get Profile (Success)
echo "1. Get Profile"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/profile
echo -e "\n"

# 2. Update Profile (Success)
echo "2. Update Profile (Success)"
curl -s -X PUT -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"name": "Kavi Updated", "phone": "9876543210"}' http://localhost:8080/api/v1/profile
echo -e "\n"

# 3. Name Too Short (Fail - Expect 400)
echo "3. Update Profile - Name Too Short"
curl -s -X PUT -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"name": "A", "phone": "9876543210"}' http://localhost:8080/api/v1/profile
echo -e "\n"

# 4. Name Too Long (Fail - Expect 400)
echo "4. Update Profile - Name Too Long"
curl -s -X PUT -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"name": "ThisNameIsWayTooLongAndHasMoreThanFiftyCharactersWhichIsForbidden", "phone": "9876543210"}' http://localhost:8080/api/v1/profile
echo -e "\n"

# 5. Phone Invalid (Fail - Expect 400)
echo "5. Update Profile - Phone Invalid"
curl -s -X PUT -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"name": "Valid Name", "phone": "123"}' http://localhost:8080/api/v1/profile
echo -e "\n"
