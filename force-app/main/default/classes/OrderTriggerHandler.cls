public with sharing class OrderTriggerHandler {

    public static void run(List<Order> novos, Map<Id, Order> antigos, Boolean isInsert, Boolean isUpdate) {
        // conjunto de IDs para armazenar apenas as Orders que precisam ser enviadas ao ERP
        Set<Id> orderIdsParaNotificar = new Set<Id>();

        if (isInsert) {
            for (Order o : novos) {
                // um pedido novo adicionado seu ID na lista de envio
                orderIdsParaNotificar.add(o.Id);
            }
        }

        if (isUpdate) {
            for (Order o : novos) {
                // pega a versão antiga do mesmo pedido no mapa para comparar alterações
                Order antigo = antigos.get(o.Id);

                // checa se o status do cliente foi alterado 
                if (o.Status__c != antigo.Status__c) {
                    orderIdsParaNotificar.add(o.Id);
                }
            }
        }
        //valida se não está vazio para não fazer chamada sem pedido
        if (!orderIdsParaNotificar.isEmpty()) {
            //processa a fila que vai disparar a notificação através da classe responsável(EnviaPedidoERP)
            System.enqueueJob(new EnviaPedidoERP(orderIdsParaNotificar));
        }
    }
}