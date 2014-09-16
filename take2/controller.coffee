class window.TimeslotBrowser
  constructor: () ->
    console.log "constructing after separation"
    @view = new TimeslotBrowser.View()
    @model = new TimeslotBrowser.Model()

  setConfigDefault: (param, val) ->
    if (!@calGridCfg[param])
      @calGridCfg[param] = val

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

    @view.displayBookings(@model.bookings)

    $(window).resize(() =>
      @view.displayBookings(@model.bookings)
    )
