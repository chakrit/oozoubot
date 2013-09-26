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

  robot.hear /(http[\:\/\w\-.]+)/i, (msg) ->
    url = msg.match[1]
    http = require('http');

    http.get(url, (res) ->
      res.setEncoding('utf8')
      res.on 'data', (data) ->
        title = data.match(/<title>.+<\/title>/)
        if (title)
          title = title[0].match(/>.+</)[0]
          title = title.slice(1).slice(0, -1)
          msg.send("(oozou) #{title}")
    ).on('error', (e) ->
      msg.send("Got error: " + e.message))

  robot.hear /(pivotaltracker\.com\/s\/projects\/)(.+)(\/stories\/)(.+)/i, (msg) ->
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


  robot.hear /(pivotaltracker\.com\/story\/show\/)(.+)/i, (msg) ->
    projects = [
      { id: 202387, name: 'xenapto' }
      { id: 133661, name: 'AT' }
      { id: 653125, name: 'fingi' }
    ]
    story_id = msg.match[2]

    for project in projects
      do (project) ->
        https = require('https')
        options =
          hostname: 'www.pivotaltracker.com'
          path: "/services/v3/projects/#{project.id}/stories/#{story_id}"
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
            # else # problem occurs
            #   error = data.match(/<message>.+<\/message>/)
            #   error = error[0].match(/>.+</)[0]
            #   error = error.slice(1).slice(0, -1)
            #   console.log error
        ).on('error', (e) ->
          msg.send('problem with request: ' + e.message))
