global class ProcessamentoDeInadimplentes implements Schedulable{
    global void execute (SchedulableContext sc){
        Database.executeBatch(new BatchIdentificarInadimplentes(), 100);
    }
}