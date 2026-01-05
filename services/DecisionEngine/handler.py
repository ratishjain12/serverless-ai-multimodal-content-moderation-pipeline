import json
import boto3
import os
from datetime import datetime

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.getenv("DYNAMODB_TABLE"))

RESULTS_BUCKET = os.getenv("RESULTS_BUCKET")

def handler(event,context):
    content_id = event.get("contentId")

    # Aggregate results (expect textLabels, imageLabels, videoLabels)
    final_labels = []
    for key in ["textLabels", "imageLabels", "videoLabels"]:
        final_labels.extend(event.get(key, []))

    final_status = "fail" if final_labels else "pass"

    result = {
        "contentId": content_id,
        "textLabels": event.get("textLabels", []),
        "imageLabels": event.get("imageLabels", []),
        "videoLabels": event.get("videoLabels", []),
        "finalStatus": final_status,
        "timestamp": datetime.utcnow().isoformat()
    }

    # Store in S3
    s3.put_object(
        Bucket=RESULTS_BUCKET,
        Key=f"{content_id}.json",
        Body=json.dumps(result).encode("utf-8")
    )

    # Store in DynamoDB
    table.put_item(Item=result)

    return result
