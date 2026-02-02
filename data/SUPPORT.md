# AWS Glue & Snowflake Support Guide

This guide provides support information for AWS Glue and Snowflake integration.

## Quick Start Checklist

Before deploying, ensure you have:

- [ ] VPC stack deployed and outputs available
- [ ] Snowflake account with:
  - [ ] Warehouse created
  - [ ] Database and schema created
  - [ ] User credentials ready
- [ ] S3 bucket for Glue scripts
- [ ] AWS CLI configured
- [ ] Appropriate IAM permissions

## Pre-Deployment Checklist

### 1. Verify VPC Stack
```bash
# Check VPC stack exists
aws cloudformation describe-stacks \
  --stack-name vpc-1 \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus'

# Get VPC outputs
aws cloudformation describe-stacks \
  --stack-name vpc-1 \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table
```

### 2. Prepare S3 Bucket
```bash
# Create bucket
aws s3 mb s3://your-glue-scripts-bucket --region us-east-1

# Upload Glue job script
aws s3 cp glue-job-template.py s3://your-glue-scripts-bucket/glue-scripts/

# Create temp directory
aws s3 mb s3://your-glue-scripts-bucket/glue-temp
```

### 3. Gather Snowflake Information
- Account identifier (e.g., `xy12345.us-east-1`)
- Username and password
- Warehouse name
- Database name
- Schema name
- Role (optional)

### 4. Verify IAM Permissions
Required permissions:
- `glue:*`
- `secretsmanager:*`
- `iam:CreateRole`
- `iam:CreatePolicy`
- `ec2:DescribeVpcs`
- `ec2:DescribeSubnets`
- `ec2:DescribeSecurityGroups`
- `s3:*`

## Deployment Steps

### Step 1: Update Parameters

Edit `parameters-glue-snowflake-dev.json`:

```json
{
  "ParameterKey": "SnowflakeAccount",
  "ParameterValue": "your_account.us-east-1"
},
{
  "ParameterKey": "SnowflakeUser",
  "ParameterValue": "your_username"
},
{
  "ParameterKey": "SnowflakePassword",
  "ParameterValue": "your_password"
},
{
  "ParameterKey": "GlueJobScriptLocation",
  "ParameterValue": "s3://your-bucket/glue-scripts/snowflake-etl.py"
},
{
  "ParameterKey": "GlueScriptsBucket",
  "ParameterValue": "your-bucket"
}
```

### Step 2: Deploy Stack

```bash
cd data
aws cloudformation create-stack \
  --stack-name glue-snowflake-dev \
  --template-body file://glue-snowflake-template.yaml \
  --parameters file://parameters-glue-snowflake-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Step 3: Verify Deployment

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name glue-snowflake-dev \
  --region us-east-1

# Get outputs
aws cloudformation describe-stacks \
  --stack-name glue-snowflake-dev \
  --query 'Stacks[0].Outputs' \
  --region us-east-1
```

## Connection String Management

### View Connection String

```bash
# Get from stack outputs
aws cloudformation describe-stacks \
  --stack-name glue-snowflake-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ConnectionString`].OutputValue' \
  --output text \
  --region us-east-1
```

### Update Connection String

1. **Update Secret:**
```bash
aws secretsmanager update-secret \
  --secret-id DataPipeline-dev-snowflake-credentials \
  --secret-string '{
    "account": "new_account.us-east-1",
    "user": "new_user",
    "password": "new_password",
    "warehouse": "NEW_WAREHOUSE",
    "database": "NEW_DATABASE",
    "schema": "NEW_SCHEMA"
  }' \
  --region us-east-1
```

2. **Update Stack:**
```bash
aws cloudformation update-stack \
  --stack-name glue-snowflake-dev \
  --template-body file://glue-snowflake-template.yaml \
  --parameters file://parameters-glue-snowflake-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Retrieve Credentials

```bash
# Get secret value
aws secretsmanager get-secret-value \
  --secret-id DataPipeline-dev-snowflake-credentials \
  --region us-east-1 \
  --query SecretString \
  --output text | jq .
```

## Running Glue Jobs

### Start Job

```bash
aws glue start-job-run \
  --job-name snowflake-etl-job-dev \
  --region us-east-1
```

### Start Job with Arguments

```bash
aws glue start-job-run \
  --job-name snowflake-etl-job-dev \
  --arguments '{
    "--connection_name": "snowflake-connection-dev",
    "--secret_id": "DataPipeline-dev-snowflake-credentials"
  }' \
  --region us-east-1
```

### Monitor Job

```bash
# Get job run status
aws glue get-job-run \
  --job-name snowflake-etl-job-dev \
  --run-id <run-id> \
  --region us-east-1

# List recent runs
aws glue get-job-runs \
  --job-name snowflake-etl-job-dev \
  --max-results 10 \
  --region us-east-1
```

## Common Use Cases

### Use Case 1: ETL from S3 to Snowflake

1. Upload data to S3
2. Create Glue job to read from S3
3. Transform data
4. Write to Snowflake

### Use Case 2: ETL from Snowflake to S3

1. Create Glue job to read from Snowflake
2. Transform data
3. Write to S3

### Use Case 3: Data Transformation in Snowflake

1. Read from Snowflake table
2. Transform using Spark
3. Write back to Snowflake

## Best Practices

1. **Security**
   - Never hardcode credentials
   - Use Secrets Manager
   - Rotate passwords regularly
   - Use least-privilege IAM

2. **Performance**
   - Right-size Glue workers
   - Use appropriate warehouse size
   - Optimize Spark queries
   - Use partitioning

3. **Cost Optimization**
   - Use appropriate worker types
   - Monitor job execution times
   - Clean up temporary files
   - Use spot instances for dev

4. **Monitoring**
   - Set up CloudWatch alarms
   - Monitor job success rates
   - Track execution times
   - Set up SNS notifications

## Resources

- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Snowflake JDBC Driver](https://docs.snowflake.com/en/user-guide/jdbc-using.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Glue Connection Types](https://docs.aws.amazon.com/glue/latest/dg/connection-using.html)

## Getting Help

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) first
2. Review AWS documentation
3. AWS Support: https://console.aws.amazon.com/support/
4. Snowflake Support: https://support.snowflake.com/
