Spine   = require('spine')
User = require('models/user')
Cliente = require('models/cliente')
Producto = require('models/producto')
Pedido = require('models/pedido')
Archive = require('models/archive')
Item = require('models/item')
$       = Spine.$

class Block extends Spine.Controller
  className: 'block reveal-modal'

  events:
    "click .accept" : "on_accept"
    "click .close-reveal-modal" : "cancel"
    
  constructor: ->
    super

  render: (pedido,callback) =>
    @html require('views/lighthouse/block')()
  
  on_accept: =>
    if User.current.is_visualforce 
      Spine.trigger "show_lightbox" , "sync"
    else if User.current.session 
      if  User.current.last_login.minutes_from_now() < 115
        Spine.trigger "show_lightbox" , "sync"
      else
        Spine.trigger "show_lightbox" , "login"
    else
      alert "No Session Available"

  cancel:->
    Spine.trigger "hide_lightbox"

class Send extends Spine.Controller
  className: 'send reveal-modal'

  elements:
    ".alert-box" : "alert_box"
    ".loader" : "loader"

  events:
    "click .accept" : "on_error_accept"

  constructor: ->
    super

  render: (pedido,callback) =>
    @html require('views/lighthouse/send')(pedido)
    @do_send(pedido,callback)
  
  do_send: ( pedido , callback ) =>
    @callback = callback
    @pedido = pedido
    @pedido.send_to_server(User.current)
    @pedido.bind "ajax_error" , @on_error
    @pedido.bind "ajax_complete" , @on_success

  on_success: (old_pedido,results) =>
    @pedido.unbind "ajax_error" , @on_error
    @pedido.unbind "ajax_complete" , @on_success
    
    @loader.hide()
    pedido = null
    errors = []
    hasErrors = false
    for result in results
      if result.success
        source = result.source
        pedido = Pedido.exists source.id
        item   = Item.exists source.item_id
        if pedido and item
          Archive.create_from_server pedido , item , source
          item.destroy()
        else
          hasErrors = true
          error = { type:"MODEL" , error: "El pedido fue guardado, pero no se encuentra en este equipo.", source: "Pedido" }
          errors.push error
      else
        hasErrors = true
        errors.push result
    
    if hasErrors
      @on_error old_pedido,errors
    else
      items = Item.findAllByAttribute "Parent_id" , old_pedido.id
      old_pedido.destroy() if items.length == 0
      @callback.apply @, [true]
      Spine.trigger "hide_lightbox"

  on_error: (pedido,error_obj) =>
    @pedido.unbind "ajax_error" , @on_error
    @pedido.unbind "ajax_success" , @on_success
    
    User.current.errors.push error_obj
    User.current.save()
    @loader.hide()
    @el.addClass "error"
    @alert_box.append obj.error + "<br/>" for obj in error_obj
  
  on_error_accept: =>
    @el.removeClass "error"
    Spine.trigger "hide_lightbox"
    @callback.apply @, [false]

class Sync extends Spine.Controller
  className: 'sync reveal-modal'

  elements:
    ".alert-box" : "alert_box"
    ".loader" : "loader"

  events:
    "click .login" : "on_login"

  constructor: ->
    super

  render: =>
    @html require('views/lighthouse/sync')(User.current)
    @do_sync()
    
  on_login: =>
    Spine.trigger "show_lightbox" , "login"
    
  do_sync: ->
    Cliente.bind "ajax_complete" , @update_producto
    Producto.bind "ajax_complete" , @sync_complete
    Cliente.bind "ajax_error" , @on_error
    Producto.bind "ajax_error" , @on_error
    @update_cliente()

  update_cliente:=>
     @log "Updating Cliente"
     Cliente.fetch_from_sf(User.current)

  update_producto: =>
    @log "Cliente Updated"
    @log "Updating Producto"
    Producto.fetch_from_sf(User.current)

  sync_complete: =>
    @log "Producto Update Complete"
    Cliente.unbind "ajax_complete" , @update_producto
    Producto.unbind "ajax_complete" , @sync_complete
    Cliente.unbind "ajax_error" , @on_error
    Producto.unbind "ajax_error" , @on_error
    
    Producto.trigger "refresh"
    Cliente.trigger "refresh"
    User.current.last_update = new Date()
    User.current.save()
    if @reset
      window.location.reload(true)
    else
      Spine.trigger "hide_lightbox"

  on_error: (error_obj) =>
    Cliente.unbind "ajax_error" , @on_error
    Producto.unbind "ajax_error" , @on_error
    Cliente.unbind "ajax_complete" , @update_producto
    Producto.unbind "ajax_complete" , @sync_complete

    User.current.errors.push error_obj
    User.current.save()
    @loader.hide()
    @alert_box.html error_obj.error
    @el.addClass "error"

class Login extends Spine.Controller
  className: 'login reveal-modal'

  elements:
    "#txt_email" : "email"
    "#txt_password" : "txt_password"
    "#txt_token" : "txt_token"
    ".alert-box" : "alert_box"
    ".login" : "login"
    ".loader" : "loader"

  events:
    "click .login" : "login"
    "click .cancel" : "cancel"
    "click .close-reveal-modal" : "cancel"

  constructor: ->
    super

  render: =>
    @html require('views/lighthouse/login')(User.current)
    
  login: =>
    @login.hide()
    @loader.show()
    
    User.bind "login_complete" , @on_login_complete

    User.bind "login_error" , @on_login_error
      
    User.login  @email.val(),  @txt_token.val() , @txt_password.val()

  on_login_complete: =>
    User.unbind "login_complete" , @on_login_complete
    User.unbind "login_error" , @on_login_error
    @login.show()
    @loader.hide()
    Spine.trigger "show_lightbox" , "sync"
    
  on_login_error: (response) =>
    User.unbind "login_complete" , @on_login_complete
    User.unbind "login_error" , @on_login_error
    @login.show()
    @loader.hide()
    @alert_box.html response.error
    @el.addClass "error"

  cancel:->
    User.current.session = null
    Spine.trigger "hide_lightbox"
    
class Lightbox extends Spine.Controller
  className: 'lightbox reveal-modal-bg'

  constructor: ->
    super
    @items = [new Login , new Sync , new Send , new Block]
    
    Spine.bind "hide_lightbox" , @hide
    
    Spine.bind "show_lightbox" , ( type , data =null, callback=null ) =>
      @el.show()
      @current = null
      for item in @items
        @current = item if item.el.hasClass type
      if @current
        @current.render(data,callback)
        @html @current

  hide: =>
    @current = null
    @el.empty()
    @el.hide()

module.exports = Lightbox