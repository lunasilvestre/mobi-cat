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
        logger.info(f"Uploaded {source_file_name} to gs://{bucket_name}/{destination_blob_name}")
    except Exception as e:
        logger.error(f"Failed to upload {source_file_name} to GCS: {e}")
        raise

def process_and_upload_file(file_path, gcs_bucket, original_url):
    try:
        csv_files = [os.path.join(root, file) for root, _, files in os.walk(file_path) 
                        for file in files if file.endswith('.csv.gz')]

        for csv_file in csv_files:
            relative_path = original_url.replace('https://movilidad-opendata.mitma.es', '')
            parquet_output_path = relative_path.replace('.csv.gz', '.parquet')

            with gzip.open(csv_file, 'rb') as f:
                table = pv.read_csv(f)
            local_parquet_file = csv_file.replace('.csv.gz', '.parquet')
            pq.write_table(table, local_parquet_file)

            upload_to_gcs(gcs_bucket, local_parquet_file, parquet_output_path)
    except Exception as e:
        logger.error(f"Failed to process and upload file from {file_path}: {e}")
        raise

def callback(message):
    logger.info(f"Received message: {message}")

    spark = SparkSession.builder \
        .appName("DownloadAndProcessFiles") \
        .getOrCreate()
    sc = spark.sparkContext

    download_dir = "/tmp/downloads"
    os.makedirs(download_dir, exist_ok=True)

    gcs_bucket = os.getenv('GCS_BUCKET_NAME')
    if not gcs_bucket:
        logger.error("GCS_BUCKET_NAME environment variable is not set.")
        message.nack()
        return

    try:
        url = message.data.decode('utf-8')
        logger.info(f"Processing URL: {url}")
        local_file, output_file_base_name = download_and_extract(url, download_dir)
        process_and_upload_file(local_file, gcs_bucket, url)
        message.ack()
        logger.info(f"Message processed successfully and acknowledged.")
    except Exception as e:
        logger.error(f"Error processing message: {e}")
        message.nack()
    finally:
        spark.stop()

def main():
    project_id = os.getenv('GCP_PROJECT_ID')
    subscription_id = os.getenv('PUBSUB_SUBSCRIPTION_NAME')

    if not project_id or not subscription_id:
        logger.error("GCP_PROJECT_ID or PUBSUB_SUBSCRIPTION_NAME environment variable is not set.")
        return

    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(project_id, subscription_id)

    logger.info(f"Subscribing to {subscription_path}")
    future = subscriber.subscribe(subscription_path, callback=None)
    try:
        future.result()
    except KeyboardInterrupt:
        future.cancel()
    except Exception as e:
        logger.error(f"Error in main loop: {e}")

if __name__ == "__main__":
    main()