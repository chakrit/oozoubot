module.exports = (robot) ->
  people = []
  orders = {}
  left   = 0
  ordering = false

  robot.respond /(.* )?lunch ((@\S+\s+?)+)/i, (msg) ->
    people = msg.match[1].split /\s+/
    orders = {}
    left   = people.length
    ordering = true
    msg.send "Hear, hear, let's get rolling"

  robot.respond /I'll have (.+)?/i, (msg) ->
    unless ordering
      msg.send "What am I, a waiter?"
      return
    orders[msg.message.user.name] = msg.match[1]
    people = person for person in people when person isnt msg.message.user.name
    left   = people.length
    switch left
      when 0
        output = for name, order of orders
          "#{name}: #{order}"
        msg.send "Well done! Here is your lunch:\n" + output.join("\n")
        ordering = false
      when 1
        msg.send "1 order to go, you can do it #{people[0]}, no pressure"
      when 2
        msg.send "2 orders to go, bring it on you guys #{people.join ' '}"
      else
        msg.send "#{left} orders to go"
