
# puppet.coffee - Make bot speaks something to the main room XD
module.exports = do ->

  { HUBOT_HIPCHAT_LOBBY_ROOM } = process.env

  return (robot) ->
    robot.respond /puppet (.+)$/i, (msg) ->
      room = reply_to: HUBOT_HIPCHAT_LOBBY_ROOM
      text = msg.match[1].trim()

      robot.send room, text

