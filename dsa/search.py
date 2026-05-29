import time

# Sample transaction data, matching the records in our XML file
transactions = [
    {"id": 1, "type": "incoming_money", "amount": 5000, "sender": "John Doe"},
    {"id": 2, "type": "payment", "amount": 2000, "sender": "You"},
    {"id": 3, "type": "transfer", "amount": 10000, "sender": "You"},
    {"id": 4, "type": "incoming_money", "amount": 15000, "sender": "Alice Brown"},
    {"id": 5, "type": "payment", "amount": 3000, "sender": "You"},
    {"id": 6, "type": "transfer", "amount": 7000, "sender": "You"},
    {"id": 7, "type": "incoming_money", "amount": 20000, "sender": "Carol Davis"},
    {"id": 8, "type": "withdrawal", "amount": 8000, "sender": "You"},
    {"id": 9, "type": "payment", "amount": 1500, "sender": "You"},
    {"id": 10, "type": "transfer", "amount": 25000, "sender": "You"},
    {"id": 11, "type": "incoming_money", "amount": 12000, "sender": "Frank Lee"},
    {"id": 12, "type": "payment", "amount": 5000, "sender": "You"},
    {"id": 13, "type": "transfer", "amount": 9000, "sender": "You"},
    {"id": 14, "type": "incoming_money", "amount": 30000, "sender": "Henry Chen"},
    {"id": 15, "type": "withdrawal", "amount": 15000, "sender": "You"},
    {"id": 16, "type": "payment", "amount": 4000, "sender": "You"},
    {"id": 17, "type": "transfer", "amount": 6000, "sender": "You"},
    {"id": 18, "type": "incoming_money", "amount": 18000, "sender": "Jack Taylor"},
    {"id": 19, "type": "payment", "amount": 2500, "sender": "You"},
    {"id": 20, "type": "transfer", "amount": 11000, "sender": "You"},
]


def linear_search(transactions, target_id):
    # Go through every transaction one by one until we find the matching ID
    for transaction in transactions:
        if transaction["id"] == target_id:
            return transaction
    return None


def build_dictionary(transactions):
    # Build a dictionary where the key is the transaction ID
    # This allows direct access by ID without scanning the whole list
    return {t["id"]: t for t in transactions}


def dictionary_lookup(lookup_dict, target_id):
    # Find a transaction directly by its key, no scanning needed
    return lookup_dict.get(target_id, None)


def compare_performance(target_id):
    # Run both methods 10000 times and measure how long each one takes

    start = time.perf_counter()
    for _ in range(10000):
        linear_search(transactions, target_id)
    linear_time = time.perf_counter() - start

    lookup_dict = build_dictionary(transactions)
    start = time.perf_counter()
    for _ in range(10000):
        dictionary_lookup(lookup_dict, target_id)
    dict_time = time.perf_counter() - start

    print(f"Searching for transaction ID: {target_id}")
    print(f"Linear search time     (10,000 runs): {linear_time:.6f} seconds")
    print(f"Dictionary lookup time (10,000 runs): {dict_time:.6f} seconds")

    if dict_time < linear_time:
        print("Result: Dictionary lookup was faster.")
    else:
        print("Result: Linear search was faster.")
    print()


if __name__ == "__main__":
    # Test with ID near the end of the list, worst case for linear search
    compare_performance(target_id=20)

    # Test with ID in the middle
    compare_performance(target_id=10)

    # Test with ID at the beginning, best case for linear search
    compare_performance(target_id=1)