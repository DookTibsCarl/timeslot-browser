class window.TimeslotBrowser.View

  buildSingleDayCol: (holder, start, end, slotSize, alternatorSize, header, showStamp) ->
    if (header == "default")
      header = TimeslotBrowser.DateUtils.headerDateFormat(start);

    $("<div/>").addClass("gridSlot").css("height", 15).html(header).appendTo(holder)
    stamp = start
    looper = 0

    while (stamp.getTime() <= end.getTime())
      if (showStamp)
        slot = $("<div/>").addClass("gridSlot").appendTo(holder)
        slot.html(if looper % alternatorSize == 0 then TimeslotBrowser.DateUtils.previewDateFormat(stamp) else "&nbsp;")
      else
        $("<div/>")# .addClass("available")
          .addClass("gridSlot")
          .addClass("gridSlotRight")
          .addClass("gridSlot" + (if (looper % alternatorSize < alternatorSize/2) then "a" else "b"))
          .attr("data-dow", TimeslotBrowser.DateUtils.dowDateFormat(stamp))
          .attr("data-slotInfo", TimeslotBrowser.DateUtils.convertDateForSlotInfo(stamp))
          .appendTo(holder)

      stamp = new Date(stamp.getTime() + (slotSize * 60 * 1000));
      looper++;

  stubOutGrid: (screenAdvance, days, slotSize, alternatorSize, hardCapStart, hardCapEnd) ->
    console.log("stubbing [" + screenAdvance + "], [" + days + "], [" + slotSize + "]");
    startOfDay = TimeslotBrowser.DateUtils.parseHardCap(hardCapStart);
    endOfDay = TimeslotBrowser.DateUtils.parseHardCap(hardCapEnd);

    daysAheadOfSunday = startOfDay.getDay();
    startOfDay = new Date(startOfDay.getTime() - (TimeslotBrowser.DateUtils.ONE_DAY * daysAheadOfSunday));
    endOfDay = new Date(endOfDay.getTime() - (TimeslotBrowser.DateUtils.ONE_DAY * daysAheadOfSunday));

    startOfDay = new Date(startOfDay.getTime() + (TimeslotBrowser.DateUtils.ONE_DAY * screenAdvance * days));
    endOfDay = new Date(endOfDay.getTime() + (TimeslotBrowser.DateUtils.ONE_DAY * screenAdvance * days));

    @startOfWeek = startOfDay;

    @buildSingleDayCol($("#timesHolder"), startOfDay, endOfDay, slotSize, alternatorSize, "&nbsp;", true);

    for i in [0..days-1]
      @endOfWeek = endOfDay; # keep setting this
      column = $("<div/>").addClass("dayCol").css("width", (100 / days) + "%").appendTo($("#dayGrid"));
      @buildSingleDayCol(column, startOfDay, endOfDay, slotSize, alternatorSize, "default", false);

      startOfDay = new Date(startOfDay.getTime() + TimeslotBrowser.DateUtils.ONE_DAY);
      endOfDay = new Date(endOfDay.getTime() + TimeslotBrowser.DateUtils.ONE_DAY);

  buildOutDom: (cfg) -> 
    @baseElement = $(cfg.targetSelector)
    @baseElement.empty()
    gridUiEl = $("<div/>").attr("id", "gridUi").appendTo(@baseElement);
    $("<span/>").css("margin-left", 5).attr("id", "navUi").html("PAGE NAV HERE").appendTo(gridUiEl);

    calHolderEl = $("<div/>").attr("id", "calHolder").appendTo(@baseElement);
    $("<div/>").attr("id", "timesHolder").addClass("times").appendTo(calHolderEl);
    gridEl = $("<div/>").attr("id", "dayGrid").addClass("dayGrid").appendTo(calHolderEl);

    previewWindowEl = $("<div/>").attr("id", "previewWindow").addClass("simpleFloater").appendTo(@baseElement);
    confirmWindowEl = $("<div/>").attr("id", "confirmWindow").addClass("simpleFloater").appendTo(@baseElement);

    $("<div/>").attr("id", "confirmStatus").appendTo(confirmWindowEl);
    buttonHolder = $("<div/>").appendTo(confirmWindowEl);
    # $("<input/>").attr({type: "button", value: "cancel"}).click(previewCancel).appendTo(buttonHolder);
    # $("<input/>").attr({type: "button", value: "ok"}).click(previewOk).appendTo(buttonHolder);

    $("<div/>").attr("id", "highlighter").appendTo(@baseElement);

    ###
    setupPrevNext(cfg.screensAhead);
    ###

    @stubOutGrid(cfg.screensAhead,
                cfg.daysToShow,
                cfg.slotSize,
                cfg.alternatorSize,
                cfg.hardCapStart,
                cfg.hardCapEnd);

  getNeighborData: (bookings, b) ->
    # THIS SHOULD LIVE IN THE MODEL!!!!!!! PUT IT THERE WHEN I IMPLEMENT!!!!!
    # should return what?
    console.log "getMaxNeighbors not yet implemented! need this for overlapping appointments"
    return 0

  displayBookings: (bookings) ->
    $(".booking").remove()
    for key, data of bookings
      console.log "add appointments for [#{key}]..."
      for booking in data
        startSlotInfo = TimeslotBrowser.DateUtils.convertDateForSlotInfo(booking.start)
        endSlotInfo = TimeslotBrowser.DateUtils.convertDateForSlotInfo(booking.end)
        console.log "\t" + startSlotInfo + "->" + endSlotInfo + ", " + booking.description

        startDom = $("[data-slotInfo='" + startSlotInfo + "']")#.addClass(booking.style)
        endDom = $("[data-slotInfo='" + endSlotInfo + "']")#.addClass(booking.style)

        if (startDom.length == 0)
          # we were maybe given a booking outside displayable range
          console.log "warning; booking outside displayable range"
          continue

        numNeighbors = @getNeighborData(bookings, booking)
        widthFactor = numNeighbors + 1

        w = startDom.width() / widthFactor
        if (endDom.length == 0)
          lastSlotOnDay = startDom.nextAll().last()
          h = lastSlotOnDay.position().top - startDom.position().top + lastSlotOnDay.height()
        else
          h = endDom.position().top - startDom.position().top

        borderPixels = parseInt(startDom.css('border-left'))

        $("<div/>").css({
          position: "absolute"
          width: w
          height: h
          left: startDom.position().left + borderPixels
          top: startDom.position().top
        }).addClass("booking").addClass(booking.style).html(booking.description).appendTo(@baseElement)
