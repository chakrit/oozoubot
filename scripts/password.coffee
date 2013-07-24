module.exports = (robot) ->
  robot.respond /oozou password[s]*/i, (msg) ->
    msg.send """
    WIFI: #{process.env.OOZOU_WIFI}
    MACMINI: #{process.env.OOZOU_MACMINI}
    IMAC: #{process.env.OOZOU_IMAC}
    TIMECAPSULE: #{process.env.OOZOU_TIMECAPSULE}
    """
