from service.cron.autodeactivate import autodeactivate_forever
from service.cron.emailnotifications import send_notifications_forever
import asyncio
from http.server import SimpleHTTPRequestHandler
from socketserver import TCPServer

class HealthCheckHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'Healthy')
        else:
            self.send_response(404)
            self.end_headers()

async def http_server():
    with TCPServer(('0.0.0.0', 8080), HealthCheckHandler) as httpd:
        print("Serving health check on port 8080...", flush=True)
        await asyncio.to_thread(httpd.serve_forever)

async def main():
    await asyncio.gather(
        # TODO: Add photo deletion task
        autodeactivate_forever(),
        send_notifications_forever(),
        http_server(),
    )

if __name__ == '__main__':
    asyncio.run(main())
