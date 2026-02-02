# Multi-VPC CloudFormation Template

This CloudFormation template creates a fully parameterized VPC infrastructure in AWS with the following components:

## Architecture

Each VPC includes:
- **1 Internet Gateway (IGW)** - Attached to the public subnet's route table
- **1 NAT Gateway** - Placed in the public subnet with Elastic IP
- **1 Public Subnet** - For resources that need direct internet access
- **2 Private Subnets** - For resources that need outbound internet access via NAT Gateway
- **Route Tables** - Public (IGW) and Private (NAT Gateway) route tables
- **Security Groups** - Separate security groups for public and private subnets
- **IAM Role** - SSM Session Manager role for secure EC2 access (replaces key-pair)

## Key Features

✅ **Fully Parameterized** - All VPC IDs, subnet CIDRs, and route tables are dynamic variables
✅ **No Hard-coded Values** - VPC ID and all resources are created dynamically
✅ **Multiple VPC Support** - Deploy multiple VPCs using different parameter files
✅ **SSM Session Manager Ready** - IAM role and instance profile included
✅ **EC2 Key-Pair Support** - Temporary key-pair parameter for immediate testing

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. EC2 Key Pair created in your AWS account (for temporary testing)
3. Appropriate IAM permissions to create VPC, EC2, IAM resources

## Deployment

### Single VPC Deployment

```bash
aws cloudformation create-stack \
  --stack-name vpc-1 \
  --template-body file://vpc-template.yaml \
  --parameters file://parameters-vpc1.json \
  --region us-east-1
```

### Multiple VPC Deployment

Deploy multiple VPCs using different parameter files:

```bash
# Deploy VPC 1
aws cloudformation create-stack \
  --stack-name vpc-1 \
  --template-body file://vpc-template.yaml \
  --parameters file://parameters-vpc1.json \
  --region us-east-1

# Deploy VPC 2
aws cloudformation create-stack \
  --stack-name vpc-2 \
  --template-body file://vpc-template.yaml \
  --parameters file://parameters-vpc2.json \
  --region us-east-1

# Deploy VPC 3
aws cloudformation create-stack \
  --stack-name vpc-3 \
  --template-body file://vpc-template.yaml \
  --parameters file://parameters-vpc3.json \
  --region us-east-1
```

### Update Existing Stack

```bash
aws cloudformation update-stack \
  --stack-name vpc-1 \
  --template-body file://vpc-template.yaml \
  --parameters file://parameters-vpc1.json \
  --region us-east-1
```

### Delete Stack

```bash
aws cloudformation delete-stack \
  --stack-name vpc-1 \
  --region us-east-1
```

## Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `VpcName` | Name tag for the VPC | `MultiVPC-Instance` | No |
| `VpcCidr` | CIDR block for the VPC | `10.0.0.0/16` | No |
| `AvailabilityZone1` | First AZ for subnets | `us-east-1a` | No |
| `AvailabilityZone2` | Second AZ for private subnets | `us-east-1b` | No |
| `PublicSubnetCidr` | CIDR block for public subnet | `10.0.1.0/24` | No |
| `PrivateSubnet1Cidr` | CIDR block for first private subnet | `10.0.2.0/24` | No |
| `PrivateSubnet2Cidr` | CIDR block for second private subnet | `10.0.3.0/24` | No |
| `KeyPairName` | EC2 Key Pair name (temporary) | Empty | No |
| `Environment` | Environment name (dev/staging/prod) | `dev` | No |

## Outputs

The template exports the following values (all dynamic, not hard-coded):

- `VpcId` - The dynamically created VPC ID
- `InternetGatewayId` - IGW ID
- `PublicSubnetId` - Public subnet ID
- `PrivateSubnet1Id` - First private subnet ID
- `PrivateSubnet2Id` - Second private subnet ID
- `NatGatewayId` - NAT Gateway ID
- `PublicRouteTableId` - Public route table ID
- `PrivateRouteTableId` - Private route table ID
- `PublicSecurityGroupId` - Public security group ID
- `PrivateSecurityGroupId` - Private security group ID
- `SSMInstanceProfileArn` - SSM Session Manager instance profile ARN

## Using Outputs in Other Stacks

You can reference these outputs in other CloudFormation stacks using:

```yaml
Parameters:
  VpcId:
    Type: String
    Default: ''

Resources:
  MyResource:
    Type: AWS::EC2::Instance
    Properties:
      SubnetId: !Ref PublicSubnetId
```

Or import using:

```yaml
Fn::ImportValue: !Sub '${StackName}-VPC-ID'
```

## EC2 Instance Deployment

### Using EC2 Key-Pair (Temporary Testing)

```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --subnet-id <PublicSubnetId-from-outputs> \
  --security-group-ids <PublicSecurityGroupId-from-outputs> \
  --key-name <your-key-pair-name> \
  --region us-east-1
```

### Using SSM Session Manager (Recommended)

1. Launch EC2 instance with the SSM Instance Profile:

```bash
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --subnet-id <PrivateSubnet1Id-from-outputs> \
  --security-group-ids <PrivateSecurityGroupId-from-outputs> \
  --iam-instance-profile Name=<SSMInstanceProfileName-from-outputs> \
  --region us-east-1
```

2. Connect via SSM Session Manager:

```bash
aws ssm start-session \
  --target <instance-id> \
  --region us-east-1
```

## Security Notes

- **Public Security Group**: Allows SSH (22), HTTP (80), and HTTPS (443) from anywhere. **Restrict this in production!**
- **Private Security Group**: Allows SSH and all traffic from public subnet only
- **SSM Session Manager**: More secure than SSH key-pairs. Use this for production workloads
- **Key-Pair**: Intended for temporary testing only. Remove SSH access from public security group once SSM is configured

## Cost Considerations

- **NAT Gateway**: ~$0.045/hour + data transfer costs
- **Elastic IP**: Free when attached to NAT Gateway
- **Internet Gateway**: Free
- **VPC**: Free

To minimize costs during testing, delete stacks when not in use.

## Customization

### Modify CIDR Blocks

Edit the parameter files to use different CIDR blocks:

```json
{
  "ParameterKey": "VpcCidr",
  "ParameterValue": "172.16.0.0/16"
}
```

### Change Availability Zones

Update the AZ parameters based on your region:

```json
{
  "ParameterKey": "AvailabilityZone1",
  "ParameterValue": "us-west-2a"
}
```

### Add More Subnets

To add additional subnets, modify the template and add:
- New subnet resources
- Route table associations
- Parameter definitions

## Troubleshooting

### Stack Creation Fails

1. Check CloudFormation events: `aws cloudformation describe-stack-events --stack-name <stack-name>`
2. Verify CIDR blocks don't overlap
3. Ensure key-pair exists in the region
4. Check IAM permissions

### Cannot Connect to EC2 Instance

1. Verify security group allows SSH (22) or SSM (443)
2. Check route table associations
3. For private instances, ensure NAT Gateway is running
4. Verify IAM role is attached for SSM access

## Auto Scaling EC2 Template

### Overview

The `autoscaling-ec2-template.yaml` provides a production-ready Auto Scaling Group configuration for EC2 instances across different environments (dev, staging, prod). It includes:

- **Launch Template** - Standardized EC2 instance configuration
- **Auto Scaling Group** - Automatic scaling based on CPU utilization
- **Target Group** - For Application Load Balancer integration (optional)
- **CloudWatch Alarms** - Monitoring and alerting
- **IAM Roles** - SSM Session Manager and CloudWatch access
- **Multi-Environment Support** - Separate parameter files for each environment

### Architecture Recommendations

#### ✅ Best Practices

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

5. **Monitoring**
   - Detailed CloudWatch monitoring enabled
   - Custom alarms for high/low CPU utilization

### Deployment

#### Prerequisites

1. VPC stack must be deployed first
2. Ensure VPC stack exports are available
3. For ELB health checks, Application Load Balancer should be configured separately

#### Deploy Auto Scaling Group for Each Environment

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

### Auto Scaling Parameters

| Parameter | Dev | Staging | Prod | Description |
|-----------|-----|---------|------|-------------|
| `InstanceType` | t3.micro | t3.small | t3.medium | EC2 instance type |
| `MinSize` | 1 | 2 | 2 | Minimum instances |
| `MaxSize` | 3 | 5 | 10 | Maximum instances |
| `DesiredCapacity` | 1 | 2 | 3 | Desired instances |
| `TargetCPU` | 70% | 70% | 60% | CPU threshold for scaling |
| `HealthCheckType` | EC2 | ELB | ELB | Health check method |

### Environment-Specific Recommendations

#### Development
- **Instance Type**: t3.micro (cost-effective)
- **Min/Max**: 1-3 instances
- **Health Check**: EC2 (simpler, no ALB required)
- **Monitoring**: Basic CloudWatch metrics
- **Purpose**: Testing and development workloads

#### Staging
- **Instance Type**: t3.small (closer to production)
- **Min/Max**: 2-5 instances
- **Health Check**: ELB (application-level checks)
- **Monitoring**: Detailed monitoring enabled
- **Purpose**: Pre-production testing

#### Production
- **Instance Type**: t3.medium or larger (based on workload)
- **Min/Max**: 2-10 instances (scale based on traffic)
- **Health Check**: ELB (required for production)
- **Monitoring**: Detailed monitoring + custom alarms
- **Target CPU**: 60% (more conservative scaling)
- **Purpose**: Production workloads with high availability

### Connecting to Auto Scaled Instances

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

### Scaling Behavior

The Auto Scaling Group uses **Target Tracking Scaling Policy** based on CPU utilization:

- **Scale Out**: When average CPU > target threshold
- **Scale In**: When average CPU < target threshold
- **Cooldown**: Prevents rapid scaling oscillations
- **Evaluation Period**: 2 periods of 5 minutes each

### Monitoring and Alarms

CloudWatch alarms are automatically created:
- **HighCPUAlarm**: Triggers when CPU exceeds threshold
- **LowCPUAlarm**: Triggers when CPU is below 30%

View alarms:
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix MyApp-prod \
  --region us-east-1
```

### Suggestions and Best Practices

#### 🔒 Security Enhancements

1. **Restrict Security Groups**
   - Remove SSH (22) from public-facing security groups in production
   - Use SSM Session Manager exclusively for access
   - Implement least-privilege IAM policies

2. **Network Security**
   - Deploy instances in private subnets only
   - Use Application Load Balancer for public access
   - Enable VPC Flow Logs for network monitoring

3. **Secrets Management**
   - Use AWS Secrets Manager or Parameter Store
   - Never hardcode credentials in UserData
   - Rotate credentials regularly

#### 💰 Cost Optimization

1. **Right-Sizing**
   - Start with smaller instance types
   - Use CloudWatch metrics to identify optimal sizes
   - Consider Reserved Instances for predictable workloads

2. **Scaling Policies**
   - Set appropriate cooldown periods
   - Use scheduled scaling for predictable traffic patterns
   - Consider Spot Instances for non-critical workloads

3. **NAT Gateway**
   - Consider NAT Instance for cost savings (less reliable)
   - Use VPC Endpoints to reduce NAT Gateway data transfer costs
   - Monitor NAT Gateway utilization

#### 🚀 Performance Optimization

1. **Application Load Balancer**
   - Deploy ALB in public subnets
   - Use target groups for health checks
   - Enable connection draining

2. **Auto Scaling Configuration**
   - Tune scaling metrics based on application behavior
   - Consider custom CloudWatch metrics (request rate, response time)
   - Implement predictive scaling for known patterns

3. **Instance Configuration**
   - Use Launch Templates for version control
   - Implement golden AMI strategy
   - Enable EBS optimization for I/O-intensive workloads

#### 📊 Monitoring and Observability

1. **CloudWatch Integration**
   - Enable detailed monitoring (1-minute intervals)
   - Create custom dashboards
   - Set up SNS notifications for alarms

2. **Logging**
   - Centralize logs using CloudWatch Logs
   - Implement log retention policies
   - Use CloudWatch Logs Insights for analysis

3. **Application Monitoring**
   - Integrate with AWS X-Ray for distributed tracing
   - Use CloudWatch Application Insights
   - Monitor application-specific metrics

#### 🔄 CI/CD Integration

1. **Infrastructure as Code**
   - Version control all CloudFormation templates
   - Use AWS CodePipeline for automated deployments
   - Implement blue/green deployments

2. **Testing**
   - Test templates in dev environment first
   - Use CloudFormation change sets for review
   - Implement automated testing pipelines

#### 🏗️ Architecture Improvements

1. **High Availability**
   - Deploy across multiple Availability Zones
   - Use Multi-AZ RDS for databases
   - Implement cross-region replication for DR

2. **Disaster Recovery**
   - Regular automated backups
   - Cross-region stack replication
   - Document recovery procedures

3. **Networking**
   - Consider Transit Gateway for multi-VPC connectivity
   - Implement VPC Peering for inter-VPC communication
   - Use PrivateLink for AWS service access

### Template Files Structure

```
VPC-BMC/
├── vpc-template.yaml                    # Main VPC template
├── autoscaling-ec2-template.yaml        # Auto Scaling Group template
├── ec2-instance-template.yaml           # Single EC2 instance template
├── parameters-vpc1.json                  # VPC parameters
├── parameters-vpc2.json                  # VPC parameters
├── parameters-vpc3.json                  # VPC parameters
├── parameters-autoscaling-dev.json      # Auto Scaling dev parameters
├── parameters-autoscaling-staging.json  # Auto Scaling staging parameters
├── parameters-autoscaling-prod.json     # Auto Scaling prod parameters
├── deploy-multiple-vpcs.sh              # Deployment script
└── README.md                            # This file
```

### Complete Deployment Workflow

1. **Deploy VPC Infrastructure**
   ```bash
   ./deploy-multiple-vpcs.sh us-east-1
   ```

2. **Deploy Auto Scaling Groups**
   ```bash
   # Dev
   aws cloudformation create-stack \
     --stack-name autoscaling-dev \
     --template-body file://autoscaling-ec2-template.yaml \
     --parameters file://parameters-autoscaling-dev.json \
     --capabilities CAPABILITY_NAMED_IAM \
     --region us-east-1

   # Staging
   aws cloudformation create-stack \
     --stack-name autoscaling-staging \
     --template-body file://autoscaling-ec2-template.yaml \
     --parameters file://parameters-autoscaling-staging.json \
     --capabilities CAPABILITY_NAMED_IAM \
     --region us-east-1

   # Production
   aws cloudformation create-stack \
     --stack-name autoscaling-prod \
     --template-body file://autoscaling-ec2-template.yaml \
     --parameters file://parameters-autoscaling-prod.json \
     --capabilities CAPABILITY_NAMED_IAM \
     --region us-east-1
   ```

3. **Verify Deployment**
   ```bash
   # Check VPC stacks
   aws cloudformation describe-stacks --region us-east-1

   # Check Auto Scaling Groups
   aws autoscaling describe-auto-scaling-groups --region us-east-1

   # Check running instances
   aws ec2 describe-instances --region us-east-1
   ```

## Next Steps

1. **Create EC2 Instances**: Deploy test instances in public and private subnets
2. **Deploy Auto Scaling Groups**: Use autoscaling templates for each environment
3. **Configure Application Load Balancer**: Add ALB in public subnet for production
4. **Set up VPC Peering**: Connect multiple VPCs if needed
5. **Add VPN/Transit Gateway**: For hybrid cloud connectivity
6. **Implement VPC Flow Logs**: For network monitoring
7. **Set up CloudWatch Dashboards**: For centralized monitoring
8. **Configure Backup Strategy**: Implement automated backups
9. **Document Runbooks**: Create operational procedures
10. **Implement CI/CD**: Automate infrastructure deployments
