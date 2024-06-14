import boto3
import tarfile
import os
import tempfile
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
s3 = boto3.client('s3')
sqs = boto3.client('sqs')

def download_tar_file(bucket, key, tar_file_path):
    logging.info(f"Downloading tar file from s3://{bucket}/{key} to {tar_file_path}")
    s3.download_file(bucket, key, tar_file_path)
    logging.info(f"Successfully downloaded tar file to {tar_file_path}")

def extract_and_upload(bucket, tar_key, member, tar):
    try:
        logging.info(f"Extracting member {member.name}")
        member_file = tar.extractfile(member)
        if member_file is not None:
            temp_member_path = os.path.join(tempfile.gettempdir(), member.name)
            with open(temp_member_path, 'wb') as f:
                f.write(member_file.read())
            logging.info(f"Successfully extracted member {member.name} to {temp_member_path}")

            # Determine the new key for the extracted file
            tar_base_dir = os.path.dirname(tar_key)
            new_key = os.path.join(tar_base_dir, os.path.basename(tar_key).replace('.tar', ''), member.name)

            logging.info(f"Uploading extracted file to s3://{bucket}/{new_key}")
            with open(temp_member_path, 'rb') as f:
                s3.put_object(Bucket=bucket, Key=new_key, Body=f)
            logging.info(f"Successfully uploaded {new_key} to {bucket}")

            # Delete the temporary extracted file to free up space
            os.remove(temp_member_path)
            logging.info(f"Deleted temporary file {temp_member_path}")
        else:
            logging.warning(f"Member {member.name} could not be extracted")
    except Exception as e:
        logging.error(f"Error processing {member.name} from {tar_key}: {e}")
        raise e

def process_tar_file(bucket, key):
    tar_file_path = os.path.join(tempfile.gettempdir(), os.path.basename(key))
    download_tar_file(bucket, key, tar_file_path)

    with tarfile.open(tar_file_path, 'r') as tar:
        members = [m for m in tar.getmembers() if m.isfile()]
        logging.info(f"Found {len(members)} members in the tar file")

        for member in members:
            extract_and_upload(bucket, key, member, tar)

    os.remove(tar_file_path)
    logging.info(f"Processed {key} and extracted {len(members)} files.")

def delete_sqs_message(queue_url, receipt_handle):
    sqs.delete_message(
        QueueUrl=queue_url,
        ReceiptHandle=receipt_handle
    )
    logging.info(f"Deleted message with receipt handle {receipt_handle} from queue {queue_url}")

def main():
    queue_url = os.getenv('QUEUE_URL')
    receipt_handle = os.getenv('RECEIPT_HANDLE')
    s3_uri = os.getenv('S3_URI')

    bucket, key = parse_s3_uri(s3_uri)

    try:
        process_tar_file(bucket, key)
        delete_sqs_message(queue_url, receipt_handle)
    except Exception as e:
        logging.error(f"Failed to process tar file {s3_uri}: {e}")
        # The message will remain in the queue and can be retried

def parse_s3_uri(uri):
    if uri.startswith("s3://"):
        uri = uri[5:]
    parts = uri.split("/", 1)
    return parts[0], parts[1]

if __name__ == "__main__":
    main()
