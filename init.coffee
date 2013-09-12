#!/usr/bin/env coffee

# init.coffee - Initializes Oozoubot Mk.II with required configuration.

module.exports = do ->

  OUTFILE = 'Makefile.vars'
  VARS    = [
    'HUBOT_HIPCHAT_JID'
    'HUBOT_HIPCHAT_NAME'
    'HUBOT_HIPCHAT_PASSWORD'
    'HUBOT_HIPCHAT_ROOMS'
    'HUBOT_HIPCHAT_LOBBY_ROOM'
    'HUBOT_HIPCHAT_TOKEN'
    'HUBOT_MEMEGEN_USERNAME'
    'HUBOT_MEMEGEN_PASSWORD'
    'HUBOT_PIVOTAL_TOKEN'
    'OOZOU_WIFI'
    'OOZOU_MACMINI'
    'OOZOU_IMAC'
    'OOZOU_TIMECAPSULE'
  ]


  _ = require 'lodash'
  fs = require 'fs'
  path = require 'path'
  readline = require 'readline'

  { log } = console

  return (args...) ->
    vars = _.clone VARS
    values = { }

    input = readline.createInterface
      input: process.stdin
      output: process.stdout

    done = ->
      input.close()

      content = '# Genereated by init.coffee, run `make init` to re-initialize.\r\n'
      content += '# For heroku, issue these commands:\r\n'
      content += ("# heroku config:set #{v} \"#{value}\"" for v, value of values).join '\r\n'
      content += '\r\n'
      content += ("#{v} := #{value}" for v, value of values).join '\r\n'
      content += '\r\n'
      content += ("export #{v}" for v of values).join '\r\n'
      content += '\r\n'
      fs.writeFileSync (path.resolve __dirname, OUTFILE), content, encoding: 'utf-8'


    log 'Enter hubot environmental variable values:'

    prompt = (variable) ->
      input.question "Enter value for #{variable} : ", (answer) ->
        values[variable] = answer

        return prompt vars.shift() if vars.length
        return done() # otherwise

    prompt vars.shift()


if require.main is module
  module.exports.apply module.exports, process.argv

