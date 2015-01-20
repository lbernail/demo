keyname=$(aws --profile lbernail --region eu-west-1 dynamodb get-item --table-name Development \
  --key '{ "application": {"S": "Common"}, "parameter" : {"S": "KeyName"}}' \
  --query Item.value.S --output text)

sg=$(aws --profile lbernail --region eu-west-1 dynamodb get-item --table-name Development \
  --key '{ "application": {"S": "Demo"}, "parameter" : {"S": "SGwebservers"}}' \
  --query Item.value.S --output text)

subnet=$(aws --profile lbernail --region eu-west-1 dynamodb get-item --table-name Development \
  --key '{ "application": {"S": "Common"}, "parameter" : {"S": "PrivateSubnet1"}}' \
  --query Item.value.S --output text)

aws --profile lbernail --region eu-west-1 ec2 run-instances \
  --image-id ami-6e7bd919 \
  --security-group-id $sg \
  --instance-type t2.micro \
  --subnet-id $subnet \
  --user-data file://loader.sh \
  --key-name $keyname \
  --iam-instance-profile Name=loader \
  --query "Instances[0].InstanceId"

