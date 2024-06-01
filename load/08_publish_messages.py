# publish_messages.py
from google.cloud import pubsub_v1
import xml.etree.ElementTree as ET
import os

project_id = os.getenv("GCP_PROJECT_ID", "lunasilvestre-com")
topic_id = os.getenv("PUBSUB_TOPIC_NAME", "mitma-download-requests")

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_id)

def publish_messages(rss_file):
    tree = ET.parse(rss_file)
    root = tree.getroot()

    for item in root.findall('.//item'):
        url = item.find('.//link').text.strip()
        publisher.publish(topic_path, url.encode('utf-8'))

publish_messages('RSS.xml')