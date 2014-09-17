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

<!--<link rel="stylesheet" href="//ajax.googleapis.com/ajax/libs/jquerymobile/1.4.3/jquery.mobile.min.css" />-->
<!-- <script src="//ajax.googleapis.com/ajax/libs/jquerymobile/1.4.3/jquery.mobile.min.js"></script> -->

	<!-- <script src="grid.js"></script> -->
	<script src="timeslotBrowser_0_1b.js"></script>


	<script>
		function foobar(a, b) {
			console.log("foobar [" + a + "]/[" + b + "]");
		}
		$(function() {
			var tsb = new TimeslotBrowser();
			tsb.initGrid({
						selectionCallback: foobar,
							selectionSize: -1,
						targetSelector:"#tibs",
						// closeOnAndBefore: "2014-09-08",
						closedTimes: [
							"Sun|7|0|10|0|closed",
							"Fri|16|0|-1|-1|closed",
							"Fri|7|0|10|0|closed",
							"Sat|7|0|10|0|closed",
							"Sat|16|0|-1|-1|closed"
						],
						bookedEvents: [
							"2014|9|17|9|0|10|30|breakfast",
							"2014|9|17|10|5|12|0|first class",
							"2014|9|19|14|5|14|57|study group"
						]
					});
		});
	</script>
</head>
<body>


<div id="tibs" class="sanity"></div>
<div id="debugger"></div>

</body>
</html>
