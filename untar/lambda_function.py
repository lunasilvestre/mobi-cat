import boto3
import os

ecs_client = boto3.client('ecs')
sqs_client = boto3.client('sqs')

def lambda_handler(event, context):
    cluster_name = os.getenv('ECS_CLUSTER_NAME')
    task_definition = os.getenv('ECS_TASK_DEFINITION')
    subnet_id = os.getenv('SUBNET_ID')
    security_group_id = os.getenv('SECURITY_GROUP_ID')

    for record in event['Records']:
        message_body = record['body']
        receipt_handle = record['receiptHandle']
        queue_url = record['eventSourceARN']

        response = ecs_client.run_task(
            cluster=cluster_name,
            launchType='FARGATE',
            taskDefinition=task_definition,
            count=1,
            networkConfiguration={
                'awsvpcConfiguration': {
                    'subnets': [subnet_id],
                    'securityGroups': [security_group_id],
                    'assignPublicIp': 'DISABLED'  # Ensure tasks are not exposed to the internet
                }
            },
            overrides={
                'containerOverrides': [
                    {
                        'name': 'process-tar-container',
                        'environment': [
                            {'name': 'S3_URI', 'value': message_body},
                            {'name': 'RECEIPT_HANDLE', 'value': receipt_handle},
                            {'name': 'QUEUE_URL', 'value': queue_url}
                        ]
                    }
                ]
            }
        )

    return {
        'statusCode': 200,
        'body': 'Tasks triggered successfully'
    }
