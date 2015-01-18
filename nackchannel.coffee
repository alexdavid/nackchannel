dgram = require 'dgram'
iron = require 'iron'
IO = require './io'


class NackChannel

  HOST: '224.0.0.0'
  PORT: 41234

  constructor: (@username, @password) ->
    @client = dgram.createSocket 'udp4'
    @server = dgram.createSocket 'udp4'
    @io = new IO

    @server.on 'message', @onRecievedMessage
    @io.on 'message', @sendMessage


  onRecievedMessage: (buffer) =>
    @unpackMessage buffer.toString(), (err, object) =>
      return if err
      @io.printMessage object


  packMessage: (message, done) ->
    unsealedMessageObject =
      name: @username
      message: message

    iron.seal unsealedMessageObject, @password, iron.defaults, done


  sendMessage: (message) =>
    @packMessage message, (err, packedMessage) =>
      buffer = new Buffer packedMessage
      @client.send buffer, 0, buffer.length, @PORT, @HOST


  start: ->
    @server.bind @PORT, =>
      @server.addMembership @HOST


  unpackMessage: (packedMessage, done) ->
    iron.unseal packedMessage, @password, iron.defaults, done


module.exports = NackChannel
