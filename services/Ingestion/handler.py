import json
import boto3
import os
import uuid

# AWS clients
sfn = boto3.client("stepfunctions")
s3 = boto3.client("s3")

# Environment variable pointing to Step Functions ARN
STEP_FUNCTION_ARN = os.environ.get("STEP_FUNCTION_ARN")

def detect_content_type(key: str) -> str:
    """Detect content type based on file extension"""
    key_lower = key.lower()
    if key_lower.endswith((".txt", ".md", ".csv")):
        return "text"
    elif key_lower.endswith((".jpg", ".jpeg", ".png", ".gif")):
        return "image"
    elif key_lower.endswith((".mp4", ".mov", ".avi", ".mkv")):
        return "video"
    else:
        return "unknown"

def handler(event, context):
    """
    Ingestion Lambda triggered by S3 upload.
    Starts Step Functions workflow.
    """
    try:
        # S3 event can contain multiple records
        for record in event.get("Records", []):
            bucket = record["s3"]["bucket"]["name"]
            key = record["s3"]["object"]["key"]

            # Generate a contentId or use S3 key
            content_id = str(uuid.uuid4())

            # Detect content type
            content_type = detect_content_type(key)
            if content_type == "unknown":
                print(f"Unknown content type for {key}, skipping")
                continue

            # Prepare Step Functions input
            step_input = {
                "contentId": content_id,
                "contentType": content_type,
                "s3InputKey": key,
                "s3Bucket": bucket
            }

            # Start Step Functions execution
            response = sfn.start_execution(
                stateMachineArn=STEP_FUNCTION_ARN,
                name=f"{content_id}",
                input=json.dumps(step_input)
            )

            print(f"Started Step Functions execution for {content_id}: {response['executionArn']}")

        return {"status": "success"}

    except Exception as e:
        print(f"Error in ingestion lambda: {str(e)}")
        raise e
