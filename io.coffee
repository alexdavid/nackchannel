Charm = require 'charm'
{ EventEmitter } = require 'events'


class IO extends EventEmitter

  constructor: ({ @stdin, @stdout } = process) ->
    @messages = []

    @charm = new Charm
    @charm.pipe @stdout
    @redraw()

    @stdout.on 'resize', @redraw
    @stdin.on 'data', @sendMessage


  sendMessage: (message) =>
    @emit 'message', message.toString()
    @redraw()


  printMessage: (message) ->
    @messages.push message
    @redraw()


  redraw: =>
    @charm.reset()
    @charm.position 0, 0
    for { name, message } in @messages[ -(@windowHeight() - 2).. ]
      @charm.write "[#{name}] #{message.trim()}"
      @charm.move -@windowWidth(), 1
    @charm.position 0, @windowHeight() - 1
    @charm.write ('─' for i in [0...@windowWidth()]).join('')
    @charm.position 0, @windowHeight()


  windowHeight: ->
    @stdout.getWindowSize()[1]


  windowWidth: ->
    @stdout.getWindowSize()[0]


module.exports = IO
