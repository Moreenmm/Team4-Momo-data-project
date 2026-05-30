import http.server
import json
import base64
import xml.etree.ElementTree as ET
from urllib.parse import urlparse

VALID_USERNAME = "admin"
VALID_PASSWORD = "password123"

XML_FILE = "data/raw/modified_sms_v2.xml"


def parse_xml():
    tree = ET.parse(XML_FILE)
    root = tree.getroot()
    transactions = []
    for index, sms in enumerate(root.findall("sms"), start=1):
        transaction = {
            "id": index,
            "address": sms.get("address"),
            "date": sms.get("date"),
            "type": sms.get("type"),
            "body": sms.get("body"),
            "service_center": sms.get("service_center"),
            "status": sms.get("status"),
            "readable_date": sms.get("readable_date"),
            "contact_name": sms.get("contact_name")
        }
        transactions.append(transaction)
    return transactions


transactions = parse_xml()


def check_auth(handler):
    auth_header = handler.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Basic "):
        return False
    encoded = auth_header.split(" ")[1]
    decoded = base64.b64decode(encoded).decode("utf-8")
    username, password = decoded.split(":", 1)
    return username == VALID_USERNAME and password == VALID_PASSWORD


def send_json(handler, status_code, data):
    body = json.dumps(data, indent=2).encode("utf-8")
    handler.send_response(status_code)
    handler.send_header("Content-Type", "application/json")
    handler.send_header("Content-Length", len(body))
    handler.end_headers()
    handler.wfile.write(body)


def get_id_from_path(path):
    parts = path.strip("/").split("/")
    if len(parts) == 2 and parts[1].isdigit():
        return int(parts[1])
    return None


class APIHandler(http.server.BaseHTTPRequestHandler):

    def do_GET(self):
        if not check_auth(self):
            send_json(self, 401, {"error": "Unauthorized. Please provide valid credentials."})
            return

        transaction_id = get_id_from_path(self.path)

        if self.path == "/transactions":
            send_json(self, 200, transactions)

        elif transaction_id is not None:
            result = next((t for t in transactions if t["id"] == transaction_id), None)
            if result:
                send_json(self, 200, result)
            else:
                send_json(self, 404, {"error": "Transaction not found."})
        else:
            send_json(self, 404, {"error": "Endpoint not found."})

    def do_POST(self):
        if not check_auth(self):
            send_json(self, 401, {"error": "Unauthorized. Please provide valid credentials."})
            return

        if self.path == "/transactions":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length)
            new_transaction = json.loads(body)
            new_transaction["id"] = max(t["id"] for t in transactions) + 1
            transactions.append(new_transaction)
            send_json(self, 201, {"message": "Transaction created.", "transaction": new_transaction})
        else:
            send_json(self, 404, {"error": "Endpoint not found."})

    def do_PUT(self):
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
        print(f"Request: {args[0]} {args[1]}")


if __name__ == "__main__":
    server = http.server.HTTPServer(("localhost", 8000), APIHandler)
    print("Server running at http://localhost:8000")
    print("Press Ctrl+C to stop.")
    server.serve_forever()