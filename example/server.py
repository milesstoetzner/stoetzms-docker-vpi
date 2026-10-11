#!/usr/bin/env python3
"""Minimal web server to run on the virtual Pi; answers with what it runs on."""

import http.server
import platform

PORT = 8080


def read(path):
    try:
        with open(path) as f:
            return f.read().strip("\0\n")
    except OSError:
        return "unknown"


def os_name():
    for line in read("/etc/os-release").splitlines():
        if line.startswith("PRETTY_NAME="):
            return line.split("=", 1)[1].strip('"')
    return "unknown"


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = (
            f"Hello from {platform.node()}\n"
            f"model:  {read('/proc/device-tree/model')}\n"
            f"os:     {os_name()}\n"
            f"kernel: {platform.release()} ({platform.machine()})\n"
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    print(f"Listening on port {PORT}")
    http.server.ThreadingHTTPServer(("", PORT), Handler).serve_forever()
