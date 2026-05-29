import http.server
import json
import base64
import xml.etree.ElementTree as ET
from urllib.parse import urlparse

# The username and password required to access the API
VALID_USERNAME = "admin"
VALID_PASSWORD = "password123"

# Path to the XML data file
XML_FILE = "data/raw/modified_sms_v2.xml"


def parse_xml():
    # Read the XML file and convert each SMS record into a dictionary
    tree = ET.parse(XML_FILE)
    root = tree.getroot()
    transactions = []
    for sms in root.findall("sms"):
        transaction = {
            "id": int(sms.get("id")),
            "type": sms.get("type"),
            "amount": int(sms.get("amount")),
            "sender": sms.get("sender"),
            "receiver": sms.get("receiver"),
            "date": sms.get("date"),
            "body": sms.get("body"),
            "status": sms.get("status")
        }
        transactions.append(transaction)
    return transactions


# Load all transactions into memory when the server starts
transactions = parse_xml()


def check_auth(handler):
    # Check if the request includes valid Basic Auth credentials
    auth_header = handler.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Basic "):
        return False
    encoded = auth_header.split(" ")[1]
    decoded = base64.b64decode(encoded).decode("utf-8")
    username, password = decoded.split(":", 1)
    return username == VALID_USERNAME and password == VALID_PASSWORD


def send_json(handler, status_code, data):
    # Send a JSON response back to the client
    body = json.dumps(data, indent=2).encode("utf-8")
    handler.send_response(status_code)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", len(body))
    handler.end_headers()
    handler.wfile.write(body)


def get_id_from_path(path):
    # Extract the transaction ID from the URL path, e.g. /transactions/3 returns 3
    parts = path.strip("/").split("/")
    if len(parts) == 2 and parts[1].isdigit():
        return int(parts[1])
    return None


class APIHandler(http.server.BaseHTTPRequestHandler):

    def do_GET(self):
        # Handle GET requests
        if not check_auth(self):
            send_json(self, 401, {"error": "Unauthorized. Please provide valid credentials."})
            return

        transaction_id = get_id_from_path(self.path)

        if self.path == "/transactions":
            # Return all transactions
            send_json(self, 200, transactions)

        elif transaction_id is not None:
            # Return a single transaction by ID
            result = next((t for t in transactions if t["id"] == transaction_id), None)
            if result:
                send_json(self, 200, result)
            else:
                send_json(self, 404, {"error": "Transaction not found."})

        else:
            send_json(self, 404, {"error": "Endpoint not found."})

    def do_POST(self):
        # Handle POST requests to add a new transaction
        if not check_auth(self):
            send_json(self, 401, {"error": "Unauthorized. Please provide valid credentials."})
            return

        if self.path == "/transactions":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            new_transaction = json.loads(body)

            # Assign a new ID based on the current highest ID
            new_transaction["id"] = max(t["id"] for t in transactions) + 1
            transactions.append(new_transaction)
            send_json(self, 201, {"message": "Transaction created.", "transaction": new_transaction})
        else:
            send_json(self, 404, {"error": "Endpoint not found."})

    def do_PUT(self):
        # Handle PUT requests to update an existing transaction
        if not check_auth(self):
            send_json(self, 401, {"error": "Unauthorized. Please provide valid credentials."})
            return

        transaction_id = get_id_from_path(self.path)
        if transaction_id is not None:
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            updated_data = json.loads(body)

            for i, t in enumerate(transactions):
                if t["id"] == transaction_id:
                    transactions[i].update(updated_data)
                    send_json(self, 200, {"message": "Transaction updated.", "transaction": transactions[i]})
                    return

            send_json(self, 404, {"error": "Transaction not found."})
        else:
            send_json(self, 404, {"error": "Endpoint not found."})

    def do_DELETE(self):
        # Handle DELETE requests to remove a transaction
        if not check_auth(self):
            send_json(self, 401, {"error": "Unauthorized. Please provide valid credentials."})
            return

        transaction_id = get_id_from_path(self.path)
        if transaction_id is not None:
            for i, t in enumerate(transactions):
                if t["id"] == transaction_id:
                    removed = transactions.pop(i)
                    send_json(self, 200, {"message": "Transaction deleted.", "transaction": removed})
                    return

            send_json(self, 404, {"error": "Transaction not found."})
        else:
            send_json(self, 404, {"error": "Endpoint not found."})

    def log_message(self, format, *args):
        # Print a simple log line for each request
        print(f"Request: {args[0]} {args[1]}")


if __name__ == "__main__":
    server = http.server.HTTPServer(("localhost", 8000), APIHandler)
    print("Server running at http://localhost:8000")
    print("Press Ctrl+C to stop.")
    server.serve_forever()