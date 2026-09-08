public with sharing class NegociarCobrancaController {
    
    //método para buscar as parcelas não pagas que estejam relacionadas a conta do Case.
    @AuraEnabled(cacheable=true)
    public static List<Parcela__c> buscarParcelas(Id caseId){

        //busca a conta relacionada ao Case
        Case c = [SELECT AccountId FROM Case WHERE Id = :caseId];

        //retorna as parcelas da conta que ainda não foram pagas ordenadas pela data de vencimento
        return [
            SELECT Id, Valor__c, Data_Vencimento__c, Status__c 
            FROM Parcela__c
            WHERE Account__c = :c.AccountId
            AND Status__c  != 'Pago'
            ORDER BY Data_Vencimento__c ASC
        ];
    }

    //método para quitar as parcelas selecionadas e liberar a conta, os pedidos e o Case
    @AuraEnabled
    public static void quitarDepoisLiberar(Id caseId, List<Id> parcelaIds){
        //validação para não processar nada sem que uma parcela seja selecionada
        if(parcelaIds == null || parcelaIds.isEmpty()){
            throw new AuraHandledException('É necessário selecionar pelo menos uma parcela.');
        }

        //busca a conta relacionada ao Case
        Case c = [SELECT AccountId FROM Case WHERE Id = :caseId];

        //busca as parcelas selecionadas para serem atualizadas
        List<Parcela__c> parcelas = [SELECT Id, Status__c FROM Parcela__c WHERE Id IN :parcelaIds];

        //atualiza o status das parcelas selecionadas para pago
        for(Parcela__c parcela : parcelas){
            parcela.Status__c = 'Pago';
        }
        update parcelas;

        //verificar se ainda há parcelas em aberto para não fechar o case com parcelas sem quitar
        Integer parcelasAbertas = [ SELECT COUNT() FROM Parcela__c WHERE Account__c = :c.AccountId AND Status__c != 'Pago'];

        if(parcelasAbertas == 0){
            //depois de quitado, altera o status da conta para ativo
            Account conta = new Account(Id = c.AccountId, Status__c = 'Ativo');
            update conta;

            //busca os pedidos que foram bloqueados relacionados à conta
            List<Order> pedidos = [SELECT Id, Status__c FROM Order WHERE AccountId = :c.AccountId AND Status__c = 'Bloqueado'];

            //libera os pedidos novamente
            for(Order pedido : pedidos){
                pedido.Status__c = 'Liberado';         
            }
            update pedidos;

            //fecha o Case de cobrança após quitado
            update new Case(Id = caseId, Status = 'Closed');
        }       
    }
}