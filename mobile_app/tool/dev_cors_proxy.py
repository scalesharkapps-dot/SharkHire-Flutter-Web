"""Local development proxy that lets the SharkHire **web** build talk to the
backend while the backend has no CORS support.

    python tool/dev_cors_proxy.py            # listens on http://localhost:8787

The web app is then run with config/web-local.json (API_BASE_URL =
http://localhost:8787). Every request is forwarded unchanged to the backend
and the response gets CORS headers for localhost pages only.

DEVELOPMENT ONLY. Not needed on Android/iOS, and not for production: the real
fix is CORS middleware on the backend (allow the web app's origin).
"""

import sys
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

TARGET = "https://backend-job-search.onrender.com"
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8787
FORWARD_HEADERS = ("authorization", "content-type", "accept")


def _local_origin(origin):
    host = urlparse(origin or "").hostname
    return host in ("localhost", "127.0.0.1")


class Proxy(BaseHTTPRequestHandler):
    def _cors(self):
        origin = self.headers.get("Origin")
        if _local_origin(origin):
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")
            self.send_header(
                "Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS"
            )
            self.send_header(
                "Access-Control-Allow-Headers", "Authorization, Content-Type, Accept"
            )
            self.send_header("Access-Control-Max-Age", "600")

    def do_OPTIONS(self):  # browser preflight, answered locally
        self.send_response(204)
        self._cors()
        self.end_headers()

    def _forward(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        headers = {
            k: v for k, v in self.headers.items() if k.lower() in FORWARD_HEADERS
        }
        req = urllib.request.Request(
            TARGET + self.path, data=body, headers=headers, method=self.command
        )
        try:
            with urllib.request.urlopen(req, timeout=90) as res:
                status, data, ctype = res.status, res.read(), res.headers.get("Content-Type")
        except urllib.error.HTTPError as e:  # 4xx/5xx: pass the error body through
            status, data, ctype = e.code, e.read(), e.headers.get("Content-Type")
        except Exception as e:  # backend unreachable
            status, data, ctype = 502, f'{{"success":false,"message":"Proxy: {e}"}}'.encode(), "application/json"
        self.send_response(status)
        if ctype:
            self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self._cors()
        self.end_headers()
        self.wfile.write(data)

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = _forward

    def log_message(self, fmt, *args):  # method + path + status only, never headers
        sys.stderr.write("proxy %s\n" % (fmt % args))


if __name__ == "__main__":
    print(f"SharkHire dev CORS proxy: http://localhost:{PORT} -> {TARGET}")
    ThreadingHTTPServer(("127.0.0.1", PORT), Proxy).serve_forever()
