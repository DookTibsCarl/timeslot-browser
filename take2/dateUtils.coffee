###
bunch of date parsing/formatting functions
###
Date.prototype.stdTimezoneOffset = (() ->
  jan = new Date(@getFullYear(), 0, 1)
  jul = new Date(@getFullYear(), 6, 1)
  return Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset())
)

Date.prototype.dst = (() ->
  return this.getTimezoneOffset() < this.stdTimezoneOffset()
)

class window.TimeslotBrowser.DateUtils
  @ONE_DAY = 24*60*60*1000

  @prettyDowNames = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ];
  @prettyMonthNames = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ];

  @advanceDateByDays: (d, days) ->
    return new Date(d.getTime() + days*TimeslotBrowser.DateUtils.ONE_DAY)

  @advanceDateByHours: (d, hours) ->
    return new Date(d.getTime() + hours*60*60*1000)

  @advanceDateByMinutes: (d, minutes) ->
    return new Date(d.getTime() + minutes*60*1000)

  @zeroPad: (x) ->
    if (x < 10)
      return "0" + x
    else
      return x


  # takes a hardcap formatted like "21:59:59" and parses that into today's date with that time
  @parseHardCap: (s) ->
    chunks = s.split(":");
    d = new Date();
    d.setHours(parseInt(chunks[0]));
    d.setMinutes(parseInt(chunks[1]));
    d.setSeconds(parseInt(chunks[2]));
    return d;

  # takes a date and returns "Sun, Jan 1"
  @headerDateFormat: (d) ->
    return TimeslotBrowser.DateUtils.prettyDowNames[d.getDay()] + ", " + TimeslotBrowser.DateUtils.prettyMonthNames[d.getMonth()] + " " + d.getDate()

  @diffFormat: (minutes) ->
    hours = Math.floor(minutes / 60)
    if hours == 0
      return minutes + " minutes"
    else
      leftovers = minutes - (hours * 60)
      rv = hours + " hour" + (if hours == 1 then "" else "s")

      if leftovers != 0
        rv += ", " + leftovers + " minutes"

      return rv

  # takes a date and returns "Sun"
  @dowDateFormat: (d) ->
    return TimeslotBrowser.DateUtils.prettyDowNames[d.getDay()]

  # takes a date and returns "YYYY-MM-DD,HH:MM"
  @convertDateForSlotInfo: (d) ->
    return d.getFullYear() + "-" + TimeslotBrowser.DateUtils.zeroPad(d.getMonth() + 1) + "-" + TimeslotBrowser.DateUtils.zeroPad(d.getDate()) + "," + TimeslotBrowser.DateUtils.zeroPad(d.getHours()) + ":" + TimeslotBrowser.DateUtils.zeroPad(d.getMinutes());

  # takes "YYYY-MM-DD,HH:MM" and returns a date
  @extractDateFromSlotInfo: (si) ->
    dateAndTime = si.split(",")
    dateChunks = (dateAndTime[0]).split("-")
    timeChunks = (dateAndTime[1]).split(":")
    return new Date(dateChunks[0], dateChunks[1]-1, dateChunks[2], timeChunks[0], timeChunks[1]);

  # takes a date and returns "3:05 PM"
  @previewDateFormat: (d) ->
    if (d.getHours() > 12)
      return (d.getHours() - 12) + ":" + TimeslotBrowser.DateUtils.zeroPad(d.getMinutes()) + " PM"
    else
      return d.getHours() + ":" + TimeslotBrowser.DateUtils.zeroPad(d.getMinutes()) + (if d.getHours() == 12 then " PM" else " AM")

