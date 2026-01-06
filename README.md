# Serverless Content Moderation Pipeline (AWS)

A comprehensive, serverless content moderation system built on AWS that automatically detects and flags inappropriate content across text, images, and videos using AWS Lambda, Step Functions, and AWS Comprehend.

## Project Overview

This project implements an end-to-end content moderation pipeline that:
- Automatically ingests content uploads via S3
- Orchestrates parallel moderation checks across multiple content types
- Aggregates results and makes final decisions
- Stores results in both S3 and DynamoDB for durability and quick access

## Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────┐
│                    S3 Upload                             │
│               (Content Input Bucket)                     │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────┐
         │   Ingestion Lambda            │
         │  - Detects content type       │
         │  - Triggers Step Function     │
         └───────────────┬───────────────┘
                         │
                         ▼
         ┌───────────────────────────────────────────┐
         │      Step Functions Workflow              │
         │    (Parallel Moderation Checks)           │
         └┬──────────────────────────────────────────┘
          │
    ┌─────┼─────┬─────────────────────────┐
    │     │     │                         │
    ▼     ▼     ▼                         ▼
  ┌──────────┐ ┌───────────┐ ┌──────────────┐ ┌──────────┐
  │  Text    │ │  Image    │ │  Video       │ │ Upload   │
  │Moderation│ │Moderation │ │ Moderation   │ │  API     │
  │ Lambda   │ │ Lambda    │ │ Lambda       │ │ Lambda   │
  └──────────┘ └───────────┘ └──────────────┘ └──────────┘
    │     │     │                         │
    └─────┼─────┴─────────────────────────┘
          │
          ▼
  ┌──────────────────────────┐
  │  Decision Engine Lambda  │
  │ - Aggregates results     │
  │ - Makes final decision   │
  │ - Stores in S3 & DB      │
  └──────────────────────────┘
          │
    ┌─────┴─────┐
    ▼           ▼
  ┌───┐      ┌─────────────┐
  │S3 │      │  DynamoDB   │
  │   │      │ (Results)   │
  └───┘      └─────────────┘
```

## Lambda Functions

### 1. **Ingestion Lambda**
- **Trigger**: S3 event notification on file upload
- **Function**: Detects content type based on file extension
- **Action**: Triggers Step Functions workflow with detected content type
- **Supported Types**: Text, Image, Video

### 2. **Text Moderation Lambda**
- **Service**: AWS Comprehend
- **Checks**:
  - PII (Personally Identifiable Information) detection
  - Toxicity detection
  - Profanity and hate speech detection
- **Output**: Flagged labels with confidence scores

### 3. **Image Moderation Lambda**
- **Service**: AWS Rekognition
- **Checks**: Visual content analysis for inappropriate imagery
- **Output**: Detected labels and confidence scores

### 4. **Video Moderation Lambda**
- **Service**: AWS Rekognition
- **Checks**: Video frame analysis for inappropriate content
- **Output**: Flagged frames and timestamps

### 5. **Upload API Lambda**
- **Endpoint**: REST API Gateway endpoint
- **Function**: Provides direct upload capability outside of S3 event triggers
- **Action**: Initiates moderation workflow for programmatic uploads

### 6. **Decision Engine Lambda**
- **Input**: Results from all moderation checks
- **Logic**: 
  - Aggregates flagged labels from all services
  - Determines final moderation status (pass/fail)
  - Creates comprehensive report
- **Output**: Stores results in S3 and DynamoDB with timestamp

## Infrastructure as Code (Terraform)

The project uses Terraform to manage AWS infrastructure:

### Key Resources

- **API Gateway** (`api-gateway.tf`)
  - REST endpoints for content upload and status queries
  - Integrated with Lambda functions

- **Lambda Functions** (`lambda.tf`)
  - Function definitions and configurations
  - Memory allocation and timeout settings
  - Environment variable configuration

- **Step Functions** (`stepfunctions.tf`)
  - Workflow orchestration
  - Parallel execution of moderation services
  - Error handling and retries

- **DynamoDB** (`dynamodb.tf`)
  - Results table for storing moderation decisions
  - Primary key: `contentId`
  - Supports query by timestamp and status

- **S3** (`s3.tf`)
  - Input bucket for content uploads
  - Results bucket for storing moderation reports
  - Access control and encryption

- **IAM** (`iam.tf`)
  - Role definitions for Lambda execution
  - Permissions for AWS services access
  - S3, DynamoDB, and Comprehend/Rekognition permissions

- **Locals & Variables** (`locals.tf`, `variables.tf`)
  - Configuration parameters
  - Naming conventions
  - Thresholds and settings

## Getting Started

### Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- Python 3.9+
- AWS CLI configured

### Installation & Deployment

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd serverless-content-moderation-pipeline-aws
   ```

2. **Build Lambda packages**
   ```bash
   python scripts/build_lambdas.py
   ```
   This script packages each Lambda function with dependencies into ZIP files.

3. **Initialize Terraform**
   ```bash
   cd terraform
   terraform init
   ```

4. **Plan and apply infrastructure**
   ```bash
   terraform plan
   terraform apply
   ```

5. **Configure environment variables**
   - Set S3 bucket names
   - Configure DynamoDB table name
   - Set moderation thresholds

### Terraform Bootstrap (Optional)

For remote state management:
```bash
cd terraform/bootstrap
terraform apply
```

This sets up S3 and DynamoDB for storing Terraform state remotely.

## Configuration

### Moderation Thresholds

Adjust confidence thresholds in Lambda handlers:

**Text Moderation** (`services/TextModeration/handler.py`):
```python
TOXICITY_THRESHOLD = 0.7      # Flag if confidence > 70%
SEVERE_THRESHOLD = 0.8         # Severe flag if confidence > 80%
```

### Environment Variables

Each Lambda requires:
- `DYNAMODB_TABLE`: Results table name
- `RESULTS_BUCKET`: S3 bucket for storing reports
- `STEP_FUNCTION_ARN`: Step Functions execution ARN

## API Endpoints

### Upload Content via API
```bash
POST /upload
Content-Type: multipart/form-data

{
  "file": <file-content>,
  "contentType": "text|image|video"
}
```

### Check Moderation Status
```bash
GET /status/{contentId}
```

### Get Results
```bash
GET /results/{contentId}
```

## Workflow Execution

1. **Content Upload**
   - Upload via S3 or REST API
   - File stored in input bucket

2. **Ingestion**
   - Lambda triggered by S3 event
   - Content type detected
   - Step Function workflow initiated

3. **Parallel Moderation**
   - Text/Image/Video Moderators run in parallel
   - Each service analyzes content independently
   - Results collected asynchronously

4. **Decision**
   - Decision Engine receives all results
   - Aggregates flagged labels
   - Generates final report

5. **Storage**
   - Results stored in S3 with `contentId.json` naming
   - DynamoDB entry created for quick lookup
   - Timestamp recorded for audit trail

## Testing

Sample test file included:
```
tests/sample_test.txt
```

Run moderation manually:
```bash
# Invoke Text Moderation directly
aws lambda invoke \
  --function-name TextModeration \
  --payload file://test-payload.json \
  response.json
```

## Output Format

### Result Object
```json
{
  "contentId": "uuid-string",
  "textLabels": ["PROFANITY", "HATE_SPEECH"],
  "imageLabels": ["INAPPROPRIATE"],
  "videoLabels": ["UNSAFE_CONTENT"],
  "finalStatus": "fail",
  "timestamp": "2025-01-06T10:30:00.000Z"
}
```

## Security Considerations

- **IAM Roles**: Least privilege principle applied
- **S3 Encryption**: Enable encryption at rest and in transit
- **DynamoDB**: Point-in-time recovery enabled
- **API Authentication**: Configure API Gateway authorizers
- **Logging**: CloudWatch Logs for Lambda execution
- **VPC**: Optional VPC configuration for Lambda isolation

## Monitoring & Logging

- **CloudWatch Logs**: All Lambda functions log to CloudWatch
- **Step Functions**: Monitor workflow execution in AWS Console
- **DynamoDB**: Monitor read/write capacity and throttling
- **API Gateway**: Monitor API calls and errors

## Cost Optimization

- Use Reserved Capacity for predictable workloads
- Set appropriate Lambda memory allocation (higher memory = faster execution)
- Enable S3 Lifecycle Policies for old results
- Configure DynamoDB on-demand or provisioned capacity as needed

## Troubleshooting

### Common Issues

**Lambda timeout**: Increase timeout in `lambda.tf`
```hcl
timeout = 120
```

**Permission denied**: Verify IAM roles in `iam.tf` have required permissions

**Step Function failures**: Check CloudWatch Logs for specific Lambda execution errors

**DynamoDB throttling**: Increase capacity or enable on-demand billing

## Future Enhancements

- [ ] Add SNS notifications for flagged content
- [ ] Implement custom moderation rules
- [ ] Add appeal workflow for false positives
- [ ] Integrate with content delivery platform
- [ ] Add analytics dashboard
- [ ] Implement caching for repeated content

## Contributing

1. Create feature branch
2. Make changes with appropriate tests
3. Update README with new features
4. Submit pull request

## License

[Specify your license here]

## Support

For issues, questions, or contributions, please open an issue in the repository.

---

**Project Structure**
```
.
├── services/                 # Lambda function handlers
│   ├── DecisionEngine/
│   ├── ImageModeration/
│   ├── Ingestion/
│   ├── TextModeration/
│   ├── UploadApi/
│   └── VideoModeration/
├── terraform/               # Infrastructure as Code
│   ├── bootstrap/           # Remote state setup
│   ├── *.tf                 # Resource definitions
│   └── variables.tf
├── scripts/                 # Utility scripts
│   └── build_lambdas.py    # Lambda packaging script
└── tests/                   # Test files
    └── sample_test.txt
```
