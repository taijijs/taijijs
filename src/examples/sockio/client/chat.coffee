socket = io.connect '/'

socket.on 'name_set', (data) ->
  $('#nameform').hide()
  $('#messages').append '<div class="systemMessage">'+'Hello '+data.name+'</div>'

$ ->
  $('#send').click ->
    socket.send JSON.stringify
      message: $('#message').val()
      type: 'userMessage'
    $('#message').val ''

  socket.on 'message', (data) ->
    console.log data
    data = JSON.parse data
    if data.username
      $('#messages').append('<div class="'+data.type+'"><span class="name">' +data.username + ":</span> " +data.message + '</div>')
    else $('#messages').append '<div class="'+data.type+'">'+data.message+'</div>'

  $('#setname').click ->
    socket.emit 'set_name', {name:$('#nickname').val()}

