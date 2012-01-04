Spine   = require('spine')
Pedido = require('models/pedido')
Cliente = require('models/cliente')
Producto = require('models/producto')
Item = require('models/item')

Pedido_Edit = require('controllers/main/pedido_edit')
 

Manager = require('spine/lib/manager')
List    = require('spine/lib/list')
$       = Spine.$

class Main extends Spine.Controller
  className: 'main columns six'
  
  constructor: ->
    super
    
    @current = null
    
    Cliente.bind "current_set" , @on_cliente_change

    Producto.bind "current_set" , @on_producto_change

    Pedido.bind "refresh" , @load_pedidos
    
  add_post: (post) ->
    post.bind "change" , @post_change
    @prepend post
    
  remove_post: (post) ->
    post.unbind "change" , @post_change
    post.release()

  post_change: (post,type) =>
    
    if type == "close" 
      if post.el.hasClass "active"
        @de_activate_posts() 
      else
        @de_activate_posts()
        @remove_post(post)
    else if type == "edit" 
      @activate_post(post)

  de_activate_posts: ->
   if @current
      @current.el.removeClass "active"
      @current.un_bind_external()
      @current = null

  activate_post: (post) ->
    @de_activate_posts()
    @current = post
    @current.bind_external()
    @current.el.addClass "active"
  
  load_pedidos: =>
    Pedido.unbind "refresh" , @load_pedidos
    last = null
    for pedido in Pedido.all()
      post = new Pedido_Edit(pedido: pedido)
      @add_post post
      last = post
    @activate_post(last) if last

  #always create a post if cliente change or current is pedido
  on_cliente_change: (e) =>
    if !@current or @current?.accept_cliente == false
     post = new Pedido_Edit(cliente: Cliente.current)
     @add_post post
     @activate_post post
    
  #never create a post if @current or post is pedido
  on_producto_change: (e) =>
    if !@current or @current?.accept_producto == false
      post = new Pedido_Edit(producto: Producto.current)
      @add_post post
      @activate_post post


module.exports = Main