import boto3  
import json
import os
from datetime import datetime

def handler(event, context):
    return { "message": "Hello, World!" }

def post_handler(event, context):

    sqs = boto3.resource('sqs')
    queue = sqs.get_queue_by_name(QueueName=os.environ['msg_sqs_name'])
    response = queue.send_message(MessageBody=json.dumps(event))


def sqs_handler(event, context):

    QUEUE_NAME = os.environ['msg_sqs_name']
    MAX_QUEUE_MESSAGES = 10
    DYNAMODB_TABLE = os.environ['msg_ddb_name']

    sqs = boto3.resource('sqs')
    dynamodb = boto3.resource('dynamodb')


def lambda_handler(event, context):

  # Receive messages from SQS queue
    queue = sqs.get_queue_by_name(QueueName=QUEUE_NAME)

    print("ApproximateNumberOfMessages:",
    queue.attributes.get('ApproximateNumberOfMessages'))

    for message in queue.receive_messages(
        MaxNumberOfMessages=int(MAX_QUEUE_MESSAGES)):

          print(message)

            # Write message to DynamoDB
            table = dynamodb.Table(DYNAMODB_TABLE)

            response = table.put_item(
              Item={
                    'MessageId': message.message_id,
                    'Body': message.body,
                    'Timestamp': datetime.now().isoformat()
              }
            )
            print("Wrote message to DynamoDB:", json.dumps(response))

            # Delete SQS message
            message.delete()
            print("Deleted message:", message.message_id)

