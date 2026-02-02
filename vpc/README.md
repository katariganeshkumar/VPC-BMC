# VPC Infrastructure Templates

This folder contains CloudFormation templates for creating VPC infrastructure in AWS.

## Files

- **vpc-template.yaml** - Main CloudFormation template for VPC creation
- **parameters-vpc1.json** - Parameters for VPC 1 (Development environment)
- **parameters-vpc2.json** - Parameters for VPC 2 (Staging environment)
- **parameters-vpc3.json** - Parameters for VPC 3 (Production environment)
- **deploy-multiple-vpcs.sh** - Script to deploy multiple VPCs

## Architecture

Each VPC includes:
- **1 Internet Gateway (IGW)** - Attached to the public subnet's route table
- **1 NAT Gateway** - Placed in the public subnet with Elastic IP
- **1 Public Subnet** - For resources that need direct internet access
- **2 Private Subnets** - For resources that need outbound internet access via NAT Gateway
- **Route Tables** - Public (IGW) and Private (NAT Gateway) route tables
- **Security Groups** - Separate security groups for public and private subnets
- **IAM Role** - SSM Session Manager role for secure EC2 access

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

Use the deployment script:

```bash
./deploy-multiple-vpcs.sh us-east-1
```

Or deploy individually:

```bash
# Deploy VPC 1 (Development)
aws cloudformation create-stack \
  --stack-name vpc-1 \
  --template-body file://vpc-template.yaml \
  --parameters file://parameters-vpc1.json \
  --region us-east-1

# Deploy VPC 2 (Staging)
aws cloudformation create-stack \
  --stack-name vpc-2 \
  --template-body file://vpc-template.yaml \
  --parameters file://parameters-vpc2.json \
  --region us-east-1

# Deploy VPC 3 (Production)
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

| Parameter | Description | Default |
|-----------|-------------|---------|
| `VpcName` | Name tag for the VPC | `MultiVPC-Instance` |
| `VpcCidr` | CIDR block for the VPC | `10.0.0.0/16` |
| `AvailabilityZone1` | First AZ for subnets | `us-east-1a` |
| `AvailabilityZone2` | Second AZ for private subnets | `us-east-1b` |
| `PublicSubnetCidr` | CIDR block for public subnet | `10.0.1.0/24` |
| `PrivateSubnet1Cidr` | CIDR block for first private subnet | `10.0.2.0/24` |
| `PrivateSubnet2Cidr` | CIDR block for second private subnet | `10.0.3.0/24` |
| `KeyPairName` | EC2 Key Pair name (temporary) | Empty |
| `Environment` | Environment name (dev/staging/prod) | `dev` |

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
Fn::ImportValue: !Sub '${StackName}-VPC-ID'
```

## Next Steps

After deploying the VPC, proceed to deploy compute resources:
- See `../compute/README.md` for EC2 and Auto Scaling Group templates
