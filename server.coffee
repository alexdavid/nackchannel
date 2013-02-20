charm = require('charm')()
dgram = require("dgram")
iron = require("iron")


password = process.argv[2]

nick = process.env.USER

server = dgram.createSocket("udp4")
client = dgram.createSocket("udp4")

port = 41234


server.bind(port)
server.addMembership '224.0.0.0'


charm.pipe process.stdout
charm.reset()


stylize = (msg) ->
  styles = {
    reset: 0

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
    "[#{styles[idx]}m"
  )

callout = (msg) ->
  msg.replace(new RegExp("@#{nick}\\b", 'g'), (match) ->
    "{magenta}#{match}{reset}"
  )

msgLine = 0
printNewMessage = (nick, msg) ->
  if msgLine > process.stdout.getWindowSize()[1]-4
    msgLine = 0
    charm.erase 'screen'

  msg = callout(msg)

  charm.position 0, ++msgLine
  charm.write '\u0007'
  charm.write stylize("[{green}#{nick}{reset}] #{msg}")
  charm.display('reset')
  positionForInput()


positionForInput = ->
  charm.position 0, process.stdout.getWindowSize()[1]-2
  charm.background 'blue'
  charm.erase 'end'
  charm.position 0, process.stdout.getWindowSize()[1]-1
  charm.background 'black'


send = (msg) ->
  msg = new Buffer msg
  client.send msg, 0, msg.length, port, '224.0.0.0', (err, bytes) ->
    positionForInput()
    charm.erase 'end'


positionForInput()

stdin = process.openStdin()
stdin.on 'data', (msg) ->
  obj =
    payload: msg.toString()
    nick: nick
  if password
    iron.seal obj, password, iron.defaults, (err, sealed) ->
      send(sealed)
  else
    msg = JSON.stringify(obj)
    send(msg)

server.on 'message', (str, rinfo) ->
  if password
    iron.unseal str.toString(), password, iron.defaults, (err, obj) ->
      return unless obj?
      printNewMessage obj.nick, obj.payload
  else
    try
      obj = JSON.parse(str)
      printNewMessage obj.nick, obj.payload


