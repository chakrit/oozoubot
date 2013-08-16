##############################
#   Control Spotify on OSX   #
##############################

# TODO: Split this into multiple modules, it's getting too big.
# TODO: Instead of doing `msg.send(false, msg)` we could be talk with our own
#   robot wrapper instead that always does this automatically.
#   (also removes the need for bundleDependencies as well)

_ = require 'underscore'
a = require 'async'
exec = require('child_process').exec
spotify = require 'spotify'
EventEmitter = require('events').EventEmitter

_.bindAll(spotify)


# wrap exec so shell errors and stderr are always logged
exec = _.wrap(exec, (exec_, cmd, cb) ->
  console.log "sh: #{cmd}"
  exec_ cmd, (e, stdout, stderr) ->
    return console.log(e.message or e.stack) if e?
    return console.log(stderr.toString()) if stderr

    # HACK: Re-activate Safari to display build status
    # TODO: Should instead remembers the last window and the re-open that instead of
    #   hard-coding it to be safari (and the user might be working on something else as well)
    args = arguments
    exec_ "osascript -e 'tell application \"Safari\" to activate'", (e, stdout, stderr) =>
      cb.apply @, args
)


# extend spotify with apple script controlling stuff
spotify = _.extend({ }, spotify,
  toggle: (cb) -> exec("osascript -e 'tell app \"Spotify\" to playpause'", cb)
  next: (cb) -> exec("osascript -e 'tell app \"Spotify\" to next track'", cb)
  prev: (cb) -> exec("osascript -e 'tell app \"Spotify\" to previous track'", cb)

  setVolume: (vol, cb) -> exec("osascript -e 'tell application \"Spotify\" to set sound volume to #{vol}'", cb)
  mute: (cb) -> exec("osascript -e 'tell application \"Spotify\" to set sound volume to 0'", cb)

  playTrack: (track, cb) -> exec("open #{track.href}", cb)
  getCurrentSong: (cb) ->
    setTimeout ->
      exec "osascript scripts/current_song.scpt", (e, stdout, stderr) ->
        cb(e, stdout.trim(), stderr.trim())
    , 1 # delay seems to be required for spotify to gives correct value

  search: _.wrap(_.bind(spotify.search, spotify), (search_, query, cb) ->
    queryObj =
      type: "track" # TODO: Allow other types of search
      query: query

    # add some default options to work around Spotify returning bad results
    query += " -Karaoke"

    console.log "search: searching #{query}"
    search_ queryObj, (e, data) ->
      return cb(e) if e?

      tracks = data.tracks
      tracks = [] unless tracks and tracks.length

      cb null, tracks
  )
)


# basic ad-hoc queueing support
queue = do ->
  emitter = null
  timer = null
  started = false

  return new class # TODO: probably better to just extends from EventEmitter
    constructor: ->
      @items = []
      # TODO: Save currently playing track
      # TODO: Save track start time (so we can serialize to redis)
      #   and restart timer accurately on deserialization

    start: =>
      clearTimeout(timer) if timer or started
      emitter = new EventEmitter() unless emitter

      @spinConsumeQueue()
      @started = true
      return emitter

    spinConsumeQueue: =>
      unless @items.length
        emitter.emit 'end', this
        return @stop()

      track = @items.shift()
      clearTimeout(timer) if timer?
      spotify.playTrack track, =>
        emitter.emit 'track', track
        timer = setTimeout((=> @spinConsumeQueue()), parseFloat(track.length) * 1000)

    skip: => @spinConsumeQueue() # alias
    undo: => @items.pop()

    stop: =>
      @started = false
      emitter = null
      clearTimeout(timer) if timer?
      timer = null

    queue: (track) =>
      @items.push(track)

    shuffle: =>
      for i in [0...@items.length] by 1
        randIdx = parseInt(i + Math.round(Math.random() * @items.length))
        randIdx = randIdx % @items.length

        temp = @items[i]
        @items[i] = @items[randIdx]
        @items[randIdx] = temp

    clear: =>
      @items = []


# robot control script exports
module.exports = (robot) ->

  # bot states
  opts =
    volume: 40 # up to 100 defaults to something low due to inability to sync with spotify directly
    muted: false
    results: null # last search results

  # HELP - ask for spotify-related commands
  robot.respond /help spotify$/i, (msg) ->
    helpText = [
      "play/pause/toggle/stop - Toggle pause/play",
      "play <query>           - Play the first song that matches the query",
      "play <1..n>            - Play song the #Nth song from the last search",
      "next/skip              - Plays next or previous song from the playlist",
      "current song           - Shows the currently playing song",
      "volume <up|down>       - Increase or decrease the volume",
      "volume <0..10>         - Sets the volume to specified level",
      "mute/unmute            - Mute/unmute the sound",
      "search <query>         - Search Spotify tracks",
      "",
      "Queueing ---",
      "next/skip              - Skips to next song in the queue (if in queue mode)",
      "undo/pop               - Pops the last track from the queue (in case of mistakes)",
      "shuffle                - Shuffle tracks currently in the queue",
      "queue                  - Display tracks currently in the queue",
      "queue <1..n>           - Queue the #Nth song from the last search",
      "queue <query>          - Queue the first song that matches the query",
      "queue skip             - Skips to the next song in the queue",
      "queue clear            - Clears the queue",
    ].join '\n'

    msg.send helpText


  # send message to dj room regardless of where the bot is last seen at
  # and also without triggering a notification
  # TODO: Always send to DJ room by default for all commands?
  #   except for user replies, of course.
  sendToDjRoom = (msg) ->
    # using hipchat's request api direclty since we can't do notification-less via normal api
    # TODO: Disabled temporary since the adapter doesn't seems to be able
    #   to properly handles this (HipChat API error: 401)
    console.log msg
    ###
    robot.adapter.post "/v1/rooms/message",
      room_id: process.env.HIPCHAT_DJ_ROOM_JID or ''
      from: "Oozoubot"
      notify: 0
      color: "green"
      message: msg
    , (e) ->
      console.log(e.message or e.stack) if e?
    ###

  # helper for the queue commands
  queueTrackAndRespond = (track, msg) ->
    queue.queue track
    msg.send false, "Queued #{track.name} by #{track.artists[0].name} | #{queue.items.length} total"
    console.log "queue: #{track.href}"

    unless queue.started
      ev = queue.start()
      # TODO: Probably better to handle at the room level
      #   e.g. robot.send { room: "dj" }, "now playing..."
      #   otherwise this will lock the responses to the room
      #   which started the queue
      ev.removeAllListeners()
      ev.on 'track', (track) ->
        sendToDjRoom "Now playing #{track.name} by #{track.artists[0].name} | #{queue.items.length} queued."
        sendToDjRoom "No more items in the queue." unless queue.items.length

        # TODO: say command? :p

      ev.on 'end', ->
        sendToDjRoom "Emptied the queue."

  # QUEUE - shows the current queue
  robot.respond /queue$/i, (msg) ->
    spotify.getCurrentSong (e, song) ->
      text = ["playing: #{song}"]
      text.push.apply text,
        "next up: #{track.name} by #{track.artists[0].name}" for track in queue.items

      for line in text then msg.send false, line

  # QUEUE N - queue track from search result N
  robot.respond /queue (\d+)$/i, (msg) ->
    unless opts.results and opts.results.length
      return msg.send "Please perform a search first using 'search <query>'"

    # TODO: DRY with PLAY N ? or provide spotify.getBestMatch or something
    trackIdx = parseInt(msg.match[1], 10) - 1
    track = opts.results[trackIdx]
    unless track then return msg.send(false, "Sorry, there were only #{opts.results.length} tracks available.")

    queueTrackAndRespond track, msg

  # QUEUE CLEAR - clears the queue
  robot.respond /queue clear$/i, (msg) ->
    queue.clear()
    msg.send "Queue emptied."

  # QUEUE SKIP - skips the queue
  robot.respond /queue skip$/i, (msg) ->
    msg.send false, "Queue skipped."
    queue.skip() # should cause a message to be printed from a track event.

  # POP - pops last track from the queue
  robot.respond /(undo|pop)$/, (msg) ->
    track = queue.undo()
    msg.send false, "Undo #{track.name}"

  # SHUFFLE - shuffle tracks in queue
  robot.respond /shuffle$/, (msg) ->
    queue.shuffle()
    msg.send false, "Shuffled." # TODO: Display tracks list

  # QUEUE <query> - queue first song that matches query
  robot.respond /queue (.+)$/i, (msg) ->
    # TODO: DRY searching validation/filter code
    #   or wrap as a generic search replier func
    query = (msg.match[1] or '').trim()
    return msg.send "Sorry, I couldn't understand your query." unless query
    return if msg.match[1].match(/^\d+$/) # skip queue N case

    # conflicting command
    return if query is "clear" or query is "skip"

    spotify.search query, (e, tracks) ->
      if e
        console.log(e.message or e.stack)
        return msg.send(false, "Sorry, it seems there is trouble in the Spotify land at the moment.")

      return msg.send(false, "Sorry, no tracks found for #{query}") unless tracks.length

      queueTrackAndRespond tracks[0], msg

  # PLAY/PAUSE/STOP/TOGGLE - control song state (actually just an alias to the same command)
  robot.respond /(toggle|play|pause|stop)$/i, (msg) ->
    past = switch msg.match[1]
      when "toggle" then "toggled"
      when "play" then "played"
      when "pause" then "paused"
      when "stop" then "stopped"

    spotify.toggle ->
      msg.send "Spotify #{past}."

  # NEXT - next song
  robot.respond /(skip|next|play next|play the next song)$/i, (msg) ->
    if queue.started
      queue.skip()
      return msg.send(false, "Queue skipped.")

    spotify.next ->
      spotify.getCurrentSong (e, song) ->
        msg.send(false, "Now playing #{song}")

  # PREV - previous song
  ### temporary disabled
  robot.respond /(previous|prev|play previous|play the previous song)$/i, (msg) ->
    spotify.prev ->
      spotify.getCurrentSong (e, song) ->
        msg.send "Now playing #{song}"
  ###

  # VOLUME - get the current volume
  robot.respond /vol(ume)?$/i, (msg) ->
    # TODO: Better to just use exact volume number?
    msg.send(false, "Current volume is #{opts.volume / 10}")

  # VOLUME N - set volume
  robot.respond /vol(ume)? ((\d{1,2})|up|down)$/i, (msg) ->
    volume = msg.match[2]
    volume = switch volume
      when "up" then opts.volume + 10
      when "down" then opts.volume - 10
      else # number specified
        10 * parseInt(volume, 10)

    volume = 0 if volume < 0
    volume = 100 if volume > 100
    spotify.setVolume (opts.volume = volume), ->
      msg.send(false, "Volume is now #{opts.volume / 10}")

  # MUTE/UNMUTE - toggle mute state
  robot.respond /(mute|unmute)$/i, (msg) ->
    if opts.muted
      spotify.setVolume opts.volume, -> msg.send(false, "Volume's back")
    else
      spotify.mute -> msg.send(false, "Muted")

    opts.muted = !opts.muted

  # CURRENT SONG - shows curently playing song
  robot.respond /(current|song|track|current song|current track)$/i, (msg) ->
    spotify.getCurrentSong (e, song) ->
      msg.send false, "Now playing #{song}."

  # SEARCH - search through Spotify API
  # TODO: Key search results by searcher (and use it when queueing) good idea?
  #   This is to help when multiple people make searches simultaneously in a short timespan
  robot.respond /search (.*)$/i, (msg) ->
    query = (msg.match[1] or '').trim()
    return msg.send "Sorry, I couldn't understand your query" unless query

    spotify.search query, (e, tracks) ->
      if e
        console.log(e.message or e.stack)
        return msg.send(false, "Sorry, it seems there is trouble in the Spotify land at the moment.")

      return msg.send(false, "Sorry, no tracks found for #{query}") unless tracks.length

      tracks = (tracks[i] for i in [0..4]) # limit results to just 5 tracks
      opts.results = tracks

      # compose a menu
      text = ["Spotify returned #{tracks.length} tracks for '#{query}':"]
      for track, i in tracks
        continue unless track and track.name # TODO: Crash on some search such as "ความหวาน" not sure why
        text.push "play #{i + 1}: #{track.name} by #{track.artists[0].name}"

      for line in text then msg.send(false, line)

  # PLAY N - play a track from previous search result
  robot.respond /play (\d)$/i, (msg) ->
    unless opts.results and opts.results.length
      return msg.send "Please perform a search first using 'search <query>'"

    if queue.started
      return msg.send("Please use the queue. `skip` to skip the current song.")

    trackIdx = parseInt(msg.match[1], 10) - 1
    track = opts.results[trackIdx]
    unless track then return msg.send("Sorry, there were only #{opts.results.length} tracks available.")

    spotify.playTrack track, ->
      msg.send false, "Now playing #{track.name} by #{track.artists[0].name}"

  # PLAY Q - play a track from a search query
  robot.respond /play ([^0-9].+)$/i, (msg) ->
    query = (msg.match[1] or '').trim()
    return msg.send "Sorry, I couldn't understand your query." unless query

    if queue.started
      return msg.send("Please use the queue. `skip` to skip the current song.")

    spotify.search query, (e, tracks) ->
      if e
        console.log(e.message or e.stack)
        return msg.send(false, "Sorry, it seems there is trouble in the Spotify land at the moment.")

      return msg.send(false, "Sorry, no tracks found for #{query}") unless tracks.length

      track = tracks[0]
      spotify.playTrack track, ->
        msg.send false, "Now playing #{track.name} by #{track.artists[0].name}"


# expose internal objects for testing
module.exports.spotify = spotify
module.exports.queue = queue

