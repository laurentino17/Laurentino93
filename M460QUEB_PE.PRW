#INCLUDE 'PROTHEUS.CH'

/*
{Protheus.doc} User Function M460QUEB()
Este ponto de entrada permite escolher se haverá ou não a quebra do Documento de Saída e é chamado quando o sistema não pré-determina que há uma quebra.
O ponto de entrada é executado ao gerar o documento de saída.
@type  Function
@author Guilherme Laurentino
@since 09/01/2025
https://tdn.totvs.com/pages/releaseview.action?pageId=6784198
*/

************************
User Function M460QUEB()
************************
 
Local lQuebra    := .F.
Local cAlias     := ""
Local aPvlNfs    := {}
Local nX         := 1
 
cAlias  := ParamIxb[01]
aPvlNfs := If(Len(ParamIxb[02]) <> 0 , aClone(ParamIxb[02]),{})
 
/*
aPvlNfs    Array com os seguintes campos como
  { C9_PEDIDO   ,;    //01
    C9_ITEM     ,;    //02
    C9_SEQUEN   ,;    //03
    C9_QTDLIB   ,;    //04
    nPrcVen     ,;    //05
    C9_PRODUTO  ,;    //06
    F4ISS=="S"  ,;    //07
    C9RECNO     ,;    //08
    C5RECNO     ,;    //09
    C6RECNO     ,;    //10
    E4RECNO     ,;    //11
    B1RECNO     ,;    //12
    B2RECNO     ,;    //13
    F4RECNO     ,;    //14
    B2_LOCAL    ,;    //15
    0           ,;    //16 - Compatibilidade (Não Usado)
    C9_QTDLIB2})    //17
*/
 
For nX := 1 To Len(aPvlNfs)
    SB1->(DbGoTo(aPvlNfs[nX,12]))
    lQuebra := If(Upper(Alltrim(SB1->B1_ZZAGREG )) == "2",.T.,lQuebra)
    //Caso em algum dos itens do pedidos de venda tenha produto com agrega igual "1" OU "2" é retornardo a quebra como Verdadeiro
    //Para funcionamento analisar os campos dos parametros F12 (Agre) ápos selecionar a serie da nota fiscal. 
    If lQuebra
        Exit
    EndIf
Next
 
Return(lQuebra)
