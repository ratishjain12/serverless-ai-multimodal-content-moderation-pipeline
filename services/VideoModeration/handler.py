import boto3
import time

rekognition = boto3.client("rekognition")

def handler(event,context):
    content_id = event.get("contentId")
    bucket = event.get("s3Bucket")
    key = event.get("s3InputKey")

    # Start async content moderation
    response = rekognition.start_content_moderation(
        Video={"S3Object": {"Bucket": bucket, "Name": key}},
        NotificationChannel={
            # Optional: SNS for async completion
        },
        MinConfidence=70
    )
    job_id = response["JobId"]

    # Poll for completion (simplified)
    while True:
        result = rekognition.get_content_moderation(JobId=job_id)
        if result["JobStatus"] in ["SUCCEEDED", "FAILED"]:
            break
        time.sleep(5)

    labels = [m["ModerationLabel"]["Name"] for m in result.get("ModerationLabels", [])]

    return {
        "contentId": content_id,
        "videoLabels": labels,
        "status": "fail" if labels else "pass"
    }
