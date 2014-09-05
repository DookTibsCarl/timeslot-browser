	var slotSize = 5; // how many minutes does a single slot on the grid equate to?
	var selectionSize = 12;

	function extractTimeFromDateDescriptor(dateDescriptor, bump) {
		var t = Date.parse(dateDescriptor);
		if (bump) {
			t += slotSize * 60 * 1000;
		}
		var d = new Date(t);
		// console.log(dateDescriptor + " -> [" + d + "]");

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
				whyFailed = "too close to appointment or daily softlimit";
			}
		}

		if (whyFailed == "") {
			return { status: true, error: "" };
		} else {
			return { status: false, error: whyFailed };
		}
	}

	function getBlockFirstElement(b) {
		return b.first();
	}

	function getBlockMidElement(b) {
		var mid = Math.floor(b.length / 2);
		if (b.length % 2 == 0) { mid--; }
		return b.eq(mid);
	}

	function findDateArrayOfDow(dow) {
		// dow is something like "Sun", "Mon", "Tue", etc.
		// returns an array of [year,month,day] that corresponds to that day of the week
		var slotInfo = $("[data-dow='" + dow + "']").attr("data-slotInfo");

		return slotInfo == null ? null : slotInfo.substring(0,10).split("-");

		// return $("[data-dow='" + dow + "']").attr("data-slotInfo").substring(0,10).split("-");
	}

	function markClosedTimes() {
		// when is room open?
		// during year
		//		7:00 am to 10:00 pm monday through thursday
		//		10:00 am to 4:00 pm friday and saturday
		//		10:00 am to 10:00 pm sunday
		// during summer and break
		//		8:00 am to 5:00 pm monday through friday.
		
		var sunday = findDateArrayOfDow("Sun");
		var friday = findDateArrayOfDow("Fri");
		var saturday = findDateArrayOfDow("Sat");

		console.log("sunday [" + sunday + "], friday [" + friday + "], saturday [" + saturday + "]");
				
		// on Fridays/Saturdays/Sundays, closed 7am-10am
		$.each([friday, saturday, sunday], function(idx, dayOfWeek) {
			if (dayOfWeek != null) {
				blockOffTime(new Date(dayOfWeek[0], dayOfWeek[1]-1, dayOfWeek[2], 7, 0),
							new Date(dayOfWeek[0], dayOfWeek[1]-1, dayOfWeek[2], 10, 0),
							"closed", "closed");
			}
		});

		$.each([friday, saturday], function(idx, dayOfWeek) {
			if (dayOfWeek != null) { 
				blockOffTime(new Date(dayOfWeek[0], dayOfWeek[1]-1, dayOfWeek[2], 16, 0),
							null,
							"closed", "closed");
			}
		});
	}

	function markAppointmentTimes() {
		blockOffTime(new Date(2014, 8, 2, 14, 5), new Date(2014, 8, 2, 14, 17), "booked", "2:05-2:17");
	}

	function performGridSetup() {
		markClosedTimes();
		markAppointmentTimes();

		$(".gridSlotRight").click(function (evt) {
			var completeBlock = getElPlusSibs(this, selectionSize);
			var outcomeBlob = isBlockFree(completeBlock);

			if (outcomeBlob.status) {
				$("#debugStatus").html("ok to select!");
				console.log("writeback please!");

				var firstSlotInfo = $(this).attr("data-slotInfo");
				var lastSlotInfo = selectionSize == 1 ? firstSlotInfo : $(this).nextAll().slice(0,selectionSize-1).last().attr("data-slotInfo");

				$("#demofield").val("END NEEDS FIXING:" + firstSlotInfo + " - " + lastSlotInfo);
				$("#ems").dialog("close");
			} else {
				$("#debugStatus").html("FAIL [" + outcomeBlob.error + "]");
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
					getBlockMidElement(completeBlock).html(extractTimeFromDateDescriptor(firstSlotInfo) + "->" + extractTimeFromDateDescriptor(lastSlotInfo, true));
				} else {
					completeBlock.css("cursor", "not-allowed");
				}

				$("#debugStatus").html("hovering over [" + firstSlotInfo + "] - " + outcome);
			} else {
				if (completeBlock.first().hasClass("hovering")) {
					getBlockMidElement(completeBlock).html("");
					completeBlock.removeClass("hovering");
				}
				$("#debugStatus").html("&nbsp;");
			}
		});
	}
