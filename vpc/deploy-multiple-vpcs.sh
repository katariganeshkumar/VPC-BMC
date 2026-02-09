#!/bin/bash

# Script to deploy multiple VPCs using modular CloudFormation templates
# Usage: ./deploy-multiple-vpcs.sh [region] [s3-bucket]
# Example: ./deploy-multiple-vpcs.sh us-east-1 my-cf-templates

set -e

REGION=${1:-us-east-1}
S3_BUCKET=${2:-""}
TEMPLATE_FILE="main.yaml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if S3 bucket is provided for modular templates
if [ -z "$S3_BUCKET" ]; then
    echo -e "${RED}Error: S3 bucket is required for modular templates${NC}"
    echo "Usage: ./deploy-multiple-vpcs.sh [region] [s3-bucket]"
    echo "Example: ./deploy-multiple-vpcs.sh us-east-1 my-cf-templates"
    exit 1
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Deploying Multiple VPCs to ${REGION}${NC}"
echo -e "${GREEN}Using S3 bucket: ${S3_BUCKET}${NC}"

# Upload templates to S3 first
upload_templates

# Function to check if stack exists
stack_exists() {
    aws cloudformation describe-stacks --stack-name "$1" --region "$REGION" >/dev/null 2>&1
}

# Function to upload templates to S3
upload_templates() {
    echo -e "${GREEN}Uploading templates to S3...${NC}"
    aws s3 cp main.yaml "s3://${S3_BUCKET}/vpc/main.yaml" --region "$REGION" >/dev/null 2>&1
    aws s3 cp templates/vpc.yaml "s3://${S3_BUCKET}/vpc/templates/vpc.yaml" --region "$REGION" >/dev/null 2>&1
    aws s3 cp templates/subnets.yaml "s3://${S3_BUCKET}/vpc/templates/subnets.yaml" --region "$REGION" >/dev/null 2>&1
    aws s3 cp templates/nat-gateway.yaml "s3://${S3_BUCKET}/vpc/templates/nat-gateway.yaml" --region "$REGION" >/dev/null 2>&1
    aws s3 cp templates/route-tables.yaml "s3://${S3_BUCKET}/vpc/templates/route-tables.yaml" --region "$REGION" >/dev/null 2>&1
    aws s3 cp templates/security-groups.yaml "s3://${S3_BUCKET}/vpc/templates/security-groups.yaml" --region "$REGION" >/dev/null 2>&1
    echo -e "${GREEN}Templates uploaded successfully${NC}"
}

# Function to deploy or update stack
deploy_stack() {
    local STACK_NAME=$1
    local PARAMS_FILE=$2
    
    # Create temp file with TemplateS3Bucket parameter
    TEMP_PARAMS=$(mktemp)
    cat "$PARAMS_FILE" > "$TEMP_PARAMS"
    
    # Add TemplateS3Bucket parameter if not already present
    if ! grep -q "TemplateS3Bucket" "$TEMP_PARAMS"; then
        sed -i.bak '$ i\
  {\
    "ParameterKey": "TemplateS3Bucket",\
    "ParameterValue": "'"$S3_BUCKET"'"
  },' "$TEMP_PARAMS"
        rm "${TEMP_PARAMS}.bak" 2>/dev/null || true
    fi
    
    TEMPLATE_URL="https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/vpc/${TEMPLATE_FILE}"
    
    if stack_exists "$STACK_NAME"; then
        echo -e "${YELLOW}Stack ${STACK_NAME} exists. Updating...${NC}"
        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-url "$TEMPLATE_URL" \
            --parameters file://"$TEMP_PARAMS" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION" >/dev/null 2>&1 || echo -e "${YELLOW}No updates to apply${NC}"
    else
        echo -e "${GREEN}Creating stack ${STACK_NAME}...${NC}"
        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-url "$TEMPLATE_URL" \
            --parameters file://"$TEMP_PARAMS" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$REGION"
    fi
    
    rm "$TEMP_PARAMS"
}

# Deploy VPC 1
if [ -f "environment/parameters-vpc1.json" ]; then
    deploy_stack "vpc-1" "environment/parameters-vpc1.json"
else
    echo -e "${RED}Error: environment/parameters-vpc1.json not found${NC}"
    exit 1
fi

# Deploy VPC 2
if [ -f "environment/parameters-vpc2.json" ]; then
    deploy_stack "vpc-2" "environment/parameters-vpc2.json"
else
    echo -e "${YELLOW}Warning: environment/parameters-vpc2.json not found, skipping VPC 2${NC}"
fi

# Deploy VPC 3
if [ -f "environment/parameters-vpc3.json" ]; then
    deploy_stack "vpc-3" "environment/parameters-vpc3.json"
else
    echo -e "${YELLOW}Warning: environment/parameters-vpc3.json not found, skipping VPC 3${NC}"
fi

echo -e "${GREEN}Deployment initiated. Check stack status with:${NC}"
echo "aws cloudformation describe-stacks --region $REGION"
