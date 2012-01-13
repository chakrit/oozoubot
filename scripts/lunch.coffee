module.exports = (robot) ->
  robot.brain.on 'loaded', =>
    unless robot.brain.data.lunch?
      db = robot.brain.data.lunch = {}
      db.people = []
      db.orders = {}
      db.left   = 0
      db.ordering = false

  robot.respond /(.* )?lunch( with:?)?((\s*@\S+)*)/i, (msg) ->
    db = robot.brain.data.lunch
    people = (name.toLowerCase() for name in msg.match[3].trim().split /\s+/)
    if people.length == 0
      msg.send "Can you let me know who's in the office today?"
      return
    db.people = people
    db.orders = {}
    db.left   = db.people.length
    db.ordering = true
    msg.send "Hear, hear, let's get rolling"
    return

  robot.respond /I'll have (.+)/i, (msg) ->
    db = robot.brain.data.lunch
    unless db.ordering
      msg.send "What am I, a waiter?"
      return
    name      = '@' + msg.message.user.name.split(' ')[0].toLowerCase()
    db.orders[name] = msg.match[1]
    db.people = (person for person in db.people when person isnt name)
    db.left   = db.people.length
    switch db.left
      when 0
        output = for name, order of db.orders
          "#{name}: #{order}"
        msg.send "Well done! Here is your lunch:\n" + output.join("\n")
        db.ordering = false
      when 1
        msg.send "1 order to go, you can do it #{db.people[0]}, no pressure"
      when 2
        msg.send "2 orders to go, bring it on you guys #{db.people[0]} #{db.people[1]}"
      else
        msg.send "#{db.left} orders to go"
    return

  robot.respond /What are we ordering/i, (msg) ->
    db = robot.brain.data.lunch
    unless db.ordering
      msg.send "Nothing as far as I'm concerned"
      return
    ordered = for name, order of db.orders
      "#{name}: #{order}"
    unordered = for name in db.people
      "#{name}: STILL WAITING"
    msg.send ordered.join("\n") + "\n" + unordered.join("\n")
    return
