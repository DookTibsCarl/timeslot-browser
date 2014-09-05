<html>

<head>
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"></script>
	<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.js"></script>
	<link rel="stylesheet" href="//code.jquery.com/ui/1.11.1/themes/smoothness/jquery-ui.css">
	<script src="grid.js"></script>

	<script>
		$(function() {
			console.log("executing...");
			var emsDialog = $( "#ems" ).dialog({
			  autoOpen: false,
			  height: 400,
			  width: "80%",
			  modal: true
			});

			$( "#launch-ems" ).button().on( "click", function() {
				var ems = $("#ems");
				ems.html("loading...");
				ems.load("grid.php", {mode:"popup"}, function() {
					console.log("finished loading!");
					performGridSetup();
				});
			  emsDialog.dialog( "open" );
			});
		});
	</script>
</head>

<body>
	This is sample content: <input type="text" id="demofield" size=150>
	<p>
	<input id="launch-ems" type="button" value="spawn picker">



	<div id="ems">
		demo content!
	</div>

</body>
</html>
