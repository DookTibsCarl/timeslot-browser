// 1. fix vertical positioning of preview/confirm window
// 2. make reverse selections function better (should be able to select back from 10pm for instance
// 3. make forward selections that hit end of day work
//
// this isn't super robust. DOesn't handle overlapping appointments correctly for instance, appointments that span a day, etc.
// sort of a mess. javascript makes lots of decisions based on state of the visual grid and not on underlying data
// just something fun I banged out "quickly"

/*
	var mouse = {x: 0, y: 0};

	document.addEventListener('mousemove', function(e){ 
	    mouse.x = e.clientX || e.pageX; 
		mouse.y = e.clientY || e.pageY 
	}, false);
*/
	var finalizedStart;
	var finalizedEnd;

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

	function extractDateFromSlotInfo(si) {
		var dateAndTime = si.split(",");
		var dateChunks = (dateAndTime[0]).split("-");
		var timeChunks = (dateAndTime[1]).split(":");
		return new Date(dateChunks[0], dateChunks[1]-1, dateChunks[2], timeChunks[0], timeChunks[1]);
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

	function isBlockFree(block, expectedLength) {
		var whyFailed = "";
		if (block.length != expectedLength) {
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
		// $("#confirmButton").attr("disabled", "disabled");
		$("#confirmWindow").hover(function(evt) {
			hidePreviewWidget();
		});

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

		if (calGridCfg.selectionSize == -1) { // we have preconfigured how long a time we need
			// we want to let the user drag within a day to book a specific time
			$(".gridSlotRight").mousedown(function (evt) {
				var completeBlock = getElPlusSibs(this, 1);
				var outcomeBlob = isBlockFree(completeBlock, 1);

				if (outcomeBlob.status) {
					console.log("start drag");
					hidePreviewWidget();

					$(".hovering").removeClass("hovering").html("");
					$(".hovering2").removeClass("hovering2").html("");
					isDraggingFrom = $(this);
					handleDrag();
					$("*").mouseup(function (evt) {
						console.log("stop dragging");
						if ($(".hovering").length > 0) {
							// finalizedStart = completeBlock.first().attr("data-slotInfo");
							// finalizedEnd = getElPlusSibs(completeBlock, $(".hovering").length + 1).last().attr("data-slotInfo");
							
							var finalBlock = $(".hovering");
							finalizedStart = finalBlock.first().attr("data-slotInfo");
							finalizedEnd = finalBlock.last().next().attr("data-slotInfo");


							enableConfirmButtons(true);
						} else {
							hideConfirmWidget();
						}
						isDraggingFrom = null;
					});
				}
			});
		}


		$(".gridSlotRight").hover(function (evt) {
			if (isDraggingFrom != null) {
				var dragData = handleDrag($(this));
				hilite(dragData.startBlock, dragData.amount, evt.type=="mouseenter");
			} else {
				var altHoverBehavior = false;
				if (calGridCfg.selectionSize == -1) {
					setStatus("FOO: " + $(this).attr("data-slotInfo"));
					// return;
					altHoverBehavior = true;
				}

				var numBlocksPreview = calGridCfg.selectionSize == -1 ? 1 : calGridCfg.selectionSize;
				hilite(this, numBlocksPreview, evt.type=="mouseenter", altHoverBehavior);
			}
		});
	}

	function hilite(originBlock, amount, onOrOff, altHoverBehavior) {
		if (altHoverBehavior == null) { altHoverBehavior = false; }
		var classForHovering = "hovering";

		if (altHoverBehavior) { classForHovering = "hovering2"; }

		var completeBlock = getElPlusSibs(originBlock, amount);

		var firstSlotInfo = $(originBlock).attr("data-slotInfo");
		var lastSlotInfo = amount == 1 ? firstSlotInfo : $(originBlock).nextAll().slice(0,amount-1).last().attr("data-slotInfo");

		console.log("showing highlight from [" + firstSlotInfo + "] -> [" + lastSlotInfo + "]");

		if (onOrOff) {
			var outcomeBlob = isBlockFree(completeBlock, amount);
			var outcome = outcomeBlob.error;

			if (outcome == "") {
				outcome = "ok!";
				completeBlock.css("cursor", "");
				completeBlock.addClass(classForHovering);
				if (!altHoverBehavior) {
					// getBlockMidElement(completeBlock).html(extractTimeFromDateDescriptor(firstSlotInfo) + "->" + extractTimeFromDateDescriptor(lastSlotInfo, true));
				} else {
					var widgetPos = calculateWidgetPosition($(originBlock), "previewWindow");
					var previewDate = extractDateFromSlotInfo(firstSlotInfo);
					showPreviewWidget(widgetPos.left, widgetPos.top, previewDateFormat(previewDate));
				}
			} else {
				if (isDraggingFrom != null) {
					hideConfirmWidget();
				}
				hidePreviewWidget();
				completeBlock.css("cursor", "not-allowed");
			}

			$("#debugStatus").html("hovering over [" + firstSlotInfo + "] - " + outcome);
		} else {
			if (completeBlock.first().hasClass(classForHovering)) {
				if (!altHoverBehavior) {
					getBlockMidElement(completeBlock).html("");
				}
				completeBlock.removeClass(classForHovering);
			}
			$("#debugStatus").html("&nbsp;");
		}
	}

	var isDraggingFrom = null;
	function handleDrag(dragTo) {
		if (dragTo == null) { dragTo = isDraggingFrom; }

		var a = extractDateFromSlotInfo(isDraggingFrom.attr("data-slotInfo"));
		var b = extractDateFromSlotInfo(dragTo.attr("data-slotInfo"));

		// force on a single day
		b.setFullYear(a.getFullYear());
		b.setMonth(a.getMonth());
		b.setDate(a.getDate());

		console.log("handle drag FROM [" + a + "] TO [" + b + "]");

		var early = a.getTime() > b.getTime() ? b : a;
		var late = a.getTime() > b.getTime() ? a : b;

		var earlyBlock = $("[data-slotInfo='" + convertDateForSlotInfo(early) + "']");
		// var earlyBlock = a.getTime() > b.getTime() ? dragTo : isDraggingFrom;
		// var lateBlock = a.getTime() > b.getTime() ? isDraggingFrom : dragTo;

		var diff = (late.getTime() - early.getTime()) / 1000 / 60;
		// setStatus("BAR: " + early + " -> " + late + " (" + diff + " mins)");

		// show in preview window
		var widgetPos = calculateWidgetPosition(earlyBlock, "confirmWindow");

		showConfirmWidget(widgetPos.left, widgetPos.top, "start: " + previewDateFormat(early) + "<br>" +
											"end: " + previewDateFormat(late) + "<br>" +
											"(" + diffFormat(diff) + ")",
						false);

		return { startBlock: earlyBlock, amount: diff / calGridCfg.slotSize };
	}

	function calculateWidgetPosition(originBlock, widgetName) {
		var preview = $("#" + widgetName);
		var spacer = 10;
		var leftPos = originBlock.position().left + originBlock.width() + spacer;
		if (originBlock.position().left > $("#calHolder").width() / 2) { leftPos = originBlock.position().left - preview.width() - spacer; }
		var topPos = originBlock.position().top + spacer;

		return { left: leftPos, top: topPos };
	}

	function hidePreviewWidget() { $("#previewWindow").css("display", "none"); }
	function showPreviewWidget(x, y, content) {
		console.log("show preview widget at [" + x + "],[" + y + "] -> [" + content + "]");
		var w = $("#previewWindow");
		w.css({ display: "block", left: x, top: y });
		w.html(content);
	}

	function hideConfirmWidget() { $("#confirmWindow").css("display", "none"); }
	function showConfirmWidget(x, y, content, enableButtons) {
		var w = $("#confirmWindow");
		w.css({ display: "block", left: x, top: y });

		var statusHolder = $("#confirmWindow #confirmStatus");
		statusHolder.html(content);

		enableConfirmButtons(false);
	}

	function enableConfirmButtons(yeaOrNay) {
		var btns = $("#confirmWindow input");
		if (yeaOrNay) {
			btns.removeAttr("disabled");
		} else {
			btns.attr("disabled", "disabled");
		}
	}

	function previewOk() {
		console.log("clicked ok");

		var callbackFxn = calGridCfg.popupSelectionCallback;
		if (callbackFxn) {
			callbackFxn(finalizedStart, finalizedEnd);
		} else {
			console.log("No callback function ; must supply 'popupSelectionCallback' in 'performGridSetup'...");
		}
	}

	function previewCancel() {
		hideConfirmWidget();
		$(".hovering").removeClass("hovering").html("");
	}

	function diffFormat(minutes) {
		var hours = Math.floor(minutes / 60);
		if (hours == 0) {
			return minutes + " minutes";
		} else {
			var leftovers = minutes - (hours*60);
			var rv =  hours + " hour" + (hours == 1 ? "" : "s");
			if (leftovers != 0) {
				rv +=  ", " + leftovers + " minutes";
			}
			return rv;
		}
	}

	function previewDateFormat(d) {
		if (d.getHours() > 12) {
			return (d.getHours() - 12) + ":" + zeroPad(d.getMinutes()) + " PM";
		} else {
			return d.getHours() + ":" + zeroPad(d.getMinutes()) + (d.getHours() == 12 ? " PM" : " AM");
		}
	}

	function setStatus(s) {
		var statusLine = $("#statusLine");
		statusLine.html(s);
	}
