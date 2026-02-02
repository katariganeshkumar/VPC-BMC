# VPC Troubleshooting Guide

This guide helps you troubleshoot common issues when deploying and managing VPC infrastructure.

## Common Issues and Solutions

### Stack Creation Fails

#### Issue: Stack creation fails with "Resource creation failed"

**Possible Causes:**
1. CIDR blocks overlap with existing VPCs
2. Insufficient IAM permissions
3. Resource limits exceeded
4. Invalid parameter values

**Solutions:**
```bash
# Check CloudFormation events for detailed error
aws cloudformation describe-stack-events \
  --stack-name vpc-1 \
  --region us-east-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Verify CIDR blocks don't overlap
aws ec2 describe-vpcs \
  --filters "Name=cidr-block-association.cidr-block,Values=10.0.0.0/16" \
  --region us-east-1

# Check IAM permissions
aws sts get-caller-identity
```

#### Issue: "Subnet CIDR conflicts with existing subnet"

**Solution:**
- Verify subnet CIDR blocks don't overlap
- Check existing subnets in the VPC
- Update parameter files with unique CIDR blocks

```bash
# List existing subnets
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=<vpc-id>" \
  --query 'Subnets[*].[SubnetId,CidrBlock]' \
  --output table
```

### NAT Gateway Issues

#### Issue: NAT Gateway creation fails

**Possible Causes:**
1. Elastic IP limit exceeded
2. Insufficient permissions
3. Public subnet doesn't exist

**Solutions:**
```bash
# Check Elastic IP limit
aws ec2 describe-addresses --region us-east-1

# Verify public subnet exists
aws ec2 describe-subnets \
  --filters "Name=tag:Type,Values=Public" \
  --region us-east-1
```

#### Issue: Instances in private subnet cannot access internet

**Troubleshooting Steps:**
1. Verify NAT Gateway is running:
```bash
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=<vpc-id>" \
  --region us-east-1
```

2. Check route table associations:
```bash
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=<vpc-id>" \
  --region us-east-1
```

3. Verify private subnet route table has NAT Gateway route:
```bash
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=<private-subnet-id>" \
  --query 'RouteTables[0].Routes' \
  --region us-east-1
```

### Internet Gateway Issues

#### Issue: Instances in public subnet cannot access internet

**Troubleshooting Steps:**
1. Verify Internet Gateway is attached:
```bash
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=<vpc-id>" \
  --region us-east-1
```

2. Check public route table:
```bash
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=<public-subnet-id>" \
  --query 'RouteTables[0].Routes' \
  --region us-east-1
```

3. Verify route to 0.0.0.0/0 points to IGW

### Security Group Issues

#### Issue: Cannot connect to instances

**Troubleshooting Steps:**
1. Check security group rules:
```bash
aws ec2 describe-security-groups \
  --group-ids <security-group-id> \
  --region us-east-1
```

2. Verify security group is attached:
```bash
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].SecurityGroups' \
  --region us-east-1
```

3. Test connectivity:
```bash
# For SSH (port 22)
nc -zv <instance-ip> 22

# For HTTP (port 80)
curl -I http://<instance-ip>
```

### Route Table Issues

#### Issue: Subnet not routing correctly

**Troubleshooting Steps:**
1. Verify route table association:
```bash
aws ec2 describe-route-tables \
  --filters "Name=association.subnet-id,Values=<subnet-id>" \
  --region us-east-1
```

2. Check routes:
```bash
aws ec2 describe-route-tables \
  --route-table-ids <route-table-id> \
  --query 'RouteTables[0].Routes' \
  --region us-east-1
```

3. Verify default route (0.0.0.0/0) exists and points to correct gateway

### DNS Issues

#### Issue: DNS resolution not working

**Troubleshooting Steps:**
1. Verify DNS settings:
```bash
aws ec2 describe-vpcs \
  --vpc-ids <vpc-id> \
  --query 'Vpcs[0].[EnableDnsHostnames,EnableDnsSupport]' \
  --region us-east-1
```

2. Both should be `true` for DNS to work properly

3. Check DNS server configuration:
```bash
# On EC2 instance
cat /etc/resolv.conf
```

## Diagnostic Commands

### Check VPC Status
```bash
# Get VPC details
aws ec2 describe-vpcs \
  --vpc-ids <vpc-id> \
  --region us-east-1

# List all resources in VPC
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=<vpc-id>" \
  --region us-east-1
```

### Check Subnet Status
```bash
# List all subnets
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=<vpc-id>" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \
  --output table \
  --region us-east-1
```

### Check NAT Gateway Status
```bash
# Get NAT Gateway details
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=<vpc-id>" \
  --query 'NatGateways[*].[NatGatewayId,State,SubnetId]' \
  --output table \
  --region us-east-1
```

### Check Internet Gateway Status
```bash
# Get Internet Gateway details
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=<vpc-id>" \
  --query 'InternetGateways[*].[InternetGatewayId,Attachments[0].State]' \
  --output table \
  --region us-east-1
```

## CloudFormation Stack Issues

### View Stack Events
```bash
aws cloudformation describe-stack-events \
  --stack-name vpc-1 \
  --region us-east-1 \
  --query 'StackEvents[*].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
  --output table
```

### Check Stack Status
```bash
aws cloudformation describe-stacks \
  --stack-name vpc-1 \
  --region us-east-1 \
  --query 'Stacks[0].[StackName,StackStatus,StackStatusReason]' \
  --output table
```

### Get Stack Outputs
```bash
aws cloudformation describe-stacks \
  --stack-name vpc-1 \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
  --output table
```

## Common Error Messages

### "VpcLimitExceeded"
- **Cause**: You've reached the VPC limit for your account
- **Solution**: Delete unused VPCs or request limit increase

### "SubnetLimitExceeded"
- **Cause**: Too many subnets in the region
- **Solution**: Delete unused subnets or request limit increase

### "NatGatewayLimitExceeded"
- **Cause**: NAT Gateway limit reached
- **Solution**: Delete unused NAT Gateways or request limit increase

### "InvalidParameterValue"
- **Cause**: Invalid CIDR block or parameter value
- **Solution**: Verify CIDR format and ensure it's valid

### "ResourceAlreadyExists"
- **Cause**: Resource with same name/tag already exists
- **Solution**: Use different name or delete existing resource

## Getting Help

### AWS Support
- AWS Support Center: https://console.aws.amazon.com/support/
- AWS Documentation: https://docs.aws.amazon.com/vpc/

### CloudFormation Documentation
- CloudFormation User Guide: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/

### Useful AWS CLI Commands
```bash
# Enable debug logging
export AWS_CLI_LOG_LEVEL=DEBUG

# Check AWS CLI version
aws --version

# Verify credentials
aws sts get-caller-identity
```

## Prevention Tips

1. **Always validate parameters** before deployment
2. **Check resource limits** before creating resources
3. **Use unique CIDR blocks** to avoid conflicts
4. **Test in dev environment** before production
5. **Monitor CloudFormation events** during deployment
6. **Keep documentation updated** with changes

## Quick Reference

### Delete Stack (Cleanup)
```bash
aws cloudformation delete-stack \
  --stack-name vpc-1 \
  --region us-east-1

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
  --stack-name vpc-1 \
  --region us-east-1
```

### Export Stack Outputs
```bash
# Save outputs to file
aws cloudformation describe-stacks \
  --stack-name vpc-1 \
  --region us-east-1 \
  --query 'Stacks[0].Outputs' > vpc-outputs.json
```
