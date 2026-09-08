# Sistema de Cobrança e Liberação de Pedido
 
Projeto de portfólio em Salesforce Sales Cloud + Service Cloud que automatiza um problema comum em empresas B2B com análise de crédito: quando um cliente atrasa um boleto, o pedido de venda fica bloqueado até a dívida ser regularizada. Fiz isso pra praticar Apex assíncrono (Batch e Queueable), LWC e integração REST resolvendo um cenário de negócio de verdade, em vez de um exemplo isolado.

## O problema
 
Sem automação, esse processo costuma ser manual: alguém do financeiro precisa checar boletos vencidos, avisar o time de vendas, e depois liberar o pedido na mão quando o cliente paga. Isso atrasa a cobrança e, às vezes, o pedido acaba liberado sem a dívida estar realmente quitada.

### FLUXO DE FUNCIONAMENTO

```
1. Parcela vence e não é paga (tempo limite definido em 3 dias)

2. Batch Apex identifica a se está inadimplente

3. Conta é marcada como inadimplente e um Case de cobrança é criado

4. O Operador financeiro negocia a dívida através do LWC no Case

5. Após parcelas quitadas , a Conta é reativada , o Pedido liberado e o Case fechado

6. Por fim o Queueable Apex vai notificar o ERP através de um callout HTTP assíncrono
```

## Por que fiz certas escolhas
 
**Batch Apex pra identificar inadimplência em vez de Trigger.** \
A regra depende de tempo, não existe evento de gravação pra isso, então não tem como ser trigger. 
 
**Queueable realizando callout ao ERP.** \
A estrutura do Queueable aceita objetos mais complexos no construtor e dá pra encadear outro job depois caso necessário.
 
**Case só fecha e Order só libera quando não sobra parcela em aberto.** \
Na primeira versão eu tinha deixado o Case fechando assim que qualquer parcela selecionada fosse quitada, mesmo com dívida sobrando. Esse problema só percebi testando manualmente. Corrigi pra contar quantas parcelas ainda estão em aberto antes de liberar e tornar o case fechado.

 
## Capturas de tela

<img width="1918" height="788" alt="imagem do case com uma parcela" src="https://github.com/user-attachments/assets/bfd20151-a0d1-4519-82b3-8f3d8338701b" />


<img width="1502" height="685" alt="parcela quitada com mensagem de sucesso" src="https://github.com/user-attachments/assets/516bddb5-0a3d-4240-b7a9-c02837444e82" />


<img width="1913" height="605" alt="case closed apos quitar" src="https://github.com/user-attachments/assets/a7c8e5ef-ef4d-4550-bc3b-c7f357ae5a6e" />

## Autor
 
Yuri Ferreira — Salesforce Developer Junior\
[LinkedIn](https://linkedin.com/in/yuri-ferreira-ab154534b) · [Trailhead](https://salesforce.com/trailblazer/yurivitorcf)
