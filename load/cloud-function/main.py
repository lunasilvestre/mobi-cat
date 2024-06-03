import googleapiclient.discovery
import os
from google.cloud import pubsub_v1
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)


def check_pubsub_and_destroy_cluster(request):
  try:
    # Retrieve environment variables
    project_id = os.getenv("GCP_PROJECT_ID")
    cluster_name = os.getenv("CLUSTER_NAME")
    region = os.getenv("GCP_REGION")
    subscription_name = os.getenv("PUBSUB_SUBSCRIPTION_NAME")
    scheduler_name = os.getenv("SCHEDULER_JOB_NAME")
    scheduler_location = os.getenv("GCP_REGION")

    # Sanity check for environment variables
    if not all([
        project_id, cluster_name, region, subscription_name, scheduler_name,
        scheduler_location
    ]):
      raise EnvironmentError("One or more environment variables are missing.")

    # Initialize Pub/Sub client
    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(project_id,
                                                     subscription_name)

    # Check for messages in the Pub/Sub subscription
    response = subscriber.pull(subscription_path, max_messages=1)
    if response.received_messages:
      logging.info("Messages still in queue, not destroying the cluster.")
      return "Messages still in queue."

    logging.info("Queue is empty. Destroying Dataproc cluster.")

    # Initialize Dataproc client
    dataproc = googleapiclient.discovery.build('dataproc', 'v1')
    cluster_client = dataproc.projects().regions().clusters()

    # Delete Dataproc cluster
    delete_cluster_operation = cluster_client.delete(projectId=project_id,
                                                     region=region,
                                                     clusterName=cluster_name)
    delete_cluster_operation.execute()
    logging.info("Dataproc cluster deleted.")

    # Initialize Cloud Scheduler client
    scheduler_client = googleapiclient.discovery.build('cloudscheduler', 'v1')
    scheduler_path = f'projects/{project_id}/locations/{scheduler_location}/jobs/{scheduler_name}'

    # Delete Scheduler job
    scheduler_client.projects().locations().jobs().delete(
        name=scheduler_path).execute()
    logging.info("Scheduler job deleted.")

    return "Cluster destroyed and scheduler job deleted."

  except Exception as e:
    logging.error(f"An error occurred: {e}")
    return f"Error: {str(e)}"


if __name__ == "__main__":
  check_pubsub_and_destroy_cluster()
