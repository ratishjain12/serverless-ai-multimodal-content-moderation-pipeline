import boto3

comprehend = boto3.client("comprehend")
s3 = boto3.client("s3")

# Adjustable confidence thresholds
TOXICITY_THRESHOLD = 0.7
SEVERE_THRESHOLD = 0.8

def handler(event, context):
    text = event.get("text")
    content_id = event.get("contentId")

    # Optional S3 input
    if not text:
        s3_key = event.get("s3InputKey")
        bucket = event.get("s3Bucket")
        if s3_key and bucket:
            text = s3.get_object(
                Bucket=bucket,
                Key=s3_key
            )["Body"].read().decode("utf-8")

    if not text:
        return {
            "contentId": content_id,
            "status": "error",
            "reason": "No text provided"
        }

    # -------- PII Detection --------
    pii_response = comprehend.detect_pii_entities(
        Text=text,
        LanguageCode="en"
    )

    pii_entities = [
        e["Type"] for e in pii_response.get("Entities", [])
    ]

    # -------- Toxicity / Profanity / Hate --------
    toxic_response = comprehend.detect_toxic_content(
        TextSegments=[{"Text": text}],
        LanguageCode="en"
    )

    labels = toxic_response["ResultList"][0]["Labels"]

    toxicity_flags = []
    severe_flags = []

    for label in labels:
        name = label["Name"]
        score = label["Score"]

        if score >= TOXICITY_THRESHOLD:
            toxicity_flags.append({
                "type": name,
                "score": round(score, 3)
            })

        if name in {"HATE_SPEECH", "THREAT"} and score >= SEVERE_THRESHOLD:
            severe_flags.append(name)

    # -------- Final Decision --------
    status = "pass"

    if pii_entities or severe_flags:
        status = "fail"
    elif toxicity_flags:
        status = "review"

    return {
        "contentId": content_id,
        "status": status,
        "moderation": {
            "pii": pii_entities,
            "toxicity": toxicity_flags
        }
    }
