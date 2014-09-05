<?php 
include("reason_header.php");
reason_include_once( 'minisite_templates/modules/default.php' );
include_once('sql_db.php');

?>
<html>
<head>
	<!-- <link href="/global_stock/css/signage/rec_center.css" type="text/css" rel="stylesheet" /> -->
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.1.0/jquery.min.js"></script>
<style>
</style>

<script>
	var slotSize = 15; // how many minutes does a single slot on the grid equate to?
	var selectionSize = 4; // say user wants an hour and 15 minutes, that's 5 slots...

	function extractTimeFromDateDescriptor(dateDescriptor, bump) {
		var t = Date.parse(dateDescriptor);
		if (bump) {
			t += slotSize * 60 * 1000;
		}
		var d = new Date(t);
		console.log(dateDescriptor + " -> [" + d + "]");

		return zeroPad(d.getHours()) + ":" + zeroPad(d.getMinutes());
	}

	function getElPlusSibs(selector, numSiblings) {
		var startBlock = $(selector);

		var completeBlock;
		if (numSiblings == -1) {
			completeBlock = startBlock.nextAll().add(startBlock);
		} else {
			completeBlock = startBlock.nextAll().slice(0,numSiblings-1).add(startBlock);
		}
		return completeBlock;
	}

	// start/end need to have been adjusted first!
	function getNumSlots(startDate, endDate) {
		if (endDate == null) { return -1; }

		console.log("calc num slots for [" + startDate + "]->[" + endDate + "]...");

		var startSecs = startDate.getTime() / 1000;
		var endSecs = endDate.getTime() / 1000;
		var diffMinutes = (endSecs - startSecs) / 60;
		var slots = diffMinutes / slotSize;
		console.log(diffMinutes + " separates these; corresponds to [" + slots + "]");
		return slots;
	}

	// if a start/end stamp doesn't correspond exactly to our granularity level, adjust it
	function adjustDateForSlotSize(d, dir) {
		if (d == null) { return d; }

		var minutesOff = d.getMinutes() % slotSize;

		if (minutesOff != 0) {
			if (dir == 1) { // forward
				minuteAdjustment = slotSize - minutesOff;
			} else { // backwards
				minuteAdjustment = -1 * minutesOff;
			}

			d = new Date(d.getTime() + (minuteAdjustment * 60 * 1000));
		}

		return d;
	}

	function zeroPad(x) {
		return (x < 10 ? "0" : "") + x;
	}

	function convertDateForSlotInfo(d) {
		return d.getFullYear() + "-" + zeroPad(d.getMonth() + 1) + "-" + zeroPad(d.getDate()) + "," + zeroPad(d.getHours()) + ":" + zeroPad(d.getMinutes());
	}

	function blockOffTime(startDate, endDate, className, visibleCopy) {
		// getElPlusSibs("[data-slotInfo='2014-Sep-06,07:00']", 12).removeClass("available").addClass("closed").first().html("closed");
		var adjustedStart = adjustDateForSlotSize(startDate, -1);
		var adjustedEnd = adjustDateForSlotSize(endDate, 1);
		var numSlots = getNumSlots(adjustedStart, adjustedEnd);
		getElPlusSibs("[data-slotInfo='" + convertDateForSlotInfo(adjustedStart) + "']", numSlots).removeClass("available").addClass(className).first().html(visibleCopy);
	}

	function isBlockFree(block) {
		var whyFailed = "";
		if (block.length != selectionSize) {
			whyFailed = "too close to end of 10pm hard limit";
		} else {
			var isWholeBlockAvail = true;
			for (var i = 0 ; i < block.length ; i++) {
				if (!block.eq(i).hasClass("available")) {
					isWholeBlockAvail = false;
					break;
				}
			}

			if (!isWholeBlockAvail) {
				whyFailed = "too close to another appointment or daily soft limits";
			}
		}

		if (whyFailed == "") {
			return { status: true, error: "" };
		} else {
			return { status: false, error: whyFailed };
		}
	}

	function getBlockMidElement(b) {
		var mid = Math.floor(b.length / 2);
		if (b.length % 2 == 0) { mid--; }
		return b.eq(mid);
	}

	function doStuff() {
		// let's add some closed times
		//       7:00 am to 10:00 pm monday through thursday
		//             10:00 am to 4:00 pm friday and saturday
		//                   10:00 am to 10:00 pm sunday
		//                      during summer and break
		//                            8:00 am to 5:00 pm monday through friday.

		blockOffTime(new Date(2014, 8, 6, 7, 0), new Date(2014, 8, 6, 10, 0), "closed", "closed");
		blockOffTime(new Date(2014, 8, 6, 16, 0), null, "closed", "closed");

		blockOffTime(new Date(2014, 8, 7, 14, 5), new Date(2014, 8, 7, 14, 17), "booked", "2:05-2:17");

		$(".gridSlotRight").click(function (evt) {
			var completeBlock = getElPlusSibs(this, selectionSize);
			var outcomeBlob = isBlockFree(completeBlock);

			if (outcomeBlob.status) {
				$("#status").html("ok to select!");
			} else {
				$("#status").html("FAIL [" + outcomeBlob.error + "]");
			}
		});

		$(".gridSlotRight").hover(function (evt) {
			var completeBlock = getElPlusSibs(this, selectionSize);

			var firstSlotInfo = $(this).attr("data-slotInfo");
			var lastSlotInfo = selectionSize == 1 ? firstSlotInfo : $(this).nextAll().slice(0,selectionSize-1).last().attr("data-slotInfo");

			if (evt.type == "mouseenter") {
				var outcomeBlob = isBlockFree(completeBlock);
				var outcome = outcomeBlob.error;

				if (outcome == "") {
					outcome = "ok!";
					completeBlock.css("cursor", "");
					completeBlock.addClass("hovering");
					getBlockMidElement(completeBlock).html(extractTimeFromDateDescriptor(firstSlotInfo) + " -> " + extractTimeFromDateDescriptor(lastSlotInfo, true));
				} else {
					completeBlock.css("cursor", "not-allowed");
				}

				$("#status").html("hovering over [" + firstSlotInfo + "] - " + outcome);
			} else {
				if (completeBlock.first().hasClass("hovering")) {
					getBlockMidElement(completeBlock).html("");
					completeBlock.removeClass("hovering");
				}
				$("#status").html("&nbsp;");
			}
		});

		/*
		// what if we want to allow selections that don't correspond to the grid granularity we've rendered with?
		$(".gridSlotRight").hover(function (evt) {
			var startBlock = $(this);
			// var vertPosInBlock = 
			var blockOffset = startBlock.offset();

			var hl = $("#highlighter");

			var hlHeight = startBlock.height() * 1.5; // an hour and a half, say

			if (evt.type == "mouseenter") {
				// console.log("blockOFfset is [" + blockOffset.left + "],[" + blockOffset.top + "]");
				// console.log("mouse is [" + evt.offsetX + "],[" + evt.offsetY + "]");
				// console.log("block is [" + startBlock.width() + "] x [" + startBlock.height() + "]");
				hl.css({display: "block", width: startBlock.width(), height: hlHeight, left: blockOffset.left + 3, top: blockOffset.top + evt.offsetY});
			}
		});
		*/
	}
</script>
</head>
<body onLoad="doStuff();">
<?php

class TibsCal {
	function __construct() {
	}

	function setupStyle() {
		$style = <<<STYLE
<style>
	#calHolder {
		width: 100%;
		// height: 100%;
		// border-style: solid;
	}
	
	.times {
		width: 10%;
		// height: 100%;
		// background-color: red;
		float:left;
		// overflow: hidden;
	}

	.dayGrid {
		width: 90%;
		// height: 100%;
		// background-color: green;
		float:left;
		// overflow: hidden;
	}

	.dayCol {
		float: left;
	}

	.gridSlot {
		height: 14px;
		font-size: 12px;
	}

	.gridSlotRight {
		border-style: solid;
		border-right: 0px;
		border-top: 0px;
		border-bottom: 0px;
		border-color: black;
		cursor: pointer;
	}

	.gridSlot0 {
		background-color: #DDDDDD ;
	}

	.gridSlot1 {
		background-color: #BBBBBB;
	}

	.hovering {
		background-color:purple;
		color: white;
	}

	.closed {
		background-color: red;
	}

	.booked {
		background-color: cyan;
		// overflow: hidden;
	}

	.gridHourBreak {
		border-top: 1px;
	}

	#highlighter {
		background-color: orange;
		display:none;
		position: absolute;
	}
</style>
STYLE;
		echo $style;
	}

	function buildSingleDayGrid($startOfDay, $endOfDay, $slotSize, $header, $showStamp) {
		if ($header == "default") {
			$header = date("D, M d", $startOfDay);
		}

		$html = "<div class='gridSlot'>$header</div>";
		$stamp = $startOfDay;
		$looper = 0;
		while ($stamp <= $endOfDay) {
			if ($showStamp) {
				$html .= "<div class='gridSlot'>" . ($looper%4==0 ? date("h:i A", $stamp) : "&nbsp;") . "</div>";
			} else {
				$hourBreaker = $looper%4==0 ? " gridHourBreak" : "";
				$html .= "<div class='available gridSlot gridSlotRight gridSlot" . ($looper%2) . "$hourBreaker' data-slotInfo='" . date("Y-m-d,H:i", $stamp) . "'>&nbsp;</div>";
			}
			$stamp += $slotSize * 60;
			$looper++;
		}
		return $html;
	}

	function drawCal($days, $slotSize) {
		$this->setupStyle();
		// echo "drawing calendar with [$slotSize] minute slots, looking out [$days] days:<P>";

		$startOfDay = strtotime("07:00:00");
		$endOfDay = strtotime("21:59:59");
		$oneDay = 24 * 60 * 60;

		$timesHtml = $this->buildSingleDayGrid($startOfDay, $endOfDay, $slotSize, "&nbsp;", true);

		$daysHtml = "";
		for ($i = 0 ; $i < $days ; $i++) {
			$startOfDay += $oneDay;
			$endOfDay += $oneDay;

			$daysHtml .= "<div class='dayCol' style='width:" . (100/$days) . "%'>";
			$daysHtml .= $this->buildSingleDayGrid($startOfDay, $endOfDay, $slotSize, "default", false);
			// $daysHtml .= $i;
			$daysHtml .= "</div>";
		}

		$foo = isset($_REQUEST["foo"]) ? $_REQUEST["foo"] : "";
		$html = <<<HTML
<div>
<span id="status">status goes here ($foo)</span>
</div>
<div id="calHolder">
	<div class="times">
		$timesHtml
	</div>
	<div class="dayGrid">
		$daysHtml
	</div>
</div>

<div id="highlighter"></div>
HTML;
		echo $html;
	}
}
?>
</head>
<?php
$tc = new TibsCal();
$tc->drawCal(7, 15);
?>
</html>
