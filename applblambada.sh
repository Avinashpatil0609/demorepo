#!/bin/bash

source test.properties

#Fetch values of subnets
SUBNET1=$(aws ec2 describe-subnets --query "Subnets[0].SubnetId" --output text)
SUBNET2=$(aws ec2 describe-subnets --query "Subnets[1].SubnetId" --output text)

#Create a application loadbalencer
alb_name=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName==\`${LOADBALENCERNAME}\`].LoadBalancerName" --output text)
if [ -z $alb_name ]
then
aws elbv2 create-load-balancer --name $LOADBALENCERNAME --subnets $SUBNET1 $SUBNET2 --security-groups $SECURITYGROUP
else
echo "Info: Load balencer name is already present, please change if new load balencer required."
fi

#Create a target group for loadbalencer
target_name=$(aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName==\`${TARGETNAME}\`].TargetGroupName" --output text)
if [ -z $target_name ]
then
aws elbv2 create-target-group --name $TARGETNAME --target-type lambda
else
echo "Info: Target group name is already present, please change if new function required."
fi

#Create a lambda function
lambda_function_name=$(aws lambda list-functions --query "Functions[?FunctionName==\`${FUNCTIONNAME}\`].FunctionName" --output text || true)
if [ -z $lambda_function_name ]
then
aws lambda create-function --function-name $FUNCTIONNAME --zip-file fileb://function.zip --handler $HANDLER --runtime $RUNTIME --role $IAMROLE
else
echo "Info: Lambda function name is already present, please change if new function required."
fi

#Add permission to lambda function
aws lambda add-permission --function-name $FUNCTIONNAME --statement-id load-balancer --action "lambda:InvokeFunction" --principal elasticloadbalancing.amazonaws.com

targetARN=$(aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName==\`${TARGETNAME}\`].TargetGroupArn" --output text)
targetlambda=$(aws lambda list-functions --query "Functions[?FunctionName==\`${FUNCTIONNAME}\`].FunctionArn" --output text)

#To register a Lambda function as a target
aws elbv2 register-targets --target-group-arn $targetARN --targets Id=$targetlambda

LoadbalencerArn=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName==\`${LOADBALENCERNAME}\`].LoadBalancerArn" --output text)

#To create a listener for load balancer with a default rule that forwards requests to target group
aws elbv2 create-listener --load-balancer-arn $LoadbalencerArn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$targetARN

#Wait for ALB to be active
state=""
while [[ $state != "active" ]];
do
 state=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName==\`${LOADBALENCERNAME}\`].State" --output text)
 sleep 10
done

#DNS name invocation to access application
Host=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName==\`${LOADBALENCERNAME}\`].DNSName" --output text)

echo $Host

#To delete ALB
#aws elbv2 delete-load-balancer --load-balancer-arn $LoadbalencerArn

#To delete Lambda function
#aws lambda delete-function --function-name $FUNCTIONNAME
