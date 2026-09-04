public with sharing class BatchIdentificarInadimplentes implements Database.Batchable<SObject>{

    public Database.QueryLocator start(Database.BatchableContext context) {
        
        // Define a data limite para parcelas vencidas
        Date limite = System.today().addDays(-3);
        
        //Busca de todas as parcelas abertas que já tenham passado do tempo limite e que estejam vinculadas a alguma conta 
        return Database.getQueryLocator([SELECT Id, Account__c FROM Parcela__c WHERE Status__c = 'Em aberto' AND Data_Vencimento__c <= :limite AND Account__c != null]);
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
        
        // Buscar Accounts que já possuam um Case de cobrança em aberto
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName();

        //validação para evitar excpetion null
        if (!rtMap.containsKey('Cobranca')) {
            return;
        }

        Id recordTypeIdFinanceiro = rtMap.get('Cobranca').getRecordTypeId();     

        //Busca e armazena as conas com case aberto
        Set<Id> contasComCaseAberto = new Set<Id>();
        for(Case c : [SELECT AccountId From Case Where AccountId IN :accountIds AND RecordTypeId = :recordTypeIdFinanceiro AND IsClosed = false]) {
            contasComCaseAberto.add(c.AccountId);
        }
        //PROCESSAMENTO - cria novos Cases apenas para contas que não possuem Case em aberto
        List<Case> novosCases = new List<Case>();
        for(Id accId : accountIds){
            if(!contasComCaseAberto.contains(accId)){
                novosCases.add(new Case(
                    AccountId = accId,
                    RecordTypeId = recordTypeIdFinanceiro,
                    Status = 'Novo',
                    Origin = 'Automático',
                    Subject = 'Cobrança automática por inadimplência'));
            }
        }

        //validação antes de inserir os novos cases
        if (!novosCases.isEmpty()) {
            insert novosCases;

            //PROCESSAMENTO - cria Task vinculada a cada nova Case gerado e insere
            List<Task> tarefas = new List<Task>();
            for (Case c : novosCases) {
                tarefas.add(new Task(
                    WhatId = c.Id,
                    Subject = 'Negociar parcelas em atraso',
                    ActivityDate = System.today().addDays(2),
                    Status = 'Not Started',
                    Priority = 'High'
                ));
            }
            insert tarefas;       
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}
