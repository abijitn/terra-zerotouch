import boto3  
import json
import os
from datetime import datetime
import random

QUEUE_NAME = os.environ['msg_sqs_name']
#MAX_QUEUE_MESSAGES = 1
DYNAMODB_TABLE = os.environ['msg_ddb_name']

sqs = boto3.resource('sqs')
dynamodb = boto3.resource('dynamodb')

def handler(event, context):
    return { "message": "Hello, World!" }

def post_handler(event, context):

    queue = sqs.get_queue_by_name(QueueName=QUEUE_NAME)
    response = queue.send_message(
        MessageAttributes={
        'Message': {
            'DataType': 'String',
            'StringValue': 'Random Message-'+datetime.now().isoformat()
        },
        'Timestamp': {
            'DataType': 'String',
            'StringValue': datetime.now().isoformat()
        }
    },MessageBody=json.dumps(event)
    )
    
def sqs_handler(event, context):

    queue = sqs.get_queue_by_name(QueueName=QUEUE_NAME)
    table = dynamodb.Table(DYNAMODB_TABLE)

    for message in queue.receive_messages(MessageAttributeNames=['Message']):

        if message.message_attributes is not None:
            msg_value = message.message_attributes.get('Message').get('StringValue')

        table.put_item(Item= {'Message': msg_value,'Timestamp':  datetime.now().isoformat()})
        return { "message": msg_value }

        message.delete()
