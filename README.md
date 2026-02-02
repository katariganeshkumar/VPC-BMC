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

## Next Steps

1. **Create EC2 Instances**: Deploy test instances in public and private subnets
2. **Configure Application Load Balancer**: Add ALB in public subnet
3. **Set up VPC Peering**: Connect multiple VPCs if needed
4. **Add VPN/Transit Gateway**: For hybrid cloud connectivity
5. **Implement VPC Flow Logs**: For network monitoring
