Spine   = require('spine')
Pedido = require('models/pedido')
Cliente = require('models/cliente')
Producto = require('models/producto')
Item = require('models/item')
List    = require('spine/lib/list')
$       = Spine.$

class Pedido_Edit extends Spine.Controller
  className: 'pedido'
  
  events:
    'click .send'                 : 'send'
    'click .archive'              : 'archive'
    'click .icon_button.close'    : 'close_delete'
    'click .edit'                 : 'edit'
    "click .delete_item"          : 'delete_item'
    "keypress input.pedido_item"  : 'on_key_press'
    "click input.pedido_item"     : "focus"
    "focusout input.pedido_item"  : 'change_item'
    "focusout input.pedido"       : 'change_pedido'


  elements: 
    'form'                        :  'form'
    ".item>button"                :  "button"
    "input"                       :  "all_inputs"
    ".total"  : "total"
    ".cantidad:last"              : "last_cantidad"

  ####
  #INITIALIZERS
  ####
    
  constructor: ->
    super
    @accept_producto = true
    @accept_cliente = false
    @pedido = Pedido.create_from_cliente @cliente if !@pedido
    #create by clicking on producto
    if @producto
      @add_item() 
      @accept_cliente = true
      Cliente.bind "current_set"   , @add_cliente
    #created from pedido
    else if !@cliente 
      items = Item.findAllByAttribute("Parent_id" , @pedido.id)
      @pedido.Items = items
      @pedido.save()
    @render()

  bind_external: ->
    Producto.bind "current_set"   , @add_item

  un_bind_external: ->
    Producto.unbind "current_set" , @add_item
    Cliente.unbind "current_set"   , @add_cliente

  render: =>
    @html require('views/main/pedido_edit')(@pedido)
    @update_total()

  update_total: =>
    @total.html Item.total(@pedido.Items).toMoney()
    
  ########
  ## UI
  #########

  on_key_press: (e) ->
    if e.which == 13
      e.currentTarget.blur()
      target = $(e.target)
      target.next().focus()
        
  focus: (e) ->
    target = $(e.currentTarget)
    target.select()

  change_pedido: (e) ->
   target = $(e.currentTarget)
   type = target.attr('data-type')
   name = target.attr('data-name')
   required = target.attr('data-required') || false
   @pedido[type] = target.val() if @validate_item(name,type,target.val(),required)
   @pedido.save()

  get_item_from_index: (element) =>
    id = element.attr('data-id')
    item = Item.find id

  #####
  # UI LOGIC 
  #####

  add_cliente: (cliente) =>
    Cliente.unbind "current_set"   , @add_cliente
    @accept_cliente = false    
    @pedido.Name = cliente.Name
    @pedido.Cliente = cliente.id
    @pedido.save()
    @render()

  add_item: =>
    producto = Producto.current
    search_result = @item_exists(producto)
    if search_result == false
      @pedido.Items.push Item.create_from_template(@pedido.id,producto)
      @pedido.save()
      @render()
    else
      @pedido.Cantidad++
      @pedido.save()
      @render()

  item_exists: (producto) =>
    for item in @pedido.Items
      if item.Producto == producto.id
        return item
    false

  change_pedido: (e) =>
    target = $(e.target)
    
    name = target.attr('data-name')
    
    @pedido[name] = target.val()
    @pedido.save()
    
  change_item: (e) =>
    target = $(e.target)
    item = @get_item_from_index target.parents('.item')
    producto = Producto.find(item.Producto)
    
    type = target.attr('data-type')
    name = target.attr('data-name')
    required = target.attr('data-required') || false

    value = target.val()
    original_value = item[name]
    max_value = producto[name]

    if @validate_item(name,type,value,required, max_value)
      @do_item_change(item,name,value)
      target.removeClass "error"
    else
      target.val @undo_item_change(item,name,original_value,max_value)
      target.addClass "error"
    @render()
      
  do_item_change: (item,name,value) ->
    item[name] = value
    item.save()
    
  undo_item_change: (item,name,original_value,max_value) ->
    value = original_value
    if name == "Descuento"
      value = max_value
      item[name] = max_value
    else if name == "Cantidad"
      value = 1
      item[name] = 1
    item.save()
    return value

  validate_item: (name,type,value,required=false,max_value) ->
    return true if type != 'Numeric' && !required
    return true if type != 'Numeric' && required & value.length > 0
    return true if isNaN(value) == false && parseInt(value) > 0 && name == "Cantidad"
    return true if isNaN(value) == false && parseInt(value) >= 0 && name == "Descuento" && value <= max_value
    return false

  delete_item: (e) =>
    target = $(e.currentTarget)
    item = @get_item_from_index target.parents('.item')
    new_items = (s_item for s_item in @pedido.Items when s_item.id != item.id)
    @pedido.Items = new_items
    item.destroy()    
    @render()

  #####
  # ACTIONS
  #####

  edit: =>
    @trigger "change" , @ , "edit"

  archive: (e) ->
    for item in @pedido.Items
      item.Parent_id= @pedido.id
      item.save()
    @pedido.Total = Item.total(@pedido.Items)
    @pedido.Estado = "Perdido"
    @pedido.save()
    Spine.trigger "show_lightbox" , "send" , @pedido, @after_send

  send: (e) ->
    target = $(e.target)
    tipo = target.attr "data-type"
    for item in @pedido.Items
      item.Parent_id= @pedido.id
      item.save()
    @pedido.Total = Item.total(@pedido.Items)
    @pedido.Referencia = @pedido.Referencia + " " + @pedido.Fuente if @pedido.Fuente != "Agente"
    
    @pedido.Fuente =  if @pedido.Fuente != "Agente" then "Otro" 
    @pedido.Contado = if tipo == "contado" then true else false
    @pedido.Estado = if @pedido.Contado then 'Aprobado' else "Pendiente"
    
    @pedido.save()
    Spine.trigger "show_lightbox" , "send" , @pedido, @after_send

  after_send: (success) =>
    if success
      @el.removeClass 'active'
      @delete_pedido(@pedido) 
      @trigger "change" , @ , "close"
    else
      items = Item.findAllByAttribute("Parent_id" , @pedido.id)
      @pedido.Items = items
      @pedido.save()
      @render()

  close_delete: () =>
    if !@el.hasClass "active"
      if confirm('Se borrara el pedido para siempre, seguimos?')
        @delete_pedido(@pedido) 
        @trigger "change" , @ , "close"
    else
      @trigger "change" , @ , "close"
      
  delete_pedido: (pedido) =>
    for p_item in Item.findAllByAttribute("Parent_id" , pedido.id)
      p_item.destroy()
    pedido.destroy()

module.exports = Pedido_Edit