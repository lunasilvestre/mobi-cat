import boto3
import xml.etree.ElementTree as ET
import logging
import os

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize S3 client
s3 = boto3.client('s3')


def extract_urls_from_rss(xml_file):
    # Parse the XML file and extract the URLs
    tree = ET.parse(xml_file)
    root = tree.getroot()
    urls = []
    for item in root.findall('./channel/item'):
        link = item.find('link')
        if link is not None:
            urls.append(link.text)
    return urls


def check_file_exists_in_s3(bucket_name, file_key):
    try:
        s3.head_object(Bucket=bucket_name, Key=file_key)
        return True
    except s3.exceptions.NoSuchKey:
        return False
    except Exception as e:
        logger.error(f"Error checking file in S3: {e}")
        return False


def main():
    rss_file = '../data/RSS.xml'  # Path to the RSS XML file
    bucket_name = os.getenv(
        'S3_BUCKET_NAME')  # S3 bucket name from environment variable

    if not bucket_name:
        logger.error("S3_BUCKET_NAME environment variable is not set")
        return

    urls = extract_urls_from_rss(rss_file)
    for url in urls:
        # logger.info(url)
        # Convert URL to S3 key
        file_key = f"mitma/raw/{url.replace('https://movilidad-opendata.mitma.es', '').lstrip('/')}"

        # logger.info(f"Checking if file exists in S3: {file_key}")

        if not check_file_exists_in_s3(bucket_name, file_key):
            print(f"File not found in S3: {url}")


if __name__ == "__main__":
    main()
