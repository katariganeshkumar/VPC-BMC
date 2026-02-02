# AWS Glue & Snowflake Troubleshooting Guide

This guide helps troubleshoot common issues with AWS Glue and Snowflake integration.

## Common Issues

### Glue Connection Issues

#### Issue: Connection test fails

**Possible Causes:**
1. VPC configuration incorrect
2. Security group blocking traffic
3. NAT Gateway not working
4. Snowflake credentials incorrect

**Solutions:**
```bash
# Check Glue connection status
aws glue get-connection \
  --name snowflake-connection-dev \
  --region us-east-1

# Verify security group
aws ec2 describe-security-groups \
  --group-ids <security-group-id> \
  --region us-east-1

# Test NAT Gateway
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=<vpc-id>" \
  --region us-east-1
```

#### Issue: "Connection timeout"

**Troubleshooting:**
1. Verify VPC subnet configuration
2. Check security group allows HTTPS (443)
3. Verify NAT Gateway is running
4. Test Snowflake connectivity manually

```bash
# Check connection properties
aws glue get-connection \
  --name snowflake-connection-dev \
  --query 'Connection.ConnectionProperties' \
  --region us-east-1
```

### Secrets Manager Issues

#### Issue: "Secret not found"

**Solutions:**
```bash
# List secrets
aws secretsmanager list-secrets \
  --region us-east-1

# Get secret value
aws secretsmanager get-secret-value \
  --secret-id DataPipeline-dev-snowflake-credentials \
  --region us-east-1
```

#### Issue: "Access denied to secret"

**Solutions:**
1. Verify IAM role has Secrets Manager permissions
2. Check resource-based policy
3. Verify secret ARN matches

```bash
# Check IAM role policy
aws iam get-role-policy \
  --role-name DataPipeline-dev-Glue-ServiceRole \
  --policy-name SecretsManagerAccess \
  --region us-east-1
```

### Glue Job Execution Issues

#### Issue: Job fails immediately

**Possible Causes:**
1. Script location incorrect
2. S3 permissions issue
3. Connection name incorrect
4. Secret ID incorrect

**Solutions:**
```bash
# Check job definition
aws glue get-job \
  --job-name snowflake-etl-job-dev \
  --region us-east-1

# Verify script exists
aws s3 ls s3://your-bucket/glue-scripts/

# Check CloudWatch logs
aws logs tail /aws-glue/jobs/snowflake-etl-job-dev --follow
```

#### Issue: "Cannot connect to Snowflake"

**Troubleshooting:**
1. Verify credentials in Secrets Manager
2. Test Snowflake connection manually
3. Check Snowflake network policies
4. Verify warehouse is running

```bash
# Get secret value
aws secretsmanager get-secret-value \
  --secret-id DataPipeline-dev-snowflake-credentials \
  --region us-east-1 \
  --query SecretString \
  --output text | jq .
```

#### Issue: Job runs but produces no output

**Troubleshooting:**
1. Check CloudWatch logs
2. Verify table names are correct
3. Check data exists in source
4. Verify write permissions

```bash
# View logs
aws logs tail /aws-glue/jobs/snowflake-etl-job-dev --follow

# Check job run details
aws glue get-job-run \
  --job-name snowflake-etl-job-dev \
  --run-id <run-id> \
  --region us-east-1
```

### S3 Access Issues

#### Issue: "Access denied to S3"

**Solutions:**
```bash
# Check IAM role S3 permissions
aws iam get-role-policy \
  --role-name DataPipeline-dev-Glue-ServiceRole \
  --policy-name S3Access \
  --region us-east-1

# Verify bucket policy
aws s3api get-bucket-policy \
  --bucket your-bucket
```

### Snowflake Connection String Issues

#### Issue: "Invalid connection string"

**Troubleshooting:**
1. Verify account format: `xy12345.us-east-1`
2. Check JDBC URL format
3. Verify parameters are correct

**Correct Format:**
```
jdbc:snowflake://{account}.snowflakecomputing.com/?warehouse={warehouse}&db={database}&schema={schema}
```

#### Issue: "Warehouse not found"

**Solutions:**
1. Verify warehouse name in Snowflake
2. Check warehouse is running
3. Verify user has access to warehouse

## Diagnostic Commands

### Check Glue Connection
```bash
aws glue get-connection \
  --name snowflake-connection-dev \
  --region us-east-1 \
  --query 'Connection.[Name,ConnectionType,ConnectionProperties]'
```

### Test Connection
```bash
aws glue test-connection \
  --name snowflake-connection-dev \
  --region us-east-1
```

### Check Job Status
```bash
aws glue get-job-runs \
  --job-name snowflake-etl-job-dev \
  --max-results 5 \
  --region us-east-1 \
  --query 'JobRuns[*].[Id,JobRunState,StartedOn,CompletedOn]' \
  --output table
```

### View CloudWatch Logs
```bash
# List log streams
aws logs describe-log-streams \
  --log-group-name /aws-glue/jobs/snowflake-etl-job-dev \
  --region us-east-1

# View logs
aws logs tail /aws-glue/jobs/snowflake-etl-job-dev --follow
```

### Check Secrets Manager
```bash
# List secrets
aws secretsmanager list-secrets \
  --filters Key=name,Values=DataPipeline \
  --region us-east-1

# Get secret metadata
aws secretsmanager describe-secret \
  --secret-id DataPipeline-dev-snowflake-credentials \
  --region us-east-1
```

## Common Error Messages

### "ConnectionNotFound"
- **Cause**: Glue connection doesn't exist
- **Solution**: Verify connection name and create if needed

### "SecretNotFound"
- **Cause**: Secrets Manager secret doesn't exist
- **Solution**: Verify secret name and create if needed

### "AccessDenied"
- **Cause**: IAM permissions insufficient
- **Solution**: Check IAM role policies

### "InvalidConnectionProperties"
- **Cause**: Connection properties incorrect
- **Solution**: Verify JDBC URL and parameters

### "JobRunFailed"
- **Cause**: Job execution error
- **Solution**: Check CloudWatch logs for details

## Prevention Tips

1. **Test Connection First**
   - Use `test-connection` command
   - Verify before running jobs

2. **Validate Credentials**
   - Test Snowflake connection manually
   - Verify all parameters

3. **Monitor Logs**
   - Set up CloudWatch alarms
   - Review logs regularly

4. **Use Secrets Manager**
   - Never hardcode credentials
   - Rotate passwords regularly

5. **Test Incrementally**
   - Start with simple queries
   - Gradually increase complexity

## Getting Help

### AWS Support
- AWS Support Center: https://console.aws.amazon.com/support/
- Glue Documentation: https://docs.aws.amazon.com/glue/

### Snowflake Support
- Snowflake Support: https://support.snowflake.com/
- Snowflake Documentation: https://docs.snowflake.com/

### Useful Resources
- [Glue Connection Troubleshooting](https://docs.aws.amazon.com/glue/latest/dg/connection-using.html)
- [Snowflake JDBC Driver](https://docs.snowflake.com/en/user-guide/jdbc-using.html)
- [Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)
