Spine = require('spine')

class Producto extends Spine.Model
  @configure 'Producto', 'Name', 'Codigo' , 'Cantidad' , 'Minimo' ,  'Precio' , 'Descuento' ,'Familia', 'Impuesto'  , "Activo" , "Meta" , "Venta"
  
  @extend Spine.Model.Local
  
  @source = 0
  
  Ratio: ->
    r = (@Venta / @Meta)
    r = 1 if r >= 1
    r = 0.1 if r <= 0 or isNaN(r)
    r*=100

  Disponible: ->
    @Minimo = @Minimo || 0
    venta_restante = @Meta - @Venta
    venta_restante = 0 if venta_restante < 0
    color = "black"
    if @Cantidad == 0
      color = "white"      
    else if @Cantidad - venta_restante > @Minimo
      color = "green"
    else if @Cantidad - venta_restante <= 0
      color = "red"
    else if @Cantidad <= @Minimo
      color = "yellow"
    else if @Cantidad > @Minimo
      color = "brown"

  
    return color

  @map_by_familia: (productos) ->
    familias = (producto.Familia for producto in productos).unique()
    groups  = []
    for familia in familias
      ratio = 0
      producto_in_familia = []
      for producto in productos when producto.Familia == familia
        producto_in_familia.push producto
        ratio+= producto.Ratio()
      groups.push {familia: familia , productos: producto_in_familia , ratio: ratio / producto_in_familia.length}
    groups

  
  @fetch_from_sf: (user) ->
    query = "Select Id,Name,CodigoExterno__c,Precio_Distribuidor__c, InventarioMinimo__c , Meta__c, Venta__c , Familia__c,Impuesto__c ,Activo__c,InventarioActual__c, DescuentoMaximo__c from Producto__c where Precio_Distribuidor__c > 0 and LastModifiedDate > " + user.last_update.to_salesforce()
    data = user.to_auth { query: query }
    $.ajax
      url: Spine.server + "/query"
      type: "POST"
      data: data
      success: @on_success
      error: @on_error
    
  @on_success: (raw_results) =>
     result_object = JSON.parse raw_results
     if result_object.success
       Producto.source =  result_object.results
       Producto.bulk_update()  
      else
        errors = JSON.parse raw_results
        Producto.trigger "ajax_error" , errors  
         
  @on_error: (error) =>
    responseText  = error.responseText
    if responseText.length > 0
      errors = JSON.parse responseText
    else
      errors = {type:"LOCAL" , error: " Indefinido: Posiblemente Problema de Red", source: "Producto" }
    Producto.trigger "ajax_error", errors

  @bulk_delete: ->
    Producto.source = Producto.all()
    start = Producto.source.length - 20
    start = 0 if start < 0
    to_work = Producto.source.slice(start)
    Producto.source = Producto.source.slice(0,start)
    for item in to_work
      item.destroy()
      setTimeout(Producto.bulk_delete, 135) if Producto.source.length > 0
    Producto.trigger "refresh" if Producto.source.length == 0
  

  @bulk_update: ->
    start = Producto.source.length - 20
    start = 0 if start < 0
    to_work = Producto.source.slice(start)
    Producto.source = Producto.source.slice(0,start)
    for item in to_work
      Producto.create_from_salesforce item
    setTimeout(Producto.bulk_update, 135) if Producto.source.length > 0
    Producto.trigger "ajax_complete" if Producto.source.length == 0


  @create_from_salesforce: (obj) =>
    producto = {}
    producto.id = obj.Id
    producto.Name = obj.Name || "N/D (error)"
    producto.Codigo = obj.CodigoExterno__c || ""
    producto.Cantidad = obj.InventarioActual__c || 0.00
    producto.Precio = obj.Precio_Distribuidor__c || 0.00
    producto.Descuento = obj.DescuentoMaximo__c || 0.00
    producto.Impuesto = obj.Impuesto__c || 0.00
    producto.Familia = obj.Familia__c || "N/D"
    producto.Meta = obj.Meta__c || 0.00
    producto.Venta = obj.Venta__c || 0.00
    producto.Activo = obj.Activo__c || true
    producto.Minimo = obj.InventarioMinimo__c || 0
    Producto.create producto
  
  @set_current: (producto) ->
    @current = producto
    @trigger('current_set',@current)

  @reset_current: ->
    @current = null
    @trigger('current_reset',@current)

  @queryToRegex: (query) ->
    str = ""
    words = query.split(" ")
    for word in words
      str += word
      str += "|"
    str = str.slice(0, -1)

  @filter: (query) =>
    return @all() unless query
    query = query.toLowerCase()
    myRegExp =new RegExp( @queryToRegex(query),'gi')
    @select (item) =>
      return false if item.Activo == false
      item.Name.search(myRegExp) > -1 or item.Codigo.indexOf(query) > -1


module.exports = Producto