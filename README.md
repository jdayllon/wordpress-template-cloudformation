# wordpress-template-cloudformation
Upgrade of CloudFormation Example Wordpress Template

This repo contains and updated versión of AWS Template to create a Wordpress with Amazon CloudFormation. 
The original version is on : https://cloudformation-templates-us-east-2.s3.us-east-2.amazonaws.com/WordPress_Single_Instance.template

Example launch:

    aws cloudformation create-stack \
    --stack-name wordpress-single-instance \
    --template-body file://$(pwd)/Wordpress_Single_Instance_updated_final.template \
    --parameters ParameterKey=DBName,ParameterValue=wordpressdb \
                ParameterKey=DBPassword,ParameterValue=password123 \
                ParameterKey=DBRootPassword,ParameterValue=password123 \
                ParameterKey=DBUser,ParameterValue=admin \
                ParameterKey=KeyName,ParameterValue=wordpress-key \
                ParameterKey=InstanceType,ParameterValue=t3.micro \
    --capabilities CAPABILITY_IAM

## Optional Create a KeyPair for EC2:

    aws ec2 create-key-pair --key-name wordpress-key --query 'KeyMaterial' --output text > wordpress-key.pem