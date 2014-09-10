<html>

<head>
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"></script>
	<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/jquery-ui.js"></script>
	<link rel="stylesheet" href="//code.jquery.com/ui/1.11.1/themes/smoothness/jquery-ui.css">
	<link href="grid.css" type="text/css" rel="stylesheet" />
	<script src="grid.js"></script>

	<script>
		function handleSelection(selectionStart, selectionEnd) {
			console.log("picker came back:");
			console.log("[" +selectionStart + "],[" + selectionEnd + "]");
			$("#demofield").val("we got [" + selectionStart + "] -----> [" + selectionEnd + "]");
			$("#emsCalendarDemo").dialog("close");
		}

		function handlePaging(updatedScreenAdvance, startDate, endDate) {
			console.log("need to handle paging [" + updatedScreenAdvance + "], [" + startDate + "], [" + endDate + "]");
			reloadEmsForm(updatedScreenAdvance, false);
		}

		function reloadEmsForm(screensAhead, initial) {
			var initObj = {
						selectionSize: -1,
						screensAhead: screensAhead,
						targetSelector:"#emsCalendarDemo",
						pagerCallback: handlePaging,
						selectionCallback: handleSelection,
						closedTimes: [
							"Sun|7|0|10|0|closed",
							"Fri|7|0|10|0|closed",
							"Sat|7|0|10|0|closed",

							"Fri|16|0|-1|-1|closed",
							"Sat|16|0|-1|-1|closed"
						]
					};

			if (screensAhead == 0) {
				initObj.bookedEvents =  [ "2014|9|11|14|5|14|17|study group" ]
			} else if (screensAhead == 1) {
				initObj.bookedEvents =  [ "2014|9|16|12|5|14|17|dummy event" ]
			}
			initGrid(initObj);

			if (initial) {
				$("#emsCalendarDemo").dialog("open");
			}
		}

		$(function() {
			console.log("executing...");
			var emsDialog = $( "#emsCalendarDemo" ).dialog({
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

	<div id="emsCalendarDemo">
		demo content!
	</div>

</body>
</html>
