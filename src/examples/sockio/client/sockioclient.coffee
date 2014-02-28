socket = io.connect '/'
socket.on 'message', (data) ->
  data = JSON.parse data
  $('#messages').append '<div class="'+data.type+'">'+data.message+'</div>'
$ ->
  $('#send').click ->
    socket.send JSON.stringify
      message: $('#message').val()
      type: 'userMessage'
    $('#message').val ''
