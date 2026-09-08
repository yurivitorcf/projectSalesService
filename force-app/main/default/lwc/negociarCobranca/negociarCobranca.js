import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import buscarParcelas from '@salesforce/apex/NegociarCobrancaController.buscarParcelas';
import quitarDepoisLiberar from '@salesforce/apex/NegociarCobrancaController.quitarDepoisLiberar';


// colunas que serão exibidas na tabela de parcelas do componente
const COLUMNS = [
    { label: 'Vencimento', fieldName: 'Data_Vencimento__c', type: 'date' },
    { label: 'Valor', fieldName: 'Valor__c', type: 'currency' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' }
];

export default class NegociadorCobranca extends LightningElement {
    @api recordId; // Id do Case recebido automaticamente
    columns = COLUMNS; // a configuração das colunas
    parcelas = []; // array que armazena as parcelas que vierem do controller
    selecionadas = []; // array para armazenar qual parcela foi selecionada pelo usuário
    resultadoWire; // armazena o resultado do wire para fazer a atualização depois

    //busca as parcelas relacionadas ao Case atual quando o componente for carregado
    @wire(buscarParcelas, { caseId: '$recordId' })
    wiredParcelas(result) {
        this.resultadoWire = result;
        if (result.data) {
            this.parcelas = result.data;
        } else if (result.error) {
            this.mostrarToast('Erro ao carregar parcelas', this.extrairMensagemErro(result.error), 'error');
        }
    }

    //desabilita o botão caso nenhuma parcela esteja selecionada
    get botaoDesabilitado() {
        return this.selecionadas.length === 0;
    }

    //atualiza a lista de parcelas selecionadas pelo usuário
    handleRowSelection(event) {
        this.selecionadas = event.detail.selectedRows.map((row) => row.Id);
    }

    //envia as parcelas selecionadas para serem processadas 
    async handleQuitar() {
        try {
            await quitarDepoisLiberar({
                caseId: this.recordId,
                parcelaIds: this.selecionadas
            });
            //toast de confirmação visual se der certo 
            this.mostrarToast('Sucesso', 'Parcelas quitadas e pedido liberado!', 'success');
            //limpa as parcelas selecionadas
            this.selecionadas = [];
            //atualiza os dados na tabela de cobranças
            await refreshApex(this.resultadoWire);

        } catch (erro) {
            //toast de confirmação visual se der errado
            this.mostrarToast('Erro ao quitar', this.extrairMensagemErro(erro), 'error');
        }
    }

    //mensagem de feedback para o user
    mostrarToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    //caso dê erro no controller retorna a mensagem dele
    extrairMensagemErro(erro) {
        return erro?.body?.message ?? 'Erro desconhecido';
    }
}