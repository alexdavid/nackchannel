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
    @getMyIP()
    conn = this
    server = net.createServer((s) =>
      s.on("data", @receive)
      s.on("error", @err)
    ).listen 0
    @port = server.address().port
    @broadcast()
    setInterval(@broadcast, 10e3)

  err: (e) ->
    console.log(e)

  connectTo: (obj) =>
    return unless obj.port?
    @connections[obj.address] ||= {}
    return if @connections[obj.address][obj.port]?
    socket = net.connect
      port: obj.port
      address: obj.address
    socket.on("error", @err)
    socket.on("close", @close(obj.address, obj.port))
    @connections[obj.address][obj.port] =
      nick: obj.nick
      color: color
      socket: socket

  close: (address, port) =>
    =>
      delete @connections[address][port]
      drawPresence()

  receive: (data) =>
    parseRawMsg(data.toString())

  send: (obj) =>
    if password
      iron.seal obj, password, iron.defaults, (err, sealed) =>
        @sendRaw(sealed)
    else
      msg = JSON.stringify(obj)
      @sendRaw(msg)
    if obj.payload?
      positionForInput()

  sendRaw: (msg) =>
    msg = new Buffer msg
    for address of @connections
      for port of @connections[address]
        socket = @connections[address][port].socket
        socket.write msg


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
      nick: nick
      color: color



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
  for address of tcpconnection.connections
    for port of tcpconnection.connections[address]
      obj = tcpconnection.connections[address][port]
      line++
      charm.position size[0] - 10, line
      charm.write(stylize("{#{obj.color}}#{obj.nick}{reset}"))
  charm.pop()

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

setInterval drawPresence, 5000

stdin = process.openStdin()
stdin.on 'data', (msg) ->
  obj =
    payload: msg.toString()
    nick: nick.toString()
    color: color.toString()
  tcpconnection.send(obj)

parseMsg = (obj) ->
  if obj.payload?
    printNewMessage obj
  else if obj.address?
    tcpconnection.connectTo(obj)

parseRawMsg = (str) ->
  if password
    iron.unseal str.toString(), password, iron.defaults, (err, obj) ->
      return unless obj?
      parseMsg(obj)
  else
    try
      obj = JSON.parse(str)
      parseMsg(obj)

server.on 'message', (str, rinfo) ->
  parseRawMsg(str)



tcpconnection = new TcpConnection
