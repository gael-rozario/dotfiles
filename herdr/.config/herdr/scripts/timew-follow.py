#!/usr/bin/env python3
"""Start timewarrior tracking for whichever herdr workspace you switch to.

Listens to herdr's socket event stream for workspace_focused events. Once a workspace
has stayed focused for DELAY seconds, runs `timew start <workspace label>` (timew ends
the previous interval itself). Skips the start if timew is already tracking that label.
Reconnects if the herdr server restarts. Run by ~/Library/LaunchAgents/com.gael.herdr-timew.plist.
"""
import json
import os
import selectors
import socket
import subprocess
import sys
import time

DELAY = float(os.environ.get("HERDR_TIMEW_DELAY", "5"))
SOCKET = os.environ.get("HERDR_SOCKET_PATH", os.path.expanduser("~/.config/herdr/herdr.sock"))
HERDR = os.environ.get("HERDR_BIN_PATH", os.path.expanduser("~/.local/bin/herdr"))
TIMEW = os.environ.get("TIMEW_BIN", "/opt/homebrew/bin/timew")


def log(msg):
    print(time.strftime("%Y-%m-%d %H:%M:%S"), msg, flush=True)


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=10)


def workspace_label(workspace_id):
    out = run(HERDR, "workspace", "get", workspace_id)
    if out.returncode != 0:
        return None
    try:
        return json.loads(out.stdout)["result"]["workspace"]["label"] or None
    except (ValueError, KeyError):
        return None


def current_tag():
    if run(TIMEW, "get", "dom.active").stdout.strip() != "1":
        return None
    return run(TIMEW, "get", "dom.active.tag.1").stdout.strip() or None


def start_tracking(workspace_id):
    label = workspace_label(workspace_id)
    if not label:
        log(f"no label for {workspace_id}, skipping")
        return
    if current_tag() == label:
        return
    out = run(TIMEW, "start", label)
    log(f"timew start {label!r} -> {out.returncode} {out.stdout.strip().splitlines()[:1]}")


def listen():
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(SOCKET)
    request = {
        "id": "timew-follow",
        "method": "events.subscribe",
        "params": {"subscriptions": [{"type": "workspace.focused"}]},
    }
    sock.sendall((json.dumps(request) + "\n").encode())
    log(f"subscribed to {SOCKET}")

    sel = selectors.DefaultSelector()
    sel.register(sock, selectors.EVENT_READ)
    buf = b""
    pending, due = None, None  # workspace waiting out the delay
    while True:
        timeout = None if due is None else max(0.0, due - time.monotonic())
        if sel.select(timeout):
            chunk = sock.recv(65536)
            if not chunk:
                raise ConnectionError("herdr closed the socket")
            buf += chunk
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                try:
                    msg = json.loads(line)
                except ValueError:
                    continue
                if msg.get("event") == "workspace_focused":
                    pending = msg["data"]["workspace_id"]
                    due = time.monotonic() + DELAY
        if due is not None and time.monotonic() >= due:
            start_tracking(pending)
            pending, due = None, None


def main():
    while True:
        try:
            listen()
        except (OSError, ConnectionError) as exc:
            log(f"disconnected: {exc}; retrying in 5s")
            time.sleep(5)


if __name__ == "__main__":
    sys.exit(main())
