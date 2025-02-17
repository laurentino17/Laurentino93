#include "protheus.ch"

/*/{Protheus.doc} User Function PE01NFESEFAZ
Ponto de entrada antes da montagem dos dados da transmissão da NFE
@type  Function
@author Guilherme Laurentino
@since 06/12/2024
@see https://centraldeatendimento.totvs.com/hc/pt-br/articles/4404432005655--Cross-Segmentos-Backoffice-Protheus-Doc-Eletr%C3%B4nicos-Ponto-de-entrada-no-NFESEFAZ-PE01NFESEFAZ
@obs Posições do Array:
    [01] = aProd
    [02] = cMensCli
    [03] = cMensFis
    [04] = aDest
    [05] = aNota
    [06] = aInfoItem
    [07] = aDupl
    [08] = aTransp
    [09] = aEntrega
    [10] = aRetirada
    [11] = aVeiculo
    [12] = aReboque
    [13] = aNfVincRur
    [14] = aEspVol
    [15] = aNfVinc
    [16] = aDetPag
    [17] = aObsCont
    [18] = aProcRef
    [19] = aMed
    [20] = aLote
/*/


USER FUNCTION PE01NFESEFAZ()

Local aDados   := PARAMIXB
Local cMsgAux  := ""
 
    cMsgAux += CRLF + '"Declaro que os produtos perigosos estao adequadamente classificados, embalados, identificados, e estivados para suportar os riscos das operacaoes de transporte e que atendem as exigencias da regulamentacao."'

    //Incrementa na mensagem que irá para o xml e danfe
    aDados[02] += cMsgAux

RETURN aDados





