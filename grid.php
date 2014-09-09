<?php 
date_default_timezone_set("America/Chicago");

/*
 * You must include:
 *	# JQuery
 *	# grid.js
 *	# grid.css
 *
 * Or things will not look/function very well...
 *
 * This is intended to be used in a JQuery modal dialog but it could easily be modified for other contexts
 *
 */

class CalendarSlotPickerWidget {
	function buildSingleDayGrid($startOfDay, $endOfDay, $slotSize, $header, $showStamp) {
		if ($header == "default") {
			$header = date("D, M d", $startOfDay);
		}

		$html = "<div class='gridSlot' style='height:15px'>$header</div>";
		$stamp = $startOfDay;
		$looper = 0;
		while ($stamp <= $endOfDay) {
			if ($showStamp) {
				$html .= "<div class='gridSlot'>" . ($looper%$this->alternatorSize==0 ? date("h:i A", $stamp) : "&nbsp;") . "</div>";
			} else {
				// $hourBreaker = $looper%4==0 ? " gridHourBreak" : "";
				$hourBreaker = "";
				$html .= "<div class='available gridSlot gridSlotRight gridSlot" . ($looper%$this->alternatorSize < ($this->alternatorSize/2) ? "a" : "b") . "$hourBreaker' data-dow='" . date("D", $stamp) . "' data-slotInfo='" . date("Y-m-d,H:i", $stamp) . "'>&nbsp;</div>";
			}
			$stamp += $slotSize * 60;
			$looper++;
		}
		return $html;
	}

	function buildPager($replacements) {
		$rv = "";
		foreach (Array("screensAhead", "chunkSize", "daysToShow", "alternatorSize", "hardCapStart", "hardCapEnd") as $param) {
			if (isset($replacements[$param])) {
				$rv .= ($rv == "" ? "?" : "&") . $param . "=" . $replacements[$param];
			} else if (isset($_REQUEST[$param])) {
				$rv .= ($rv == "" ? "?" : "&") . $param . "=" . $_REQUEST[$param];
			}
		}
		return $rv;
	}

	function drawCal($screenAdvance, $days, $slotSize, $alternatorSize, $hardCapStart, $hardCapEnd, $popupPagerCallback) {
		$this->alternatorSize = $alternatorSize;
		$this->screenOffset = $screenAdvance;
		
		if (isset($_POST["mode"])) {
			$this->mode = $_POST["mode"];
		} else {
			$this->mode = "unknown";
		}

		$startOfDay = strtotime($hardCapStart);
		$endOfDay = strtotime($hardCapEnd);
		$oneDay = 24 * 60 * 60;

		// back up to Sunday
		$daysAheadOfSunday = date("w", $startOfDay);
		$startOfDay -= $oneDay * $daysAheadOfSunday;
		$endOfDay -= $oneDay * $daysAheadOfSunday;

		$startOfDay += $oneDay * $screenAdvance*$days;
		$endOfDay += $oneDay * $screenAdvance*$days;

		$timesHtml = $this->buildSingleDayGrid($startOfDay, $endOfDay, $slotSize, "&nbsp;", true);

		$daysHtml = "";
		for ($i = 0 ; $i < $days ; $i++) {
			$daysHtml .= "<div class='dayCol' style='width:" . (100/$days) . "%'>";
			$daysHtml .= $this->buildSingleDayGrid($startOfDay, $endOfDay, $slotSize, "default", false);
			// $daysHtml .= $i;
			$daysHtml .= "</div>";

			$startOfDay += $oneDay;
			$endOfDay += $oneDay;
		}

		$weekNav = "";

		if ($this->mode == "popup") {
			if ($this->screenOffset > 0) { $weekNav .= "<a href='#' onClick='$popupPagerCallback(" . ($this->screenOffset-1) . ");'>Previous</a>"; } else { $weekNav .= "Previous"; }
			$weekNav .= " | ";
			$weekNav .= "<a href='#' onClick='$popupPagerCallback(" . ($this->screenOffset+1) . ");'>Next</a>";
		} else {
			if ($this->screenOffset > 0) { $weekNav .= "<a href='" . $this->buildPager(Array("screensAhead" => $this->screenOffset-1)) . "'>Previous</a>"; } else { $weekNav .= "Previous"; }
			$weekNav .= " | ";
			$weekNav .= "<a href='" . $this->buildPager(Array("screensAhead" => $this->screenOffset+1)) . "'>Next</a>";
		}

		$html = <<<HTML
<div><span id="debugStatus">status goes here ($this->mode)</span></div>
<div id="gridUi">
	<span style="margin-left: 5px">$weekNav</span>
<!--
	<span style="float:right; margin-right: 20px">
		<span id="statusLine"></span>
		<span id="okHolder"><input type="button" id="confirmButton" value="ok"/></span>
-->
</div>
<div id="calHolder">
	<div class="times">
		$timesHtml
	</div>
	<div class="dayGrid">
		$daysHtml
	</div>
</div>

<div id="previewWindow" class="simpleFloater">
</div>

<div id="confirmWindow" class="simpleFloater">
	<div id="confirmStatus"></div>
	<div>
		<input type="button" value="cancel" onClick="previewCancel();">
		<input type="button" value="ok" onClick="previewOk();">
	</div>
</div>

<div id="highlighter"></div>
HTML;
		echo $html;
	}
}

function getParam($paramName, $defaultVal) {
	return isset($_REQUEST[$paramName]) ? $_REQUEST[$paramName] : $defaultVal;
}

// look in params for some ways to customize the display
$screenOffset = max(getParam("screensAhead", 0), 0);
$chunkSize = getParam("chunkSize", 5);
$daysToShow = getParam("daysToShow", 7);
$alternatorSize = getParam("alternatorSize", 12);
$hcStart = getParam("hardCapStart", "07:00:00");
$hcEnd = getParam("hardCapEnd", "21:59:59");
$popupPagerCallback = getParam("popupPagerCallback", "calendarPagerCallback");

$tc = new CalendarSlotPickerWidget();
$tc->drawCal($screenOffset, $daysToShow, $chunkSize, $alternatorSize, $hcStart, $hcEnd, $popupPagerCallback);
?>
