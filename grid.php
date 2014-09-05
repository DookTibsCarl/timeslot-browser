<?php 
date_default_timezone_set("America/Chicago");

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
		
		if (isset($_POST["mode"])) {
			$this->mode = $_POST["mode"];
		} else {
			$this->mode = "unknown";
		}

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

		$html = <<<HTML
<!-- <div><span id="debugStatus">status goes here ($this->mode)</span></div> -->
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

$tc = new TibsCal();
$tc->drawCal(7, 15);
?>
