###
bunch of date parsing/formatting functions
###
class window.TimeslotBrowser.DateUtils
  @ONE_DAY = 24*60*60*1000

  @prettyDowNames = [ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ];
  @prettyMonthNames = [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ];

  @advanceDateByDays: (d, days) ->
    return new Date(d.getTime() + days*TimeslotBrowser.DateUtils.ONE_DAY)

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

  # takes a date and returns "Sun"
  @dowDateFormat: (d) ->
    return TimeslotBrowser.DateUtils.prettyDowNames[d.getDay()]

  # takes a date and returns "YYYY-MM-DD,HH:MM"
  @convertDateForSlotInfo: (d) ->
    return d.getFullYear() + "-" + TimeslotBrowser.DateUtils.zeroPad(d.getMonth() + 1) + "-" + TimeslotBrowser.DateUtils.zeroPad(d.getDate()) + "," + TimeslotBrowser.DateUtils.zeroPad(d.getHours()) + ":" + TimeslotBrowser.DateUtils.zeroPad(d.getMinutes());

  # takes a date and returns "3:05 PM"
  @previewDateFormat: (d) ->
    if (d.getHours() > 12)
      return (d.getHours() - 12) + ":" + TimeslotBrowser.DateUtils.zeroPad(d.getMinutes()) + " PM"
    else
      return d.getHours() + ":" + TimeslotBrowser.DateUtils.zeroPad(d.getMinutes()) + (if d.getHours() == 12 then " PM" else " AM")

