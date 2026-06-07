"""
json_input.py

Handles collecting a JSON string from the user via multiple methods:
  1. Clipboard  (pbpaste)          — copy JSON first, press Enter
  2. VS Code    (code --wait)      — edits a temp file, save & close tab
  3. File picker (osascript)       — native macOS Finder dialog
  4. Terminal   (stdin, Ctrl+D)    — paste/type directly
"""

import json
import os
import subprocess
import sys
import tempfile
from typing import Optional


# ─────────────────────────────────────────────
#  Public entry point
# ─────────────────────────────────────────────

def collect_json_from_user(feature_name: str) -> Optional[str]:
    """
    Ask the user how they want to provide their JSON example,
    collect it, validate it, and return the raw JSON string.

    Returns None if the user skips or input is invalid.
    """
    print("\n  How would you like to provide the JSON example?")
    print("  1)  Clipboard  — copy your JSON first, then press Enter (recommended)")
    print("  2)  VS Code    — opens a temp file, paste JSON, save & close tab")
    print("  3)  File       — Finder dialog to select a .json file")
    print("  4)  Terminal   — paste here (press Ctrl+D on a new line when done)")

    try:
        choice = input("\n  Choice (1-4) [1]: ").strip() or "1"
    except EOFError:
        return None

    handlers = {
        "1": _from_clipboard,
        "2": lambda: _from_vscode(feature_name),
        "3": _from_file_picker,
        "4": _from_terminal,
    }

    handler = handlers.get(choice)
    if not handler:
        print("  ⚠️  Invalid choice.")
        return None

    raw = handler()
    if raw is None:
        return None

    return _validate_and_return(raw)


# ─────────────────────────────────────────────
#  Option 1 — Clipboard
# ─────────────────────────────────────────────

def _from_clipboard() -> Optional[str]:
    print("\n  → Reading from clipboard...")
    try:
        result = subprocess.run(["pbpaste"], capture_output=True, text=True, timeout=5)
        content = result.stdout.strip()
        if not content:
            print("  ⚠️  Clipboard is empty. Copy your JSON first and try again.")
            return None
        return content
    except FileNotFoundError:
        print("  ⚠️  pbpaste not available (not on macOS?).")
        return None
    except Exception as e:
        print(f"  ✗ Error reading clipboard: {e}")
        return None


# ─────────────────────────────────────────────
#  Option 2 — VS Code temp file
# ─────────────────────────────────────────────

def _from_vscode(feature_name: str) -> Optional[str]:
    starter = (
        '{\n'
        '  "result": {\n'
        '    "id": 1,\n'
        '    "replace_me": "paste your real JSON response here"\n'
        '  }\n'
        '}\n'
    )
    tmp_path = os.path.join(
        tempfile.gettempdir(), f"fmc_{feature_name}_entity_input.json"
    )
    with open(tmp_path, "w") as f:
        f.write(starter)

    print(f"\n  → Temp file created: {tmp_path}")
    print("  Paste your JSON into the file, SAVE it, then CLOSE the tab.")

    opened = False
    # Try VS Code with --wait (blocks until the user closes the tab)
    try:
        subprocess.run(["code", "--wait", tmp_path], timeout=600, check=False)
        opened = True
    except FileNotFoundError:
        pass
    except subprocess.TimeoutExpired:
        print("  ⚠️  Timed out waiting for VS Code (10 min limit).")

    if not opened:
        # Fallback: open with macOS default app and wait for user
        print("  VS Code not found — opening with default app instead.")
        try:
            subprocess.Popen(["open", tmp_path])
        except Exception:
            pass
        try:
            input("  Press Enter once you have saved the file and are ready to continue...")
        except EOFError:
            pass

    # Read the file back
    try:
        with open(tmp_path) as f:
            content = f.read().strip()
    except Exception as e:
        print(f"  ✗ Could not read temp file: {e}")
        return None
    finally:
        _silent_delete(tmp_path)

    return content if content else None


# ─────────────────────────────────────────────
#  Option 3 — macOS file picker
# ─────────────────────────────────────────────

def _from_file_picker() -> Optional[str]:
    print("\n  → Opening file picker...")
    script = (
        'POSIX path of (choose file '
        'with prompt "Select your JSON response file" '
        'of type {"json", "txt", "public.plain-text"})'
    )
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True, text=True, timeout=60
        )
        if result.returncode != 0 or not result.stdout.strip():
            print("  No file selected.")
            return None

        file_path = result.stdout.strip()
        with open(file_path) as f:
            content = f.read().strip()

        print(f"  ✓ Loaded: {os.path.basename(file_path)}")
        return content

    except subprocess.TimeoutExpired:
        print("  ⚠️  File picker timed out.")
        return None
    except FileNotFoundError:
        print("  ✗ osascript not available.")
        return None
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return None


# ─────────────────────────────────────────────
#  Option 4 — Terminal stdin
# ─────────────────────────────────────────────

def _from_terminal() -> Optional[str]:
    print("\n  Paste your JSON below.")
    print("  (Press Ctrl+D on a NEW line when done)\n")
    lines = []
    try:
        for line in sys.stdin:
            lines.append(line.rstrip("\n"))
    except EOFError:
        pass
    content = "\n".join(lines).strip()
    return content if content else None


# ─────────────────────────────────────────────
#  Shared helpers
# ─────────────────────────────────────────────

def _validate_and_return(raw: str) -> Optional[str]:
    """Validate JSON and return it, or print an error and return None."""
    try:
        json.loads(raw)
        return raw
    except json.JSONDecodeError as e:
        print(f"\n  ✗ Invalid JSON — {e}")
        print("  The entity files will use the empty template instead.")
        return None


def _silent_delete(path: str):
    try:
        os.unlink(path)
    except Exception:
        pass
