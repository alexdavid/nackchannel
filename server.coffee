dgram = require("dgram")
charm = require('charm')()

server = dgram.createSocket("udp4")
client = dgram.createSocket("udp4")

port = 41234


server.bind(port)
server.addMembership '224.0.0.0'


charm.pipe process.stdout
charm.reset()


msgLine = 0
printNewMessage = (msg) ->
  if msgLine > process.stdout.getWindowSize()[1]-3
    msgLine = 0
    charm.erase 'screen'
  charm.position 0, ++msgLine
  charm.write '\u0007'
  charm.write msg


positionForInput = ->
  charm.position 0, process.stdout.getWindowSize()[1]-2
  charm.background 'blue'
  charm.erase 'end'
  charm.position 0, process.stdout.getWindowSize()[1]-1
  charm.background 'black'


positionForInput()

stdin = process.openStdin()
stdin.on 'data', (msg) ->
  msg = new Buffer "[#{process.argv[1]}] #{msg.toString()}"
  client.send msg, 0, msg.length, port, '224.0.0.0', (err, bytes) ->
    positionForInput()
    charm.erase 'end'


server.on 'message', (msg, rinfo) ->
  printNewMessage msg.toString()
  positionForInput()
