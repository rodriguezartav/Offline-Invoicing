require('lib/setup')
require('lib/format')
Spine    = require('spine')
Pedidos = require('controllers/pedidos')
Lightbox = require('controllers/lightbox')
Cliente = require('models/cliente')
Producto = require('models/producto')
Item = require('models/item')
User = require('models/user')
Archive = require('models/archive')
Pedido = require('models/pedido')
Error = require('models/error')

Mock = require('lib/mock')

class App extends Spine.Controller
  
  events:
    "click .update"  :  "update"
    "click .pedidos" : "on_body_click"

  constructor: ->
    super
    
    Spine.server = if @test then "http://127.0.0.1:9393" else "http://rodco-api2.heroku.com"
    
    @html require('views/layout')()
  
    @pedidos = new Pedidos
    @lightbox = new Lightbox
    @append @pedidos , @lightbox
        
    Spine.Route.setup()

    User.retrieve()
    
    Spine.source = "Remote"
      
    if @email
      User.current.session = { instance_url: @instance_url , token: @token }
      User.current.email = @email
      User.current.last_login = new Date()
      User.current.is_visualforce = true
      User.current.save()
      Spine.source = "Salesforce"
      Spine.trigger("show_lightbox","sync")
    else if User.current.last_login.minutes_from_now() > 115
      Spine.trigger("show_lightbox","login")
    else if User.current.last_update.minutes_from_now() > 5
      Spine.trigger("show_lightbox","sync")

    #Set inactivityu block
    @on_body_click()

  on_body_click: =>
    clearTimeout(@timeout) if @timeout
    @timeout = setTimeout(@block_ui,300000);
    
  block_ui: =>    
    Spine.trigger "show_lightbox" , "block"
  
  update: (e) ->
    Spine.trigger "show_lightbox" , "sync"

  @on_check_success: (raw_json) ->
    response = JSON.parse raw_json
    if !response.access == "destroy"
      Cliente.bulk_delete()
      Pedido.bulk_delete()
      Item.bulk_delete()
      Producto.bulk_delete()
    if !response.access == "refresh"
      Cliente.bulk_delete()
      Pedido.bulk_delete()
      Item.bulk_delete()
      Producto.bulk_delete()
      
module.exports = App