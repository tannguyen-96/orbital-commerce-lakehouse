# Walmart Lakehouse Pipeline

This project implements a scheduled Walmart data pipeline using Supabase PostgreSQL, Databricks, dbt, and Apache Airflow 3 running in Docker.

## End-to-end flow

```text
Supabase PostgreSQL
	|
	| Databricks ingestion pipeline
	v
Databricks bronze layer
	|
	| dbt transformations
	v
silver_technical -> silver_business -> gold
	^
	|
Apache Airflow orchestration and scheduling
```

### Source database: Supabase

Supabase PostgreSQL is the system of record for the Walmart commerce data. The source schema contains customers, stores, products, employees, orders, and order items.

### Ingestion: Databricks bronze layer

A Databricks pipeline is triggered by Airflow to extract the Supabase source tables and load them into the Databricks bronze layer. Bronze provides the landing layer for downstream processing and preserves the ingested source entities before transformation.

### Transformation: dbt

The dbt project transforms bronze data into analytics layers:

- `silver_technical`: standardized technical models for each source entity.
- `silver_business`: business joins and derived datasets.
- `gold`: analytics-ready facts, dimensions, and snapshots.

Airflow runs the dbt commands in dependency order and stops downstream work when ingestion or tests fail.

## DAG

The [`orchestrate`](airflow/dags/orchestrate.py) DAG is scheduled daily at `11:00` in the `Asia/Bangkok` timezone. Catchup is disabled, so only scheduled runs after deployment are created.

The workflow executes tasks in this order:

```text
ingest_cdc
	-> clean_target
	-> source_freshness
	-> silver_technical
	-> silver_technical_tests
	-> silver_business
	-> silver_business_tests
	-> gold_ephemeral
	-> gold_dimensions
	-> gold_facts
```

## Schedule and triggers

The DAG is configured with:

- **Schedule:** daily at `11:00`
- **Timezone:** `Asia/Bangkok`
- **Catchup:** disabled
- **Manual trigger:** available from the Airflow UI or Airflow CLI

Each scheduled or manual run starts the Databricks ingestion job, then executes the bronze freshness check and dbt silver/gold workflow.

## Task responsibilities

| Task | Responsibility |
| --- | --- |
| `ingest_cdc` | Triggers the Databricks job that loads source data into the bronze layer and waits for completion. |
| `clean_target` | Removes the previous dbt `target` and `logs` directories. |
| `source_freshness` | Runs `dbt source freshness` from the dbt project directory. |
| `silver_technical` | Builds technical silver models. |
| `silver_technical_tests` | Runs tests for technical silver models. |
| `silver_business` | Builds business silver models. |
| `silver_business_tests` | Runs tests for business silver models. |
| `gold_ephemeral` | Builds gold ephemeral models. |
| `gold_dimensions` | Applies dbt snapshots for historical dimensions. |
| `gold_facts` | Builds gold fact models. |

All dbt tasks execute in `/opt/airflow/walmart_project`, which is mounted from `airflow/walmart_project` on the host.

## Docker services

The Docker Compose deployment in [`airflow/docker-compose.yaml`](airflow/docker-compose.yaml) runs:

- Airflow API server
- Airflow scheduler
- Airflow DAG processor
- Airflow triggerer
- Airflow worker
- PostgreSQL metadata database
- Redis message broker

The custom [`airflow/Dockerfile`](airflow/Dockerfile) installs the project dependencies from [`airflow/requirements.txt`](airflow/requirements.txt).

## Configuration

Create `airflow/.env` locally. Store credentials and connection values there or in a secrets manager; do not commit them.

The DAG requires access to:

- Databricks workspace and job credentials for `ingest_cdc`
- The Databricks SQL/dbt target used by the mounted Walmart dbt project
- Airflow Fernet and JWT secrets

## Run locally

From this directory, build and start the Airflow stack:

```powershell
cd airflow
docker compose up --build
```

Open the Airflow UI, enable `orchestrate`, and trigger a manual run to validate the full dependency chain. Logs are written under `airflow/logs`.

## Operational behavior

- Tasks run sequentially; a failed ingestion or dbt test stops downstream tasks.
- `catchup=False` prevents historical backfill runs when the DAG is first registered.
- The `clean_target` task removes compiled dbt artifacts before each run.
- The Databricks ingestion task polls the submitted job until it succeeds or returns a terminal failure state.
