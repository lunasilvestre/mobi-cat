import os
import unittest
from unittest.mock import patch
import boto3
from moto import mock_s3, mock_sqs
import lambda_function


class TestLambdaFunction(unittest.TestCase):

    @mock_s3
    @mock_sqs
    @patch.dict(os.environ, {
        'S3_BUCKET_NAME': 'mobi-cat',
        'AWS_REGION': 'eu-south-2'
    })
    def test_download_and_upload_flow(self):
        s3 = boto3.client('s3', region_name='eu-south-2')
        sqs = boto3.client('sqs', region_name='eu-south-2')

        # Create S3 bucket
        s3.create_bucket(Bucket='mobi-cat')

        # Create SQS queues
        dlq_response = sqs.create_queue(QueueName='mitma-dlq')
        main_queue_response = sqs.create_queue(
            QueueName='mitma-queue',
            Attributes={
                'RedrivePolicy': json.dumps({
                    'deadLetterTargetArn': dlq_response['QueueUrl'],
                    'maxReceiveCount': '5'
                })
            }
        )
        main_queue_url = main_queue_response['QueueUrl']

        # Send a message to SQS queue representing a file URL
        s3_file_url = 'https://example.com/testfile.csv'
        sqs.send_message(QueueUrl=main_queue_url, MessageBody=s3_file_url)

        # Mock requests.get to return content from URL
        with patch('lambda_function.requests.get') as mock_get:
            mock_get.return_value.status_code = 200
            mock_get.return_value.iter_content = lambda chunk_size: [b'file content']

            # Invoke the Lambda function handler
            event = {
                'Records': [
                    {'body': s3_file_url}
                ]
            }
            lambda_function.lambda_handler(event, None)

            # Assert S3 upload
            objects = s3.list_objects_v2(Bucket='mobi-cat', Prefix='mitma/raw/testfile.csv')
            self.assertEqual(objects.get('KeyCount'), 1, "File was not uploaded to S3")

            # Check if Lambda was invoked
            received_messages = sqs.receive_message(QueueUrl=main_queue_url)
            self.assertTrue('Messages' not in received_messages, "Message was not deleted from queue")


if __name__ == '__main__':
    unittest.main()