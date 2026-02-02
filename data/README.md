# AWS Glue and Snowflake Integration

This folder contains CloudFormation templates for integrating AWS Glue with Snowflake, including secure connection string management.

## Overview

This solution provides:
- **AWS Glue Connection** - Secure connection to Snowflake using JDBC
- **Secrets Manager Integration** - Secure storage of Snowflake credentials
- **Glue ETL Jobs** - Sample jobs for data transformation
- **IAM Roles** - Proper permissions for Glue to access Snowflake and S3
- **VPC Integration** - Glue connections through VPC private subnets

## Architecture

```
┌─────────────┐
│   Snowflake │
│   Database  │
└──────┬──────┘
       │ JDBC Connection
       │ (via VPC)
┌──────▼──────────────────┐
│  AWS Glue Connection     │
│  (in VPC Private Subnet)│
└──────┬──────────────────┘
       │
┌──────▼──────────────────┐
│  AWS Glue ETL Job       │
│  (Spark/Python)         │
└──────┬──────────────────┘
       │
┌──────▼──────┐
│     S3      │
│  (Output)   │
└─────────────┘
```

## Prerequisites

1. **VPC Stack Deployed** - The VPC stack must be deployed first
2. **Snowflake Account** - Active Snowflake account with:
   - Warehouse created
   - Database and schema created
   - User credentials
3. **S3 Bucket** - For Glue scripts and temporary files
4. **IAM Permissions** - To create Glue, Secrets Manager, and IAM resources

## Files

- **glue-snowflake-template.yaml** - Main CloudFormation template
- **parameters-glue-snowflake-dev.json** - Development environment parameters
- **parameters-glue-snowflake-prod.json** - Production environment parameters
- **glue-job-template.py** - Sample Glue ETL job script

## Deployment

### Step 1: Prepare S3 Bucket

```bash
# Create S3 bucket for Glue scripts
aws s3 mb s3://your-glue-scripts-bucket --region us-east-1

# Upload Glue job script
aws s3 cp glue-job-template.py s3://your-glue-scripts-bucket/glue-scripts/
```

### Step 2: Update Parameters

Edit the parameter file with your Snowflake credentials:

```json
{
  "ParameterKey": "SnowflakeAccount",
  "ParameterValue": "xy12345.us-east-1"
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
  "ParameterValue": "s3://your-glue-scripts-bucket/glue-scripts/snowflake-etl.py"
}
```

### Step 3: Deploy Stack

**Development:**
```bash
cd data
aws cloudformation create-stack \
  --stack-name glue-snowflake-dev \
  --template-body file://glue-snowflake-template.yaml \
  --parameters file://parameters-glue-snowflake-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Production:**
```bash
aws cloudformation create-stack \
  --stack-name glue-snowflake-prod \
  --template-body file://glue-snowflake-template.yaml \
  --parameters file://parameters-glue-snowflake-prod.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

## Connection String Configuration

### Snowflake JDBC Connection String

The template automatically generates the JDBC connection string:

```
jdbc:snowflake://{account}.snowflakecomputing.com/?warehouse={warehouse}&db={database}&schema={schema}
```

### Using Connection String in Glue Jobs

The connection string is configured in the Glue connection and can be referenced in your Glue jobs:

```python
# In your Glue job script
connection_name = args['connection_name']
secret_id = args['secret_id']

# Get credentials from Secrets Manager
secrets_client = boto3.client('secretsmanager')
secret_response = secrets_client.get_secret_value(SecretId=secret_id)
snowflake_creds = json.loads(secret_response['SecretString'])

# Build connection options
snowflake_options = {
    "sfURL": f"{snowflake_creds['account']}.snowflakecomputing.com",
    "sfUser": snowflake_creds['user'],
    "sfPassword": snowflake_creds['password'],
    "sfDatabase": snowflake_creds['database'],
    "sfSchema": snowflake_creds['schema'],
    "sfWarehouse": snowflake_creds['warehouse']
}
```

## Security

### Secrets Manager

Snowflake credentials are stored securely in AWS Secrets Manager:
- Encrypted at rest using AWS KMS
- Access controlled via IAM policies
- Automatically rotated (if configured)

### VPC Integration

- Glue connections use VPC private subnets
- Security groups control outbound traffic
- NAT Gateway provides internet access for Snowflake connection

### IAM Permissions

The Glue service role has:
- Access to Secrets Manager (read-only)
- S3 access for scripts and data
- CloudWatch Logs access
- Glue service permissions

## Running Glue Jobs

### Start Job via AWS CLI

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

### Monitor Job Execution

```bash
# Get job run status
aws glue get-job-run \
  --job-name snowflake-etl-job-dev \
  --run-id <run-id> \
  --region us-east-1

# List recent job runs
aws glue get-job-runs \
  --job-name snowflake-etl-job-dev \
  --max-results 10 \
  --region us-east-1
```

## Connection String Management

### Update Connection String

To update Snowflake connection parameters:

1. Update the secret in Secrets Manager:
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

2. Update Glue connection:
```bash
aws cloudformation update-stack \
  --stack-name glue-snowflake-dev \
  --template-body file://glue-snowflake-template.yaml \
  --parameters file://parameters-glue-snowflake-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Retrieve Connection String

```bash
# Get connection string from stack outputs
aws cloudformation describe-stacks \
  --stack-name glue-snowflake-dev \
  --query 'Stacks[0].Outputs[?OutputKey==`ConnectionString`].OutputValue' \
  --output text \
  --region us-east-1

# Get credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id DataPipeline-dev-snowflake-credentials \
  --region us-east-1 \
  --query SecretString \
  --output text
```

## Parameters Reference

| Parameter | Description | Example |
|-----------|-------------|---------|
| `SnowflakeAccount` | Snowflake account identifier | `xy12345.us-east-1` |
| `SnowflakeUser` | Snowflake username | `admin` |
| `SnowflakePassword` | Snowflake password | `password123` |
| `SnowflakeWarehouse` | Warehouse name | `COMPUTE_WH` |
| `SnowflakeDatabase` | Database name | `MY_DATABASE` |
| `SnowflakeSchema` | Schema name | `PUBLIC` |
| `GlueConnectionName` | Glue connection name | `snowflake-connection` |
| `GlueJobScriptLocation` | S3 path to job script | `s3://bucket/scripts/job.py` |
| `GlueWorkerType` | Worker type (G.1X, G.2X, G.4X) | `G.1X` |
| `GlueNumberOfWorkers` | Number of workers | `2` |

## Outputs

The stack exports:
- `GlueConnectionName` - Glue connection name
- `GlueConnectionArn` - Connection ARN
- `GlueServiceRoleArn` - Service role ARN
- `SnowflakeSecretArn` - Secrets Manager secret ARN
- `ConnectionString` - JDBC connection string (without credentials)
- `GlueJobName` - ETL job name (if created)

## Troubleshooting

### Connection Issues

1. **Verify VPC Configuration**
   - Ensure Glue connection uses private subnet
   - Check security group allows outbound HTTPS (443)
   - Verify NAT Gateway is running

2. **Check Secrets Manager**
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id DataPipeline-dev-snowflake-credentials \
     --region us-east-1
   ```

3. **Test Snowflake Connection**
   - Verify credentials manually
   - Check Snowflake network policies
   - Verify warehouse is running

### Job Execution Issues

1. **Check CloudWatch Logs**
   ```bash
   aws logs tail /aws-glue/jobs/snowflake-etl-job-dev --follow
   ```

2. **Verify S3 Permissions**
   - Check Glue service role has S3 access
   - Verify bucket policies

3. **Check Job Arguments**
   - Verify connection_name matches
   - Verify secret_id is correct

## Best Practices

1. **Security**
   - Never hardcode credentials in scripts
   - Use Secrets Manager for all credentials
   - Rotate passwords regularly
   - Use least-privilege IAM policies

2. **Performance**
   - Right-size Glue workers based on workload
   - Use appropriate warehouse size in Snowflake
   - Optimize Spark queries

3. **Cost Optimization**
   - Use appropriate worker types
   - Monitor job execution times
   - Clean up temporary files in S3

4. **Monitoring**
   - Set up CloudWatch alarms
   - Monitor job success rates
   - Track execution times

## Next Steps

1. **Customize Glue Job Script** - Modify `glue-job-template.py` for your use case
2. **Add More Data Sources** - Extend template for additional sources
3. **Set Up Scheduling** - Use EventBridge to schedule jobs
4. **Add Monitoring** - Set up CloudWatch dashboards
5. **Implement Error Handling** - Add retry logic and error notifications

## Resources

- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Snowflake JDBC Driver](https://docs.snowflake.com/en/user-guide/jdbc-using.html)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [Glue Connection Types](https://docs.aws.amazon.com/glue/latest/dg/connection-using.html)
