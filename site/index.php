<?php
require 'vendor/autoload.php';
use Aws\DynamoDb\DynamoDbClient;


$props = parse_ini_file("application.properties");

# Initialize DB connection
$conn = new mysqli($props['dbhost'], $props['dbuser'], $props['dbpwd'],$props['database'],$props['dbport']);
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


echo "<p><h3>Database content</h3>\n";
$rs=$conn->query("show tables");
if($rs === false) {
  trigger_error('Wrong SQL: ' . $sql . ' Error: ' . $conn->error, E_USER_ERROR);
} else {
  $rs->data_seek(0);
  while($row = $rs->fetch_row()){
    echo $row[0]."<br/>";
  }
}
echo "</p>\n";


echo "<p><h3>DynamoDB content</h3>";
$iterator = $client->getIterator('Scan', array( 'TableName' => $props['ddbtable'] ));
echo "<table class='t1'>\n";
echo "<thead><tr><th>Application</th><th>Build ID</th><th>AMI</th></tr></thead>\n";
foreach ($iterator as $item) {
  echo '<tr><td>'.$item['Application']['S'].'</td><td>'.$item['Build_ID']['S'].'</td><td>'.$item['AMI']['S']."</td></tr>\n";
}
echo "</table>\n";
echo "</p>\n";

echo " </body>\n";
echo "</html>\n";

mysql_close($link);
?>
