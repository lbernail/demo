<?php
require 'vendor/autoload.php';
use Aws\DynamoDb\DynamoDbClient;


$props = parse_ini_file("application.properties");

# Initialize DB connection
$link = mysql_connect($props['dblocation'], $props['dbuser'], $props['dbpwd']);
if (!$link) { die('Could not connect: ' . mysql_error()); }
$selected = mysql_select_db("examples",$props['database']) or die("Could not select examples");

# Initialize DynamoDB client
$client = DynamoDbClient::factory(array( 'profile' => 'default', 'region' => $props['region']));


echo "<html>\n";
echo " <head>\n";
echo "  <title>Automation Demo</title>\n";
echo " </head>\n";
echo " <body>\n";

$result = mysql_query("show tables;");
echo "<p>Database content>\n";
echo "Tables: <b>$result<b>";
echo "</p>\n";


$iterator = $client->getIterator('Scan', array( 'TableName' => 'AMI_artifacts'));
echo "<p>DynamoDB content\n";
echo "<table>\n";
echo "<tr><th>Application</th><th>Build ID</th><th>AMI</th></tr>\n";
foreach ($iterator as $item) {
  echo '<tr><td>'.$item['Application']['S'].'</td><td>'.$item['Build_ID']['S'].'</td><td>'.$item['AMI']['S']."</td></tr>\n";
}
echo "</table>\n";
echo "</p>\n";

echo " </body>\n";
echo "</html>\n";

mysql_close($link);
?> 
