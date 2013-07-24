# Description:
#   Let's make him say what you want! :D
# 
# Dependencies:
#   -
#
# Configuration:
#   -
#
# Commands:
#   room <roomname> say <msg>
#
# Author:
#   hlung@oozou.com (Fri 13 Dec 2012)
#
#-------------------------------------------------

_bot = null

# --------------------
# Get robot var for using in sending messages later on.
# --------------------
module.exports = (robot) ->
  _bot = robot

  robot.respond /room (.+) say (.+)/i, (msg) ->
    #log 'roomsay 1',msg.match[1],msg.match[2]
    roomsay(msg.match[1],msg.match[2])
    

# This works after bot joins the room. 
# So call it inside some CronJob or setInterval(fun,dur,obj)
# --------------------
roomsay = (roomname,strings) -> 
  # e.g. ROOM_RPY = { "reply_to": '13184_botlab@conf.hipchat.com'  }	
  ROOM_RPY = { "reply_to": "13184_#{roomname.toLowerCase()}@conf.hipchat.com"  }	
  _bot.send(ROOM_RPY, strings) if strings

log = (str...) => console.log str...

