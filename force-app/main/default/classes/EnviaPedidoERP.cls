public with sharing class EnviaPedidoERP implements Queueable, Database.AllowsCallouts, Finalizer {
    
    // IDs dos pedidos que serão processados
    private Set<Id> orderIds; 

    public EnviaPedidoERP(Set<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(this);

        //buscar os dados dos pedidos 
        List<Order> pedidos = [SELECT Id, OrderNumber, Status__c, AccountId, Account.Name, TotalAmount FROM Order WHERE Id IN :orderIds];

        //loop para disparar o callout individual
        for(Order pedido : pedidos){
            enviarParaERP(pedido);
        }
    }

    public void execute(FinalizerContext context) {
        //validação se a execução não disparou uma exceção 
        if (context.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
           System.debug(LoggingLevel.ERROR,
                'Falha: Job Id: ' + context.getAsyncApexJobId() +
                'Erro: ' + context.getException().getMessage());
        }
    }

    private void enviarParaERP(Order ped) {
        //monta a estrutura do corpo da requisição JSON
        Map<String, Object> payload = new Map<String, Object>{
            'pedidoId' => ped.Id,
            'numero' => ped.OrderNumber,
            'status' => ped.Status__c,
            'cliente' => ped.Account.Name,
            'valorTotal' => ped.TotalAmount
        };

        //configuração dos parâmetros do protocolo HTTP
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ERP_Mock/pedidos');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        req.setTimeout(10000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        //retonra a resposta do servidor ERP
        System.debug('Resposta: ' + res.getStatusCode());
    }
}
