$ ->
  $('#setname').click ->
    socket.emit 'set_name', {name:$('nickname').val()}