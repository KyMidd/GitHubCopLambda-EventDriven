from __future__ import print_function
import json
import boto3
import sys
from botocore.exceptions import ClientError
import hashlib
import hmac
import re
from urllib.parse import unquote

# botocore.vendored present in Lambda hosted environment, but not local
from botocore.vendored import requests # For lambda-hosted runs
#import requests # For local testing

# Calculate the signature
def calculate_signature(github_signature, githhub_payload):
    signature_bytes = bytes(github_signature, 'utf-8')
    digest = hmac.new(key=signature_bytes, msg=githhub_payload, digestmod=hashlib.sha1)
    signature = digest.hexdigest()
    return signature

# Validate the signature
def validate_signature(GITHUB_SECRET, event, body):
  
  incoming_signature = re.sub(r'^sha1=', '', event['headers']['X-Hub-Signature'])
  incoming_payload = unquote(re.sub(r'^payload=', '', event['body']))
  calculated_signature = calculate_signature(GITHUB_SECRET, incoming_payload.encode('utf-8'))

  if incoming_signature != calculated_signature:
    print("Unauthorized attempt")
    sys.exit()
  else:
    print("🚀 Confirmed HMAC matches, authorized access, continuing")
  
# Isolate the event body from the event package
def isolate_event_body(event):
  # Dump the event to a string, then load it as a dict
  event_string = json.dumps(event, indent=2)
  event_dict = json.loads(event_string)
  
  # Isolate the event body from event package
  event_body = event_dict['body']
  body = json.loads(event_body)
  
  # Return the event
  return body

# Get the event action
def check_event_action(event):
    
  # Check action of event
  action = event['action']
  
  # If action isn't "created", exit
  if action != 'created':
    print("🚫 Event action detected as: " + action)
    print("🚫 Event is not creating a repo, exiting")

    # Return 200 code
    return {
      'statusCode': 200,
      'body': json.dumps("Since action is ", action, ", and not 'created', we are exiting")
    }

    # Exit script
    sys.exit()
  else:
    print("🚀 Successfully detected action: " + action)

  # Get repo name
  repo_name = event['repository']['name']
  print("🚀 Successfully detected repo: " + repo_name)
  return repo_name

# Get GitHubPAT secret from AWS Secrets Manager that we'll use to start the githubcop workflow
def get_secret(secret_name, region_name):
  
  # Create a Secrets Manager client
  session = boto3.session.Session()
  client = session.client(
    service_name='secretsmanager',
    region_name=region_name
  )

  try:
    get_secret_value_response = client.get_secret_value(
      SecretId=secret_name
    )
  except ClientError as e:
    # For a list of exceptions thrown, see
    # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    print("Had an error attempting to get secret from AWS Secrets Manager:", e)
    raise e

  # Decrypts secret using the associated KMS key.
  secret = get_secret_value_response['SecretString']

  # Print happy joy joy
  print("🚀 Successfully got secret", secret_name, "from AWS Secrets Manager")
  
  # Return the secret
  return secret

# Start repo cop workflow targeting a single repo
def start_repo_cop_targeted(repo_name, PAT):

  # Define new data to create
  payload = {
    "ref": "master",
    "inputs": {
      "repo-to-police": repo_name
    }
  }
  print("🚀 Successfully created payload")

  post_headers = {
    "Accept": "application/vnd.github+json",
    "Authorization": "Bearer " + PAT,
    "X-GitHub-Api-Version": "2022-11-28"
  }
  print("🚀 Successfully created post headers")

  # The API endpoint to communicate with
  url_post = "https://api.github.com/repos/{org_name}}/{repo_name}}/actions/workflows/{actions_yaml_file_name}}.yml/dispatches"

  # A POST request to tthe API
  try:
    post_response = requests.post(
      url_post,
      headers=post_headers,
      json=payload
    )
  except ClientError as e:
    # For a list of exceptions thrown, see
    # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    raise e

  if post_response.status_code != 204:
    print("🚨 Error: ", post_response.status_code)
    print(post_response.text)
    sys.exit()

def return_response_code():
  return {
    'statusCode': 200,
    'body': json.dumps('Processed by GitHubCop Trigger Lambda!')
  }

# Main function
def lambda_handler(event, context):

  print("🚀 Lambda execution starting")

  # Isolate the event body from the event package
  body = isolate_event_body(event)

  # Fetch the webhook secret from secrets manager
  GITHUB_SECRET = get_secret("GitHubWebhookSecret", "us-east-1")

  # Validate the signature
  validate_signature(GITHUB_SECRET, event, body)
  
  # Check event action. If new repo added, get repo name. Else, exit
  repo_name = check_event_action(body)

  # Get the PAT from secrets manager
  PAT = get_secret("GitHubAccessToken", "us-east-1")

  # Start the githubcop workflow
  start_repo_cop_targeted(repo_name, PAT)

  # Print happy joy joy
  print("🚀 Successfully started repo cop workflow targeting repo: " + repo_name)

  # Return response code
  return return_response_code()
