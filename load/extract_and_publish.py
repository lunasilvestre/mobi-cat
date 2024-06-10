import boto3
import xml.etree.ElementTree as ET
import logging
import os

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Validate required environment variables
required_env_vars = ['SQS_QUEUE_URL']
for var in required_env_vars:
    if not os.getenv(var):
        logger.error(f"Environment variable {var} is not set")
        raise EnvironmentError(f"Environment variable {var} is not set")

# Initialize SQS client
sqs = boto3.client('sqs')


def extract_urls_from_rss(xml_file):
    tree = ET.parse(xml_file)
    root = tree.getroot()
    urls = []

    # Assuming the structure follows the common RSS feed format
    for item in root.findall('./channel/item'):
        link = item.find('link')
        if link is not None:
            urls.append(link.text)

    return urls


def publish_to_sqs(message, queue_url):
    try:
        response = sqs.send_message(QueueUrl=queue_url, MessageBody=message)
        logger.info(
            f"Published to SQS: {message} - MessageId: {response.get('MessageId')}"
        )
    except Exception as e:
        logger.error(f"Failed to publish message to SQS: {e}")
        raise


def main():
    rss_file = '../data/RSS.xml'
    queue_url = os.getenv('SQS_QUEUE_URL')

    urls = extract_urls_from_rss(rss_file)
    for url in urls:
        publish_to_sqs(url, queue_url)


if __name__ == "__main__":
    main()
