#!/bin/bash

# Deployment script for modular VPC CloudFormation templates
# This script uploads templates to S3 and deploys the stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if required parameters are provided
if [ "$#" -lt 3 ]; then
    echo -e "${RED}Usage: $0 <S3_BUCKET> <STACK_NAME> <PARAMETERS_FILE> [REGION]${NC}"
    echo "Example: $0 my-cf-templates vpc-1 environment/parameters-vpc1.json us-east-1"
    exit 1
fi

S3_BUCKET=$1
STACK_NAME=$2
PARAMETERS_FILE=$3
REGION=${4:-us-east-1}

# Validate parameters file exists
if [ ! -f "$PARAMETERS_FILE" ]; then
    echo -e "${RED}Error: Parameters file '$PARAMETERS_FILE' not found${NC}"
    exit 1
fi

echo -e "${GREEN}Starting deployment process...${NC}"
echo "S3 Bucket: $S3_BUCKET"
echo "Stack Name: $STACK_NAME"
echo "Parameters File: $PARAMETERS_FILE"
echo "Region: $REGION"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

# Check if S3 bucket exists
if ! aws s3 ls "s3://${S3_BUCKET}" --region "$REGION" &> /dev/null; then
    echo -e "${YELLOW}Warning: S3 bucket '$S3_BUCKET' does not exist or is not accessible${NC}"
    echo "Creating bucket..."
    aws s3 mb "s3://${S3_BUCKET}" --region "$REGION"
fi

echo -e "${GREEN}Uploading templates to S3...${NC}"

# Upload main template
aws s3 cp main.yaml "s3://${S3_BUCKET}/vpc/main.yaml" --region "$REGION"
echo "  ✓ Uploaded main.yaml"

# Upload all template modules
aws s3 cp templates/vpc.yaml "s3://${S3_BUCKET}/vpc/templates/vpc.yaml" --region "$REGION"
echo "  ✓ Uploaded templates/vpc.yaml"

aws s3 cp templates/subnets.yaml "s3://${S3_BUCKET}/vpc/templates/subnets.yaml" --region "$REGION"
echo "  ✓ Uploaded templates/subnets.yaml"

aws s3 cp templates/nat-gateway.yaml "s3://${S3_BUCKET}/vpc/templates/nat-gateway.yaml" --region "$REGION"
echo "  ✓ Uploaded templates/nat-gateway.yaml"

aws s3 cp templates/route-tables.yaml "s3://${S3_BUCKET}/vpc/templates/route-tables.yaml" --region "$REGION"
echo "  ✓ Uploaded templates/route-tables.yaml"

aws s3 cp templates/security-groups.yaml "s3://${S3_BUCKET}/vpc/templates/security-groups.yaml" --region "$REGION"
echo "  ✓ Uploaded templates/security-groups.yaml"

echo ""
echo -e "${GREEN}Templates uploaded successfully!${NC}"
echo ""

# Check if stack exists
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" &> /dev/null; then
    echo -e "${YELLOW}Stack '$STACK_NAME' already exists. Updating...${NC}"
    OPERATION="update-stack"
else
    echo -e "${GREEN}Creating new stack '$STACK_NAME'...${NC}"
    OPERATION="create-stack"
fi

# Prepare parameters with S3 bucket parameter
TEMP_PARAMS=$(mktemp)
cat "$PARAMETERS_FILE" > "$TEMP_PARAMS"

# Add TemplateS3Bucket parameter if not already present
if ! grep -q "TemplateS3Bucket" "$TEMP_PARAMS"; then
    # Add TemplateS3Bucket parameter (insert before the last closing bracket)
    sed -i.bak '$ i\
  {\
    "ParameterKey": "TemplateS3Bucket",\
    "ParameterValue": "'"$S3_BUCKET"'"
  },' "$TEMP_PARAMS"
    rm "${TEMP_PARAMS}.bak" 2>/dev/null || true
fi

# Deploy stack
if aws cloudformation "$OPERATION" \
    --stack-name "$STACK_NAME" \
    --template-url "https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/vpc/main.yaml" \
    --parameters "file://${TEMP_PARAMS}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION"; then
    
    echo ""
    echo -e "${GREEN}Stack ${OPERATION} initiated successfully!${NC}"
    echo "Waiting for stack ${OPERATION} to complete..."
    
    if [ "$OPERATION" = "create-stack" ]; then
        aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION"
    else
        aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME" --region "$REGION"
    fi
    
    echo -e "${GREEN}Stack ${OPERATION} completed successfully!${NC}"
else
    echo -e "${RED}Stack ${OPERATION} failed${NC}"
    rm "$TEMP_PARAMS"
    exit 1
fi

# Cleanup
rm "$TEMP_PARAMS"

echo ""
echo -e "${GREEN}Deployment completed successfully!${NC}"
