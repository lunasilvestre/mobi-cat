import os
from google.cloud import pubsub_v1
from google.api_core.exceptions import NotFound
import logging
import xml.etree.ElementTree as ET

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Define environment variables
project_id = os.getenv('GCP_PROJECT_ID')
topic_id = "mitma-download-requests"
subscription_id = os.getenv('PUBSUB_SUBSCRIPTION_NAME')
gcp_region = os.getenv('GCP_REGION', 'us-central1')  # Default to 'us-central1' if not set

if not project_id:
    logger.error("GCP_PROJECT_ID environment variable is not set.")
    exit(1)

if not subscription_id:
    logger.error("PUBSUB_SUBSCRIPTION_NAME environment variable is not set.")
    exit(1)

# Initialize the Publisher and Subscriber clients with regional endpoints if required
publisher = pubsub_v1.PublisherClient(client_options={"api_endpoint": f"{gcp_region}-pubsub.googleapis.com:443"})
subscriber = pubsub_v1.SubscriberClient(client_options={"api_endpoint": f"{gcp_region}-pubsub.googleapis.com:443"})

# Define topic and subscription paths
topic_path = publisher.topic_path(project_id, topic_id)
subscription_path = subscriber.subscription_path(project_id, subscription_id)

# Ensure the topic exists
try:
    publisher.get_topic(request={"topic": topic_path})
    logger.info(f"Topic {topic_path} already exists.")
except NotFound:
    logger.info(f"Topic {topic_path} not found. Creating topic.")
    publisher.create_topic(request={"name": topic_path})
    logger.info(f"Topic {topic_path} created successfully.")

# Ensure the subscription exists
try:
    subscriber.get_subscription(request={"subscription": subscription_path})
    logger.info(f"Subscription {subscription_path} already exists.")
except NotFound:
    logger.info(
        f"Subscription {subscription_path} not found. Creating subscription.")
    subscriber.create_subscription(request={
        "name": subscription_path,
        "topic": topic_path
    })
    logger.info(f"Subscription {subscription_path} created successfully.")


def publish_messages(rss_file):
    # Parse the RSS file
    tree = ET.parse(rss_file)
    root = tree.getroot()

    # Find all URLs in the RSS file and publish each one
    for item in root.findall('.//item'):
        url = item.find('.//link').text.strip()
        future = publisher.publish(topic_path, url.encode('utf-8'))
        future.add_done_callback(lambda _: logger.info(f"Published URL: {url}. Message ID: {future.result()}"))
        try:
            future.result()
        except Exception as e:
            logger.error(f"Failed to publish URL {url}: {e}")


# Publish messages from the RSS file
publish_messages('RSS-test.xml')