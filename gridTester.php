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

	<script>
		$(function() {
			performGridSetup({
									selectionSize: -1,
									closeOnAndBefore: "2014-09-08",
									closedTimes: [
										"Sun|7|0|10|0|closed",
										"Fri|7|0|10|0|closed",
										"Sat|7|0|10|0|closed",

										"Fri|16|0|-1|-1|closed",
										"Sat|16|0|-1|-1|closed"
									],
									bookedEvents: [
										"2014|9|4|14|5|14|17|study group"
									]
								});
		});
	</script>
</head>
<body>

<?php
	include("grid.php");
?>

</body>
</html>
