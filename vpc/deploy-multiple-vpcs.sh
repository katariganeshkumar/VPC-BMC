#!/bin/bash

# Script to deploy multiple VPCs using CloudFormation
# Usage: ./deploy-multiple-vpcs.sh [region]

set -e

REGION=${1:-us-east-1}
TEMPLATE_FILE="vpc-template.yaml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Deploying Multiple VPCs to ${REGION}${NC}"

# Function to check if stack exists
stack_exists() {
    aws cloudformation describe-stacks --stack-name "$1" --region "$REGION" >/dev/null 2>&1
}

# Function to deploy or update stack
deploy_stack() {
    local STACK_NAME=$1
    local PARAMS_FILE=$2
    
    if stack_exists "$STACK_NAME"; then
        echo -e "${YELLOW}Stack ${STACK_NAME} exists. Updating...${NC}"
        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-body file://"$TEMPLATE_FILE" \
            --parameters file://"$PARAMS_FILE" \
            --region "$REGION" >/dev/null 2>&1 || echo -e "${YELLOW}No updates to apply${NC}"
    else
        echo -e "${GREEN}Creating stack ${STACK_NAME}...${NC}"
        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-body file://"$TEMPLATE_FILE" \
            --parameters file://"$PARAMS_FILE" \
            --region "$REGION"
    fi
}

# Deploy VPC 1
if [ -f "parameters-vpc1.json" ]; then
    deploy_stack "vpc-1" "parameters-vpc1.json"
else
    echo -e "${RED}Error: parameters-vpc1.json not found${NC}"
    exit 1
fi

# Deploy VPC 2
if [ -f "parameters-vpc2.json" ]; then
    deploy_stack "vpc-2" "parameters-vpc2.json"
else
    echo -e "${YELLOW}Warning: parameters-vpc2.json not found. Skipping VPC 2${NC}"
fi

# Deploy VPC 3
if [ -f "parameters-vpc3.json" ]; then
    deploy_stack "vpc-3" "parameters-vpc3.json"
else
    echo -e "${YELLOW}Warning: parameters-vpc3.json not found. Skipping VPC 3${NC}"
fi

echo -e "${GREEN}Deployment initiated. Check stack status with:${NC}"
echo "aws cloudformation describe-stacks --region $REGION"
