# BMC 340B Cloud Infrastructure

Comprehensive AWS CloudFormation infrastructure for BMC 340B healthcare data processing and delivery platform.

## 🏗️ Architecture Overview

This project provides a complete, production-ready infrastructure for BMC 340B data processing, including networking, security, compute, storage, data processing, integration, delivery, and CI/CD automation.

```
┌─────────────────────────────────────────────────────────────────┐
│                         BMC 340B Platform                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │   Delivery    │  │  Integration │  │ Data Process │        │
│  │ CloudFront    │  │ Private Link │  │ AWS Glue     │        │
│  │ Route 53      │  │ Snowflake    │  │ ETL Jobs     │        │
│  │ API Gateway   │  │              │  │              │        │
│  └──────┬────────┘  └──────┬───────┘  └──────┬───────┘        │
│         │                   │                  │                 │
│  ┌──────▼───────────────────▼──────────────────▼───────┐       │
│  │              Compute Layer                           │       │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │       │
│  │  │   Dev    │  │    QA    │  │   Prod   │          │       │
│  │  │   ASG    │  │   ASG    │  │   ASG    │          │       │
│  │  │   ALB    │  │   ALB    │  │   ALB    │          │       │
│  │  └──────────┘  └──────────┘  └──────────┘          │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                   │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              Storage Layer                            │       │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │       │
│  │  │   Dev    │  │    QA    │  │   Prod   │          │       │
│  │  │ S3 Input │  │ S3 Input │  │ S3 Input │          │       │
│  │  │ S3 Output│  │ S3 Output│  │ S3 Output│          │       │
│  │  │ Web Bucket│ │ Web Bucket│ │ Web Bucket│          │       │
│  │  └──────────┘  └──────────┘  └──────────┘          │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                   │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              Network Layer                            │       │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │       │
│  │  │   Dev    │  │    QA    │  │   Prod   │          │       │
│  │  │   VPC    │  │   VPC    │  │   VPC    │          │       │
│  │  │ Subnets  │  │ Subnets  │  │ Subnets  │          │       │
│  │  │ NAT GW   │  │ NAT GW   │  │ NAT GW   │          │       │
│  │  │ VPC EP   │  │ VPC EP   │  │ VPC EP   │          │       │
│  │  └──────────┘  └──────────┘  └──────────┘          │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                   │
│  ┌──────────────────────────────────────────────────────┐       │
│  │              Security Layer                           │       │
│  │  WAF │ IAM Roles │ Security Groups │ SFTP Policies  │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
VPC-BMC/
├── vpc/                              # Networking Infrastructure
│   ├── vpc-template.yaml             # VPC, Subnets, NAT Gateway, VPC Endpoints
│   ├── parameters-vpc-dev.json        # Dev VPC parameters
│   ├── parameters-vpc-qa.json        # QA VPC parameters
│   ├── parameters-vpc-prod.json      # Prod VPC parameters
│   ├── deploy-multiple-vpcs.sh      # Multi-VPC deployment script
│   ├── README.md
│   ├── SUPPORT.md
│   └── TROUBLESHOOTING.md
│
├── security/                          # Security Infrastructure (NEW)
│   ├── waf-template.yaml             # Web Application Firewall
│   ├── iam-roles-template.yaml       # IAM Roles and Policies
│   ├── security-groups-template.yaml # Security Groups
│   ├── sftp-template.yaml            # SFTP Access Policies
│   ├── parameters-security-dev.json
│   ├── parameters-security-qa.json
│   ├── parameters-security-prod.json
│   ├── README.md
│   ├── SUPPORT.md
│   └── TROUBLESHOOTING.md
│
├── compute/                          # Compute Infrastructure
│   ├── autoscaling-ec2-template.yaml # Auto Scaling Groups
│   ├── alb-template.yaml              # Application Load Balancer
│   ├── ec2-instance-template.yaml    # EC2 Instances
│   ├── parameters-compute-dev.json
│   ├── parameters-compute-qa.json
│   ├── parameters-compute-prod.json
│   ├── README.md
│   ├── SUPPORT.md
│   └── TROUBLESHOOTING.md
│
├── storage/                          # Storage Infrastructure (NEW)
│   ├── s3-buckets-template.yaml      # S3 Buckets (Input/Output/Web)
│   ├── parameters-storage-dev.json
│   ├── parameters-storage-qa.json
│   ├── parameters-storage-prod.json
│   ├── README.md
│   ├── SUPPORT.md
│   └── TROUBLESHOOTING.md
│
├── data/                             # Data Processing
│   ├── glue-snowflake-template.yaml  # AWS Glue ETL Jobs
│   ├── glue-job-template.py          # Sample Glue Script
│   ├── parameters-glue-dev.json
│   ├── parameters-glue-qa.json
│   ├── parameters-glue-prod.json
│   ├── README.md
│   ├── SUPPORT.md
│   └── TROUBLESHOOTING.md
│
├── integration/                      # Integration Layer (NEW)
│   ├── privatelink-template.yaml     # VPC Private Link for Snowflake
│   ├── snowflake-connection-template.yaml
│   ├── parameters-integration-dev.json
│   ├── parameters-integration-qa.json
│   ├── parameters-integration-prod.json
│   ├── README.md
│   ├── SUPPORT.md
│   └── TROUBLESHOOTING.md
│
├── delivery/                         # Delivery Layer (NEW)
│   ├── cloudfront-template.yaml      # CloudFront Distribution
│   ├── route53-template.yaml         # Route 53 DNS
│   ├── apigateway-template.yaml      # API Gateway
│   ├── parameters-delivery-dev.json
│   ├── parameters-delivery-qa.json
│   ├── parameters-delivery-prod.json
│   ├── README.md
│   ├── SUPPORT.md
│   └── TROUBLESHOOTING.md
│
├── cicd/                             # CI/CD Automation (NEW)
│   ├── github-actions/
│   │   ├── deploy-dev.yml            # Dev deployment workflow
│   │   ├── deploy-qa.yml             # QA deployment workflow
│   │   ├── deploy-prod.yml           # Prod deployment workflow
│   │   └── test.yml                  # Testing workflow
│   ├── scripts/
│   │   ├── deploy-stack.sh           # Stack deployment script
│   │   └── validate-template.sh      # Template validation script
│   ├── README.md
│   └── SUPPORT.md
│
├── scripts/                          # Utility Scripts
│   ├── deploy-all.sh                # Deploy entire infrastructure
│   ├── destroy-all.sh               # Destroy entire infrastructure
│   └── validate-all.sh              # Validate all templates
│
├── docs/                             # Documentation
│   ├── architecture.md               # Architecture documentation
│   ├── deployment-guide.md           # Deployment guide
│   ├── security-guide.md             # Security best practices
│   └── operations-runbook.md         # Operations runbook
│
├── README.md                         # Main project README
├── README-BMC-340B.md               # This file - BMC 340B specific
└── imp-plan for next.md              # Improvement plan
```

## 🎯 Components

### 1. Networking

**Purpose**: Creates isolated VPCs for Dev, QA, and Prod environments

**Components**:
- **VPCs**: Separate VPCs for each environment
- **Subnets**: Public and private subnets across multiple AZs
- **Route Tables**: Public (IGW) and private (NAT Gateway) routing
- **NAT Gateways**: Outbound internet access for private subnets
- **VPC Endpoints**: Private connectivity to AWS services (S3, Glue, Secrets Manager)

**Deployment**:
```bash
cd vpc
./deploy-multiple-vpcs.sh us-east-1
```

**Key Features**:
- Multi-AZ deployment for high availability
- Isolated environments (Dev/QA/Prod)
- VPC endpoints for cost optimization
- Dynamic CIDR allocation

### 2. Security

**Purpose**: Implements comprehensive security controls

**Components**:
- **WAF (Web Application Firewall)**: Protects web applications from common attacks
- **IAM Roles**: Least-privilege access policies
- **Security Groups**: Network-level access control
- **SFTP Access Policies**: Secure file transfer policies
- **Secrets Manager**: Secure credential storage

**Deployment**:
```bash
cd security
aws cloudformation create-stack \
  --stack-name security-dev \
  --template-body file://waf-template.yaml \
  --parameters file://parameters-security-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Key Features**:
- WAF rules for OWASP Top 10 protection
- IAM roles with least privilege
- Security groups with minimal required access
- SFTP user access policies
- Encrypted secrets storage

### 3. Compute

**Purpose**: Provides scalable compute resources for each environment

**Components**:
- **Auto Scaling Groups**: Auto-scaling EC2 instances
- **Application Load Balancers**: Traffic distribution
- **Target Groups**: Health checks and routing
- **EC2 Instances**: Application servers
- **Launch Templates**: Standardized instance configuration

**Deployment**:
```bash
cd compute
aws cloudformation create-stack \
  --stack-name compute-dev \
  --template-body file://autoscaling-ec2-template.yaml \
  --parameters file://parameters-compute-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Key Features**:
- Environment-specific scaling (Dev: 1-3, QA: 2-5, Prod: 2-10)
- Health checks (EC2 for Dev, ELB for QA/Prod)
- Multi-AZ deployment
- SSM Session Manager for secure access

### 4. Storage

**Purpose**: Manages S3 buckets for data storage and web hosting

**Components**:
- **S3 Input Buckets**: Ingest data from external sources
- **S3 Output Buckets**: Store processed data
- **S3 Web Buckets**: Host static web content
- **Bucket Policies**: Access control
- **Lifecycle Policies**: Cost optimization

**Deployment**:
```bash
cd storage
aws cloudformation create-stack \
  --stack-name storage-dev \
  --template-body file://s3-buckets-template.yaml \
  --parameters file://parameters-storage-dev.json \
  --region us-east-1
```

**Key Features**:
- Environment-specific buckets (Dev/QA/Prod)
- Versioning enabled
- Encryption at rest
- Lifecycle policies for cost optimization
- CloudFront integration ready

### 5. Data Processing

**Purpose**: ETL processing between S3 and Snowflake

**Components**:
- **AWS Glue Jobs**: ETL processing jobs
- **Glue Connections**: Snowflake connectivity
- **Glue Databases**: Data catalog
- **Glue Crawlers**: Schema discovery (optional)

**Deployment**:
```bash
cd data
aws cloudformation create-stack \
  --stack-name data-dev \
  --template-body file://glue-snowflake-template.yaml \
  --parameters file://parameters-glue-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Key Features**:
- Secure Snowflake connection via Secrets Manager
- Environment-specific Glue jobs
- Configurable worker types and counts
- CloudWatch logging and monitoring

### 6. Integration

**Purpose**: Connects AWS services to Snowflake securely

**Components**:
- **VPC Private Link**: Private connectivity to Snowflake
- **Snowflake Connection**: JDBC connection configuration
- **Connection String Management**: Dynamic connection strings
- **Secrets Manager Integration**: Credential management

**Deployment**:
```bash
cd integration
aws cloudformation create-stack \
  --stack-name integration-dev \
  --template-body file://privatelink-template.yaml \
  --parameters file://parameters-integration-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Key Features**:
- Private connectivity (no internet exposure)
- Secure credential management
- Connection string parameterization
- Multi-environment support

### 7. Delivery

**Purpose**: Provides web and API access to the platform

**Components**:
- **CloudFront**: CDN for static content
- **Route 53**: DNS management
- **API Gateway**: RESTful API endpoints
- **SSL/TLS Certificates**: ACM certificates

**Deployment**:
```bash
cd delivery
aws cloudformation create-stack \
  --stack-name delivery-dev \
  --template-body file://cloudfront-template.yaml \
  --parameters file://parameters-delivery-dev.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

**Key Features**:
- Global content delivery
- Custom domain support
- API rate limiting
- SSL/TLS encryption
- WAF integration

### 8. CI/CD

**Purpose**: Automated build and deployment

**Components**:
- **GitHub Actions**: Workflow automation
- **Deployment Scripts**: Stack deployment automation
- **Validation Scripts**: Template validation
- **Environment Promotion**: Dev → QA → Prod

**Workflows**:
```yaml
# .github/workflows/deploy-dev.yml
name: Deploy to Dev
on:
  push:
    branches: [develop]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Deploy Infrastructure
        run: ./scripts/deploy-stack.sh dev
```

**Key Features**:
- Automated deployments
- Environment promotion workflows
- Template validation
- Rollback capabilities
- Deployment notifications

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **GitHub Repository** for CI/CD
4. **Snowflake Account** with credentials
5. **Domain Name** (for Route 53, optional)

### Deployment Order

1. **Networking** (VPCs)
   ```bash
   cd vpc && ./deploy-multiple-vpcs.sh us-east-1
   ```

2. **Security** (WAF, IAM, Security Groups)
   ```bash
   cd security && ./deploy-all-security.sh
   ```

3. **Storage** (S3 Buckets)
   ```bash
   cd storage && ./deploy-all-storage.sh
   ```

4. **Compute** (ASG, ALB, EC2)
   ```bash
   cd compute && ./deploy-all-compute.sh
   ```

5. **Integration** (Private Link, Snowflake)
   ```bash
   cd integration && ./deploy-all-integration.sh
   ```

6. **Data Processing** (Glue Jobs)
   ```bash
   cd data && ./deploy-all-data.sh
   ```

7. **Delivery** (CloudFront, Route 53, API Gateway)
   ```bash
   cd delivery && ./deploy-all-delivery.sh
   ```

### Complete Deployment

```bash
# Deploy entire infrastructure
./scripts/deploy-all.sh dev

# Validate all templates
./scripts/validate-all.sh

# Destroy infrastructure (careful!)
./scripts/destroy-all.sh dev
```

## 📊 Environment Configuration

### Development
- **Purpose**: Development and testing
- **Resources**: Minimal (cost-optimized)
- **Scaling**: 1-3 instances
- **Monitoring**: Basic CloudWatch
- **Data**: Sample/test data

### QA
- **Purpose**: Quality assurance and staging
- **Resources**: Medium-sized
- **Scaling**: 2-5 instances
- **Monitoring**: Detailed CloudWatch
- **Data**: Production-like test data

### Production
- **Purpose**: Live production environment
- **Resources**: Full-scale
- **Scaling**: 2-10 instances (auto-scaling)
- **Monitoring**: Comprehensive (CloudWatch + custom)
- **Data**: Production data
- **Security**: Enhanced (WAF, enhanced monitoring)

## 🔒 Security Considerations

### Network Security
- Private subnets for compute resources
- Security groups with least privilege
- VPC endpoints for AWS services
- Private Link for Snowflake connectivity

### Access Control
- IAM roles with least privilege
- MFA required for production
- SSM Session Manager (no SSH keys)
- Secrets Manager for credentials

### Data Protection
- Encryption at rest (S3, EBS)
- Encryption in transit (TLS/SSL)
- Secrets Manager for sensitive data
- VPC Flow Logs for monitoring

### Compliance
- HIPAA considerations (if applicable)
- Audit logging (CloudTrail)
- Access logging (S3, CloudFront)
- Regular security reviews

## 💰 Cost Optimization

### Development
- Use smaller instance types
- Single NAT Gateway
- Basic monitoring
- Spot instances where possible

### QA
- Medium instance types
- Standard monitoring
- Reserved instances for predictable workloads

### Production
- Right-sized instances
- Reserved instances/Savings Plans
- Detailed monitoring
- Cost alerts and budgets

## 📈 Monitoring and Operations

### CloudWatch Dashboards
- Infrastructure health
- Application performance
- Cost monitoring
- Security events

### Alarms
- High CPU/Memory
- Failed job executions
- Unusual API activity
- Cost threshold breaches

### Logging
- CloudWatch Logs (applications)
- VPC Flow Logs (network)
- CloudTrail (API calls)
- S3 Access Logs

## 🔄 CI/CD Workflow

```
┌─────────────┐
│   Developer │
│   Push Code │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ GitHub Repo │
└──────┬──────┘
       │
       ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ GitHub      │─────▶│ Deploy Dev  │─────▶│ Deploy QA   │
│ Actions     │      │             │      │             │
└─────────────┘      └─────────────┘      └──────┬──────┘
                                                    │
                                                    ▼
                                            ┌─────────────┐
                                            │ Deploy Prod │
                                            │ (Manual)    │
                                            └─────────────┘
```

## 📚 Documentation

- **[Architecture Guide](docs/architecture.md)** - Detailed architecture documentation
- **[Deployment Guide](docs/deployment-guide.md)** - Step-by-step deployment instructions
- **[Security Guide](docs/security-guide.md)** - Security best practices
- **[Operations Runbook](docs/operations-runbook.md)** - Day-to-day operations

## 🛠️ Maintenance

### Regular Tasks
- Review CloudWatch metrics weekly
- Update security groups monthly
- Review IAM permissions quarterly
- Cost optimization review monthly

### Updates
- Update CloudFormation templates
- Patch EC2 instances (via Systems Manager)
- Update Glue job scripts
- Rotate secrets regularly

## 🆘 Support

- **Troubleshooting**: See `TROUBLESHOOTING.md` in each folder
- **Support Guide**: See `SUPPORT.md` in each folder
- **AWS Support**: https://console.aws.amazon.com/support/
- **Documentation**: See `README.md` in each folder

## 📝 License

This project is proprietary and confidential.

## 👥 Contributors

- Infrastructure Team
- DevOps Team
- Security Team

## 📅 Version History

- **v1.0** - Initial release with VPC, Compute, and Data Processing
- **v2.0** - Added Security, Storage, Integration, Delivery, and CI/CD
- **v2.1** - Enhanced monitoring and cost optimization

---

**Note**: This is a comprehensive infrastructure template for BMC 340B. Ensure all parameters are configured correctly before deployment to production.
