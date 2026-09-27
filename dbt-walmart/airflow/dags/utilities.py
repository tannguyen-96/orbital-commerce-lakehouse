from databricks.sdk import WorkspaceClient
from databricks.sdk.service.jobs import RunLifeCycleState, RunResultState
import time

def ingest_function():
    ws = WorkspaceClient(
        host="https://dbc-2b62d18b-7a6f.cloud.databricks.com",
        token="{{ env_var('DATABRICKS_TOKEN') }}"
    )

    job_trigger = ws.jobs.run_now(job_id="897198529485381")

    while True:
        job_run = ws.jobs.get_run(job_trigger.run_id)
        # print(f"Current job run state: {job_run.state.life_cycle_state}, result state: {job_run.state.result_state}")
        if job_run.state.life_cycle_state in [RunLifeCycleState.TERMINATED, RunLifeCycleState.SKIPPED, RunLifeCycleState.INTERNAL_ERROR]:
            if job_run.state.result_state == RunResultState.SUCCESS:
                print("Job succeeded")
                break
            else:
                raise Exception("Job failed with state: " + job_run.state.result_state)

        time.sleep(5)
    return "ingest_cdc completed"