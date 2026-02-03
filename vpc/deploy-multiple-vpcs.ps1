# PowerShell script to deploy multiple VPCs using CloudFormation
# Usage: .\deploy-multiple-vpcs.ps1 [region]

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"
$TemplateFile = "vpc-template.yaml"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "Deploying Multiple VPCs to $Region" -ForegroundColor Green

# Function to check if stack exists
function Test-StackExists {
    param([string]$StackName)
    $result = aws cloudformation describe-stacks --stack-name $StackName --region $Region 2>&1
    if ($LASTEXITCODE -eq 0) {
        return $true
    } else {
        return $false
    }
}

# Function to deploy or update stack
function Deploy-Stack {
    param(
        [string]$StackName,
        [string]$ParamsFile
    )
    
    if (-not (Test-Path $ParamsFile)) {
        Write-Host "Warning: $ParamsFile not found. Skipping $StackName" -ForegroundColor Yellow
        return
    }
    
    if (Test-StackExists -StackName $StackName) {
        Write-Host "Stack $StackName exists. Updating..." -ForegroundColor Yellow
        try {
            aws cloudformation update-stack `
                --stack-name $StackName `
                --template-body file://$TemplateFile `
                --parameters file://$ParamsFile `
                --capabilities CAPABILITY_NAMED_IAM `
                --region $Region 2>&1 | Out-Null
        } catch {
            Write-Host "No updates to apply for $StackName" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Creating stack $StackName..." -ForegroundColor Green
        aws cloudformation create-stack `
            --stack-name $StackName `
            --template-body file://$TemplateFile `
            --parameters file://$ParamsFile `
            --capabilities CAPABILITY_NAMED_IAM `
            --region $Region
    }
}

# Deploy VPC 1
if (Test-Path "parameters-vpc1.json") {
    Deploy-Stack -StackName "vpc-1" -ParamsFile "parameters-vpc1.json"
} else {
    Write-Host "Error: parameters-vpc1.json not found" -ForegroundColor Red
    exit 1
}

# Deploy VPC 2
if (Test-Path "parameters-vpc2.json") {
    Deploy-Stack -StackName "vpc-2" -ParamsFile "parameters-vpc2.json"
} else {
    Write-Host "Warning: parameters-vpc2.json not found. Skipping VPC 2" -ForegroundColor Yellow
}

# Deploy VPC 3
if (Test-Path "parameters-vpc3.json") {
    Deploy-Stack -StackName "vpc-3" -ParamsFile "parameters-vpc3.json"
} else {
    Write-Host "Warning: parameters-vpc3.json not found. Skipping VPC 3" -ForegroundColor Yellow
}

Write-Host "`nDeployment initiated. Check stack status with:" -ForegroundColor Green
Write-Host "  aws cloudformation describe-stacks --region $Region" -ForegroundColor Cyan
