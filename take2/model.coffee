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

  recordAppointment: (start, end, clz, desc) ->
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

        @recordAppointment(new Date(actualDay[0], actualDay[1]-1, actualDay[2], chunks[1], chunks[2]),
                    if chunks[3] == -1 then null else new Date(actualDay[0], actualDay[1]-1, actualDay[2], chunks[3], chunks[4]),
                    descriptor, chunks[5])
      else
        for z in [0..6]
          chunks[z] = parseInt(chunks[z])

        @recordAppointment(new Date(chunks[0], chunks[1]-1, chunks[2], chunks[3], chunks[4]),
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


class window.TimeslotBrowser.Booking
  constructor: (@start, @end, @style, @description) ->
    # console.log "building appointment obj"
