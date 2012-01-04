Spine = require('spine')

class Error extends Spine.Model
  @configure 'Error', "type" , "context" , "error" , "info" , "source" , "raw" , "sent"

  @extend Spine.Model.Local

  @send_unsent: ->
    errors_list = Error.all()
    if errors_list.length > 0
      errors = JSON.stringify {errors: errors_list}
      $.ajax
        url        :  'http://rodco-api.heroku.com/errors'
        type       :  "POST"
        data       :  errors
        success    :  @on_send_success

  @on_send_success: (raw_results) =>
    for error in Error.all()
      error.sent = true
      error.save()

  @create_from_server: (raw_error, context,info) ->
    raw_error.raw = JSON.stringify raw_error
    raw_error.context = context
    raw_error.info= info
    error = Error.create raw_error
    return error

  to_string: =>
    ui = "<h4>Error " + @context + " " + @info + " en " + @type + "</h4>"
    ui += '<p>' + @error  + '</p>'
    ui += '<p>' + @raw  + '</p>'
    ui
    
module.exports = Error