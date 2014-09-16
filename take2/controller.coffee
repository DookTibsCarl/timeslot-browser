class window.TimeslotBrowser
  constructor: () ->
    console.log "constructing after separation"
    @view = new TimeslotBrowser.View()
    @model = new TimeslotBrowser.Model()

  setConfigDefault: (param, val) ->
    if (!@calGridCfg[param])
      @calGridCfg[param] = val

  setupListeners: () ->
    console.log "setting up listeners"
    thisHook = this
    $(".gridSlotRight").hover((evt) ->
      if false
        console.log "BLAH"
      else
        altHoverBehavior = thisHook.calGridCfg.selectionSize == -1

        numBlocksPreview = if thisHook.calGridCfg.selectionSize == -1 then 1 else thisHook.calGridCfg.selectionSize
        thisHook.view.attemptToHighlight(thisHook.model, this, numBlocksPreview, evt.type=="mouseenter", altHoverBehavior)
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

    console.log "NOT YET SUPPORTING 'CLOSED BEFORE' STYLE BOOKINGS..."
    @model.storeBookings(@calGridCfg.closedTimes, "closed");
    @model.storeBookings(@calGridCfg.bookedEvents, "booked");

    @model.sortBookings()
    # @model.printBookings("set!")

    @view.displayBookings(@model)

    $(window).resize(() =>
      @view.displayBookings(@model)
    )

    @setupListeners()
