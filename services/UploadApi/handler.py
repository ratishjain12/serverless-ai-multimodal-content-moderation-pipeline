import json
import boto3
import os
import uuid

s3 = boto3.client("s3")

# Bucket must already exist
UPLOAD_BUCKET = os.environ.get("UPLOAD_BUCKET", "content-moderation-input")
URL_EXPIRATION = int(os.environ.get("URL_EXPIRATION", "300"))  # seconds

def handler(event, context):
    """
    Returns a pre-signed URL for uploading content to S3
    """
    try:
        # Optional: read desired file name or type from client
        body = json.loads(event.get("body", "{}"))
        filename = body.get("filename")
        content_type = body.get("contentType", "application/octet-stream")

        if not filename:
            return {
                "statusCode": 400,
                "body": json.dumps({"message": "filename is required"})
            }

        # Generate a unique contentId
        content_id = str(uuid.uuid4())
        s3_key = f"{content_id}/{filename}"

        # Generate pre-signed URL
        presigned_url = s3.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": UPLOAD_BUCKET,
                "Key": s3_key,
                "ContentType": content_type
            },
            ExpiresIn=URL_EXPIRATION
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "contentId": content_id,
                "s3Key": s3_key,
                "uploadUrl": presigned_url
            })
        }

    except Exception as e:
        print(f"Error generating presigned URL: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal server error"})
        }
