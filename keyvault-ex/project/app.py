import os
from flask import Flask, render_template
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

app = Flask(__name__)

def get_secret():
    kv_name = os.getenv("KEYVAULT_NAME")
    secret_name = os.getenv("SECRET_NAME")

    kv_url = f"https://{kv_name}.vault.azure.net"

    credential = DefaultAzureCredential()
    client = SecretClient(vault_url=kv_url, credential=credential)

    secret = client.get_secret(secret_name)
    return secret.value

@app.route("/")
def home():
    try:
        secret_value = get_secret()
    except Exception as e:
        secret_value = f"Error: {str(e)}"

    return render_template("index.html", secret=secret_value)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)