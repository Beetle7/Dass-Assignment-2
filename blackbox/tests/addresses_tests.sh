#!/bin/bash

# Addresses Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

echo "---- Address Tests ----"

# 1. Create a HOME address (Default)
echo "1. Create HOME Address"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"label": "HOME", "street": "1999 Gachibowli Road", "city": "Hyderabad", "pincode": "500032", "is_default": true}' http://localhost:8080/api/v1/addresses
echo -e "\n"

# 2. Create an OFFICE address (New Default)
echo "2. Create OFFICE Address"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"label": "OFFICE", "street": "456 Tech Park", "city": "Bangalore", "pincode": "560100", "is_default": true}' http://localhost:8080/api/v1/addresses
echo -e "\n"

# 3. List all addresses
echo "3. List Addresses"
curl -s -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/addresses
echo -e "\n"

# 4. Invalid Label (Fail - Expect 400)
echo "4. Invalid Label"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"label": "PARK", "street": "Valid Street", "city": "Valid City", "pincode": "123456"}' http://localhost:8080/api/v1/addresses
echo -e "\n"

# 5. Street Too Short (Fail - Expect 400)
echo "5. Street Too Short"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"label": "OTHER", "street": "Road", "city": "Valid City", "pincode": "123456"}' http://localhost:8080/api/v1/addresses
echo -e "\n"

# 6. Street Too Long (Fail - Expect 400)
echo "6. Street Too Long"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"label": "OTHER", "street": "This string is definitely longer than one hundred characters which is the maximum limit allowed for the street field in this specific api endpoint so it should fail", "city": "Valid City", "pincode": "123456"}' http://localhost:8080/api/v1/addresses
echo -e "\n"

# 7. City Too Short (Fail - Expect 400)
echo "7. City Too Short"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"label": "OTHER", "street": "Valid Street", "city": "A", "pincode": "123456"}' http://localhost:8080/api/v1/addresses
echo -e "\n"

# 8. Pincode Invalid Length (Fail - Expect 400)
echo "8. Pincode Invalid Length (3 digits)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"label": "OTHER", "street": "Valid Street", "city": "City", "pincode": "123"}' http://localhost:8080/api/v1/addresses
echo -e "\n"

# 9. Pincode Invalid Characters (Fail - Expect 400)
echo "9. Pincode Invalid Characters (Not digits)"
curl -s -X POST -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"label": "OTHER", "street": "Valid Street", "city": "City", "pincode": "12345A"}' http://localhost:8080/api/v1/addresses
echo -e "\n"

echo "Note: The following update/delete tests require manual insertion of ADDRESS_ID."
echo "Uncomment the following lines and replace ID with a valid ID from test #3"

# echo "10. Update Street & Default Status (Success)"
# curl -s -X PUT -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"street": "Updated Valid Street Name", "is_default": false}' http://localhost:8080/api/v1/addresses/ID
# echo -e "\n"

# echo "11. Try to Update Restricted Fields (Fail/Ignore)"
# curl -s -X PUT -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" -H "Content-Type: application/json" -d '{"label": "OFFICE", "city": "New City"}' http://localhost:8080/api/v1/addresses/ID
# echo -e "\n"

# echo "12. Delete Address (Success)"
# curl -s -X DELETE -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/addresses/ID
# echo -e "\n"

# 13. Delete Non-Existent Address (Fail - Expect 404)
echo "13. Delete Non-Existent Address"
curl -s -X DELETE -H "X-Roll-Number: 2024101139" -H "X-User-ID: 1" http://localhost:8080/api/v1/addresses/999999
echo -e "\n"
