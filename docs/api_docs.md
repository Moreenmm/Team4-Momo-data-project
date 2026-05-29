# MoMo Transactions API Documentation

## Overview

This API provides access to MoMo SMS transaction records. It allows clients to 
retrieve, create, update, and delete transaction records. All endpoints are 
protected with Basic Authentication.

- Base URL: http://localhost:8000
- Authentication: Basic Auth (username and password required on every request)
- Response format: JSON

---

## Authentication

All requests must include an Authorization header with valid credentials.

- Username: admin
- Password: password123

Example header:
Authorization: Basic YWRtaW46cGFzc3dvcmQxMjM=

If credentials are missing or wrong, the API returns a 401 error.

---

## Endpoints

### 1. Get All Transactions

- Method: GET
- URL: /transactions
- Description: Returns a list of all transaction records.

Request example:
curl.exe -u admin:password123 http://localhost:8000/transactions

Response example (200 OK):
[
  {
    "id": 1,
    "type": "incoming_money",
    "amount": 5000,
    "sender": "John Doe",
    "receiver": "You",
    "date": "2024-01-15 08:30:00",
    "body": "You have received 5,000 RWF from John Doe.",
    "status": "completed"
  }
]

---

### 2. Get One Transaction

- Method: GET
- URL: /transactions/{id}
- Description: Returns a single transaction by its ID.

Request example:
curl.exe -u admin:password123 http://localhost:8000/transactions/1

Response example (200 OK):
{
  "id": 1,
  "type": "incoming_money",
  "amount": 5000,
  "sender": "John Doe",
  "receiver": "You",
  "date": "2024-01-15 08:30:00",
  "body": "You have received 5,000 RWF from John Doe.",
  "status": "completed"
}

Error response (404 Not Found):
{
  "error": "Transaction not found."
}

---

### 3. Create a Transaction

- Method: POST
- URL: /transactions
- Description: Adds a new transaction record.

Request example:
curl.exe -u admin:password123 -X POST http://localhost:8000/transactions
-H "Content-Type: application/json"
-d '{"type":"payment","amount":3500,"sender":"You","receiver":"Netflix","date":"2024-01-24 10:00:00","body":"Payment to Netflix","status":"completed"}'

Response example (201 Created):
{
  "message": "Transaction created.",
  "transaction": {
    "id": 21,
    "type": "payment",
    "amount": 3500,
    "sender": "You",
    "receiver": "Netflix",
    "date": "2024-01-24 10:00:00",
    "body": "Payment to Netflix",
    "status": "completed"
  }
}

---

### 4. Update a Transaction

- Method: PUT
- URL: /transactions/{id}
- Description: Updates an existing transaction by its ID.

Request example:
curl.exe -u admin:password123 -X PUT http://localhost:8000/transactions/1
-H "Content-Type: application/json"
-d '{"amount":9999,"status":"updated"}'

Response example (200 OK):
{
  "message": "Transaction updated.",
  "transaction": {
    "id": 1,
    "type": "incoming_money",
    "amount": 9999,
    "sender": "John Doe",
    "receiver": "You",
    "date": "2024-01-15 08:30:00",
    "body": "You have received 5,000 RWF from John Doe.",
    "status": "updated"
  }
}

---

### 5. Delete a Transaction

- Method: DELETE
- URL: /transactions/{id}
- Description: Removes a transaction record by its ID.

Request example:
curl.exe -u admin:password123 -X DELETE http://localhost:8000/transactions/2

Response example (200 OK):
{
  "message": "Transaction deleted.",
  "transaction": {
    "id": 2,
    "type": "payment",
    "amount": 2000,
    "sender": "You",
    "receiver": "MTN"
  }
}

---

## Error Codes

| Code | Meaning                        |
|------|--------------------------------|
| 200  | Request was successful         |
| 201  | New record was created         |
| 401  | Unauthorized, wrong credentials|
| 404  | Record or endpoint not found   |

---

## DSA Notes

Two search methods were implemented and compared:

- Linear Search: Scans through each transaction one by one until the ID matches.
  Time complexity is O(n), meaning it gets slower as the list grows.

- Dictionary Lookup: Stores transactions in a dictionary with the ID as the key.
  Access is direct and does not depend on list size. Time complexity is O(1).

Test results over 10,000 runs:
- Searching for ID 20: linear = 0.008540s, dictionary = 0.000931s
- Searching for ID 10: linear = 0.005106s, dictionary = 0.000873s
- Searching for ID 1:  linear = 0.002947s, dictionary = 0.001950s

Dictionary lookup was faster in all three cases.