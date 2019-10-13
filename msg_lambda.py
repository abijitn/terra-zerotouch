import boto3  
import json

def handler(event, context):
    return { "message": "Hello, World!" }

def post_handler(event, context):
#    return { "message": "I should have created something..." }

    sqs = boto3.resource('sqs')

    queue = sqs.get_queue_by_name(QueueName='testsqs')

    response = queue.send_message(MessageBody=json.dumps(event))