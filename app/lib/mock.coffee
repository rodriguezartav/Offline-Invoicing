class Mock
  constructor: ->
    $.mockjax 
      url: '/update',
      responseTime: 750,
      responseText: @get_data_as_json()

    $.mockjax 
      url: '/save',
      responseTime: 750,
      response: (settings) ->
        pedidos = JSON.parse settings.data
        response = []
        for pedido in pedidos
          response.push {success:true , id: "new_id-" + pedido.id , pedido: pedido} 
        @responseText = JSON.stringify(response)
       

  get_data_as_json: ->  
    clientes= [
      {Name: 'Joaquim Velazco' , id: 'axjdfksjfkshs1' , Codigo: '101345' , Saldo: 500000 , Credito: 1000000}
      {Name: 'Matereriales Ferreterros para la Construccion' , id: 'axjdfksjfkshs23' , Codigo: '105333', Saldo: 1500000 , Credito: 1000000}
      {Name: 'Victor Manuel Chavez' , id: 'axjdfksjfkshs3' , Codigo: '234544', Saldo: 300000 , Credito: 500000}
      {Name: 'Simplicio Bobadilla' , id: 'axjdfksjfkshs4' , Codigo: '24555', Saldo: 50000 , Credito: 200000}
      {Name: 'Ruben Validisio' , id: 'axjdfksjfkshs5' , Codigo: '334455', Saldo: 10000000 , Credito: 10000000}
    ]

    productos= [
      {Name: 'Zapatos Verdes' , id: 'axjdfksjfkshs1p' , Codigo: '61003033833'   , Cantidad: 323 , Precio: 344.44 , Descuento: 9  ,  Impuesto: 13 }
      {Name: 'Camisa Amarilla' , id: 'axjdfksjfkshs2p' , Codigo: '1016013018'    , Cantidad: 23 , Precio: 1497.17 , Descuento: 4  ,  Impuesto: 13 }
      {Name: 'Pantalon Largo' , id: 'axjdfksjfkshs3p' , Codigo: '1261003033833' , Cantidad: 2 , Precio: 765.00 , Descuento: 15   ,  Impuesto: 13 }
      {Name: 'Pantalon Corto' , id: 'axjdfksjfkshs4p' , Codigo: '331016013018'  , Cantidad: 77 , Precio: 29876.44 , Descuento: 2 ,  Impuesto: 0  }
    ]

    return JSON.stringify {clientes: clientes , productos: productos}

module?.exports = Mock