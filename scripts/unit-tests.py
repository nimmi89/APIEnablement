import requests
import requests
import responses
import pytest
import json

from requests.exceptions import ConnectionError

#Input API URL
url = "https://hwp0b6bz0l.execute-api.ap-southeast-2.amazonaws.com/v1OpsTechnicalTest/"

#Input metadata API endpoint
metadata_url = "https://hwp0b6bz0l.execute-api.ap-southeast-2.amazonaws.com/v1OpsTechnicalTest/metadata"
wrong_url = "https://hwp0b6bz0l.execute-api.ap-southeast-2.amazonaws.com/v1OpsTechnicalTest/random"
#Input API key
headers = {'x-api-key':'1KS7AxDY5x1YRgjQLwhCl7DkH5r4WxiG48toH7IJ'}


def test_apiendpoint_response():
    response = requests.get(url, headers=headers)
    assert response.status_code == 200

def test_apiendpoint_header():
    response = requests.get(url , headers=headers)
    assert response.headers['Content-Type'] == "application/json"


def test_apiendpoint_metadata_sha():
    response = requests.get(metadata_url, headers=headers)
    response_body = response.json()
    assert response_body["myapplication"][0]["lastcommitsha"] == "9287354"


def test_apiendpoint_metadata_version():
    response = requests.get(metadata_url, headers=headers)
    response_body = response.json()
    assert response_body["myapplication"][0]["version"] == "1.1"



##Wrong URL[failure tests]
@responses.activate
def test_apiendpoint_check():
    with pytest.raises(ConnectionError):
        requests.get(wrong_url, headers=headers)


def test_apiendpoint_wrongstatuscode():
    response = requests.get(wrong_url, headers=headers)
    assert response.status_code == 403
    
