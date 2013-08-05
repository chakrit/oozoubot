# Grab XKCD comic image urls
#
# xkcd       - The latest XKCD comic
# xkcd <num> - XKCD comic matching the supplied number
#
module.exports = (robot) ->
  robot.respond /xkcd\s?(\d+)?/i, (msg) ->
    if msg.match[1] == undefined
      num = ''
    else
      num = "#{msg.match[1]}/"

    msg.http("http://xkcd.com/#{num}info.0.json")
      .get() (err, res, body) ->
        if res.statusCode == 404
          msg.send 'Comic not found.'
        else
          object = JSON.parse(body)
          msg.send object.alt
          msg.send object.title
          msg.send object.img

  robot.hear /(http:\/\/pantip.com\/topic\/)(.+)/i, (msg) ->
    topic_id = msg.match[2]
    http = require('http');

    http.get("http://pantip.com/topic/#{topic_id}", (res) ->
      res.setEncoding('utf8')
      res.on 'data', (data) ->
        title = data.match(/<title>.+<\/title>/)
        if (title)
          title = title[0].match(/>.+</)[0]
          title = title.slice(1).slice(0, -1)
          msg.send(title)
    ).on('error', (e) ->
      msn.send("Got error: " + e.message))

  robot.hear /(https:\/\/www\.pivotaltracker\.com\/s\/projects\/)(.+)(\/stories\/)(.+)/i, (msg) ->
    project_id = msg.match[2]
    story_id = msg.match[4]

    https = require('https')
    options =
      hostname: 'www.pivotaltracker.com'
      path: "/services/v3/projects/#{project_id}/stories/#{story_id}"
      method: 'GET'
      headers:
        'X-TrackerToken': process.env.HUBOT_PIVOTAL_TOKEN

    https.get(options, (res) ->
      res.setEncoding 'utf8'
      res.on 'data', (data) ->
        name = data.match(/<name>.+<\/name>/)
        if (name)
          name = name[0].match(/>.+</)[0]
          name = name.slice(1).slice(0, -1)

          ent = require 'ent'
          msg.send("(pivotal) #{ent.decode name}")
    ).on('error', (e) ->
      msg.send('problem with request: ' + e.message))
