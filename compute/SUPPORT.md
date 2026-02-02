# Compute Support Guide

This guide provides support information and resources for EC2 and Auto Scaling Group deployment.

## Quick Start Checklist

Before deploying compute resources, ensure:

- [ ] VPC stack is deployed and outputs are available
- [ ] AWS CLI installed and configured
- [ ] Appropriate IAM permissions
- [ ] AMI ID selected for your region
- [ ] Instance type selected
- [ ] Scaling parameters configured
- [ ] Health check type decided (EC2 or ELB)

## Pre-Deployment Checklist

### 1. Verify VPC Stack Exists
```bash
# Check VPC stack status
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

### 2. Verify IAM Permissions

Required permissions:
- `ec2:RunInstances`
- `ec2:CreateLaunchTemplate`
- `autoscaling:CreateAutoScalingGroup`
- `autoscaling:CreateScalingPolicy`
- `iam:CreateRole`
- `iam:CreateInstanceProfile`
- `cloudwatch:PutMetricAlarm`
- `cloudformation:*`

### 3. Select AMI ID

```bash
# List Amazon Linux 2 AMIs
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*" \
           "Name=architecture,Values=x86_64" \
           "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].[ImageId,Name,CreationDate]' \
  --output table \
  --region us-east-1
```

### 4. Verify Instance Type Availability
```bash
# Check available instance types in region
aws ec2 describe-instance-type-offerings \
  --location-type availability-zone \
  --filters "Name=instance-type,Values=t3.micro" \
  --region us-east-1
```

## Deployment Support

### Step-by-Step Auto Scaling Deployment

1. **Navigate to compute folder**
   ```bash
   cd compute
   ```

2. **Review parameters**
   ```bash
   cat parameters-autoscaling-dev.json
   ```

3. **Update VpcStackName if needed**
   ```bash
   # Edit parameter file
   # Set VpcStackName to match your VPC stack name
   ```

4. **Deploy Auto Scaling Group**
   ```bash
   aws cloudformation create-stack \
     --stack-name autoscaling-dev \
     --template-body file://autoscaling-ec2-template.yaml \
     --parameters file://parameters-autoscaling-dev.json \
     --capabilities CAPABILITY_NAMED_IAM \
     --region us-east-1
   ```

5. **Monitor deployment**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name autoscaling-dev \
     --region us-east-1 \
     --query 'Stacks[0].StackStatus'
   ```

6. **Verify instances launching**
   ```bash
   aws autoscaling describe-auto-scaling-groups \
     --auto-scaling-group-names <asg-name> \
     --region us-east-1
   ```

## Common Use Cases

### Use Case 1: Development Environment
- **Instance Type**: t3.micro
- **Scaling**: 1-3 instances
- **Health Check**: EC2
- **Monitoring**: Basic

```bash
aws cloudformation create-stack \
  --stack-name autoscaling-dev \
  --template-body file://autoscaling-ec2-template.yaml \
  --parameters file://parameters-autoscaling-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Use Case 2: Production Environment
- **Instance Type**: t3.medium+
- **Scaling**: 2-10 instances
- **Health Check**: ELB (requires ALB)
- **Monitoring**: Detailed

```bash
aws cloudformation create-stack \
  --stack-name autoscaling-prod \
  --template-body file://autoscaling-ec2-template.yaml \
  --parameters file://parameters-autoscaling-prod.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Use Case 3: Custom Configuration
1. Copy parameter file: `cp parameters-autoscaling-dev.json parameters-custom.json`
2. Edit `parameters-custom.json` with your values
3. Deploy with custom parameters

## Parameter Reference

### Required Parameters
- `VpcStackName` - Name of the VPC CloudFormation stack
- `Environment` - Environment name (dev/staging/prod)
- `ApplicationName` - Application name for resource naming
- `InstanceType` - EC2 instance type
- `MinSize` - Minimum number of instances
- `MaxSize` - Maximum number of instances
- `DesiredCapacity` - Desired number of instances

### Optional Parameters
- `HealthCheckType` - EC2 or ELB (default: ELB)
- `HealthCheckGracePeriod` - Grace period in seconds (default: 300)
- `TargetTrackingScalingPolicyCPU` - CPU threshold (default: 70)
- `SubnetDeployment` - public or private (default: private)
- `AMIId` - Custom AMI ID (optional)
- `EnableDetailedMonitoring` - true/false (default: true)

## Output Reference

After deployment, the stack exports:

- `AutoScalingGroupName` - Use this to manage the ASG
- `AutoScalingGroupARN` - ASG ARN
- `LaunchTemplateId` - Launch Template ID
- `SecurityGroupId` - Security Group ID
- `TargetGroupARN` - Target Group ARN (if ELB health check)
- `EC2InstanceProfileARN` - For attaching to instances

## Connecting to Instances

### Via SSM Session Manager (Recommended)

```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output table \
  --region us-east-1

# Connect to instance
aws ssm start-session \
  --target <instance-id> \
  --region us-east-1
```

### Via SSH (if configured)

```bash
# Get instance public IP
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --region us-east-1

# SSH to instance
ssh -i <key-file.pem> ec2-user@<public-ip>
```

## Monitoring and Scaling

### View Auto Scaling Activity
```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name <asg-name> \
  --max-records 10 \
  --region us-east-1
```

### Check Current Capacity
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names <asg-name> \
  --query 'AutoScalingGroups[0].[MinSize,DesiredCapacity,MaxSize,Instances | length(@)]' \
  --output table \
  --region us-east-1
```

### View CloudWatch Metrics
```bash
# CPU Utilization
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

### Manual Scaling
```bash
# Set desired capacity
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name <asg-name> \
  --desired-capacity 5 \
  --region us-east-1

# Suspend scaling processes
aws autoscaling suspend-processes \
  --auto-scaling-group-name <asg-name> \
  --scaling-processes AlarmNotification \
  --region us-east-1
```

## Best Practices

1. **Instance Configuration**
   - Use Launch Templates for version control
   - Enable detailed monitoring for production
   - Use SSM Session Manager for access

2. **Scaling Configuration**
   - Set appropriate min/max sizes
   - Configure cooldown periods
   - Use target tracking for automatic scaling

3. **Health Checks**
   - Use EC2 checks for simple applications
   - Use ELB checks for web applications
   - Configure appropriate grace periods

4. **Security**
   - Deploy in private subnets
   - Use security groups with least privilege
   - Enable VPC Flow Logs

5. **Cost Management**
   - Right-size instances based on metrics
   - Use Reserved Instances for predictable workloads
   - Monitor and optimize scaling policies

## Integration with Application Load Balancer

### Prerequisites
- ALB deployed in public subnet
- Target Group created
- Health check type set to ELB

### Attach ASG to Target Group
```bash
# Update ASG to use target group
aws autoscaling attach-load-balancer-target-groups \
  --auto-scaling-group-name <asg-name> \
  --target-group-arns <target-group-arn> \
  --region us-east-1
```

## Resources

### AWS Documentation
- [EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [Auto Scaling User Guide](https://docs.aws.amazon.com/autoscaling/)
- [CloudWatch User Guide](https://docs.aws.amazon.com/cloudwatch/)
- [SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

### AWS CLI Reference
- [EC2 Commands](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)
- [Auto Scaling Commands](https://docs.aws.amazon.com/cli/latest/reference/autoscaling/index.html)
- [CloudWatch Commands](https://docs.aws.amazon.com/cli/latest/reference/cloudwatch/index.html)

## FAQ

### Q: How do I update the Launch Template?
A: Create a new version and update the Auto Scaling Group to use it.

### Q: Can I change instance types without downtime?
A: Yes, update the Launch Template and instances will be replaced gradually.

### Q: How do I scale manually?
A: Use `set-desired-capacity` command or update the parameter and redeploy.

### Q: What's the difference between EC2 and ELB health checks?
A: EC2 checks instance status, ELB checks application health via HTTP/HTTPS.

### Q: How do I enable detailed monitoring?
A: Set `EnableDetailedMonitoring` parameter to `true` in the template.

## Getting Additional Help

### AWS Support
- AWS Support Center: https://console.aws.amazon.com/support/
- EC2 Documentation: https://docs.aws.amazon.com/ec2/
- Auto Scaling Documentation: https://docs.aws.amazon.com/autoscaling/

### Support Channels
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) first
2. Review AWS documentation
3. AWS Forums: https://forums.aws.amazon.com/
4. AWS Support: https://console.aws.amazon.com/support/

## Version History

- **v1.0** - Initial release with Auto Scaling Group and Launch Template
- **v1.1** - Added SSM Session Manager support
- **v1.2** - Added environment-specific configurations
- **v1.3** - Added Target Group support for ALB integration
