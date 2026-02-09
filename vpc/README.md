# VPC Infrastructure Templates

This folder contains modular CloudFormation templates for creating VPC infrastructure in AWS.

## Project Structure

```
vpc/
├── main.yaml                    # Main template that orchestrates all modules
├── templates/                   # Modular template files
│   ├── vpc.yaml                # VPC, Internet Gateway module
│   ├── subnets.yaml            # Public and Private Subnets module
│   ├── nat-gateway.yaml        # NAT Gateway and Elastic IP module
│   ├── route-tables.yaml       # Route Tables and Associations module
│   └── security-groups.yaml    # Security Groups module
├── environment/                 # Environment-specific parameter files
│   ├── parameters-vpc1.json    # Parameters for VPC 1 (Development)
│   ├── parameters-vpc2.json    # Parameters for VPC 2 (Staging)
│   └── parameters-vpc3.json    # Parameters for VPC 3 (Production)
└── deploy-multiple-vpcs.sh     # Deployment script
```

## Architecture

The templates are organized into modular components:

- **main.yaml** - Main orchestration template using nested stacks
- **templates/vpc.yaml** - Creates VPC and Internet Gateway
- **templates/subnets.yaml** - Creates public and private subnets
- **templates/nat-gateway.yaml** - Creates NAT Gateway with Elastic IP
- **templates/route-tables.yaml** - Creates route tables and associations
- **templates/security-groups.yaml** - Creates security groups for public and private subnets

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

### Prerequisites

**Important:** Nested stacks require templates to be uploaded to an S3 bucket. 

**Option 1: Use the deployment script (Recommended)**

The `deploy-modular.sh` script automatically uploads templates to S3 and deploys the stack:

```bash
./deploy-modular.sh <S3_BUCKET> <STACK_NAME> <PARAMETERS_FILE> [REGION]

# Example:
./deploy-modular.sh my-cf-templates vpc-1 environment/parameters-vpc1.json us-east-1
```

**Option 2: Manual upload and deployment**

Before deploying, upload all templates to S3:

```bash
# Set your S3 bucket name
S3_BUCKET="your-cloudformation-templates-bucket"
REGION="us-east-1"

# Upload all templates to S3
aws s3 cp main.yaml s3://${S3_BUCKET}/vpc/main.yaml --region ${REGION}
aws s3 cp templates/vpc.yaml s3://${S3_BUCKET}/vpc/templates/vpc.yaml --region ${REGION}
aws s3 cp templates/subnets.yaml s3://${S3_BUCKET}/vpc/templates/subnets.yaml --region ${REGION}
aws s3 cp templates/nat-gateway.yaml s3://${S3_BUCKET}/vpc/templates/nat-gateway.yaml --region ${REGION}
aws s3 cp templates/route-tables.yaml s3://${S3_BUCKET}/vpc/templates/route-tables.yaml --region ${REGION}
aws s3 cp templates/security-groups.yaml s3://${S3_BUCKET}/vpc/templates/security-groups.yaml --region ${REGION}
```

Or upload the entire directory:

```bash
aws s3 sync . s3://${S3_BUCKET}/vpc/ --exclude "*.sh" --exclude "*.ps1" --exclude "README.md" --region ${REGION}
```

### Single VPC Deployment (Modular Structure)

**Using deployment script:**
```bash
./deploy-modular.sh my-cf-templates vpc-1 environment/parameters-vpc1.json us-east-1
```

**Manual deployment:**
```bash
S3_BUCKET="your-cloudformation-templates-bucket"
REGION="us-east-1"

# Note: You need to add TemplateS3Bucket parameter to your parameters file
# or pass it via --parameters flag

aws cloudformation create-stack \
  --stack-name vpc-1 \
  --template-url https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/vpc/main.yaml \
  --parameters file://environment/parameters-vpc1.json \
  --parameters ParameterKey=TemplateS3Bucket,ParameterValue=${S3_BUCKET} \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION}
```


### Multiple VPC Deployment

**Using Modular Templates:**

```bash
S3_BUCKET="your-cloudformation-templates-bucket"
REGION="us-east-1"

# Deploy VPC 1 (Development)
aws cloudformation create-stack \
  --stack-name vpc-1 \
  --template-url https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/vpc/main.yaml \
  --parameters file://environment/parameters-vpc1.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION}

# Deploy VPC 2 (Staging)
aws cloudformation create-stack \
  --stack-name vpc-2 \
  --template-url https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/vpc/main.yaml \
  --parameters file://environment/parameters-vpc2.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION}

# Deploy VPC 3 (Production)
aws cloudformation create-stack \
  --stack-name vpc-3 \
  --template-url https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/vpc/main.yaml \
  --parameters file://environment/parameters-vpc3.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION}
```

**Using deployment script:**

```bash
# Deploy all VPCs using the deployment script
./deploy-multiple-vpcs.sh us-east-1 my-cf-templates
```

### Update Existing Stack

**Modular Template:**
```bash
S3_BUCKET="your-cloudformation-templates-bucket"
REGION="us-east-1"

aws cloudformation update-stack \
  --stack-name vpc-1 \
  --template-url https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/vpc/main.yaml \
  --parameters file://environment/parameters-vpc1.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ${REGION}
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
- `VpcCidr` - VPC CIDR Block
- `InternetGatewayId` - IGW ID
- `PublicSubnetId` - Public subnet ID
- `PublicSubnetCidr` - Public subnet CIDR Block
- `PrivateSubnet1Id` - First private subnet ID
- `PrivateSubnet1Cidr` - First private subnet CIDR Block
- `PrivateSubnet2Id` - Second private subnet ID
- `PrivateSubnet2Cidr` - Second private subnet CIDR Block
- `NatGatewayId` - NAT Gateway ID
- `NatGatewayEIP` - NAT Gateway Elastic IP Address
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
