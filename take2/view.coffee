class window.TimeslotBrowser.View

  constructor: (@controller) ->

  buildSingleDayCol: (holder, start, end, slotSize, alternatorSize, header, showStamp) ->
    if (header == "default")
      header = @dutils.headerDateFormat(start);

    $("<div/>").addClass("gridSlot").css("height", 15).html(header).appendTo(holder)
    stamp = start
    looper = 0

    while (stamp.getTime() <= end.getTime())
      if (showStamp)
        slot = $("<div/>").addClass("gridSlot").appendTo(holder)
        slot.html(if looper % alternatorSize == 0 then @dutils.previewDateFormat(stamp) else "&nbsp;")
      else
        $("<div/>")# .addClass("available")
          .addClass("gridSlot")
          .addClass("gridSlotRight")
          .addClass("gridSlot" + (if (looper % alternatorSize < alternatorSize/2) then "a" else "b"))
          .attr("data-dow", @dutils.dowDateFormat(stamp))
          .attr("data-slotInfo", @dutils.convertDateForSlotInfo(stamp))
          .appendTo(holder)

      stamp = new Date(stamp.getTime() + (slotSize * 60 * 1000));
      looper++;

  stubOutGrid: (screenAdvance, days, slotSize, alternatorSize, hardCapStart, hardCapEnd) ->
    console.log("stubbing [" + screenAdvance + "], [" + days + "], [" + slotSize + "]");
    startOfDay = @dutils.parseHardCap(hardCapStart);
    endOfDay = @dutils.parseHardCap(hardCapEnd);

    daysAheadOfSunday = startOfDay.getDay();
    startOfDay = new Date(startOfDay.getTime() - (@dutils.ONE_DAY * daysAheadOfSunday));
    endOfDay = new Date(endOfDay.getTime() - (@dutils.ONE_DAY * daysAheadOfSunday));

    startOfDay = new Date(startOfDay.getTime() + (@dutils.ONE_DAY * screenAdvance * days));
    endOfDay = new Date(endOfDay.getTime() + (@dutils.ONE_DAY * screenAdvance * days));

    @startOfWeek = startOfDay;

    @buildSingleDayCol($("#timesHolder"), startOfDay, endOfDay, slotSize, alternatorSize, "&nbsp;", true);

    for i in [0..days-1]
      @endOfWeek = endOfDay; # keep setting this
      column = $("<div/>").addClass("dayCol").css("width", (100 / days) + "%").appendTo($("#dayGrid"));
      @buildSingleDayCol(column, startOfDay, endOfDay, slotSize, alternatorSize, "default", false);

      startOfDay = new Date(startOfDay.getTime() + @dutils.ONE_DAY);
      endOfDay = new Date(endOfDay.getTime() + @dutils.ONE_DAY);

  buildOutDom: (@calGridCfg) -> 
    @dutils = TimeslotBrowser.DateUtils

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
    $("<input/>").attr({type: "button", value: "cancel"}).click(( () => @previewCancel() )).appendTo(buttonHolder);
    $("<input/>").attr({type: "button", value: "ok"}).click(( () => @previewOk() )).appendTo(buttonHolder);

    $("<div/>").attr("id", "highlighter").appendTo(@baseElement);

    @setupPrevNext(@calGridCfg.screensAhead);

    @stubOutGrid(@calGridCfg.screensAhead,
                @calGridCfg.daysToShow,
                @calGridCfg.slotSize,
                @calGridCfg.alternatorSize,
                @calGridCfg.hardCapStart,
                @calGridCfg.hardCapEnd);

  setupPrevNext: (currScreensAhead) ->
    holder = $("#navUi")
    holder.empty()

    # prev/next links should call some function - the grid needs fresh data to render the right subset of appointments
    prev = $("<span/>").appendTo(holder)
    if (currScreensAhead <= 0)
      prev.html("Previous")
    else
      prevLink = $("<a/>").attr("href", "#").html("Previous").appendTo(prev)

      prevLink.click(() =>
        if @calGridCfg.pagerCallback
          @calGridCfg.pagerCallback(@calGridCfg.screensAhead - 1, @calculatePseudoWeekOffset(0, -1), @calculatePseudoWeekOffset(1, -1));
        else
          @calGridCfg.screensAhead = @calGridCfg.screensAhead - 1;
          @controller.initGrid(@calGridCfg);
      )

    $("<span/>").html(" | ").appendTo(holder)

    next = $("<span/>").appendTo(holder)
    nextLink = $("<a/>").attr("href", "#").html("Next").appendTo(next)

    nextLink.click(() =>
      if @calGridCfg.pagerCallback
        @calGridCfg.pagerCallback(@calGridCfg.screensAhead + 1, @calculatePseudoWeekOffset(0, 1), @calculatePseudoWeekOffset(1, 1));
      else
        @calGridCfg.screensAhead = @calGridCfg.screensAhead + 1;
        @controller.initGrid(@calGridCfg);
    )

  calculatePseudoWeekOffset: (fencePost, direction) ->
    d = if fencePost == 0 then @startOfWeek else @endOfWeek
    d = @dutils.advanceDateByDays(d, @calGridCfg.daysToShow * direction)
    return d

  previewOk: () ->
    callbackFxn = @calGridCfg.selectionCallback
    if callbackFxn != undefined
      callbackFxn(@finalizedStart, @finalizedEnd)
    else
      console.log("No callback function ; must supply 'selectionCallback' in 'performGridSetup'...")
    @previewCancel()

  previewCancel: () ->
    @hideConfirmWidget()
    $(".hovering").removeClass("hovering").html("")

  getElPlusSibs: (block, numSiblings) ->
    startBlock = $(block)
    if numSiblings == -1
      completeBlock = startBlock.nextAll().add(startBlock)
    else
      completeBlock = startBlock.nextAll().slice(0,numSiblings-1).add(startBlock)
    return completeBlock

  getBlockFirstElement: (block) ->
    return block.first()

  getBlockMidElement: (block) ->
    mid = Math.floor(block.length / 2)
    if block.length % 2 == 0 then mid--
    return block.eq(mid)

  attemptToStartDrag: (model, originBlockReference) ->
    completeBlock = @getElPlusSibs(originBlockReference, 1)
    firstSlotDate = @dutils.extractDateFromSlotInfo(completeBlock.first().attr("data-slotInfo"))
    blockIsFree = model.isBlockFree(firstSlotDate, firstSlotDate, true)
    if blockIsFree
      console.log "start drag"
      @hidePreviewWidget()
      for hoverClass in ["hovering", "hovering2"]
        $(".#{hoverClass}").removeClass(hoverClass).html("")

      @isDraggingFrom = $(originBlockReference)
      @handleDrag()

      $("*").mouseup(() => @stopDragging())
      $(".gridSlotRight").on("touchend", () => @stopDragging())

  handleDrag: (dragTo = @isDraggingFrom) ->
    a = @dutils.extractDateFromSlotInfo(@isDraggingFrom.attr("data-slotInfo"))
    b = @dutils.extractDateFromSlotInfo(dragTo.attr("data-slotInfo"))
    console.log "handling drag, from: " + a + " to " + b

    # force on a single day
    b.setFullYear(a.getFullYear())
    b.setMonth(a.getMonth())
    b.setDate(a.getDate())

    if b.getTime() < a.getTime()
      #reverse drag - need to bump the isDraggingFrom one unit so that you can reverse drag from an appointment boundary for instance...
      a = new Date(a.getTime() + (@calGridCfg.slotSize * 60 * 1000))

    early = if a.getTime() > b.getTime() then b else a;
    late = if a.getTime() > b.getTime() then a else b;

    $("#debugger").html( "handling drag, from: " + early + " to " + late)

    earlyBlock = $("[data-slotInfo='" + @dutils.convertDateForSlotInfo(early) + "']")

    diff = (late.getTime() - early.getTime()) / 1000 / 60;

    # show in preview window
    widgetPos = @calculateWidgetPosition(earlyBlock, "confirmWindow");

    @showConfirmWidget(widgetPos.left, widgetPos.top, 
                      "start: " + @dutils.previewDateFormat(early) + "<br>" +
                      "end: " + @dutils.previewDateFormat(late) + "<br>" +
                      "(" + @dutils.diffFormat(diff) + ")",
                      false)

    return { startBlock: earlyBlock, amount: diff / @calGridCfg.slotSize }


  stopDragging: () ->
    $("*").off("mouseup")
    $(".gridSlotRight").off("touchend")
    finalBlock = $(".hovering")
    if finalBlock.length > 0
      console.log "hovering window vis"
      console.log "slot size [" + @calGridCfg.slotSize + "]"
      @finalizedStart = finalBlock.first().attr("data-slotInfo")
      @finalizedEnd = finalBlock.last().attr("data-slotInfo")

      bumpDate = @dutils.extractDateFromSlotInfo(@finalizedEnd)
      bumpDate = new Date(bumpDate.getTime() + @calGridCfg.slotSize * 60 * 1000)
      @finalizedEnd = @dutils.convertDateForSlotInfo(bumpDate)

      console.log "finished with [" + @finalizedStart + "]/[" + @finalizedEnd + "]"

      @enableConfirmButtons(true)
    else
      console.log "hovering window gone"
      @hideConfirmWidget()

    @isDraggingFrom = undefined


  attemptToHighlight: (model, originBlockReference, amount, onOrOff, altHoverBehavior = false) ->
    classForHovering = if altHoverBehavior then "hovering2" else "hovering"
    completeBlock = @getElPlusSibs(originBlockReference, amount)

    originBlock = $(originBlockReference)

    firstSlotInfo = originBlock.attr("data-slotInfo")
    lastSlotInfo = if amount == 1 then firstSlotInfo else originBlock.nextAll().slice(0,amount-1).last().attr("data-slotInfo")

    # console.log ("check #{firstSlotInfo} -> #{lastSlotInfo}")

    if onOrOff
      blockIsFree = model.isBlockFree(
                      @dutils.extractDateFromSlotInfo(firstSlotInfo),
                      @dutils.extractDateFromSlotInfo(lastSlotInfo),
                      true)#firstSlotInfo == lastSlotInfo)

      if blockIsFree
        completeBlock.css("cursor", "").addClass(classForHovering)
        if !altHoverBehavior
          # @getBlockMidElement(completeBlock).html("some message")
        else
          widgetPos = @calculateWidgetPosition(originBlock, "previewWindow")
          previewDate = @dutils.extractDateFromSlotInfo(firstSlotInfo)
          @showPreviewWidget(widgetPos.left, widgetPos.top, @dutils.previewDateFormat(previewDate))
      else
        if @isDraggingFrom != undefined
          @hideConfirmWidget()
        @hidePreviewWidget()
        completeBlock.css("cursor", "not-allowed")
    else
      if (completeBlock.first().hasClass(classForHovering))
        if !altHoverBehavior
          @getBlockMidElement(completeBlock).html("")
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

  enableConfirmButtons: (yeaOrNay) ->
    btns = $("#confirmWindow input")
    if yeaOrNay
      btns.removeAttr("disabled")
    else
      btns.attr("disabled", "disabled")
  
  calculateWidgetPosition: (originBlock, widgetName) ->
    baseLeft = originBlock.parent().position().left
    baseTop = originBlock.position().top

    # console.log(baseLeft + "," + baseTop)

    widget = $("#" + widgetName)
    spacer = 10
    if baseLeft > $("#calHolder").width() / 2
      leftPos = baseLeft - widget.width() - spacer
    else
      leftPos = baseLeft + originBlock.width() + spacer
    topPos = baseTop + spacer + 50

    mainContainer = $(@calGridCfg.targetSelector)
    topPos += mainContainer.scrollTop()

    # console.log(topPos + "..." + originBlock.parent().height())

    if topPos + 100 >= originBlock.parent().height() then topPos -= 100
    return { left: leftPos, top: topPos }

  displayBookings: (mdl) ->
    bookings = mdl.bookings
    $(".booking").remove()
    for key, data of bookings
      # console.log "add appointments for [#{key}]..."
      for booking in data
        startSlotInfo = @dutils.convertDateForSlotInfo(booking.start)
        endSlotInfo = @dutils.convertDateForSlotInfo(booking.end)
        # console.log "\t" + startSlotInfo + "->" + endSlotInfo + ", " + booking.description

        startDom = $("[data-slotInfo='" + startSlotInfo + "']")#.addClass(booking.style)
        endDom = $("[data-slotInfo='" + endSlotInfo + "']")#.addClass(booking.style)

        if (startDom.length == 0)
          # we were maybe given a booking outside displayable range
          console.log "warning; booking outside displayable range"
          continue

        neighborData = mdl.getNeighborData(booking)
        if neighborData.neighbors.length == 0
          l = 0
          w = "100%"
        else
          # console.log "got [" + neighborData.neighbors.length + "] neighbor"
          l = ((neighborData.position / (neighborData.neighbors.length+1)) * 100) + "%"
          w = (100 / ((neighborData.neighbors.length)+1)) + "%"

        minutesDifference = (booking.end.getTime() - booking.start.getTime()) / (60 * 1000)
        numChunks = minutesDifference / @calGridCfg.slotSize
        h = numChunks * startDom.first().height()

        $("<div/>").css({
          position: "relative"
          width: w
          height: h
          left: l
          top: 0
        }).addClass("booking").addClass(booking.style).html(booking.description).appendTo(startDom)
