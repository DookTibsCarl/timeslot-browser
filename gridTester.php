<?php 
include("reason_header.php");
reason_include_once( 'minisite_templates/modules/default.php' );
include_once('sql_db.php');

?>
<html>
<head>
	<!-- <link href="/global_stock/css/signage/rec_center.css" type="text/css" rel="stylesheet" /> -->
	<link href="grid.css" type="text/css" rel="stylesheet" />
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"></script>
	<script src="grid.js"></script>
</head>
<body onLoad="performGridSetup();">

<?php
	include("grid.php");
?>

</body>
</html>
