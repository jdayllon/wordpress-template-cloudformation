#!/bin/bash

# Gets the available instance types and their supported architectures
aws ec2 describe-instance-types --query "InstanceTypes[*].[InstanceType,ProcessorInfo.SupportedArchitectures[0]]" --output json | jq -c 'reduce .[] as $item ({}; .[$item[0]] = {"Arch": (if $item[1] == "x86_64" then "HVM64" elif $item[1] == "arm64" then "ARM64" else $item[1] end)})' > instance-types.json

echo "Instance types saved to instance-types.json"

# Gets higger "t*.small" instance type
instance_type=$(jq -r 'keys_unsorted[]' instance-types.json | grep -E '^t.*\.small$' | sort -V | tail -n 1)

# AMI ID for different regions and architectures
# Like : "af-south-1"       : {"HVM64" : "ami-0412806bd0f2cf75f", "HVMG2" : "NOT_SUPPORTED"},
# and put it in the file "amis.json"

# Get all available regions
regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)

# Initialize JSON
echo "{" > amis.json

# Process each region
for region in $regions; do
  echo "Processing region: $region"
  
  # Get latest Amazon Linux 2 AMI for x86_64 (HVM64)
  hvm64_ami=$(aws ec2 describe-images --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --region $region \
    --output text 2>/dev/null || echo "NOT_SUPPORTED")
  
  # Get latest Amazon Linux 2 AMI for ARM64
  arm64_ami=$(aws ec2 describe-images --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-arm64-gp2" "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --region $region \
    --output text 2>/dev/null || echo "NOT_SUPPORTED")
  
  # Get latest Amazon Linux 2 AMI for GPU instances (HVMG2)
  hvmg2_ami=$(aws ec2 describe-images --owners amazon \
    --filters "Name=name,Values=amzn2-ami-graphics-hvm-*" "Name=state,Values=available" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --region $region \
    --output text 2>/dev/null || echo "NOT_SUPPORTED")
  
  # Get latest Amazon Linux 2 AMI for PV (if still available, mostly for legacy)
  pv_ami=$(aws ec2 describe-images --owners amazon \
    --filters "Name=virtualization-type,Values=paravirtual" "Name=state,Values=available" "Name=name,Values=amzn-ami-pv-*" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --region $region \
    --output text 2>/dev/null || echo "NOT_SUPPORTED")
    
  # Handle if AMIs not found
  for ami_var in hvm64_ami arm64_ami hvmg2_ami pv_ami; do
    if [ "${!ami_var}" == "None" ] || [ -z "${!ami_var}" ]; then
      eval $ami_var="\"NOT_SUPPORTED\""
    fi
  done
  
  # Add to JSON (with comma except for last region)
  echo "  \"$region\": {\"HVM64\": \"$hvm64_ami\", \"ARM64\": \"$arm64_ami\", \"HVMG2\": \"$hvmg2_ami\", \"PV\": \"$pv_ami\"}," >> amis.json
done

# Remove the last comma and close JSON
sed -i '' -e '$ s/,$//' amis.json
echo "}" >> amis.json

echo "AMIs saved to amis.json with all available platforms"

echo "Updating CloudFormation template..."
# Replace the AMI ID in the CloudFormation template
# Current info is in jq .Mappings.AWSInstanceType2Arch
jq --argjson new_amis "$(cat instance-types.json)" '.Mappings.AWSInstanceType2Arch = $new_amis' WordPress_Single_Instance.template > Wordpress_Single_Instance_updated.json

# Replace default instance type with the higher "t*.small" instance type
# jq .Parameters.InstanceType.Default
jq --arg instance_type "$instance_type" '.Parameters.InstanceType.Default = $instance_type' Wordpress_Single_Instance_updated.json > Wordpress_Single_Instance_updated_default.json

# jq .Mappings.AWSRegionArch2AMI
jq --argjson new_amis "$(cat amis.json)" '.Mappings.AWSRegionArch2AMI = $new_amis' Wordpress_Single_Instance_updated_default.json > Wordpress_Single_Instance_updated_final.json

echo "Updated CloudFormation template."