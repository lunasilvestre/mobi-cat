import os
import logging
import requests
import tarfile
import gzip
from pyspark.sql import SparkSession
from google.cloud import storage, pubsub_v1
import pyarrow.csv as pv
import pyarrow.parquet as pq

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def download_and_extract(url, download_dir):
    try:
        local_filename = os.path.join(download_dir, url.split('/')[-1])
        with requests.get(url, stream=True) as r:
            r.raise_for_status()
            with open(local_filename, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192):
                    if chunk:
                        f.write(chunk)
        if local_filename.endswith('.tar'):
            with tarfile.open(local_filename, 'r:') as tar:
                tar.extractall(path=download_dir)
        return local_filename, os.path.basename(url).replace('.tar', '')
    except Exception as e:
        logger.error(f"Failed to download or extract {url}: {e}")
        raise


def upload_to_gcs(bucket_name, source_file_name, destination_blob_name):
    try:
        client = storage.Client()
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(destination_blob_name)
        blob.upload_from_filename(source_file_name)
        logger.info(
            f"Uploaded {source_file_name} to gs://{bucket_name}/{destination_blob_name}"
        )
    except Exception as e:
        logger.error(f"Failed to upload {source_file_name} to GCS: {e}")
        raise


def process_and_upload_file(file_path, gcs_bucket, original_url):
    try:
        csv_files = [
            os.path.join(root, file) for root, _, files in os.walk(file_path)
            for file in files if file.endswith('.csv.gz')
        ]

        for csv_file in csv_files:
            relative_path = original_url.replace(
                'https://movilidad-opendata.mitma.es', '')
            parquet_output_path = relative_path.replace('.csv.gz', '.parquet')

            with gzip.open(csv_file, 'rb') as f:
                table = pv.read_csv(f)
            local_parquet_file = csv_file.replace('.csv.gz', '.parquet')
            pq.write_table(table, local_parquet_file)

            upload_to_gcs(gcs_bucket, local_parquet_file, parquet_output_path)

            # Remove the processed file to free up space
            os.remove(csv_file)
            os.remove(local_parquet_file)
    except Exception as e:
        logger.error(
            f"Failed to process and upload file from {file_path}: {e}")
        raise


def cleanup(download_dir, local_file):
    try:
        if os.path.exists(download_dir):
            for root, dirs, files in os.walk(download_dir, topdown=False):
                for name in files:
                    os.remove(os.path.join(root, name))
                for name in dirs:
                    os.rmdir(os.path.join(root, name))
            os.rmdir(download_dir)

        if os.path.exists(local_file):
            os.remove(local_file)
    except Exception as e:
        logger.error(f"Failed to cleanup files: {e}")
        raise


def callback(message):
    logger.info(f"Received message: {message}")

    # Initialize SparkSession if it doesn't exist
    spark = SparkSession.builder \
        .appName("DownloadAndProcessFiles") \
        .getOrCreate()

    sc = spark.sparkContext

    # Retrieve properties from Spark configuration
    # Retrieve properties from Spark configuration or environment variables
    GCP_PROJECT_ID = os.getenv(
        "GCP_PROJECT_ID",
        spark.conf.get("spark.executorEnv.GCP_PROJECT_ID", None))
    PUBSUB_SUBSCRIPTION_NAME = os.getenv(
        "PUBSUB_SUBSCRIPTION_NAME",
        spark.conf.get("spark.executorEnv.PUBSUB_SUBSCRIPTION_NAME", None))

    # Verify that the variables are correctly set
    if not GCP_PROJECT_ID or not PUBSUB_SUBSCRIPTION_NAME:
        message.nack()
        error_message = (
            "GCP_PROJECT_ID or PUBSUB_SUBSCRIPTION_NAME environment variable is not set."
            f" Got GCP_PROJECT_ID={GCP_PROJECT_ID}, PUBSUB_SUBSCRIPTION_NAME={PUBSUB_SUBSCRIPTION_NAME}"
        )
        logger.error(error_message)
        raise ValueError(error_message)

    logger.info(
        f"GCP_PROJECT_ID: {GCP_PROJECT_ID}, PUBSUB_SUBSCRIPTION_NAME: {PUBSUB_SUBSCRIPTION_NAME}"
    )

    download_dir = "/tmp/downloads"
    os.makedirs(download_dir, exist_ok=True)

    gcs_bucket = os.getenv(
        'GCS_BUCKET_NAME',
        spark.conf.get("spark.executorEnv.GCS_BUCKET_NAME", None))
    if not gcs_bucket:
        logger.error("GCS_BUCKET_NAME environment variable is not set.")
        message.nack()
        return

    try:
        url = message.data.decode('utf-8')
        logger.info(f"Processing URL: {url}")
        local_file, output_file_base_name = download_and_extract(
            url, download_dir)
        process_and_upload_file(local_file, gcs_bucket, url)
        message.ack()
        logger.info(f"Message processed successfully and acknowledged.")
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        message.nack()
    finally:
        # spark.stop()
        cleanup(download_dir, local_file)


def main():
    project_id = os.getenv('GCP_PROJECT_ID')
    subscription_id = os.getenv('PUBSUB_SUBSCRIPTION_NAME')
    gcp_region = os.getenv('GCP_REGION', 'us-central1')  # Default to 'us-central1' if not set

    if not project_id or not subscription_id:
        logger.error(
            "GCP_PROJECT_ID or PUBSUB_SUBSCRIPTION_NAME environment variable is not set."
        )
        return

    subscriber = pubsub_v1.SubscriberClient(client_options={"api_endpoint": f"{gcp_region}-pubsub.googleapis.com:443"})
    subscription_path = subscriber.subscription_path(project_id,
                                                     subscription_id)

    # Configure flow control
    flow_control = pubsub_v1.types.FlowControl(
        max_messages=1,  # Maximum number of messages to process concurrently
        max_bytes=100 * 1024 *
        1024,  # Maximum amount of data (in bytes) to process concurrently
    )

    logger.info(f"Subscribing to {subscription_path}")
    future = subscriber.subscribe(subscription_path,
                                  callback=callback,
                                  flow_control=flow_control)
    try:
        future.result()
    except KeyboardInterrupt:
        future.cancel()
    except Exception as e:
        logger.error(f"Error in main loop: {e}")


if __name__ == "__main__":
    main()
