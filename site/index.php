<?php
require 'vendor/autoload.php';
use Aws\DynamoDb\DynamoDbClient;


$props = parse_ini_file("application.properties");

# Initialize DB connection
$conn = new mysqli($props['dbhost'], $props['dbuser'], $props['dbpwd'],$props['database']);
// check connection
if ($conn->connect_error) {
  trigger_error('Database connection failed: '  . $conn->connect_error, E_USER_ERROR);
}

# Initialize DynamoDB client
$client = DynamoDbClient::factory(array( 'profile' => 'default', 'region' => $props['region']));


echo "<html>\n";
echo " <head>\n";
echo "  <title>Automation Demo</title>\n";
echo "<link rel=\"stylesheet\" type=\"text/css\" href=\"demo.css\">\n";
echo " </head>\n";
echo " <body>\n";

echo "<p><h3>DynamoDB content</h3>";
$iterator = $client->getIterator('Scan', array( 'TableName' => $props['ddbtable'] ));
echo "<table class='t1'>\n";
echo "<thead><tr><th>User</th><th>Instances</th></thead>\n";
foreach ($iterator as $item) {
  echo '<tr><td>'.$item['user']['S'].'</td><td>'.$item['instances']['N']."</td></tr>\n";
}
echo "</table>\n";
echo "</p>\n";


echo "<p><h3>Database content</h3>\n";
$sql="select eventTime,userIdentityAccountId Account,substring_index(userIdentityArn,':',-1) user,substring(userAgent,1,80) userAgent from trail where eventname='RunInstances' order by eventTime desc;";
$rs=$conn->query($sql);
if($rs === false) {
  echo "Unable to retrieve data: ".$conn->error;
} else {
  echo "<table class='t1'>\n";
  echo "<thead><tr><th>Time</th><th>Account</th><th>User</th><th>User Agent</th></tr></thead>\n";
  $rs->data_seek(0);
  while($row = $rs->fetch_row()){
    echo "<tr><td>${row[0]}</td><td>${row[1]}</td><td>${row[2]}</td><td>${row[3]}</td></tr>\n";
  }
  echo "</table>\n";
}
echo "</p>\n";


echo " </body>\n";
echo "</html>\n";

?>
