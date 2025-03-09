# wordpress-template-cloudformation
Upgrade of CloudFormation Example Wordpress Template

Example launch:

    aws cloudformation create-stack \
    --stack-name wordpress-single-instance \
    --template-body file://$(pwd)/Wordpress_Single_Instance_updated_final.json \
    --parameters ParameterKey=DBName,ParameterValue=wordpressdb \
                ParameterKey=DBPassword,ParameterValue=password123 \
                ParameterKey=DBRootPassword,ParameterValue=password123 \
                ParameterKey=DBUser,ParameterValue=admin \
                ParameterKey=KeyName,ParameterValue=tu-key-pair \
    --capabilities CAPABILITY_IAM



    aws cloudformation create-stack \
    --stack-name wordpress-single-instance \
    --template-body file://$(pwd)/Wordpress_Single_Instance_updated_final.template \
    --parameters ParameterKey=DBName,ParameterValue=wordpressdb \
                 ParameterKey=DBPassword,ParameterValue=password123 \
                 ParameterKey=DBRootPassword,ParameterValue=password123 \
                 ParameterKey=DBUser,ParameterValue=admin \
                 ParameterKey=KeyName,ParameterValue=MacMini \
                 ParameterKey=InstanceType,ParameterValue=t3.micro \
    --capabilities CAPABILITY_IAM    