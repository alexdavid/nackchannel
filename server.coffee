dgram = require("dgram")
charm = require('charm')()

server = dgram.createSocket("udp4")
client = dgram.createSocket("udp4")

port = 41234


server.bind(port)
server.addMembership '224.0.0.0'


charm.pipe process.stdout
charm.reset()


stylize = (msg) ->
  styles = {
    blink: 5
    bold: 1
    underline: 4

    black: 30
    blue: 34
    cyan: 36
    green: 32
    magenta: 35
    red: 31
    white: 37
    yellow: 33
  }
  matcher = /{([a-z]+)}/gi
  msg.replace(matcher, (match, idx) ->
    '['+styles[idx]+'m'
  )

callout = (msg) ->
  msg.replace(new RegExp('@'+process.argv[2]+'\\b', 'g'), (match) ->
    '{magenta}'+match+'{white}'
  )

msgLine = 0
printNewMessage = (msg) ->
  if msgLine > process.stdout.getWindowSize()[1]-4
    msgLine = 0
    charm.erase 'screen'

  msg = callout(msg)
  msg = stylize(msg)

  charm.position 0, ++msgLine
  charm.write '\u0007'
  charm.write msg
  charm.display('reset')


positionForInput = ->
  charm.position 0, process.stdout.getWindowSize()[1]-2
  charm.background 'blue'
  charm.erase 'end'
  charm.position 0, process.stdout.getWindowSize()[1]-1
  charm.background 'black'


positionForInput()

stdin = process.openStdin()
stdin.on 'data', (msg) ->
  msg = new Buffer "{green}[#{process.argv[2]}]{white} #{msg.toString()}"
  client.send msg, 0, msg.length, port, '224.0.0.0', (err, bytes) ->
    positionForInput()
    charm.erase 'end'


server.on 'message', (msg, rinfo) ->
  printNewMessage msg.toString()
  positionForInput()
