#!/bin/bash

# Support Tickets API Tests
BASE_URL="http://localhost:8080/api/v1/support"
ROLL="2024101139"
USER_ID="1"

echo "---- Support Tickets API Tests ----"

req() {
    curl -s -H "X-Roll-Number: $ROLL" -H "X-User-ID: $USER_ID" -H "Content-Type: application/json" "$@"
}

# 1. Create ticket (valid)
echo "1. POST /support/ticket - valid subject and message"
TICKET=$(req -X POST -d '{"subject": "Order not received", "message": "My order from last week has not arrived yet."}' "$BASE_URL/ticket")
echo "$TICKET"
TICKET_ID=$(echo "$TICKET" | grep -oP '"ticket_id":\s*\K\d+')
echo -e "\n"

# 2. Verify new ticket starts as OPEN
echo "2. GET /support/tickets - ticket $TICKET_ID must have status OPEN"
req "$BASE_URL/tickets"
echo -e "\n"

# 3. Subject too short (< 5 chars) -> 400
echo "3. POST /support/ticket - subject 'Hi' too short (expect 400)"
req -X POST -d '{"subject": "Hi", "message": "This is a valid message."}' "$BASE_URL/ticket" -w " Status: %{http_code}"
echo -e "\n"

# 4. Message empty -> 400
echo "4. POST /support/ticket - empty message (expect 400)"
req -X POST -d '{"subject": "Valid Subject Here", "message": ""}' "$BASE_URL/ticket" -w " Status: %{http_code}"
echo -e "\n"

# 5. Message too long (> 500 chars) -> 400
LONG_MSG=$(python3 -c "print('A' * 501)")
echo "5. POST /support/ticket - 501 char message (expect 400)"
req -X POST -d "{\"subject\": \"Valid Subject\", \"message\": \"$LONG_MSG\"}" "$BASE_URL/ticket" -w " Status: %{http_code}"
echo -e "\n"

# 6. Verify message saved exactly as written
echo "6. GET /support/tickets/$TICKET_ID - verify full message stored correctly"
req "$BASE_URL/tickets/$TICKET_ID"
echo -e "\n"

# 7. OPEN -> IN_PROGRESS (valid)
echo "7. PUT /support/tickets/$TICKET_ID - OPEN to IN_PROGRESS (expect 200)"
req -X PUT -d '{"status": "IN_PROGRESS"}' "$BASE_URL/tickets/$TICKET_ID" -w " Status: %{http_code}"
echo -e "\n"

# 8. IN_PROGRESS -> CLOSED (valid)
echo "8. PUT /support/tickets/$TICKET_ID - IN_PROGRESS to CLOSED (expect 200)"
req -X PUT -d '{"status": "CLOSED"}' "$BASE_URL/tickets/$TICKET_ID" -w " Status: %{http_code}"
echo -e "\n"

# 9. CLOSED -> OPEN (backwards, invalid) -> 400
echo "9. PUT /support/tickets/$TICKET_ID - CLOSED to OPEN (expect 400)"
req -X PUT -d '{"status": "OPEN"}' "$BASE_URL/tickets/$TICKET_ID" -w " Status: %{http_code}"
echo -e "\n"

# 10. OPEN -> CLOSED (skip IN_PROGRESS, invalid) -> 400
echo "10. Create ticket and try OPEN -> CLOSED directly (expect 400)"
TICKET2=$(req -X POST -d '{"subject": "Second test ticket", "message": "Testing invalid transition."}' "$BASE_URL/ticket")
echo "$TICKET2"
TICKET2_ID=$(echo "$TICKET2" | grep -oP '"ticket_id":\s*\K\d+')
req -X PUT -d '{"status": "CLOSED"}' "$BASE_URL/tickets/$TICKET2_ID" -w " Status: %{http_code}"
echo -e "\n"

echo "---- End Support Tickets API Tests ----"
