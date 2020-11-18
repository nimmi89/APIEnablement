import json

def lambda_handler(event, context):
    body = "Lambda says your API is healthy!!"
    statusCode = 200
    return { "isBase64Encoded": True, "statusCode": 200, "headers": {  }, "body": json.dumps(body) }



