#!/bin/bash

aws cloudformation create-stack --stack-name mitma-sqs-queues-stack --template-body file://sqs-queues.yaml

aws cloudformation wait stack-create-complete --stack-name mitma-sqs-queues-stack

aws cloudformation describe-stacks --stack-name mitma-sqs-queues-stack --query "Stacks[0].Outputs"
