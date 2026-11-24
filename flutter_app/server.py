import http.server
import socketserver
import os

DIRECTORY = os.path.join(os.path.dirname(__file__), "build", "web")

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        requested_path = self.translate_path(self.path)
        # If the file does not exist (like a Flutter client route /user-training), serve index.html
        if not os.path.exists(requested_path):
            self.path = "/index.html"
        return super().do_GET()

if __name__ == "__main__":
    PORT = 8080
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", PORT), SPAHandler) as httpd:
        print(f"TESS Web Server running on http://0.0.0.0:{PORT} (SPA routing enabled)")
        httpd.serve_forever()

