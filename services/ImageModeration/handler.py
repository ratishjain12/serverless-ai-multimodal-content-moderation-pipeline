import boto3

rekognition = boto3.client("rekognition")
s3 = boto3.client("s3")

def handler(event, context):
    content_id = event.get("contentId")
    bucket = event.get("s3Bucket")
    key = event.get("s3InputKey")

    response = rekognition.detect_moderation_labels(
        Image={"S3Object": {"Bucket": bucket, "Name": key}},
        MinConfidence=70
    )

    labels = [label["Name"] for label in response.get("ModerationLabels", [])]

    return {
        "contentId": content_id,
        "imageLabels": labels,
        "status": "fail" if labels else "pass"
    }
