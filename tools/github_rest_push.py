#!/usr/bin/env python3
import urllib.request
import json
import base64
import os
import subprocess
import sys

OWNER = "DenverMan02"
REPO = "stupid-godot-pvz-slop"
API_BASE = f"https://api.github.com/repos/{OWNER}/{REPO}"

def api_request(endpoint, data=None, method=None):
    url = f"{API_BASE}/{endpoint}" if not endpoint.startswith("http") else endpoint
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "GodotPvZ-Pusher"
    }
    payload = None
    if data is not None:
        payload = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=payload, headers=headers, method=method)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

def main():
    print("1. Fetching latest remote HEAD on main...")
    ref_info = api_request("git/refs/heads/main")
    parent_sha = ref_info["object"]["sha"]
    print(f"   Remote HEAD: {parent_sha}")

    commit_info = api_request(f"git/commits/{parent_sha}")
    base_tree_sha = commit_info["tree"]["sha"]
    print(f"   Base Tree: {base_tree_sha}")

    print("2. Fetching remote tree blobs...")
    tree_data = api_request(f"git/trees/{base_tree_sha}?recursive=1")
    remote_files = {item["path"]: item["sha"] for item in tree_data.get("tree", []) if item["type"] == "blob"}

    if "--files" in sys.argv:
        idx = sys.argv.index("--files")
        local_files = [f for f in sys.argv[idx + 1:] if not f.startswith("-")]
    else:
        local_files = subprocess.check_output(["git", "ls-files"]).decode().splitlines()
    files_to_update = []
    for p in local_files:
        if not os.path.isfile(p):
            continue
        h = subprocess.check_output(["git", "hash-object", p]).decode().strip()
        if p not in remote_files or remote_files[p] != h:
            files_to_update.append(p)

    print(f"   Files to upload/update: {len(files_to_update)}")
    for f in files_to_update:
        print(f"   -> {f}")

    if not files_to_update:
        print("Nothing to push! Already in sync.")
        return

    tree_entries = []
    for f in files_to_update:
        with open(f, "rb") as fl:
            raw_content = fl.read()
        b64_content = base64.b64encode(raw_content).decode("utf-8")
        blob_res = api_request("git/blobs", {
            "content": b64_content,
            "encoding": "base64"
        })
        blob_sha = blob_res["sha"]
        tree_entries.append({
            "path": f,
            "mode": "100644",
            "type": "blob",
            "sha": blob_sha
        })
        print(f"   Uploaded blob: {f} ({blob_sha})")

    print("3. Creating new git tree...")
    new_tree = api_request("git/trees", {
        "base_tree": base_tree_sha,
        "tree": tree_entries
    })
    new_tree_sha = new_tree["sha"]
    print(f"   New Tree SHA: {new_tree_sha}")

    commit_msg = "Fix bottom shelf stretching, energy icon scale, PvZ2 currencies and building cutouts"
    for arg in sys.argv[1:]:
        if arg == "--files":
            break
        if not arg.startswith("-"):
            commit_msg = arg
            break

    print("4. Creating new git commit...")
    new_commit = api_request("git/commits", {
        "message": commit_msg,
        "tree": new_tree_sha,
        "parents": [parent_sha],
        "author": {
            "name": "Denver",
            "email": "denvermoon69@gmail.com"
        }
    })
    new_commit_sha = new_commit["sha"]
    print(f"   New Commit SHA: {new_commit_sha}")

    print("5. Updating refs/heads/main...")
    update_res = api_request("git/refs/heads/main", {
        "sha": new_commit_sha,
        "force": False
    }, method="PATCH")
    print(f"   Branch main successfully updated to {update_res['object']['sha']}!")

if __name__ == "__main__":
    main()
