charm = require('charm')()
dgram = require("dgram")
iron = require("iron")


password = process.argv[2]

present = {}

config = {}
try
  config = require("#{process.env.HOME}/.nackchannelrc.json")

nick = config.nick || process.env.USER
nick += "{reset}"

colors = [ "black","blue","cyan","green","magenta","red","white","yellow" ]
randomColor = colors[Math.floor(Math.random()*colors.length)]
color = randomColor
if(typeof config.color != 'undefined')
  color = config.color

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
  charm.write stylize("[{#{color}}#{nick}{reset}] #{msg}")
  charm.display('reset')
  positionForInput()


positionForInput = ->
  charm.position 0, process.stdout.getWindowSize()[1]-2
  charm.background 'blue'
  charm.erase 'end'
  charm.position 0, process.stdout.getWindowSize()[1]-1
  charm.background 'black'

presence = ->
  line = 0
  size = process.stdout.getWindowSize()

  for i in [0..10]
    charm.position size[0] - 10, line
    charm.write("         ")
    line++
    

  line = 0
  for n of present
    if((new Date() - present[n]) < 5000)
      line++
      charm.position size[0] - 10, line
      charm.write(stylize(n))

  positionForInput()
  obj =
    nick: nick
    presence: true
  send(obj)

see = (obj) ->
  present[obj.nick] = new Date()
  


sendRaw = (msg) ->
  msg = new Buffer msg
  client.send msg, 0, msg.length, port, '224.0.0.0', (err, bytes) ->
    positionForInput()
    charm.erase 'end'

send = (obj) ->
  if password
    iron.seal obj, password, iron.defaults, (err, sealed) ->
      sendRaw(sealed)
  else
    msg = JSON.stringify(obj)
    sendRaw(msg)


positionForInput()

setInterval presence, 1000

stdin = process.openStdin()
stdin.on 'data', (msg) ->
  obj =
    payload: msg.toString()
    nick: nick
    color: color
  send(obj)

parseMsg = (obj) ->
  if obj.payload?
    printNewMessage obj.nick, obj.payload
  else if obj.presence?
    see(obj)
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
      parseMsg(obj)
  else
    try
      obj = JSON.parse(str)
      parseMsg(obj)


