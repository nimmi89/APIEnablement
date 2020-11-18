import json

def lambda_handler(event, context):
    body = "Hello World!! Have a wonderful day"

    return {
        "body": json.dumps(body),
        "headers":{
            "Content-Type" : "application/json"
        }
    }
