import random
import datetime
import hashlib
import requests
import io
import lorem
import json
import os

username = "swift"
password = "veryfast"
project = "service"

keystone_url = "http://localhost:5000/v3"

auth_data = {
    "auth": {
        "identity": {
            "methods": ["password"],
            "password": {
                "user": {
                    "domain": { "id": "default" },
                    "name": username,
                    "password": password,
                }
            }
        },
        "scope": {
            "project": {
                "name": project,
                "domain": { "id": "default" }
            }
        }
    }
}

auth = requests.request("POST", f"{keystone_url}/auth/tokens", json=auth_data)
swift_url = auth.json()["token"]["catalog"][1]["endpoints"][0]["url"]
token = auth.headers["X-Subject-Token"]


for i in range(0, 10):
    container = f"bucket-{i:03d}"
    r = requests.put(f"{swift_url}/{container}", headers={"X-Auth-Token": token})
    print(f"{r.status_code} {container}")
    for _ in range(0, 10):
        filename = ohash = hashlib.sha1(os.urandom(256)).hexdigest() + ".txt"
        r = requests.put(
            f"{swift_url}/{container}/{filename}", 
            headers={"X-Auth-Token": token},
            files={"files": (filename, lorem.get_paragraph())}
        )
        print(f"{r.status_code} {filename}")
    print()
