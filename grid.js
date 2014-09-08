// this isn't super robust. DOesn't handle overlapping appointments correctly for instance.

	// var slotSize = 5; // how many minutes does a single slot on the grid equate to?
	// var selectionSize = 12;
	var calGridCfg = {};

	function extractTimeFromDateDescriptor(dateDescriptor, bump) {
		var t = Date.parse(dateDescriptor);
		if (bump) {
			t += calGridCfg.slotSize * 60 * 1000;
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

		// console.log("calc num slots for [" + startDate + "]->[" + endDate + "]...");

		var startSecs = startDate.getTime() / 1000;
		var endSecs = endDate.getTime() / 1000;
		var diffMinutes = (endSecs - startSecs) / 60;
		var slots = diffMinutes / calGridCfg.slotSize;
		// console.log(diffMinutes + " separates these; corresponds to [" + slots + "]");
		return slots;
	}

	// if a start/end stamp doesn't correspond exactly to our granularity level, adjust it
	function adjustDateForSlotSize(d, dir) {
		if (d == null) { return d; }

		var minutesOff = d.getMinutes() % calGridCfg.slotSize;

		if (minutesOff != 0) {
			if (dir == 1) { // forward
				minuteAdjustment = calGridCfg.slotSize - minutesOff;
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
		// console.log(startDate + " --> " + adjustedStart);
		// console.log(endDate + " --> " + adjustedEnd);
		var numSlots = getNumSlots(adjustedStart, adjustedEnd);
		// getElPlusSibs("[data-slotInfo='" + convertDateForSlotInfo(adjustedStart) + "']", numSlots).removeClass("available").addClass(className).first().html(visibleCopy);
		var slots = getElPlusSibs("[data-slotInfo='" + convertDateForSlotInfo(adjustedStart) + "']", numSlots);
		if (slots.first().hasClass("available")) {
			slots.removeClass("available").addClass(className).first().html(visibleCopy);
		} else {
			// this time slot was already marked with something else...
		}
	}

	function isBlockFree(block) {
		var whyFailed = "";
		if (block.length != calGridCfg.selectionSize) {
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

	// events is an array of ???; each entry takes the form of either:
	// 1. "<dow>|<hour>|<min>|<hour>|<min>|closed for some reason"
	//    ex: "Sun|7|0|10|0..." means Sunday 7am to 10am
	// 2. "<year>|<month>|<day>|<hour>|<min>|<hour>|<min>|booked by somebody"
	//	  ex: "2014|9|2|14|5|14|17..." mens "Sept 2, 2014, from 2:05 - 2:17
	function markSpecialTimes(events, classForAffectedRows) {
		if (events == null) { return; }
		// when is room open?
		// during year
		//		7:00 am to 10:00 pm monday through thursday
		//		10:00 am to 4:00 pm friday and saturday
		//		10:00 am to 10:00 pm sunday
		// during summer and break
		//		8:00 am to 5:00 pm monday through friday.

		for (var i = 0 ; i < events.length ; i++) {
			var currEvt = events[i];
			// console.log("attempt to mark off [" + currEvt + "]");
			var chunks = currEvt.split("|");
			if (isNaN(chunks[0])) {
				var actualDay = findDateArrayOfDow(chunks[0]);
				blockOffTime(new Date(actualDay[0], actualDay[1]-1, actualDay[2], chunks[1], chunks[2]),
							chunks[3] == -1 ? null : new Date(actualDay[0], actualDay[1]-1, actualDay[2], chunks[3], chunks[4]),
							classForAffectedRows, chunks[5]);
			} else {
				blockOffTime(new Date(chunks[0], chunks[1]-1, chunks[2], chunks[3], chunks[4]),
							chunks[5] == -1 ? null : new Date(chunks[0], chunks[1]-1, chunks[2], chunks[5], chunks[6]),
							classForAffectedRows, chunks[7]);
			}
		}
	}

	function setConfigDefault(param, val) {
		if (!calGridCfg[param]) {
			calGridCfg[param] = val;
		}
	}

	function performGridSetup(configObj) {
		calGridCfg = configObj ? configObj : {};	
		setConfigDefault("slotSize", 5);
		setConfigDefault("selectionSize", 12);

		// if closeOnAndBefore was supplied, mark that off completely.
		// used for instance in preventing people from picking times in the past, times today and in the past, etc.
		if (configObj.closeOnAndBefore) {
			var oneDay = 24*60*60*1000;
			var closeSentinel = new Date(Date.parse(configObj.closeOnAndBefore) + oneDay);

			var pastTimes = [];

			var loopSlotData = $(".gridSlotRight").first().attr("data-slotInfo"); // very first slot

			while (true) {
				var dateChunks = ((loopSlotData.split(","))[0]).split("-");
				var timeChunks = ((loopSlotData.split(","))[1]).split(":");
				var loopDate = new Date(dateChunks[0], dateChunks[1]-1, dateChunks[2], 0, 0, 0);

				if (loopDate.getTime() < closeSentinel.getTime()) {
					console.log("this is on or before [" + configObj.closeOnAndBefore + "]");
					pastTimes.push(dateChunks[0] + "|" + dateChunks[1] + "|" + dateChunks[2] + "|" + timeChunks[0] + "|" + timeChunks[1] + "|-1|-1|past")

					var nextSlotDate = new Date(loopDate.getTime() + oneDay);
					nextSlotDate.setHours(timeChunks[0]);
					nextSlotDate.setMinutes(timeChunks[1]);
					var nextSlot = $("[data-slotInfo^='" + convertDateForSlotInfo(nextSlotDate) + "']");
					if (nextSlot.length == 1) {
						loopSlotData = convertDateForSlotInfo(nextSlotDate);
					} else {
						break;
					}
				} else {
					break;
				}
			}

			markSpecialTimes(pastTimes, "inThePast");
		}
		markSpecialTimes(calGridCfg.closedTimes, "closed");
		markSpecialTimes(calGridCfg.bookedEvents, "booked");

		$(".gridSlotRight").click(function (evt) {
			var completeBlock = getElPlusSibs(this, calGridCfg.selectionSize);
			var outcomeBlob = isBlockFree(completeBlock);

			if (outcomeBlob.status) {
				$("#debugStatus").html("ok to select!");
				console.log("writeback please!");

				var firstSlotInfo = $(this).attr("data-slotInfo");
				var lastSlotInfo = calGridCfg.selectionSize == 1 ? firstSlotInfo : $(this).nextAll().slice(0,calGridCfg.selectionSize-1).last().attr("data-slotInfo");
				var tmpTime = Date.parse(lastSlotInfo);
				tmpTime += calGridCfg.slotSize * 60 * 1000;
				var adjustedDate = new Date(tmpTime);

				var callbackFxn = calGridCfg.popupSelectionCallback;
				if (callbackFxn) {
					// $("#demofield").val(firstSlotInfo + " - " + convertDateForSlotInfo(adjustedDate));
					callbackFxn(firstSlotInfo, convertDateForSlotInfo(adjustedDate));	
				} else {
					console.log("No callback function ; must supply 'popupSelectionCallback' in 'performGridSetup'...");
				}
				$("#ems").dialog("close");
			} else {
				$("#debugStatus").html("FAIL [" + outcomeBlob.error + "]");
			}
		});

		$(".gridSlotRight").hover(function (evt) {
			var completeBlock = getElPlusSibs(this, calGridCfg.selectionSize);

			var firstSlotInfo = $(this).attr("data-slotInfo");
			var lastSlotInfo = calGridCfg.selectionSize == 1 ? firstSlotInfo : $(this).nextAll().slice(0,calGridCfg.selectionSize-1).last().attr("data-slotInfo");

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
