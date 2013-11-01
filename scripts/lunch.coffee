module.exports = (robot) ->
  robot.brain.on 'loaded', =>
    unless robot.brain.data.lunch?
      db = robot.brain.data.lunch = {}
      db.people = []
      db.orders = {}
      db.left   = 0
      db.ordering = false

  robot.respond /friday lunch:?((\s+@\S+)*)\s*/i, (msg) ->
    db = robot.brain.data.lunch
    db.people = (name.toLowerCase() for name in msg.match[1].trim().split /\s+/)
    if db.people.length == 1 and db.people[0] == ''
      db.ordering = false
      msg.send "The correct syntax is: friday lunch <list of participants>"
      return
    db.orders = {}
    db.left   = db.people.length
    db.ordering = true
    msg.send "What will you guys have? Say I'll have <dish>. To add more people, say include <name> for lunch."
    return

  robot.respond /lunch list/i, (msg)->
    oauth_token = process.env.HUBOT_HIPCHAT_TOKEN
    msg.send 'Asking hipchat for user statuses ..'
    msg.http("https://api.hipchat.com/v1/users/list?format=json&auth_token=#{oauth_token}")
      .get() (err, res, body) ->
        if err
          msg.send "Hipchat says: #{err}"
          return
        users = JSON.parse(body)
        users = for u in users.users
          "@#{u.mention_name}" if u.status isnt 'offline'

        msg.send "@oozou friday lunch #{users.join(' ')}"

  robot.respond /cancel lunch/, (msg) ->
    db = robot.brain.data.lunch = {}
    db.people = []
    db.orders = {}
    db.left   = 0
    db.ordering = false
    msg.send 'Lunch has been canceled'

  robot.respond /include (.+) for lunch/i, (msg) ->
    db = robot.brain.data.lunch
    unless db.ordering
      return msg.send "We are not having lunch soon, are we?"

    additions = (name.toLowerCase() for name in msg.match[1].trim().split /\s+/)
    db.people.push.apply db.people, additions
    return msg.send "Added #{additions.length} people. Say I'll have <dish> to order!"

  robot.respond /remove (.+) from lunch/i, (msg) ->
    db = robot.brain.data.lunch
    unless db.ordering
      return msg.send "We are not having lunch soon, are we?"

    additions = (name.toLowerCase() for name in msg.match[1].trim().split /\s+/)
    for x in additions
      ind = db.people.indexOf.call db.people, x
      if ind isnt -1
        db.people.splice.call db.people, ind, 1
        db.left -= 1
        msg.send "Remove #{additions.join(', ')} from lunch"
      else
        msg.send "Oops, #{additions.join(', ')} hasn't been included in the lunch"

    if db.left is 0
      if db.people.length > 0
        output = for name, order of db.orders
          "#{name}: #{order}"
        msg.send "Well done! Here is your lunch:\n" + output.join("\n")
      else
        msg.send "Cancel lunch"

      db.ordering = false

  robot.respond /(?:i'?ll have|have|haz|can haz) (.+)/i, (msg) ->
    db = robot.brain.data.lunch
    unless db.ordering
      msg.send "I don't recall you are having lunch right now"
      return
    user = msg.message.user
    name = "@#{user.mention_name or user.name.split(' ')[0].toLowerCase()}"
    db.orders[name] = msg.match[1]
    db.people = (person for person in db.people when person isnt name)
    db.left   = db.people.length

    msg.send "#{msg.match[1]} for #{name}"

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

  robot.respond /What are we (ordering|having|eating)/i, (msg) ->
    db = robot.brain.data.lunch
    unless db.ordering
      msg.send "Nothing as far as I'm concerned"
      return
    ordered = for name, order of db.orders
      "#{name.substring(1)}: #{order}"
    unordered = for name in db.people
      "#{name.substring(1)}: STILL WAITING"
    msg.send ordered.join("\n") + "\n" + unordered.join("\n")
    return
