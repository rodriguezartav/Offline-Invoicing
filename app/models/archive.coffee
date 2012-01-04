Spine = require('spine')

class Archive extends Spine.Model
  @configure 'Archive', "Producto_Name" , "Producto" , "Cantidad" , 
    "Precio" , "Impuesto" , "Descuento" , "Total" , "Cliente_Name" , 
    "Cliente" , "Referencia" , "Transporte" , "Observacion"

  @extend Spine.Model.Local

  @create_from_server: (pedido,item,final) ->
    archive = Archive.create
      id            :  final.Id
      Producto_Name :  item.Name
      
      Producto      :  final.Producto__c
      Cantidad      :  final.Cantidad__c 
      Precio        :  final.Precio__c
      Impuesto      :  final.Impuesto__c
      Descuento     :  final.Descuento__c
      Total         :  0
      Cliente_Name  :  pedido.Name
      Cliente       :  final.Cliente__c
      Referencia    :  final.Referencia__c
      Transporte    :  "n/d"
      Observacion   :  final.Observacion__c

  @filter: (query,over_cero=false) ->
    @select (item) ->
      match = true
      if query
        match = item.Cliente == query and (item.Total > 0 or !over_cero)
      else
        match = item.Total > 0 if over_cero
      match

  @items_by_cliente: (query) ->
    return Archive.all() if !query
    @select (item) ->
      match = false
      match = item.Cliente == query
      match

  @items_by_producto: (query) ->
    return Archive.all() if !query
    @select (item) ->
      match = false
      match = item.Producto == query
      match

  @group_by_producto: (archives) ->
    product_map = {}
    grouped_list = []
    for archive in archives
      list = product_map[archive.Producto] || {Producto: archive.Producto_Name , Total: 0}
      list.Total += parseInt(archive.Cantidad)
      product_map[archive.Producto] = list
    for key, value of product_map    
      grouped_list.push value    
    return grouped_list

  @group_by_familia: (archives) ->
    product_map = {}
    grouped_list = []
    for archive in archives
      list = product_map[archive.Familia] || {Producto: archive.Familia || "N/D", Total: 0}
      list.Total += parseInt(archive.Cantidad)
      product_map[archive.Familia] = list
    for key, value of product_map    
      grouped_list.push value    
    return grouped_list


module.exports = Archive