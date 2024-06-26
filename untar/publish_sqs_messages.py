import boto3

# Initialize the SQS client
sqs = boto3.client('sqs', region_name='eu-south-2')

# Define the SQS queue URL
queue_url = 'https://sqs.eu-south-2.amazonaws.com/636901251658/mitma-untar-queue'

# Load the URIs from the file
file_path = '../logs/filtered_uris_correct.txt'

with open(file_path, 'r') as file:
    uris = file.readlines()

# Publish each URI as a separate message
for uri in uris:
    response = sqs.send_message(QueueUrl=queue_url, MessageBody=uri.strip())
    print(f"MessageId: {response['MessageId']} sent for URI: {uri.strip()}")
