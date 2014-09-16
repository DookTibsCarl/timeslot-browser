class window.TimeslotBrowser.Model
  constructor: () ->
    console.log "constructing model"

    ###
    bookings is an associative array. Keys are date strings like "YYYY-MM-DD". Values
    are arrays.

    Each slot in the array is an appointment object.
    ###
    @bookings = {}

  setConfig: (@calGridCfg) ->
    console.log "setting cfg on model"

  # if a start/end stamp doesn't correspond exactly to our granularity level, adjust it
  adjustDateForSlotSize: (d, dir) ->
    if d == null
      return d

    minutesOff = d.getMinutes() % @calGridCfg.slotSize;
    if (minutesOff != 0)
      if (dir == 1) # forward
        minuteAdjustment = @calGridCfg.slotSize - minutesOff;
      else
        minuteAdjustment = -1 * minutesOff;
      d = new Date(d.getTime() + (minuteAdjustment * 60 * 1000));
    d.setSeconds(0)

    return d;

  setAbsoluteRanges: (@veryFirstSlot, @veryLastSlot) ->
    console.log "setting absolute ranges (first and last visible slot) to [#{veryFirstSlot}], [#{veryLastSlot}]"

  findDateArrayOfDow: (dow) ->
    # dow is something like "Sun", "Mon", "Tue", etc.
    # returns an array of [year,month,day] that corresponds to that day of the week
    #var slotInfo = $("[data-dow='" + dow + "']").attr("data-slotInfo");
    # return slotInfo == null ? null : slotInfo.substring(0,10).split("-");
    d = new Date(@veryFirstSlot.getTime())
    looper = 0
    while true
      if TimeslotBrowser.DateUtils.prettyDowNames[d.getDay()] == dow
        return [d.getFullYear(), d.getMonth() + 1, d.getDate()]
      else
        d = TimeslotBrowser.DateUtils.advanceDateByDays(d, 1)
      looper++

      if (looper > 7)
        break
        
    return null

  getLastSlotForDate: (d) ->
    return new Date(d.getFullYear(), d.getMonth(), d.getDate(), @veryLastSlot.getHours(), @veryLastSlot.getMinutes(), @veryLastSlot.getSeconds())

  getDayStorageKey: (d) ->
    return d.getFullYear() + "-" + TimeslotBrowser.DateUtils.zeroPad(d.getMonth() + 1) + "-" + TimeslotBrowser.DateUtils.zeroPad(d.getDate())

  recordBooking: (start, end, clz, desc) ->
    if end == null
      end = @getLastSlotForDate(start)
    adjustedStart = @adjustDateForSlotSize(start, -1)
    adjustedEnd = @adjustDateForSlotSize(end, 1)
    # console.log "block off [#{adjustedStart}] -> [#{adjustedEnd}], #{clz}, #{desc}"

    if (adjustedStart.getFullYear() == adjustedEnd.getFullYear() and adjustedStart.getMonth() == adjustedEnd.getMonth() and adjustedStart.getDate() == adjustedEnd.getDate())
      key = @getDayStorageKey(adjustedStart)
      storage = @bookings[key]
      if storage == undefined then storage = []
      storage.push(new TimeslotBrowser.Booking(adjustedStart, adjustedEnd, clz, desc))
      @bookings[key] = storage
    else
      console.log "this booking spans days; not supported"

  ###
  bookingData is an array of strings each entry takes the form of either:
  1. "<dow>|<hour>|<min>|<hour>|<min>|closed for some reason"
     ex: "Sun|7|0|10|0..." means Sunday 7am to 10am
  2. "<year>|<month>|<day>|<hour>|<min>|<hour>|<min>|booked by somebody"
    ex: "2014|9|2|14|5|14|17..." means "Sept 2, 2014, from 2:05 - 2:17
  ###
  storeBookings: (bookingData, descriptor) ->
    console.log "storing [#{bookingData}] as [#{descriptor}]"
    return if bookingData == null

    for res in bookingData
      chunks = res.split("|")
      if (isNaN(chunks[0]))
        actualDay = @findDateArrayOfDow(chunks[0])
        
        for z in [1,2,3,4]
          chunks[z] = parseInt(chunks[z])

        @recordBooking(new Date(actualDay[0], actualDay[1]-1, actualDay[2], chunks[1], chunks[2]),
                    if chunks[3] == -1 then null else new Date(actualDay[0], actualDay[1]-1, actualDay[2], chunks[3], chunks[4]),
                    descriptor, chunks[5])
      else
        for z in [0..6]
          chunks[z] = parseInt(chunks[z])

        @recordBooking(new Date(chunks[0], chunks[1]-1, chunks[2], chunks[3], chunks[4]),
                    if chunks[5] == -1 then null else new Date(chunks[0], chunks[1]-1, chunks[2], chunks[5], chunks[6]),
                    descriptor, chunks[7])

  printBookings: (desc) ->
    for key, value of @bookings
      console.log "#{desc}: [#{key}]"
      for appt, i in value
        console.log "\t[#{i}]: [#{appt.start}]"

  # sorts all stored bookings by startTime
  sortBookings: () ->
    for key, value of @bookings
      value.sort( (a,b) ->
        if (a.start.getTime() < b.start.getTime())
          return -1
        else if (a.start.getTime() > b.start.getTime())
          return 1
        else
          return 0
      )
      @bookings[key] = value

  # given a starting time slot, returns info on the appointments that overlap this time
  #
  # NOT TESTED AT ALL!
  getBookingsAtTime: (d) ->
    # @calGridCfg.slotSize;
    key = @getDayStorageKey(d)
    storage = @bookings[key]
    
    rv = []
    if storage != undefined
      for b in storage
        if (b.start.getTime() <= d.getTime() and b.end.getTime() > d.getTime())
          rv.push(b)

    return rv

  ###
  given a specific booking b, get data about neighbors. Specifically what are the others, what's the max number of neighbors it will 
  overlap with, what should its position be relative to those neighbors, etc.
  for now this is going to be somewhat naive...imagine we have the following appointments on a given day:
    9am - 10:30am: breakfast
    10am - noon: study
    11:45am - 3pm: lab
  And I'm trying to figure out how to render "study". Ideally I want to know that it has breakfast and lab as neighbors, but no
  more than a single booking overlaps at any given time. This would let me do stuff like render all three at 50% column width for instance.
  This is a little tricky though, and also it's unclear how many overlapping appointments we even need to support! So for now, I'm going
  to treat this as having two neighbors. This leads to 33% column width on these guys which is a little weird, but I'm writing this so 
  we could enact a more sophisticated algorithm down the line (which would probably involve precalculating all appointments that hit any given
  5 minute block once up front, and then checking each block that b includes when calculating neighbor data)
  ###
  getNeighborData: (booking) ->
    key = @getDayStorageKey(booking.start)
    storage = @bookings[key]
    neighbors = []
    numToLeft = 0
    passeOurselves = false
    if storage != undefined
      for loopBooking in storage
        if (loopBooking.end.getTime() <= booking.start.getTime())
          continue
        else if (loopBooking.start.getTime() >= booking.end.getTime())
          break
        else
          # it's a neighbor! (or ourself)
          if (loopBooking.id != booking.id)
            passedOurselves = true

          if (loopBooking.id != booking.id)
            if (loopBooking.start.getTime() < booking.start.getTime())
              numToLeft++
            else if (loopBooking.start.getTime() == booking.start.getTime() and !passedOurselves)
              numToLeft++
            neighbors.push(loopBooking)

    return { neighbors: neighbors, position: numToLeft }
  
  isBlockFree: (startTime, endTime, advance = false) ->
    # console.log "isBlockFree? [" + startTime + "] / [" + endTime + "]"
    fakeBooking = new TimeslotBrowser.Booking(startTime, TimeslotBrowser.DateUtils.advanceDateByMinutes(endTime, if advance then @calGridCfg.slotSize else 0), "", "placeholder")
    neighborData = @getNeighborData(fakeBooking)
    return neighborData.neighbors.length == 0


class window.TimeslotBrowser.Booking
  @UNIQUE_PK = 1

  constructor: (@start, @end, @style, @description) ->
    # console.log "building appointment obj"
    @id = @constructor.UNIQUE_PK++
    console.log "built appt with [#{@id}]"
