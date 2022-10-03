import boto3
import json
import os


def is_array_of_numbers(input):
    if not (isinstance(input, list)):
        return False

    for x in input:
        if not (isinstance(x, int) or isinstance(x, float)):
            return False

    return True


def lambda_handler(event, context):

    input = event["body"]

    if is_array_of_numbers(input):

        arn = os.environ["SNS_ARN"]
        client = boto3.client("sns")

        result = sum(input)

        response = client.publish(
            TargetArn=arn,
            Message=json.dumps({"default": json.dumps(resoult)}),
            MessageStructure="json",
        )
        if "HTTPStatusCode" in response.keys() and response["HTTPStatusCode"] != 200:
            return json.dumps({"status": 500})

        return json.dumps({"status": 200, "result": result})

    else:
        return json.dumps({"status": 400})
