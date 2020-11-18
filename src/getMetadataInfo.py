import json
import os

def lambda_handler(event,context): 

 version = os.environ.get("VERSION")
 git_sha = os.environ.get("GIT_SHA")
 response = {
        "statusCode": 200,
        "headers": {},
        "body": json.dumps({
	 "myapplication": [
  	{
    		"version": version,
    		"description" : "pre-interview technical test",
    		"lastcommitsha": git_sha
  	}
       ]})
    }

 return response

