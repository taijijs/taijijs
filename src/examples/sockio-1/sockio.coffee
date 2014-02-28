io = require 'socket.io'

exports.initialize = (server) ->
  io = io.listen server
  io.sockets.on 'connection', (socket) ->
    console.log 'dsfaj;l connected'
    socket.send JSON.stringify
      type: 'serverMessage'
      message: 'welcome to chat room.'
    socket.on 'message', (message) ->
      message = JSON.parse message
      console.log 'on message: '+JSON.stringify message
      if message.type=='userMessage'
        socket.broadcast.send JSON.stringify message
        message.type = 'myMessage'
        socket.send JSON.stringify message

#    socket.on 'set-name', (data) ->
#      socket.set 'nikname', data.name, -> socket.emit 'name-set', data
#      socket.send JSON.stringify
#        type:'serverMessage'
#        message