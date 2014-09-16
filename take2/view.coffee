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

  buildOutDom: (@calGridCfg) -> 
    @baseElement = $(@calGridCfg.targetSelector)
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
    setupPrevNext(@calGridCfg.screensAhead);
    ###

    @stubOutGrid(@calGridCfg.screensAhead,
                @calGridCfg.daysToShow,
                @calGridCfg.slotSize,
                @calGridCfg.alternatorSize,
                @calGridCfg.hardCapStart,
                @calGridCfg.hardCapEnd);

  getElPlusSibs: (block, numSiblings) ->
    startBlock = $(block)
    if numSiblings == -1
      completeBlock = startBlock.nextAll().add(startBlock)
    else
      completeBlock = startBlock.nextAll().slice(0,numSiblings-1).add(startBlock)
    return completeBlock

  getBlockFirstElement: (block) ->
    return b.first()

  getBlockMidElement: (block) ->
    mid = Math.floor(block.length / 2)
    if b.length % 2 == 0 then mid--
    return b.eq(mid)

  attemptToHighlight: (model, originBlockReference, amount, onOrOff, altHoverBehavior = false) ->
    classForHovering = if altHoverBehavior then "hovering2" else "hovering"
    completeBlock = @getElPlusSibs(originBlockReference, amount)

    originBlock = $(originBlockReference)

    firstSlotInfo = originBlock.attr("data-slotInfo")
    lastSlotInfo = if amount == 1 then firstSlotInfo else originBlock.nextAll().slice(0,amount-1).last().attr("data-slotInfo")

    if onOrOff
      isBlockFree = model.isBlockFree(
                      TimeslotBrowser.DateUtils.extractDateFromSlotInfo(firstSlotInfo),
                      TimeslotBrowser.DateUtils.extractDateFromSlotInfo(lastSlotInfo),
                      true)
      console.log "IS BLOCK FREE NOT YET PROPERLY IMPLEMENTED"

      if isBlockFree
        completeBlock.css("cursor", "").addClass(classForHovering)
        if !altHoverBehavior
          # @getBlockMidElement(completeBlock).html("some message")
        else
          widgetPos = @calculateWidgetPosition(originBlock, "previewWindow")
          previewDate = TimeslotBrowser.DateUtils.extractDateFromSlotInfo(firstSlotInfo)
          @showPreviewWidget(widgetPos.left, widgetPos.top, TimeslotBrowser.DateUtils.previewDateFormat(previewDate))
      else
        if @isDraggingFrom != undefined
          @hideConfirmWidget()
        @hidePreviewWidget()
        completeBlock.css("cursor", "not-allowed")
    else
      if (completeBlock.first().hasClass(classForHovering))
        if !altHoverBehavior
          getBlockMidElement(completeBlock).html("")
        completeBlock.removeClass(classForHovering)

  hidePreviewWidget: () -> $("#previewWindow").css("display", "none")
  showPreviewWidget: (x, y, content) ->
    w = $("#previewWindow")
    w.css({ display: "block", left: x, top: y })
    w.html(content)

  hideConfirmWidget: () -> $("#confirmWindow").css("display", "none")
  showConfirmWidget: (x, y, content, enableButtons) ->
    w = $("#confirmWindow")
    w.css({ display: "block", left: x, top: y })

    statusHolder = $("#confirmWindow #confirmStatus")
    statusHolder.html(content)

    @enableConfirmButtons(false)
  
  calculateWidgetPosition: (originBlock, widgetName) ->
    preview = $("#" + widgetName)
    spacer = 10
    if originBlock.position().left > $("#calHolder").width() / 2
      leftPos = originBlock.position().left - preview.width() - spacer
    else
      leftPos = originBlock.position().left + originBlock.width() + spacer
    topPos = originBlock.position().top + spacer

    mainContainer = $(@calGridCfg.targetSelector)
    topPos += mainContainer.scrollTop()

    if topPos + 50 >= mainContainer.height() then topPos -= 50
    return { left: leftPos, top: topPos }

  displayBookings: (mdl) ->
    bookings = mdl.bookings
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

        neighborData = mdl.getNeighborData(booking)

        # position & dimensions
        borderPixels = parseInt(startDom.css('border-left'))

        l = startDom.position().left + borderPixels
        if neighborData.neighbors.length == 0
          w = startDom.width()
        else
          # multiple bookings overlap...
          padder = startDom.width() * .01
          widthFactor = neighborData.neighbors.length + 1
          w = startDom.width() / widthFactor - padder
          l += neighborData.position * (startDom.width() / widthFactor)

        if (endDom.length == 0)
          lastSlotOnDay = startDom.nextAll().last()
          h = lastSlotOnDay.position().top - startDom.position().top + lastSlotOnDay.height()
        else
          h = endDom.position().top - startDom.position().top

        $("<div/>").css({
          position: "absolute"
          width: w
          height: h
          left: l
          top: startDom.position().top
        }).addClass("booking").addClass(booking.style).html(booking.description).prependTo(@baseElement)
