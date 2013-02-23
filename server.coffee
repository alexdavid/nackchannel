os = require('os')
net = require("net")
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

colors = [ "blue","cyan","green","magenta","red","white","yellow" ]
randomColor = colors[Math.floor(Math.random()*colors.length)]
color = randomColor
if(typeof config.color != 'undefined')
  color = config.color

server = dgram.createSocket("udp4")
client = dgram.createSocket("udp4")

port = 41234


class TcpConnection
  constructor: ->
    @connections = {}
    @server = net.createServer()
    @getMyIP()
    @server.listen 0, =>
      @port = @server.address().port
      setInterval(@broadcast, 3e3)
    @server.on("data", @receive)

  connectTo: (obj) ->
    @connections[obj.address] ||= {}
    return if @connections[obj.address][obj.port]
    @connections[obj.address][obj.port] = {}
    socket = new net.Socket
    socket.connect(obj.address, obj.port)
    socket.on("data", @receive)
    @connections[obj.address][obj.port].socket = socket

  receive: =>

  send: (data) =>
    for address of @connections
      for port of @connectsions[address]
        @connections[address][port].write(data)


  getMyIP: =>
    interfaces = os.networkInterfaces()
    for k of interfaces
      for address in interfaces[k]
        if address.internal == false && address.family == "IPv4"
          @address = address.address

  broadcast: =>
    send
      port: @port
      address: @address



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

messageList = []
msgLine = 0
printNewMessage = (obj) ->
  obj.payload = callout(obj.payload)
  messageList.push(obj)

  charm.push()
  if msgLine > process.stdout.getWindowSize()[1]-4
    messageList.shift()

    charm.erase 'screen'
    msgLine = 0
    for obj in messageList
      charm.position 0, ++msgLine
      if obj.nick == nick
        charm.write stylize("[{#{obj.color}}{bold}#{obj.nick}{reset}] #{obj.payload}")
      else
        charm.write stylize("[{#{obj.color}}#{obj.nick}{reset}] #{obj.payload}")
    charm.write '\u0007'
    charm.display('reset')

    drawPresence()
  else
    charm.position 0, ++msgLine
    charm.write '\u0007'
    if obj.nick == nick
      charm.write stylize("[{#{obj.color}}{bold}#{obj.nick}{reset}] #{obj.payload}")
    else
      charm.write stylize("[{#{obj.color}}#{obj.nick}{reset}] #{obj.payload}")
    charm.display('reset')
  charm.pop()

  positionForInput()

positionForInput = ->
  charm.position 0, process.stdout.getWindowSize()[1]-2
  charm.background 'blue'
  charm.erase 'end'
  charm.position 0, process.stdout.getWindowSize()[1]-1
  charm.background('black')
  charm.erase 'end'

drawPresence = ->
  charm.push()
  line = 0
  size = process.stdout.getWindowSize()

  for i in [0..10]
    charm.position size[0] - 10, line
    charm.write("         ")
    line++
    

  line = 0
  for n of present
    if((new Date() - present[n].when) < 15000)
      line++
      charm.position size[0] - 10, line
      charm.write(stylize("{#{present[n].color}}#{n}{reset}"))
  charm.pop()

presence = ->
  drawPresence()

  obj =
    nick: nick
    presence: true
    color: color
  send(obj)

see = (obj) ->
  present[obj.nick] =
    when: new Date()
    color: obj.color
  


sendRaw = (msg) ->
  msg = new Buffer msg
  client.send msg, 0, msg.length, port, '224.0.0.0'

send = (obj) ->
  if password
    iron.seal obj, password, iron.defaults, (err, sealed) ->
      sendRaw(sealed)
  else
    msg = JSON.stringify(obj)
    sendRaw(msg)
  if obj.payload?
    positionForInput()


positionForInput()

setInterval presence, 5000

stdin = process.openStdin()
stdin.on 'data', (msg) ->
  obj =
    payload: msg.toString()
    nick: nick.toString()
    color: color.toString()
  send(obj)

parseMsg = (obj) ->
  if obj.payload?
    printNewMessage obj
  else if obj.presence?
    see(obj)

server.on 'message', (str, rinfo) ->
  if password
    iron.unseal str.toString(), password, iron.defaults, (err, obj) ->
      return unless obj?
      parseMsg(obj)
  else
    try
      obj = JSON.parse(str)
      parseMsg(obj)



tcpconnection = new TcpConnection
