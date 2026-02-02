# Compute Troubleshooting Guide

This guide helps you troubleshoot common issues when deploying and managing EC2 instances and Auto Scaling Groups.

## Common Issues and Solutions

### Auto Scaling Group Issues

#### Issue: Auto Scaling Group fails to launch instances

**Possible Causes:**
1. Launch Template issues
2. Insufficient capacity in Availability Zones
3. Security group or subnet configuration issues
4. IAM role/permissions issues

**Solutions:**
```bash
# Check Auto Scaling Group activity
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name> \
  --region us-east-1

# Check failed activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name> \
  --region us-east-1 \
  --query 'Activities[?StatusCode==`Failed`]'

# Verify Launch Template
aws ec2 describe-launch-template-versions \
  --launch-template-id <launch-template-id> \
  --region us-east-1
```

#### Issue: Instances terminate immediately after launch

**Possible Causes:**
1. Health check failures
2. User data script errors
3. Security group blocking required traffic

**Troubleshooting Steps:**
```bash
# Check instance status
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].[State.Name,StateTransitionReason]' \
  --region us-east-1

# Check CloudWatch logs for user data errors
aws logs tail /var/log/cloud-init-output.log --follow

# Verify health check configuration
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name> \
  --query 'AutoScalingGroups[0].[HealthCheckType,HealthCheckGracePeriod]' \
  --region us-east-1
```

#### Issue: Auto Scaling Group not scaling

**Possible Causes:**
1. Scaling policies not configured
2. CloudWatch alarms not triggering
3. Cooldown period active
4. Min/Max size limits reached

**Solutions:**
```bash
# Check scaling policies
aws autoscaling describe-policies \
  --auto-scaling-group-name <asg-name> \
  --region us-east-1

# Check CloudWatch alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix <asg-name> \
  --region us-east-1

# Check current capacity
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name> \
  --query 'AutoScalingGroups[0].[MinSize,DesiredCapacity,MaxSize]' \
  --region us-east-1
```

### Launch Template Issues

#### Issue: Launch Template creation fails

**Possible Causes:**
1. Invalid AMI ID
2. Invalid instance type
3. IAM role doesn't exist
4. Security group doesn't exist

**Solutions:**
```bash
# Verify AMI exists
aws ec2 describe-images \
  --image-ids <ami-id> \
  --region us-east-1

# Verify instance type is available
aws ec2 describe-instance-type-offerings \
  --location-type availability-zone \
  --filters "Name=instance-type,Values=t3.micro" \
  --region us-east-1

# Check IAM role exists
aws iam get-role --role-name <role-name>
```

#### Issue: Instances launch with wrong configuration

**Troubleshooting Steps:**
1. Verify Launch Template version:
```bash
aws ec2 describe-launch-template-versions \
  --launch-template-id <launch-template-id> \
  --versions '$Latest' \
  --region us-east-1
```

2. Check Auto Scaling Group uses correct version:
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name> \
  --query 'AutoScalingGroups[0].LaunchTemplate' \
  --region us-east-1
```

### Instance Connection Issues

#### Issue: Cannot connect via SSM Session Manager

**Possible Causes:**
1. SSM agent not installed/running
2. IAM role not attached
3. Security group blocking traffic
4. VPC endpoints not configured

**Solutions:**
```bash
# Check SSM agent status (on instance)
sudo systemctl status amazon-ssm-agent

# Verify IAM role attached
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].IamInstanceProfile' \
  --region us-east-1

# Check SSM agent logs
sudo tail -f /var/log/amazon/ssm/amazon-ssm-agent.log

# Test SSM connectivity
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=<instance-id>" \
  --region us-east-1
```

#### Issue: Cannot SSH to instance

**Troubleshooting Steps:**
1. Verify security group allows SSH (port 22)
2. Check key pair is correct
3. Verify instance is in public subnet (if using public IP)
4. Check route table configuration

```bash
# Check security group rules
aws ec2 describe-security-groups \
  --group-ids <security-group-id> \
  --query 'SecurityGroups[0].IpPermissions' \
  --region us-east-1

# Verify key pair
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].KeyName' \
  --region us-east-1
```

### Health Check Issues

#### Issue: Instances failing health checks

**EC2 Health Checks:**
```bash
# Check instance status checks
aws ec2 describe-instance-status \
  --instance-ids <instance-id> \
  --region us-east-1

# Check system status
aws ec2 describe-instance-status \
  --instance-ids <instance-id> \
  --query 'InstanceStatuses[0].SystemStatus' \
  --region us-east-1

# Check instance status
aws ec2 describe-instance-status \
  --instance-ids <instance-id> \
  --query 'InstanceStatuses[0].InstanceStatus' \
  --region us-east-1
```

**ELB Health Checks:**
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region us-east-1

# Check target group configuration
aws elbv2 describe-target-groups \
  --target-group-arns <target-group-arn> \
  --query 'TargetGroups[0].[HealthCheckProtocol,HealthCheckPath,HealthCheckIntervalSeconds]' \
  --region us-east-1
```

### Scaling Policy Issues

#### Issue: Scaling policies not working

**Troubleshooting Steps:**
1. Verify scaling policy exists:
```bash
aws autoscaling describe-policies \
  --auto-scaling-group-name <asg-name> \
  --region us-east-1
```

2. Check CloudWatch metrics:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=<asg-name> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region us-east-1
```

3. Check alarm state:
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix <asg-name> \
  --region us-east-1
```

### CloudWatch Monitoring Issues

#### Issue: Metrics not appearing in CloudWatch

**Solutions:**
```bash
# Verify detailed monitoring is enabled
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].Monitoring.State' \
  --region us-east-1

# Check CloudWatch agent status (if installed)
sudo systemctl status amazon-cloudwatch-agent

# Verify IAM permissions for CloudWatch
aws iam get-role-policy \
  --role-name <role-name> \
  --policy-name CloudWatchAgentServerPolicy
```

### Cost Issues

#### Issue: Unexpected costs

**Troubleshooting Steps:**
1. Check instance types and counts:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' \
  --output table \
  --region us-east-1
```

2. Review Auto Scaling Group activity:
```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name> \
  --max-records 50 \
  --region us-east-1
```

3. Check CloudWatch costs:
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

## Diagnostic Commands

### Check Auto Scaling Group Status
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name> \
  --query 'AutoScalingGroups[0].[AutoScalingGroupName,MinSize,DesiredCapacity,MaxSize,HealthCheckType,Status]' \
  --output table \
  --region us-east-1
```

### List All Instances in ASG
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name> \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus]' \
  --output table \
  --region us-east-1
```

### Check Launch Template
```bash
aws ec2 describe-launch-template-versions \
  --launch-template-id <launch-template-id> \
  --versions '$Latest' \
  --query 'LaunchTemplateVersions[0].LaunchTemplateData' \
  --region us-east-1
```

### View CloudWatch Logs
```bash
# List log groups
aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2 \
  --region us-east-1

# View recent log events
aws logs tail /aws/ec2/<log-group-name> --follow --region us-east-1
```

## Common Error Messages

### "InsufficientInstanceCapacity"
- **Cause**: Not enough capacity in selected Availability Zones
- **Solution**: Try different AZs or instance types

### "InvalidParameterValue"
- **Cause**: Invalid parameter in Launch Template or ASG
- **Solution**: Verify all parameters are correct

### "ResourceLimitExceeded"
- **Cause**: Account limits reached
- **Solution**: Request limit increase or delete unused resources

### "InvalidAMIID.NotFound"
- **Cause**: AMI doesn't exist in the region
- **Solution**: Use correct AMI ID for the region

### "InvalidGroup.NotFound"
- **Cause**: Security group doesn't exist
- **Solution**: Verify security group ID and VPC

## Prevention Tips

1. **Test Launch Templates** before deploying to ASG
2. **Monitor CloudWatch metrics** regularly
3. **Set appropriate scaling policies** based on workload
4. **Use health checks** appropriate for your application
5. **Review costs** regularly
6. **Keep documentation updated**

## Getting Help

### AWS Support
- AWS Support Center: https://console.aws.amazon.com/support/
- EC2 Documentation: https://docs.aws.amazon.com/ec2/
- Auto Scaling Documentation: https://docs.aws.amazon.com/autoscaling/

### Useful Resources
- CloudWatch Logs Insights: https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:logs-insights
- EC2 Instance Connect: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances:
