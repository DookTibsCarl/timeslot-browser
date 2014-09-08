<html>

<head>
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"></script>
	<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.js"></script>
	<link rel="stylesheet" href="//code.jquery.com/ui/1.11.1/themes/smoothness/jquery-ui.css">
	<link href="grid.css" type="text/css" rel="stylesheet" />
	<script src="grid.js"></script>

	<script>
		function pageEmsForm(screensAhead) {
			reloadEmsForm(screensAhead);
		}

		function handleSelection(selectionStart, selectionEnd) {
			console.log("picker came back:");
			console.log("[" +selectionStart + "],[" + selectionEnd + "]");
			$("#demofield").val("we got [" + selectionStart + "] -----> [" + selectionEnd + "]");
		}

		function reloadEmsForm(x, initial) {
			console.log("reload form [" + x + "]");

			var ems = $("#ems");
			ems.html("reloading...");
			ems.load("grid.php", {mode:"popup", popupPagerCallback:"pageEmsForm", screensAhead:x}, function() {
				console.log("finished loading next week!");
				performGridSetup({
									popupSelectionCallback: handleSelection,
									closedTimes: [
										"Sun|7|0|10|0|closed",
										"Fri|7|0|10|0|closed",
										"Sat|7|0|10|0|closed",

										"Fri|16|0|-1|-1|closed",
										"Sat|16|0|-1|-1|closed"
									]
								});
			});

			if (initial) {
				console.log("first time open");
				  ems.dialog( "open" );
			}
		}

		$(function() {
			console.log("executing...");
			var emsDialog = $( "#ems" ).dialog({
				title: "Choose something",
			  autoOpen: false,
			  height: $(window).height() * .75,
			  width: "80%",
			  modal: true
			});

			$( "#launch-ems" ).button().on( "click", function() {
				reloadEmsForm(0, true);
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
