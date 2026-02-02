# Compute Infrastructure Templates

This folder contains CloudFormation templates for EC2 instances and Auto Scaling Groups.

## Files

- **autoscaling-ec2-template.yaml** - Auto Scaling Group template with Launch Template
- **ec2-instance-template.yaml** - Single EC2 instance template
- **parameters-autoscaling-dev.json** - Dev environment parameters
- **parameters-autoscaling-staging.json** - Staging environment parameters
- **parameters-autoscaling-prod.json** - Production environment parameters

## Prerequisites

Before deploying compute resources, ensure the VPC stack is deployed:
- See `../vpc/README.md` for VPC deployment instructions

## Auto Scaling Group Template

### Features

- Launch Template with versioning
- Auto Scaling Group with CPU-based scaling
- Multi-AZ deployment (spans both private subnets)
- CloudWatch alarms and monitoring
- SSM Session Manager integration
- Target Group for ALB integration (optional)
- Environment-specific configurations

### Deployment

**Development Environment:**
```bash
aws cloudformation create-stack \
  --stack-name autoscaling-dev \
  --template-body file://autoscaling-ec2-template.yaml \
  --parameters file://parameters-autoscaling-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Staging Environment:**
```bash
aws cloudformation create-stack \
  --stack-name autoscaling-staging \
  --template-body file://autoscaling-ec2-template.yaml \
  --parameters file://parameters-autoscaling-staging.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Production Environment:**
```bash
aws cloudformation create-stack \
  --stack-name autoscaling-prod \
  --template-body file://autoscaling-ec2-template.yaml \
  --parameters file://parameters-autoscaling-prod.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Parameters

| Parameter | Dev | Staging | Prod | Description |
|-----------|-----|---------|------|-------------|
| `VpcStackName` | vpc-1 | vpc-1 | vpc-1 | VPC stack name |
| `Environment` | dev | staging | prod | Environment name |
| `InstanceType` | t3.micro | t3.small | t3.medium | EC2 instance type |
| `MinSize` | 1 | 2 | 2 | Minimum instances |
| `MaxSize` | 3 | 5 | 10 | Maximum instances |
| `DesiredCapacity` | 1 | 2 | 3 | Desired instances |
| `TargetCPU` | 70% | 70% | 60% | CPU threshold for scaling |
| `HealthCheckType` | EC2 | ELB | ELB | Health check method |
| `SubnetDeployment` | private | private | private | Subnet type |

### Architecture Recommendations

1. **Deploy in Private Subnets** (Recommended)
   - Production workloads should be in private subnets
   - Access via Application Load Balancer in public subnet
   - Use NAT Gateway for outbound internet access

2. **Multi-AZ Deployment**
   - Auto Scaling Group spans both private subnets (different AZs)
   - Ensures high availability and fault tolerance

3. **Health Checks**
   - **EC2**: Basic instance health checks (for dev/testing)
   - **ELB**: Application-level health checks (for staging/prod)

4. **Scaling Policies**
   - CPU-based target tracking (configurable per environment)
   - Cooldown periods to prevent rapid scaling oscillations

### Connecting to Instances

Since instances are in private subnets, use SSM Session Manager:

```bash
# List running instances
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Connect via SSM
aws ssm start-session --target <instance-id> --region us-east-1
```

### Monitoring

CloudWatch alarms are automatically created:
- **HighCPUAlarm**: Triggers when CPU exceeds threshold
- **LowCPUAlarm**: Triggers when CPU is below 30%

View alarms:
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix MyApp-prod \
  --region us-east-1
```

## Single EC2 Instance Template

For deploying a single EC2 instance (not recommended for production):

```bash
aws cloudformation create-stack \
  --stack-name ec2-instance \
  --template-body file://ec2-instance-template.yaml \
  --parameters ParameterKey=VpcStackName,ParameterValue=vpc-1 \
  --region us-east-1
```

## Outputs

The Auto Scaling template exports:

- `AutoScalingGroupName` - Auto Scaling Group Name
- `AutoScalingGroupARN` - Auto Scaling Group ARN
- `LaunchTemplateId` - Launch Template ID
- `SecurityGroupId` - Auto Scaling Security Group ID
- `TargetGroupARN` - Target Group ARN (if created)
- `EC2InstanceProfileARN` - EC2 Instance Profile ARN

## Best Practices

1. **Security**: Use SSM Session Manager instead of SSH keys
2. **Monitoring**: Enable detailed CloudWatch monitoring
3. **Scaling**: Tune scaling metrics based on application behavior
4. **Cost**: Right-size instances based on CloudWatch metrics
5. **High Availability**: Deploy across multiple Availability Zones

## Troubleshooting

### Stack Creation Fails
- Verify VPC stack is deployed and outputs are available
- Check IAM permissions
- Verify parameter values

### Cannot Connect to Instances
- Verify SSM agent is running
- Check IAM role is attached
- Verify security group rules

### Scaling Issues
- Review CloudWatch metrics
- Check scaling policy configuration
- Verify cooldown periods
