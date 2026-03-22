from http.server import BaseHTTPRequestHandler, HTTPServer
import requests
import json
from multiprocessing import Process, cpu_count
import urllib.parse

IMDS_URL = "http://169.254.169.254/metadata/instance?api-version=2021-02-01"

# -------- CPU LOAD FUNCTION --------
def burn_cpu():
    while True:
        x = 0
        for i in range(10**7):
            x += i * i

processes = []

def start_cpu_load(num_procs):
    global processes
    if processes:
        return  # already running

    for _ in range(num_procs):
        p = Process(target=burn_cpu)
        p.daemon = True
        p.start()
        processes.append(p)

# -------- HTTP HANDLER --------
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urllib.parse.urlparse(self.path)

        # 🔥 Trigger CPU load
        if parsed_path.path == "/load":
            num_cores = cpu_count()
            start_cpu_load(num_cores)

            self.send_response(200)
            self.end_headers()
            self.wfile.write(f"Started CPU load on {num_cores} cores\n".encode())
            return

        # 🛑 Stop CPU load (optional)
        if parsed_path.path == "/stop":
            global processes
            for p in processes:
                p.terminate()
            processes = []

            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Stopped CPU load\n")
            return

        # 📊 Default: Show VM metadata
        try:
            headers = {"Metadata": "true"}
            response = requests.get(IMDS_URL, headers=headers)
            data = response.json()

            compute = data.get("compute", {})
            network = data.get("network", {})

            instance_id = compute.get("vmId", "N/A")
            vm_name = compute.get("name", "N/A")
            location = compute.get("location", "N/A")

            private_ip = "N/A"
            try:
                private_ip = network["interface"][0]["ipv4"]["ipAddress"][0]["privateIpAddress"]
            except Exception:
                pass

            output = f"""
            <html>
            <head><title>Azure VM Info</title></head>
            <body>
                <h1>Azure VM Metadata</h1>
                <p><b>VM Name:</b> {vm_name}</p>
                <p><b>Instance ID:</b> {instance_id}</p>
                <p><b>Location:</b> {location}</p>
                <p><b>Private IP:</b> {private_ip}</p>

                <h2>Actions</h2>
                <p><a href="/load">Start CPU Load</a></p>
                <p><a href="/stop">Stop CPU Load</a></p>
            </body>
            </html>
            """

            self.send_response(200)
            self.send_header("Content-type", "text/html")
            self.end_headers()
            self.wfile.write(output.encode("utf-8"))

        except Exception as e:
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode("utf-8"))


# -------- SERVER START --------
if __name__ == "__main__":
    server_address = ("", 80)
    httpd = HTTPServer(server_address, Handler)
    print("Server running on port 80...")
    httpd.serve_forever()