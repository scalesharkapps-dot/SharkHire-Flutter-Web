"""Serve the web build locally the way Render serves it:

* real files from build/web_production,
* /api/* forwarded to the backend (same-origin for the browser, so no CORS),
* any other path -> index.html.

    python tool/serve_like_render.py            # http://localhost:5210

Build first with:
    flutter build web --release --dart-define-from-file=config/render.json --output build/web_production
"""

import os
import sys
import urllib.error
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

BACKEND = "https://backend-job-search.onrender.com"
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 5210
# Optional 2nd argument: the build folder (Vercel uses build/web).
ROOT = os.path.join(
    os.path.dirname(__file__),
    "..",
    sys.argv[2] if len(sys.argv) > 2 else os.path.join("build", "web_production"),
)
FORWARD_HEADERS = ("authorization", "content-type", "accept")


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def _proxy(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None
        headers = {k: v for k, v in self.headers.items() if k.lower() in FORWARD_HEADERS}
        req = urllib.request.Request(BACKEND + self.path, data=body, headers=headers, method=self.command)
        try:
            with urllib.request.urlopen(req, timeout=90) as res:
                status, data, ctype = res.status, res.read(), res.headers.get("Content-Type")
        except urllib.error.HTTPError as e:
            status, data, ctype = e.code, e.read(), e.headers.get("Content-Type")
        except Exception as e:
            status, data, ctype = 502, f'{{"success":false,"message":"Proxy: {e}"}}'.encode(), "application/json"
        self.send_response(status)
        if ctype:
            self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _is_api(self):
        return self.path.startswith("/api/")

    def do_GET(self):
        if self._is_api():
            return self._proxy()
        path = self.translate_path(self.path.split("?")[0])
        if not os.path.exists(path):
            self.path = "/index.html"  # SPA fallback, like the Render rewrite
        return super().do_GET()

    def do_POST(self):
        return self._proxy() if self._is_api() else self.send_error(405)

    do_PUT = do_PATCH = do_DELETE = do_POST

    def log_message(self, fmt, *args):  # method + path + status only
        sys.stderr.write("render-local %s\n" % (fmt % args))


if __name__ == "__main__":
    print(f"Serving {os.path.abspath(ROOT)} on http://localhost:{PORT} (/api -> {BACKEND})")
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
