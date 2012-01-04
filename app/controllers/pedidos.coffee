Spine   = require('spine')
Cliente = require('models/cliente')
Pedido = require('models/pedido')
User = require('models/user')
Item = require('models/item')
Archive = require('models/archive')
Producto = require('models/producto')
Manager = require('spine/lib/manager')
$       = Spine.$

Main    = require('controllers/main')
Infobar    = require('controllers/infobar')
Sidebar = require('controllers/sidebar')


class Pedidos extends Spine.Controller
  className: 'pedidos row'
  
  constructor: ->
    super

    User.fetch()

    @sidebar  =  new Sidebar
    @main     =  new Main
    @infobar  =  new Infobar

    @append @sidebar , @main , @infobar

    Cliente.fetch()
    Producto.fetch()
    Item.fetch()
    Pedido.fetch()
    Archive.fetch()

module.exports = Pedidos