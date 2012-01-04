Spine = require('spine')

class Cliente extends Spine.Model
  @configure 'Cliente', 'Name', 'Codigo' , 'Saldo' , 'Credito'  , 'Meta' , 'Venta' ,'SubRuta' , 'Vendedor' , 'DiasCredito__c' , "Activo" , "Telefono" 
  @extend Spine.Model.Local

  @source = 0

  Ruta: ->
    @SubRuta?[0]

  Ratio: ->
    r = (@Venta / @Meta)
    r = 1 if r >= 1
    r = 0.1 if r <= 0 or isNaN(r)
    r*100

  Ratio_Credito: ->
    r = (@Saldo / @Credito)
    r = 1 if r >= 1
    r = 0.1 if r <= 0 or isNaN(r)
    r*100

  @map_by_ruta: (clientes) ->
    rutas = (cliente.Ruta() for cliente in clientes when cliente.SubRuta > 0 ).unique()
    groups  = []
    for ruta in rutas
      ratio = 0
      cliente_in_ruta = []
      for cliente in clientes when cliente.Ruta() == ruta
        cliente_in_ruta.push cliente
        ratio += cliente.Ratio()
      groups.push {ruta: ruta , clientes: cliente_in_ruta, ratio: ratio / cliente_in_ruta.length } if cliente_in_ruta.length > 0
    groups

  @fetch_from_sf: (user) ->
    last = user.last_update.to_salesforce()
    query = "Select Id , Name, SubRuta__c , DiasCredito__c , Meta__c, Ruta__c , Ventas__c , Vendedor__r.VendedorId__c , CodigoExterno__c , Saldo__c, CreditoAsignado__c  , Activo__c , Telefono__c from Cliente__c where LastModifiedDate > " + last
    data = user.to_auth { query: query }
    $.ajax
      url:"http://127.0.0.1:9393/query"
      xhrFields: {withCredentials: true}
      type: "POST"
      data: data
      success: @on_update_success
      error: @on_update_error

  @on_update_success: (raw_results) =>
     result_object = JSON.parse raw_results
     if result_object.success
       Cliente.source =  result_object.results
       Cliente.bulk_update()
      else
        errors = JSON.parse raw_results
        Cliente.trigger "ajax_error" , errors

  @on_update_error: (error) =>
    responseText  = error.responseText
    if responseText.length > 0
      errors = JSON.parse responseText
    else
      errors = {type:"LOCAL" , error: " Indefinido: Posiblemente Problema de Red", source: "Cliente" }
    Cliente.trigger "ajax_error" , errors

  @bulk_update: ->
    start = Cliente.source.length - 30
    start = 0 if start < 0
    to_work = Cliente.source.slice(start)
    Cliente.source = Cliente.source.slice(0,start)
    for item in to_work
      Cliente.create_from_salesforce item
    setTimeout(Cliente.bulk_update, 100) if Cliente.source.length > 0
    Cliente.trigger "ajax_complete" if Cliente.source.length == 0

  @bulk_delete: ->
    Cliente.source = Cliente.all()
    start = Cliente.source.length - 30
    start = 0 if start < 0
    to_work = Cliente.source.slice(start)
    Cliente.source = Cliente.source.slice(0,start)
    for item in to_work
      item.destroy()
      setTimeout(Cliente.bulk_delete, 100) if Cliente.source.length > 0
    Cliente.trigger "refresh" if Cliente.source.length == 0

  @create_from_salesforce: (obj) -> 
    cliente = {}
    cliente.id = obj.Id
    cliente.Name = obj.Name || "N/D (error)"
    cliente.SubRuta = obj.SubRuta__c
    cliente.Vendedor  = obj.Vendedor__r.VendedorId__c
    cliente.DiasCredito__c = obj.DiasCredito__c
    cliente.Name =  cliente.Name.replace "¬•" , "Ñ"
    cliente.Codigo = obj.CodigoExterno__c || ""
    cliente.Saldo = obj.Saldo__c || 0.00
    cliente.Credito = obj.CreditoAsignado__c || 0.00
    cliente.Activo = obj.Activo__c || true
    cliente.Telefono = obj.Telefono__c || "N/D"
    cliente.Meta= obj.Meta__c || 0.00
    cliente.Venta = obj.Ventas__c || 0.00
    Cliente.create cliente

  @set_current: (cliente) ->
    #if cliente?.id != @current?.id
    @current = cliente
    @trigger('current_set' , @current)

  @reset_current: ->
    @current = null
    @trigger('current_reset' , @current)
        
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
      item.Name.search(myRegExp) > -1 or String(item.Codigo).indexOf(query) == 0
        
module.exports = Cliente