<html>

<head>
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"></script>
	<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.js"></script>
	<link rel="stylesheet" href="//code.jquery.com/ui/1.11.1/themes/smoothness/jquery-ui.css">

	<script>
		$(function() {
			console.log("executing...");
			dialog = $( "#ems" ).dialog({
			  autoOpen: false,
			  height: 300,
			  width: 350,
			  modal: true,
			  buttons: {
				Cancel: function() {
				  dialog.dialog( "close" );
				}
			  },
			  close: function() {
				// form[ 0 ].reset();
				// allFields.removeClass( "ui-state-error" );
			  }
			});

			$( "#launch-ems" ).button().on( "click", function() {
				var ems = $("#ems");
				ems.html("loading...");
				ems.load("grid.php?foo=test", {}, function() {
					console.log("finished loading!");
				});
			  dialog.dialog( "open" );
			});
		});
	</script>
</head>

<body>
	This is sample content: <input type="text" id="demofield">
	<p>
	<input id="launch-ems" type="button" value="spawn picker">



	<div id="ems">
		demo content!
	</div>

</body>
</html>
