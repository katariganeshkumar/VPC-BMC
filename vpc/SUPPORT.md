# VPC Support Guide

This guide provides support information and resources for VPC infrastructure deployment.

## Quick Start Checklist

Before deploying, ensure you have:

- [ ] AWS CLI installed and configured
- [ ] Appropriate IAM permissions
- [ ] EC2 Key Pair created (for testing)
- [ ] Unique CIDR blocks planned
- [ ] Region selected
- [ ] Stack name decided

## Pre-Deployment Checklist

### 1. Verify AWS CLI Configuration
```bash
# Check AWS CLI is installed
aws --version

# Verify credentials
aws sts get-caller-identity

# Check default region
aws configure get region
```

### 2. Verify IAM Permissions

Required permissions:
- `ec2:CreateVpc`
- `ec2:CreateSubnet`
- `ec2:CreateInternetGateway`
- `ec2:CreateNatGateway`
- `ec2:CreateRouteTable`
- `ec2:CreateSecurityGroup`
- `iam:CreateRole`
- `iam:CreateInstanceProfile`
- `cloudformation:*`

### 3. Check Resource Limits
```bash
# Check VPC limit
aws service-quotas get-service-quota \
  --service-code vpc \
  --quota-code L-F678F1CE \
  --region us-east-1

# Check Elastic IP limit
aws ec2 describe-addresses --region us-east-1 | wc -l
```

### 4. Verify CIDR Blocks
- Ensure CIDR blocks don't overlap
- Use private IP ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
- Plan subnet sizes appropriately

## Deployment Support

### Step-by-Step Deployment

1. **Navigate to VPC folder**
   ```bash
   cd vpc
   ```

2. **Review parameters**
   ```bash
   cat parameters-vpc1.json
   ```

3. **Deploy VPC**
   ```bash
   aws cloudformation create-stack \
     --stack-name vpc-1 \
     --template-body file://vpc-template.yaml \
     --parameters file://parameters-vpc1.json \
     --region us-east-1
   ```

4. **Monitor deployment**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name vpc-1 \
     --region us-east-1 \
     --query 'Stacks[0].StackStatus'
   ```

5. **Get outputs**
   ```bash
   aws cloudformation describe-stacks \
     --stack-name vpc-1 \
     --region us-east-1 \
     --query 'Stacks[0].Outputs'
   ```

## Common Use Cases

### Use Case 1: Single VPC for Development
```bash
# Use parameters-vpc1.json (dev environment)
aws cloudformation create-stack \
  --stack-name vpc-dev \
  --template-body file://vpc-template.yaml \
  --parameters file://parameters-vpc1.json \
  --region us-east-1
```

### Use Case 2: Multiple VPCs for Different Environments
```bash
# Deploy all VPCs using script
./deploy-multiple-vpcs.sh us-east-1
```

### Use Case 3: Custom VPC Configuration
1. Copy parameter file: `cp parameters-vpc1.json parameters-custom.json`
2. Edit `parameters-custom.json` with your values
3. Deploy: `aws cloudformation create-stack --stack-name vpc-custom ...`

## Parameter File Reference

### Required Parameters
- `VpcName` - Name tag for the VPC
- `VpcCidr` - CIDR block (e.g., 10.0.0.0/16)
- `PublicSubnetCidr` - Public subnet CIDR (e.g., 10.0.1.0/24)
- `PrivateSubnet1Cidr` - First private subnet CIDR (e.g., 10.0.2.0/24)
- `PrivateSubnet2Cidr` - Second private subnet CIDR (e.g., 10.0.3.0/24)

### Optional Parameters
- `AvailabilityZone1` - First AZ (default: us-east-1a)
- `AvailabilityZone2` - Second AZ (default: us-east-1b)
- `KeyPairName` - EC2 Key Pair (for testing)
- `Environment` - Environment tag (dev/staging/prod)

## Output Reference

After deployment, the stack exports:

- `VpcId` - Use this in other stacks
- `PublicSubnetId` - For public resources
- `PrivateSubnet1Id` - For private resources (AZ 1)
- `PrivateSubnet2Id` - For private resources (AZ 2)
- `NatGatewayId` - NAT Gateway reference
- `PublicSecurityGroupId` - Public security group
- `PrivateSecurityGroupId` - Private security group
- `SSMInstanceProfileArn` - For EC2 instances

## Integration with Other Stacks

### Using VPC Outputs in Compute Stack

```yaml
# In compute template
Parameters:
  VpcStackName:
    Type: String
    Default: vpc-1

Resources:
  MyInstance:
    Type: AWS::EC2::Instance
    Properties:
      SubnetId: !ImportValue
        Fn::Sub: '${VpcStackName}-Private-Subnet-1-ID'
      SecurityGroupIds:
        - !ImportValue
          Fn::Sub: '${VpcStackName}-Private-SG-ID'
```

## Best Practices

1. **Naming Convention**
   - Use descriptive stack names: `vpc-dev`, `vpc-prod`
   - Tag resources consistently
   - Use environment tags

2. **CIDR Planning**
   - Reserve space for future growth
   - Use consistent CIDR patterns
   - Document CIDR allocations

3. **Security**
   - Deploy production workloads in private subnets
   - Use SSM Session Manager instead of SSH
   - Restrict security group rules

4. **Cost Management**
   - Delete unused stacks
   - Monitor NAT Gateway costs
   - Use VPC Endpoints where possible

## Monitoring and Maintenance

### Regular Checks
- Review CloudWatch metrics
- Check NAT Gateway utilization
- Monitor security group rules
- Review IAM roles

### Maintenance Tasks
- Update documentation
- Review and update CIDR allocations
- Clean up unused resources
- Review cost reports

## Resources

### AWS Documentation
- [VPC User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [CloudFormation User Guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/)
- [EC2 User Guide](https://docs.aws.amazon.com/AWS2/latest/userguide/)

### AWS CLI Reference
- [AWS CLI VPC Commands](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html)
- [AWS CLI CloudFormation Commands](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/index.html)

### Community Resources
- [AWS VPC FAQ](https://aws.amazon.com/vpc/faqs/)
- [AWS Forums](https://forums.aws.amazon.com/)
- [Stack Overflow - AWS VPC](https://stackoverflow.com/questions/tagged/amazon-vpc)

## Getting Additional Help

### AWS Support
- **Basic Support**: Included with AWS account
- **Developer Support**: $29/month
- **Business Support**: $100/month
- **Enterprise Support**: $15,000/month

### Support Channels
1. **AWS Support Center**: https://console.aws.amazon.com/support/
2. **AWS Documentation**: https://docs.aws.amazon.com/
3. **AWS Forums**: https://forums.aws.amazon.com/
4. **AWS re:Post**: https://repost.aws/

## FAQ

### Q: Can I modify a VPC after creation?
A: Yes, but some changes require replacement. Use CloudFormation update-stack.

### Q: How many subnets can I have per VPC?
A: Default limit is 200 subnets per VPC. Can be increased via support request.

### Q: Can I change CIDR blocks?
A: No, CIDR blocks cannot be changed after VPC creation. You must create a new VPC.

### Q: How much does a NAT Gateway cost?
A: ~$0.045/hour + data transfer costs. See AWS pricing for details.

### Q: Can I use this template in multiple regions?
A: Yes, just specify the region in the deployment command and update AZ parameters.

## Version History

- **v1.0** - Initial release with basic VPC, subnets, IGW, NAT Gateway
- **v1.1** - Added SSM Session Manager support
- **v1.2** - Added environment-specific parameter files

## Contact

For issues or questions:
1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) first
2. Review AWS documentation
3. Open an issue in the repository
4. Contact AWS Support if needed
