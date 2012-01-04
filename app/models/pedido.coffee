Spine = require('spine')
Item = require('models/item')
Archive = require('models/archive')

class Pedido extends Spine.Model
  @configure 'Pedido', "Name" , "Cliente" ,"Estado" ,"Total" , "Referencia" , "Transporte" , "Observacion","Plazo","Ruta", "Items" , "Email" , "Telefono" , "Nombre" , "Identificacion","Fuente","Contado"
  
  @extend Spine.Model.Local

  format_for_server: ->  
    results = []
    items = Item.findAllByAttribute "Parent_id" , @id
    for item in items
      temp = 
        id: @id
        Nombre__c: @Nombre
        Email__c: @Email
        Telefono__c: @Telefono
        Identificacion__c: @Identificacion
        Cliente__c: @Cliente
        Plazo__c: @Plazo
        Referencia__c: @Referencia
        Observacion__c: @Observacion
        Fuente__c: @Fuente
        IsContado__c: @Contado
        Estado__c: @Estado
        item_id: item.id
        Producto__c: item.Producto
        Cantidad__c: item.Cantidad
        Precio__c: item.Precio
        Descuento__c: item.Descuento
        Impuesto__c: item.Impuesto
        Costo__c : item.Costo
      results.push temp
    results

  @create_from_cliente: (cliente = {Name: "",id: null , DiasCredito: 0}) ->
    Pedido.create 
      Name        : cliente.Name
      Cliente     : cliente.id if cliente.id
      Fuente      : "Agente"
      Plaza       : cliente.DiasCredito
      Total       : 0
      Estado      : "Pendiente"
      Referencia  : parseInt(Math.random() * 100000)
      Items       : []
      Observacion : ""
      Transporte  : ""   

  send_to_server: (user) =>
    data = user.to_auth { type: "Oportunidad__c" , items: JSON.stringify( @format_for_server() )  }
    $.ajax
      url        :  Spine.server + "/save"
      type       :  "POST"
      data       :  data
      success    :  @on_send_success
      error      :  @on_send_error

  on_send_success: (raw_results) =>
    results = JSON.parse raw_results
    @trigger "ajax_complete" , results

  on_send_error: (error) =>
    responseText = error.responseText
    if responseText.length > 0
      errors = JSON.parse responseText
    else
      errors = { type:"LOCAL" , error: " Indefinido: Posiblemente Problema de Red", source: "Pedido" }
    @trigger "ajax_error" , errors

  @items_by_cliente: (query,over_cero=false) ->
    return Pedido.all() if !query
    @select (item) ->
      match = true
      if query
        match = item.Cliente == query and (item.Total > 0 or !over_cero)
      else
        match = item.Total > 0 if over_cero
      match

  @bulk_delete: ->
    for item in Pedido.all()
      item.destroy()

module.exports = Pedido