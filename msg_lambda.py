import boto3  
import json
import os
from datetime import datetime, timedelta
import random
from boto3.dynamodb.conditions import Key, Attr

QUEUE_NAME = os.environ['msg_sqs_name']
#MAX_QUEUE_MESSAGES = 1
DYNAMODB_TABLE = os.environ['msg_ddb_name']

sqs = boto3.resource('sqs')
dynamodb = boto3.resource('dynamodb')

def handler(event, context):

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(DYNAMODB_TABLE)
    olddate = datetime(1990,5,10,12,30,0,0).isoformat()
    kce = Key('Ugly_trick').eq('MessagePart') & Key('Timestamp').between(olddate, datetime.now().isoformat())
    response = table.query(KeyConditionExpression = kce, ScanIndexForward = False, Limit = 1)

    #response = table.query(
        #hash_key=Message, ScanIndexForward=True, limit=1
        #KeyConditionExpression=Key('Message').eq('latest_entry_identifier')
    #    )
    items = response['Items']
    print(items)
    return { "message": items}

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
    const_msg = "MessagePart"
    for message in queue.receive_messages(MessageAttributeNames=['Message']):

        if message.message_attributes is not None:
            msg_value = message.message_attributes.get('Message').get('StringValue')

        table.put_item(Item= {'Ugly_trick': const_msg,'Message': msg_value,'Timestamp':  datetime.now().isoformat()})
        return { "message": msg_value }

        message.delete()
