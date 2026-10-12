#!/usr/bin/env python3
import sys
import subprocess
from datetime import datetime

def run_cmd(cmd):
    """Runs a shell command and streams the output."""
    print(f"\n> {' '.join(cmd)}")
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"[!] Error: Command failed with exit code {result.returncode}")
        return False
    return True

def pull():
    """Pull latest changes from the current branch."""
    print("--- Pulling latest changes ---")
    return run_cmd(["git", "pull"])

def push(message=None):
    """Stage all files, commit, and push."""
    if not message:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        message = input(f"Enter commit message [Default: 'Sync {timestamp}']: ").strip()
        if not message:
            message = f"Sync {timestamp}"

    print(f"--- Staging, committing, and pushing: '{message}' ---")
    if not run_cmd(["git", "add", "-A"]):
        return False
    
    # Check if there are changes to commit
    status = subprocess.run(["git", "status", "--porcelain"], capture_output=True, text=True)
    if not status.stdout.strip():
        print("[i] Nothing new to commit. Pushing any unpushed commits...")
    else:
        if not run_cmd(["git", "commit", "-m", message]):
            return False

    return run_cmd(["git", "push"])

def status():
    """Show git status."""
    return run_cmd(["git", "status", "-s"])

def interactive_menu():
    while True:
        print("\n=== Git Sync Helper ===")
        print("1. Push (add, commit, push)")
        print("2. Pull (fetch & merge)")
        print("3. Status")
        print("4. Exit")
        choice = input("Select an option (1-4): ").strip()

        if choice == "1":
            push()
        elif choice == "2":
            pull()
        elif choice == "3":
            status()
        elif choice in ("4", "q", "exit"):
            print("Goodbye!")
            break
        else:
            print("[!] Invalid option. Try again.")

def main():
    if len(sys.argv) == 1:
        interactive_menu()
    else:
        command = sys.argv[1].lower()
        if command == "push":
            msg = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else None
            push(msg)
        elif command == "pull":
            pull()
        elif command == "status":
            status()
        else:
            print("Usage:")
            print("  python3 git_sync.py              (Interactive menu)")
            print("  python3 git_sync.py pull         (Pull updates)")
            print("  python3 git_sync.py push [msg]   (Stage, commit with optional message, and push)")
            print("  python3 git_sync.py status       (Quick status check)")

if __name__ == "__main__":
    main()