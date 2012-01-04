Spine   = require('spine')
Cliente = require('models/cliente')
Producto = require('models/producto')
Pedido = require('models/pedido')
Manager = require('spine/lib/manager')
$       = Spine.$

class Clientes extends Spine.Controller
  className: 'clientes active'

  elements:
    '.list'         :   'list'
    'input'         :   'search'

  events:
    'keyup input'   :   'filter'
    'click input'   :   'on_input_click'
    "click div>.item" : "change"

  constructor: ->
    super
    @html require('views/sidebar/clientes')()

    Cliente.bind('refresh', @render)
    
    @active =>
      Cliente.reset_current()

  on_input_click: =>
    Cliente.reset_current()
    @filter()

  filter: ->
    @query = @search.val()
    @render()

  render: =>
    clientes = Cliente.filter(@query)
    clientes_by_ruta = Cliente.map_by_ruta(clientes)
    @list.html require('views/sidebar/cliente_item')(clientes_by_ruta)

  change: (e) =>
    target = $(e.target)
    parents = target.parents(".item")
    id = parents.attr("data-id") || target.attr("data-id")
    item = Cliente.find( id )
    Cliente.set_current item

  on_show_click: =>
    Cliente.reset_current()

class Productos extends Spine.Controller
  className: 'productos'

  elements:
    '.list'           :   'list'
    'input'           :   'search'

  events:
    'keyup input'     :  'filter'
    'click input'     :  'on_input_click'
    "click div.item" :  "change"
    
  constructor: ->
    super
    @html require('views/sidebar/productos')()
   
    Producto.bind('refresh change', @render)
    
    @active =>
      Producto.reset_current()

  on_input_click: =>
    Producto.reset_current()
    @filter()

  filter: ->
    @query = @search.val()
    @render()

  render: =>
    productos = Producto.filter(@query)
    productos_by_familia = Producto.map_by_familia(productos)    
    @list.html require('views/sidebar/producto_item')(productos_by_familia) 
    
  change: (e) =>
    target = $(e.target)
    parents = target.parents(".item")
    id = parents.attr("data-id") || target.attr("data-id")
    item = Producto.find( id )
    Producto.set_current item

class Sidebar extends Spine.Controller
  className: 'sidebar columns three'
  
  elements:
    ".tabs>dd>a" : "tabs_header"
    ".tabs>dd>a.tab_clientes" : "tab_clientes"
    ".tabs>dd>a.tab_productos" : "tab_productos"
    "ul" :  "tabs_content"
  
  events:
    "click .tab_clientes" : "tab_clientes_click"
    "click .tab_productos" : "tab_productos_click"
  
  constructor: ->
    super
    @html require('views/sidebar/layout')()
    
    @clientes = new Clientes(tag: 'li')
    @productos = new Productos(tag: 'li')

    @tabs_content.append @clientes.el , @productos.el 
    @manager = new Manager @clientes , @productos


  tab_clientes_click: (e) =>
    target = $(e?.target) or @tab_clientes
    @tabs_header.removeClass "active"
    target.addClass "active"
    @clientes.activate()
    @productos.deactivate()


  tab_productos_click: (e) =>
    target = $(e?.target) or @tab_productos
    @tabs_header.removeClass "active"
    target.addClass "active"
    @clientes.deactivate()
    @productos.activate()

module.exports = Sidebar