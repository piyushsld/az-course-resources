# For setup of this app, install npm using apt-get
# Run these two commands inside the folder
npm install -g azure-functions-core-tools@4
pip install azure-functions psycopg2-binary

Project Structure -

db_handler.py - shared func code to insert entry in postgres db

# Local Event-Driven Pipeline with Docker Compose

**Azure Functions + Azurite + PostgreSQL**

This document describes how to run a complete **local event-driven pipeline** using Docker Compose:

```
Storage Queue (Azurite)
        ↓
Azure Function
        ↓
PostgreSQL
```

The setup runs the following services locally:

* **Azurite** – Azure Storage emulator (Queues, Blobs, Tables)
* **PostgreSQL** – database
* **Azure Function App** – event processors

This environment allows testing event-driven pipelines without deploying to Azure.

---

# 1. Prerequisites

Install the following tools:

* Docker
* Docker Compose
* Azure Functions Core Tools
* Python 3.9+

Verify installations:

```
docker --version
docker compose version
func --version
python --version
```

---

# 2. Project Structure

Create the following directory structure:

```
event-pipeline/
│
├── docker-compose.yml
│
├── function-app/
│   ├── function_app.py
│   ├── requirements.txt
│   ├── host.json
│   └── local.settings.json
│
└── init-db/
    └── init.sql
```

---

# 3. Docker Compose Configuration

Create `docker-compose.yml` in the root directory.

```
version: "3.9"

services:

  postgres:
    image: postgres:15
    container_name: local-postgres
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
    volumes:
      - ./init-db/init.sql:/docker-entrypoint-initdb.d/init.sql

  azurite:
    image: mcr.microsoft.com/azure-storage/azurite
    container_name: azurite
    restart: always
    command: azurite --skipApiVersionCheck
    ports:
      - "10000:10000"
      - "10001:10001"
      - "10002:10002"

```

This launches:

```
Postgres → localhost:5432
Azurite Blob → localhost:10000
Azurite Queue → localhost:10001
Azurite Table → localhost:10002
```

---

# 4. PostgreSQL Initialization

Create `init-db/init.sql`.

```
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    source TEXT,
    payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

This table stores incoming events.

---

# 5. Azure Function Code

Create `function-app/function_app.py`.

```
import azure.functions as func
import psycopg2
import json
import os
import logging

app = func.FunctionApp()

def write_event(source, payload):

    conn = psycopg2.connect(
        host=os.environ["PG_HOST"],
        database=os.environ["PG_DB"],
        user=os.environ["PG_USER"],
        password=os.environ["PG_PASSWORD"],
        port=5432
    )

    cur = conn.cursor()

    cur.execute(
        "INSERT INTO events(source, payload) VALUES (%s,%s)",
        (source, json.dumps(payload))
    )

    conn.commit()

    cur.close()
    conn.close()


@app.queue_trigger(
    arg_name="msg",
    queue_name="event-queue",
    connection="AzureWebJobsStorage"
)
def queue_processor(msg: func.QueueMessage):

    payload = json.loads(msg.get_body().decode())
    logging.info(f"Queue message received: {payload}")

    write_event("storage_queue", payload)


@app.event_grid_trigger(arg_name="event")
def eventgrid_processor(event: func.EventGridEvent):

    payload = event.get_json()
    logging.info(f"EventGrid event received: {payload}")

    write_event("event_grid", payload)
```

---

# 6. Python Dependencies

Create `function-app/requirements.txt`.

```
azure-functions
psycopg2-binary
```

Install dependencies:

```
pip install -r requirements.txt
```

---

# 7. Azure Function Configuration

Create `function-app/local.settings.json`.

```
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",

    "PG_HOST": "localhost",
    "PG_DB": "postgres",
    "PG_USER": "postgres",
    "PG_PASSWORD": "password"
  }
}
```

---

# 8. Start the Local Environment

Start the services:

```
docker compose up -d
```

Verify containers:

```
docker ps
```

Expected output:

```
local-postgres
azurite
```

---

# 9. Start the Azure Function

Navigate to the function directory.

```
cd function-app
func start
```

Expected output:

```
Functions:

queue_processor
eventgrid_processor
```

---

# 10. Create Queue

Create the queue in Azurite.

```
az storage queue create \
--name event-queue \
--connection-string "UseDevelopmentStorage=true"
```

---

# 11. Send Test Message

```
az storage message put \
--queue-name event-queue \
--content '{"order_id":101,"amount":50}' \
--connection-string "UseDevelopmentStorage=true"
```

The function should trigger automatically.

---

# 12. Verify Data in PostgreSQL

Connect to PostgreSQL.

```
psql -h localhost -U postgres -d postgres
```

Run:

```
SELECT * FROM events;
```

Example output:

```
id | source         | payload
1  | storage_queue  | {"order_id":101,"amount":50}
```

---

# 13. Architecture Overview

```
                +----------------+
                |  Event Source  |
                +----------------+
                       |
                       v
              +------------------+
              |  Azurite Queue   |
              +------------------+
                       |
                       v
               +-----------------+
               |  Azure Function |
               +-----------------+
                       |
                       v
                +---------------+
                |   PostgreSQL  |
                +---------------+
```

---

# 14. Stopping the Environment

Stop all containers:

```
docker compose down
```

To remove volumes:

```
docker compose down -v
```

---

# 15. Benefits of This Setup

* Fully local development
* No Azure cost
* Reproducible environment
* Fast debugging
* Easy CI integration
* Portable across machines

---

# 16. Future Enhancements

* Add Dead Letter Queue
* Add Retry Policies
* Add Connection Pooling
* Add Batch Inserts
* Add Observability (OpenTelemetry)

---

# 17. Summary

This setup provides a simple **local event-driven architecture** that replicates an Azure production pipeline:

```
Queue → Azure Function → PostgreSQL
```

Using Docker Compose allows developers to run the entire stack with:

```
docker compose up
```

making development, testing, and onboarding significantly easier.

# 18. No Docker setup

$ azurite --skipApiVersionCheck &
$ docker run --name postgres-local -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=postgres -p 5432:5432 -d postgres
$ cd function-app
$ func start
