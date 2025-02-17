#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"

#DEFINE TIPO_SAIDA 		"S"
#DEFINE TIPO_ENTRADA 	"E"

/*/{Protheus.doc} PE01NFESEFAZ

Implementação do ponto de entrada da NFE para buscar as msg da notas da tabela de mensagen

@type function
@author Daniel A Braga
@since 14/07/2017

@history 14/07/2017, Daniel A Braga, Exemplo de implementação da nova função. 

@see Classe FswTemplMsg
/*/
User Function PE01NFESEFAZ()
	Local aArea 	    := Lj7GetArea({"SC5","SC6","SF1","SF2","SD1","SD2","SA1","SA2","SB1","SB5","SF4","SA3"})
	Local aParam 	    := PARAMIXB 
	Local cMensCli	    := aParam[02]
    Local aNota   	    := aParam[05]
	Local cTipo			:= iif(aNota[4] == "1" ,TIPO_SAIDA,TIPO_ENTRADA)
	Local cDocNF 		:= iif(cTipo == TIPO_SAIDA,SF2->F2_DOC     ,SF1->F1_DOC)
	Local cSerieNF		:= iif(cTipo == TIPO_SAIDA,SF2->F2_SERIE   ,SF1->F1_SERIE)
	Local cCodCliFor	:= iif(cTipo == TIPO_SAIDA,SF2->F2_CLIENTE ,SF1->F1_FORNECE)
	Local cLoja			:= iif(cTipo == TIPO_SAIDA,SF2->F2_LOJA    ,SF1->F1_LOJA)
	Local oFswTemplMsg 	:= FswTemplMsg():TemplMsg(cTipo,cDocNF,cSerieNF,cCodCliFor,cLoja)       	
    
    cMensCli += CRLF + oFswTemplMsg:getMsgNFE() + CRLF
    cMensCli += CRLF + '"Declaro que os produtos perigosos estao adequadamente classificados, embalados, identificados, e estivados para suportar os riscos das operacaoes de transporte e que atendem as exigencias da regulamentacao."'


	aParam[2] := cMensCli

	Lj7RestArea(aArea)  	

Return aParam
