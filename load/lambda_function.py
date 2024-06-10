import os
import logging
import requests
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize S3 client
try:
    s3 = boto3.client('s3')
except (NoCredentialsError, PartialCredentialsError) as e:
    logger.error(f"S3 Client Initialization Error: {e}")
    raise

# Validate required environment variables
required_env_vars = ['S3_BUCKET_NAME']
for var in required_env_vars:
    if not os.getenv(var):
        logger.error(f"Environment variable {var} is not set")
        raise EnvironmentError(f"Environment variable {var} is not set")


def download_file(url, download_dir):
    local_filename = os.path.join(download_dir, url.split('/')[-1])
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        with open(local_filename, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
    except requests.RequestException as e:
        logger.error(f"Failed to download file from {url}: {e}")
        raise
    return local_filename


def upload_to_s3(local_filename, s3_key):
    bucket_name = os.getenv('S3_BUCKET_NAME')
    try:
        s3.upload_file(local_filename, bucket_name, s3_key)
        logger.info(
            f"Uploaded {local_filename} to s3://{bucket_name}/{s3_key}")
    except boto3.exceptions.S3UploadFailedError as e:
        logger.error(f"Failed to upload file to S3: {e}")
        raise


def lambda_handler(event, context):
    download_dir = '/tmp/downloads'
    os.makedirs(download_dir, exist_ok=True)

    try:
        for record in event['Records']:
            url = record['body']
            logger.info(f"Processing URL: {url}")

            # Download the file from the URL
            local_filename = download_file(url, download_dir)

            # Generate S3 key for uploading
            s3_key = f"mitma/raw/{url.replace('https://movilidad-opendata.mitma.es', '').lstrip('/')}"

            # Upload the file to S3
            upload_to_s3(local_filename, s3_key)

    except NoCredentialsError:
        logger.error("Credentials not available")
        raise
    except PartialCredentialsError:
        logger.error("Incomplete credentials provided")
        raise
    except Exception as e:
        logger.error(f"Failed to process: {e}")
        raise
    finally:
        # Clean up the download directory
        for root, dirs, files in os.walk(download_dir, topdown=False):
            for name in files:
                os.remove(os.path.join(root, name))
            for name in dirs:
                os.rmdir(os.path.join(root, name))

    return {'statusCode': 200, 'body': 'Processing complete'}
