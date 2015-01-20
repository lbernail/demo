#!/bin/sh
yum install -y mysql
endpoint=$(aws --region eu-west-1 dynamodb get-item --table-name Development \
  --key '{ "application": {"S": "Demo"}, "parameter" : {"S": "DatabaseEndpoint"}}' \
  --query Item.value.S --output text)
dbname=$(aws --region eu-west-1 dynamodb get-item --table-name Development \
  --key '{ "application": {"S": "Demo"}, "parameter" : {"S": "DBName"}}' \
  --query Item.value.S --output text)
dbuser=$(aws --region eu-west-1 dynamodb get-item --table-name Development \
  --key '{ "application": {"S": "Demo"}, "parameter" : {"S": "DBUser"}}' \
  --query Item.value.S --output text)
dbpassword=$(aws --region eu-west-1 dynamodb get-item --table-name Development \
  --key '{ "application": {"S": "Demo"}, "parameter" : {"S": "DBPassword"}}' \
  --query Item.value.S --output text)
ddb=$(aws --region eu-west-1 dynamodb get-item --table-name Development \
  --key '{ "application": {"S": "Demo"}, "parameter" : {"S": "DynamoTable"}}' \
  --query Item.value.S --output text)

mysqldump -u cloudtrail -pcloudtrail -h bastion.aws.d2-si.eu -P 33306 cloudtrail | \
  mysql -u $dbuser -p$dbpassword $dbname -h $endpoint

echo "select substring_index(userIdentityArn,':',-1) as user,count(*) as instances from trail where eventname='RunInstances' group by user;" | \
  mysql --skip-column-names -u $dbuser -p$dbpassword $dbname -h $endpoint > /tmp/ddb.data

while read line
do
  user=$(echo $line | cut -d ' ' -f 1)
  instances=$(echo $line | cut -d ' ' -f 2)
  aws --region eu-west-1 dynamodb put-item --table-name $ddb \
    --item "{\"user\": {\"S\": \"$user\"},\"instances\":{\"N\": \"$instances\"}}"
done < /tmp/ddb.data

id=$(curl http://169.254.169.254/2014-11-05/meta-data/instance-id)
aws --region eu-west-1 ec2 terminate-instances --instance-ids $id
