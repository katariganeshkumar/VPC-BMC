# PowerShell Commands for AWS CloudFormation

## Quick Reference

PowerShell uses backticks (`` ` ``) for line continuation, NOT backslashes (`\`).

## Correct Syntax

### Option 1: Single Line (Easiest)
```powershell
aws cloudformation create-stack --stack-name vpc-1 --template-body file://vpc-template.yaml --parameters file://parameters-vpc1.json --region us-east-1
```

### Option 2: Multi-line with Backticks
```powershell
aws cloudformation create-stack `
    --stack-name vpc-1 `
    --template-body file://vpc-template.yaml `
    --parameters file://parameters-vpc1.json `
    --region us-east-1
```

### Option 3: Using PowerShell Script
```powershell
.\deploy-multiple-vpcs.ps1 us-east-1
```

## Common Commands

### Create Stack
```powershell
aws cloudformation create-stack --stack-name vpc-1 --template-body file://vpc-template.yaml --parameters file://parameters-vpc1.json --capabilities CAPABILITY_NAMED_IAM --region us-east-1
```

### Update Stack
```powershell
aws cloudformation update-stack --stack-name vpc-1 --template-body file://vpc-template.yaml --parameters file://parameters-vpc1.json --capabilities CAPABILITY_NAMED_IAM --region us-east-1
```

### Describe Stack
```powershell
aws cloudformation describe-stacks --stack-name vpc-1 --region us-east-1
```

### Get Stack Status
```powershell
aws cloudformation describe-stacks --stack-name vpc-1 --query 'Stacks[0].StackStatus' --output text --region us-east-1
```

### Delete Stack
```powershell
aws cloudformation delete-stack --stack-name vpc-1 --region us-east-1
```

### List Stacks
```powershell
aws cloudformation list-stacks --region us-east-1
```

### Get Stack Outputs
```powershell
aws cloudformation describe-stacks --stack-name vpc-1 --query 'Stacks[0].Outputs' --output table --region us-east-1
```

## PowerShell Script Usage

### Deploy Multiple VPCs
```powershell
cd vpc
.\deploy-multiple-vpcs.ps1 us-east-1
```

### Deploy with Custom Region
```powershell
.\deploy-multiple-vpcs.ps1 us-west-2
```

## Troubleshooting

### Error: "Missing expression after unary operator '--'"
**Cause**: Using bash-style backslash (`\`) instead of PowerShell backtick (`` ` ``)

**Solution**: Use backticks or single line command

### Error: "file:// not found"
**Cause**: File path issue in PowerShell

**Solution**: Use forward slashes or relative paths:
```powershell
# Correct
--template-body file://vpc-template.yaml

# Also works
--template-body .\vpc-template.yaml
```

### Error: "Parameters file not found"
**Cause**: Wrong directory or file path

**Solution**: Check current directory:
```powershell
Get-Location
ls *.json
```

## Environment-Specific Deployments

### Development
```powershell
aws cloudformation create-stack --stack-name vpc-dev --template-body file://vpc-template.yaml --parameters file://parameters-vpc1.json --capabilities CAPABILITY_NAMED_IAM --region us-east-1
```

### QA/Staging
```powershell
aws cloudformation create-stack --stack-name vpc-qa --template-body file://vpc-template.yaml --parameters file://parameters-vpc2.json --capabilities CAPABILITY_NAMED_IAM --region us-east-1
```

### Production
```powershell
aws cloudformation create-stack --stack-name vpc-prod --template-body file://vpc-template.yaml --parameters file://parameters-vpc3.json --capabilities CAPABILITY_NAMED_IAM --region us-east-1
```

## Tips

1. **Always use backticks** (`` ` ``) for line continuation in PowerShell
2. **Use single quotes** for strings with special characters
3. **Check AWS CLI version**: `aws --version`
4. **Verify credentials**: `aws sts get-caller-identity`
5. **Use tab completion** for parameter names

## Example: Complete Deployment Workflow

```powershell
# 1. Navigate to vpc directory
cd vpc

# 2. Verify files exist
ls vpc-template.yaml
ls parameters-vpc1.json

# 3. Deploy stack
aws cloudformation create-stack --stack-name vpc-1 --template-body file://vpc-template.yaml --parameters file://parameters-vpc1.json --capabilities CAPABILITY_NAMED_IAM --region us-east-1

# 4. Wait for completion (optional)
aws cloudformation wait stack-create-complete --stack-name vpc-1 --region us-east-1

# 5. Get outputs
aws cloudformation describe-stacks --stack-name vpc-1 --query 'Stacks[0].Outputs' --output table --region us-east-1
```
