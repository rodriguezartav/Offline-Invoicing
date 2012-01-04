Spine = require('spine')

class Item extends Spine.Model
  @configure 'Item', "Name" , "Producto" , "Cantidad" , "Precio" , "Impuesto" , "Descuento" , "Parent_id" , "Subtotal" , "Total" , "Costo" , "Familia"

  @extend Spine.Model.Local

  @descuento_monto: (item) =>
    monto = 0
    if item.Descuento < 35
      subtotal = (Math.round item.Precio * item.Cantidad * 100 )
      monto = (Math.round subtotal * item.Descuento / 100) / 100
    else
      monto = item.Descuento
    return monto

  @impuesto_monto: (item) =>
    monto = 0
    if item.Impuesto < 35
      subtotal = ( Math.round item.Precio * item.Cantidad * 100 )
      subtotal =   subtotal - ( Item.descuento_monto(item) * 100 )
      monto    = ( Math.round subtotal * item.Impuesto / 100 ) / 100
    else
      monto =  item.Impuesto__c
    return monto

  @create_from_template: ( pedidoId , producto ) ->
    Item.create
      Producto: producto.id
      Name: producto.Name
      Familia: producto.Familia
      Cantidad: 1
      Parent_id: pedidoId
      Costo: producto.Costo
      Impuesto: producto.Impuesto
      Precio: producto.Precio
      Descuento: 0
      
  @update_total: (item) =>
    item.Subtotal = (Math.round item.Precio * item.Cantidad * 100 ) / 100
    item.Total = item.Subtotal - Item.descuento_monto(item) + Item.impuesto_monto(item)

  @total: (items) ->
    total = 0
    for item in items
      Item.update_total(item)
      total += item.Total
    parseInt(total*100)/100

  @bulk_delete: ->
    for item in Item.all()
      item.destroy()

  @items_by_cliente: (query) ->
    @select (item) ->
      match = false
      if query
        match = item.Cliente == query
      match

module.exports = Item