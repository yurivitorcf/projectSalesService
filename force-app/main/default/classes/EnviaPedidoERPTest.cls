@isTest
private class EnviaPedidoERPTest {

    //classe para simular a resposta de um servidor ERP externo
    private class ERPMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"status":"recebido"}');
        return res;
        }
    }

    @isTest
    static void testEnvioPedido() {

        // preparar dados de teste
        Account acc = new Account(Name = 'Cliente Teste');
        insert acc;
        
        Order ped = new Order(
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = System.today()
        );

        insert ped;

        //setando o uso do mock
        Test.setMock(HttpCalloutMock.class, new ERPMock());
    
        //execução controlada da classe que envia um pedido
        Test.startTest();
        System.enqueueJob(new EnviaPedidoERP(
            new Set<Id>{ ped.Id }
        ));
        Test.stopTest();

        //validação dos resultados, job retorna o histórico de execuções assíncronas
        AsyncApexJob job = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals('Completed', job.Status, 'O job deveria ter concluido com sucesso');
        System.assertEquals(0, job.NumberOfErrors, 'O job nao deveria ter erros');
    }
}