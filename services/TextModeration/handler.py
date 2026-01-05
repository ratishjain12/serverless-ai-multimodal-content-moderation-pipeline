import boto3

comprehend = boto3.client("comprehend")

def handler(event,context):
    # Expecting S3 key or direct text in the event
    text = event.get("text")
    content_id = event.get("contentId")

    if not text:
        # Optionally, fetch text from S3 if s3InputKey is provided
        s3_key = event.get("s3InputKey")
        if s3_key:
            s3 = boto3.client("s3")
            bucket = event.get("s3Bucket")
            text = s3.get_object(Bucket=bucket, Key=s3_key)["Body"].read().decode("utf-8")

    # Call Comprehend to detect PII or sentiment/toxicity
    pii_entities = comprehend.detect_pii_entities(Text=text, LanguageCode="en")["Entities"]
    # Here, you could add custom logic to flag offensive words etc.

    result = {
        "contentId": content_id,
        "textLabels": [e["Type"] for e in pii_entities],
        "status": "fail" if pii_entities else "pass"
    }

    return result
