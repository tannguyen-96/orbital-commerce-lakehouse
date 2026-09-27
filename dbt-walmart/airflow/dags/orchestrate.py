import pendulum
from airflow.sdk import dag, task
from airflow.operators.bash import BashOperator
from databricks.sdk import WorkspaceClient
from utilities import ingest_function

@dag(
    dag_id="orchestrate",
    schedule="0 11 * * *",
    catchup=False,
    start_date=pendulum.datetime(2026, 9, 28, tz="Asia/Bangkok")
)
def orchestrate():
    @task
    def ingest_cdc():
        result = ingest_function()
        return result

    @task.bash
    def clean_target():
        return "rm -rf /opt/airflow/walmart_project/target && rm -rf /opt/airflow/walmart_project/logs"

    @task.bash
    def source_freshness():
        # Manually set the working directory using the 'cd' command before running
        return "cd /opt/airflow/walmart_project && dbt source freshness"

    silver_technical = BashOperator(
        task_id="silver_technical",
        cwd="/opt/airflow/walmart_project",
        bash_command="dbt run --select silver_technical"
    )

    silver_technical_tests = BashOperator(
        task_id="silver_technical_tests",
        cwd="/opt/airflow/walmart_project",
        bash_command="dbt test --select silver_technical"
    )

    silver_business = BashOperator(
        task_id="silver_business",
        cwd="/opt/airflow/walmart_project",
        bash_command="dbt run --select silver_business"
    )

    silver_business_tests = BashOperator(
        task_id="silver_business_tests",
        cwd="/opt/airflow/walmart_project",
        bash_command="dbt test --select silver_business"
    )

    gold_ephermeral = BashOperator(
        task_id="gold_ephermeral",
        cwd="/opt/airflow/walmart_project",
        bash_command="dbt run --select gold/ephermeral"
    )

    gold_dimensions = BashOperator(
        task_id="gold_dimensions",
        cwd="/opt/airflow/walmart_project",
        bash_command="dbt snapshot"
    )

    gold_facts = BashOperator(
        task_id="gold_facts",
        cwd="/opt/airflow/walmart_project",
        bash_command="dbt run --select gold/facts"
    )

    ingest_cdc() >> clean_target() >> source_freshness() >> silver_technical >> silver_technical_tests >> silver_business >> silver_business_tests >> gold_ephermeral >> gold_dimensions >> gold_facts

orchestrate_dag = orchestrate()