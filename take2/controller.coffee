class window.TimeslotBrowser
  constructor: () ->
    console.log "constructing after separation"
    @view = new TimeslotBrowser.View(this)
    @model = new TimeslotBrowser.Model()

  setConfigDefault: (param, val) ->
    if (!@calGridCfg[param])
      @calGridCfg[param] = val

  setupListeners: () ->
    console.log "setting up listeners"
    @setupMouseListeners()
    @setupTouchListeners()

  setupTouchListeners: () ->
    thisHook = this

    if @calGridCfg.selectionSize == -1
      $(".gridSlotRight").on("touchstart", (evt) ->
        originDiv = $(this) # where you tapped
        $("<div/>").html("tap [" + originDiv.attr("data-slotInfo") + "]").prependTo($("#debugger"))
        thisHook.view.attemptToStartDrag(thisHook.model, this)
      )

      $(".gridSlotRight").on("touchmove", (evt) ->
        evt.preventDefault()

        if (evt.originalEvent.touches.length == 1)
          touch = evt.originalEvent.touches[0]
          originDiv = $(this) # where you started dragging from
          dragDiv = $(document.elementFromPoint(touch.clientX, touch.clientY))

          dragData = thisHook.view.handleDrag($(dragDiv))
          console.log dragData
          # $("<div/>").html("moving [" + originDiv.attr("data-slotInfo") + "]/[" + dragDiv.attr("data-slotInfo") + "]!").prependTo($("#debugger"))
          $("<div/>").html("moving [" + dragData + "]").prependTo($("#debugger"))
          $(".hovering").removeClass("hovering")
          thisHook.view.attemptToHighlight(thisHook.model, dragData.startBlock, dragData.amount, true)

      )

  setupMouseListeners: () ->
    thisHook = this

    if @calGridCfg.selectionSize == -1
      $(".gridSlotRight").mousedown((evt) ->
        $("#debugger").html("mousedown!")
        thisHook.view.attemptToStartDrag(thisHook.model, this)
      )

      $(".gridSlotRight").hover((evt) ->
        if thisHook.view.isDraggingFrom != undefined
          dragData = thisHook.view.handleDrag($(this))
          thisHook.view.attemptToHighlight(thisHook.model, dragData.startBlock, dragData.amount, evt.type=="mouseenter")
        else
          altHoverBehavior = thisHook.calGridCfg.selectionSize == -1

          numBlocksPreview = if thisHook.calGridCfg.selectionSize == -1 then 1 else thisHook.calGridCfg.selectionSize
          thisHook.view.attemptToHighlight(thisHook.model, this, numBlocksPreview, evt.type=="mouseenter", altHoverBehavior)

          ###
          if (!altHoverBehavior) {
            // show in preview window
            var widgetPos = calculateWidgetPosition($(this), "confirmWindow");

            var early = extractDateFromSlotInfo($(this).attr("data-slotInfo"));
            var late = advanceDateByMinutes(early, calGridCfg.slotSize * calGridCfg.selectionSize);
            var diff = (late.getTime() - early.getTime()) / 1000 / 60;
            showConfirmWidget(widgetPos.left, widgetPos.top, "start: " + previewDateFormat(early) + "<br>" +
                              "end: " + previewDateFormat(late) + "<br>" +
                              "(" + diffFormat(diff) + ")",
                    false);
          }
          ###
            
      )

    # hide the preview widget when we move onto confirmwindow, onto another booking, or out of frame
    $("#confirmWindow").hover((evt) => @view.hidePreviewWidget())
    $(".booking").hover((evt) => @view.hidePreviewWidget())
    $("#calHolder").mouseout((evt) => @view.hidePreviewWidget())

  initGrid: (@calGridCfg) ->
    if @calGridCfg == null then @calGridCfg = {}

    if !@calGridCfg.targetSelector
      console.log "error - no target selector defined"
      return

    @setConfigDefault("slotSize", 5)                # what's the smallest increment an appointment can be booked in? 5 minute default
    @setConfigDefault("selectionSize", -1);         # do we want to enforce a selection size (12 slots for instance) or let user drag to select?
    @setConfigDefault("screensAhead", 0);
    @setConfigDefault("daysToShow", 7);
    @setConfigDefault("alternatorSize", 12);
    @setConfigDefault("hardCapStart", "07:00:00");
    @setConfigDefault("hardCapEnd", "21:59:59");

    @view.buildOutDom(@calGridCfg)

    @model.setConfig(@calGridCfg)

    # this is a little ugly - why is the view determining the start/end? living with this for now.
    @model.setAbsoluteRanges(@view.startOfWeek, @view.endOfWeek)

    if (@calGridCfg.closeOnAndBefore)
      closeSentinel = new Date(@calGridCfg.closeOnAndBefore.getTime());
      pastTimes = [];
      loopDate = new Date(@view.startOfWeek.getTime())
      loopDate.setHours(0); loopDate.setMinutes(0); loopDate.setSeconds(0); loopDate.setMilliseconds(0);

      while true
        if (loopDate.getTime() <= closeSentinel.getTime())
          pastTimes.push(loopDate.getFullYear() + "|" + (loopDate.getMonth()+1) + "|" + loopDate.getDate() + "|" + @view.startOfWeek.getHours() + "|" + @view.startOfWeek.getMinutes() + "|-1|-1|past")
          loopDate = TimeslotBrowser.DateUtils.advanceDateByDays(loopDate, 1)
        else
          break
      @model.storeBookings(pastTimes, "inThePast");

    @model.storeBookings(@calGridCfg.closedTimes, "closed");
    @model.storeBookings(@calGridCfg.bookedEvents, "booked");

    @model.sortBookings()
    # @model.printBookings("set!")

    @view.displayBookings(@model)

    ###
    $(window).resize(() =>
      @view.displayBookings(@model)
    )
    ###

    @setupListeners()
