#!/bin/sh

ddb=$1

echo "select substring_index(userIdentityArn,':',-1) as user,count(*) as instances from trail where eventname='RunInstances' group by user;" | \
  mysql --skip-column-names -u cloudtrail -pcloudtrail -h bastion.aws.d2-si.eu -P 33306 cloudtrail  > /tmp/ddb.data

while read line
do
  user=$(echo $line | cut -d ' ' -f 1)
  instances=$(echo $line | cut -d ' ' -f 2)
  aws --profile lbernail-admin --region eu-west-1 dynamodb put-item --table-name $ddb \
    --item "{\"user\": {\"S\": \"$user\"},\"instances\":{\"N\": \"$instances\"}}"
done < /tmp/ddb.data

