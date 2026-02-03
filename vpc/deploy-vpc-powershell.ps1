# PowerShell script to deploy VPC stack
# Usage: .\deploy-vpc-powershell.ps1 -StackName vpc-1 -Region us-east-1

param(
    [Parameter(Mandatory=$false)]
    [string]$StackName = "vpc-1",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "parameters-vpc1.json"
)

Write-Host "Deploying VPC stack: $StackName" -ForegroundColor Green
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host "Parameters File: $ParametersFile" -ForegroundColor Cyan

# Check if template file exists
if (-not (Test-Path "vpc-template.yaml")) {
    Write-Host "Error: vpc-template.yaml not found!" -ForegroundColor Red
    exit 1
}

# Check if parameters file exists
if (-not (Test-Path $ParametersFile)) {
    Write-Host "Error: $ParametersFile not found!" -ForegroundColor Red
    exit 1
}

# Deploy stack
try {
    aws cloudformation create-stack `
        --stack-name $StackName `
        --template-body file://vpc-template.yaml `
        --parameters file://$ParametersFile `
        --region $Region
    
    Write-Host "`nStack creation initiated successfully!" -ForegroundColor Green
    Write-Host "Monitor stack status with:" -ForegroundColor Yellow
    Write-Host "  aws cloudformation describe-stacks --stack-name $StackName --region $Region" -ForegroundColor Cyan
    
} catch {
    Write-Host "Error deploying stack: $_" -ForegroundColor Red
    exit 1
}
