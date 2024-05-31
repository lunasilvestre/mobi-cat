from google.cloud import pubsub_v1
from google.cloud import storage
import os
import requests

project_id = os.getenv('GCP_PROJECT_ID')
subscription_id = os.getenv('PUBSUB_SUBSCRIPTION')
bucket_name = os.getenv('GCS_BUCKET')

subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(project_id, subscription_id)

def callback(message):
    print(f"Received message: {message}")
    try:
        url = message.data.decode('utf-8')
        # Download file
        response = requests.get(url)
        file_content = response.content
        # Upload to GCS
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(url.split('/')[-1])
        blob.upload_from_string(file_content)
        message.ack()
    except Exception as e:
        print(f"Error processing message: {e}")
        message.nack()  # Indicating failure to process message

future = subscriber.subscribe(subscription_path, callback)
try:
    future.result()
except KeyboardInterrupt:
    future.cancel()
