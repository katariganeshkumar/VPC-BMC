# GitHub Actions Workflows

This directory contains GitHub Actions workflows for deploying VPC infrastructure.

## Workflows

### `deploy-vpc.yml`

Main workflow for deploying VPC infrastructure using CloudFormation.

#### Features

- **Template Validation**: Validates all CloudFormation templates before deployment
- **Manual Deployment**: Deploy via workflow_dispatch with customizable parameters
- **Automatic Deployment**: Auto-deploy on push to main branch
- **Multiple Actions**: Support for deploy, update, and delete operations
- **Stack Management**: Handles stack creation, updates, and deletion
- **Output Display**: Shows stack outputs after successful deployment

#### Triggers

1. **Manual Trigger** (`workflow_dispatch`):
   - Deploy specific stack (vpc-1, vpc-2, vpc-3)
   - Choose environment (dev, staging, prod)
   - Select AWS region
   - Choose action (deploy, update, delete)

2. **Push to main/develop**:
   - Automatically validates templates
   - Can be configured to auto-deploy

3. **Pull Request**:
   - Validates templates on PR creation

#### Required GitHub Secrets

Configure the following secrets in your GitHub repository settings:

- `AWS_ACCESS_KEY_ID`: AWS access key ID with CloudFormation permissions
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key
- `CLOUDFORMATION_S3_BUCKET`: S3 bucket name for storing CloudFormation templates

#### Required AWS Permissions

The AWS credentials need the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:*",
        "s3:GetObject",
        "s3:PutObject",
        "s3:CreateBucket",
        "s3:ListBucket",
        "ec2:*",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Usage

1. **Manual Deployment**:
   - Go to Actions tab in GitHub
   - Select "Deploy VPC Infrastructure"
   - Click "Run workflow"
   - Fill in the parameters:
     - Stack Name: vpc-1, vpc-2, or vpc-3
     - Environment: dev, staging, or prod
     - AWS Region: e.g., us-east-1
     - Action: deploy, update, or delete
   - Click "Run workflow"

2. **Automatic Deployment**:
   - Push changes to `main` branch
   - Workflow will automatically validate and deploy

#### Workflow Steps

1. **Validate Templates**: Validates all CloudFormation templates
2. **Upload to S3**: Uploads templates to S3 bucket
3. **Prepare Parameters**: Adds TemplateS3Bucket parameter to parameter files
4. **Deploy/Update/Delete**: Performs the selected action
5. **Display Outputs**: Shows stack outputs after successful deployment

#### Example Workflow Run

```yaml
Stack Name: vpc-1
Environment: dev
AWS Region: us-east-1
Action: deploy
```

This will:
1. Validate all templates
2. Upload templates to S3
3. Deploy vpc-1 stack using parameters from `environment/parameters-vpc1.json`
4. Display stack outputs

## Setting Up GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each required secret:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `CLOUDFORMATION_S3_BUCKET`

## Troubleshooting

### Template Validation Fails

- Check that all YAML files are valid
- Ensure all required parameters are defined
- Verify AWS credentials have validation permissions

### S3 Upload Fails

- Verify S3 bucket exists or can be created
- Check AWS credentials have S3 permissions
- Ensure bucket name in secret is correct

### Stack Deployment Fails

- Check CloudFormation console for detailed error messages
- Verify all required parameters are provided
- Ensure AWS credentials have CloudFormation permissions
- Check that resources don't already exist (for create operations)

### Stack Update Fails

- Verify changes are valid
- Check for resource conflicts
- Review CloudFormation change set for details
