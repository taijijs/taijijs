io = require 'socket.io'

exports.initialize = (server) ->
  io = io.listen server, { log: false }
  io.sockets.on 'connection', (socket) ->
    console.log 'dsfaj;l connected'
    socket.on 'message', (message) ->
      message = JSON.parse message
      console.log 'on message: '+JSON.stringify message
      if message.type=='userMessage'
        socket.get 'nickname', (err, nickname) ->
          message.username=nickname
          socket.broadcast.send JSON.stringify message
          message.type = 'myMessage'
          socket.send JSON.stringify message

    socket.on 'set_name', (data) ->
      console.log JSON.stringify data
      socket.set 'nikname', data.name, ->
        socket.get 'nickname', (err, nickname) ->
          console.log 'nickname:'+nickname
        socket.emit 'name_set', data
    socket.send JSON.stringify {type: 'serverMessage', message: 'welcome to chat room.'}