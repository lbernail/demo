<html>
 <head>
  <title>PHP Test</title>
 </head>
 <body>
 <?php
echo '<p>Hello World</p>';
$ini_array = parse_ini_file("application.properties");
print_r($ini_array);
?> 
 </body>
</html>
