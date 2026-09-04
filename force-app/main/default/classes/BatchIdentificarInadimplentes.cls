public class BatchIdentificarInadimplentes implements Database.Batchable<SObject>, Database.Stateful {

    public Database.QueryLocator start(Database.BatchableContext context) {
        
        // Define a data limite para parcelas vencidas
        Date limite = System.today().addDays(-3);
        
        //Busca de todas as parcelas abertas que já tenham passado do tempo limite e que estejam vinculadas a alguma conta 
        return Database.getQueryLocator([SELECT Id, Account__C, Account__r.Status__c FROM Parcela__c WHERE Status__c = 'Em aberto' AND Data_Vencimento__c < :limite AND Account__C != null]);
    }

    public void execute(Database.BatchableContext context, List<Parcela__c> scope) {
        // Uma collection set para armazenar os valores únicos dos Ids relacionados as parcelas
        Set<Id> accountIds = new Set<Id>();

        //loop para popular o accountIds criado
        for(Parcela__c parcela in scope){
            accountIds.add(parcela.Account__c);
        }
        //validação para encerrar o processo caso não haja nenhuma conta
        if(accountIds.isEmpty()){
            return;
        }

        //PROCESSAMENTO - atualização do status das contas para inadimplente
        //Buscando contas relacionadas a parcelas atrasadas e que não estão inadimplente no set criado
        List<Account> contasParaAtualizar = [SELECT Id, Status__c FROM Account WHERE Id IN :accountIds AND Status__c != 'Inadimplente'];

        //Conversão do status para inadimplente
        for(Account conta in contasParaAtualizar){
            conta.Status__c = 'Inadimplente';
        }

        //validação antes de processar um DML
        if(!contasParaAtualizar.isEmpty()){
            update contasParaAtualizar;
        }      
        


    }

    public void finish(Database.BatchableContext context) {

    }
}
