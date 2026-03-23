#!/bin/bash

# Support Tests
# Prerequisites: Server running on localhost:8080
# Using X-Roll-Number: 2024101139 and X-User-ID: 1

BASE_URL="http://localhost:8080/api/v1"
HEADERS="-H 'X-Roll-Number: 2024101139' -H 'X-User-ID: 1' -H 'Content-Type: application/json'"
ROLL="2024101139"
USER_ID="1"

echo "---- Support Tests ----"

# Helper
req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Get Support Tickets
echo "1. Get Support Tickets (Should be empty initially unless persistence)"
req "$BASE_URL/support/tickets"
echo -e "\n"

# 2. Add Valid Ticket
echo "2. Add Valid Ticket (Subject 'Issue 1', Message 'Help Me')"
# Capture ID. Use grep/sed to extract numeric ID.
# Assuming json format {"ticket_id":123,...}
OUTPUT=$(req -X POST -d '{"subject": "Issue 1", "message": "Help Me"}' "$BASE_URL/support/ticket")
echo "Response: $OUTPUT"
TICKET_ID=$(echo "$OUTPUT" | grep -o '"ticket_id":[0-9]*' | cut -d: -f2)
echo "Extracted Ticket ID: $TICKET_ID"
echo -e "\n"

# Verify Ticket Added and Status OPEN
echo "Verifying Ticket:"
req "$BASE_URL/support/tickets"
echo -e "\n"

# 3. Add Invalid Ticket - Subject Short
echo "3. Add Invalid Ticket (Subject 'Hi') - Should Fail 400"
req -X POST -d '{"subject": "Hi", "message": "Help Me"}' "$BASE_URL/support/ticket" -w " Status: %{http_code}"
echo -e "\n"

# 4. Add Invalid Ticket - Message Short
echo "4. Add Invalid Ticket (Message ' ') - Should Fail 400"
req -X POST -d '{"subject": "Issue 2", "message": ""}' "$BASE_URL/support/ticket" -w " Status: %{http_code}"
echo -e "\n"

# 5. Update Ticket Status - Invalid Transition (OPEN -> CLOSED)
# Use extracted ID
echo "5. Update Ticket $TICKET_ID Status (OPEN -> CLOSED) - Should Fail 400 (Must go via IN_PROGRESS)"
req -X PUT -d '{"status": "CLOSED"}' "$BASE_URL/support/tickets/$TICKET_ID" -w " Status: %{http_code}"
echo -e "\n"

# Verify Status
echo "Verifying Status (Should remain OPEN):"
req "$BASE_URL/support/tickets"
echo -e "\n"

# 6. Update Ticket Status - Valid Transition (OPEN -> IN_PROGRESS)
echo "6. Update Ticket $TICKET_ID Status (OPEN -> IN_PROGRESS) - Should Succeed 200"
req -X PUT -d '{"status": "IN_PROGRESS"}' "$BASE_URL/support/tickets/$TICKET_ID" -w " Status: %{http_code}"
echo -e "\n"

# 7. Update Ticket Status - Valid Transition (IN_PROGRESS -> CLOSED)
echo "7. Update Ticket $TICKET_ID Status (IN_PROGRESS -> CLOSED) - Should Succeed 200"
req -X PUT -d '{"status": "CLOSED"}' "$BASE_URL/support/tickets/$TICKET_ID" -w " Status: %{http_code}"
echo -e "\n"

# 8. Update Ticket Status - Invalid Transition (CLOSED -> OPEN)
echo "8. Update Ticket $TICKET_ID Status (CLOSED -> OPEN) - Should Fail 400"
req -X PUT -d '{"status": "OPEN"}' "$BASE_URL/support/tickets/$TICKET_ID" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Support Tests ----"
