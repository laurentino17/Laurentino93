/**********************************************************************************************
* Programa		:	NomForCli																	
* Autor			:	Dione Oliveira
* Data			:	29/08/2019
* Descricao		:	Retornar o nome do cliente ou do fornecedor dependendo do tipo do pedido
* Parametros	:	Nao utilizado.
* Retorno		:	cNome
*
***********************************************************************************************/

User Function NomForCli(nTp)
Local cRet 		:= ""
Local aArea		:= GetArea()
Local aAreaSC7  := GetArea()
local cCodF 	:= ""
local nTamCodCF := 0
local nTamLoj   := 0

	If nTp == 1
		If SC5->C5_TIPO == "B" .Or. SC5->C5_TIPO == "D"
			cRet := Posicione("SA2",1,xFilial("SA2") + SC5->C5_CLIENTE + SC5->C5_LOJACLI,"A2_NOME")
		Else
			cRet := Posicione("SA1",1,xFilial("SA1") + SC5->C5_CLIENTE + SC5->C5_LOJACLI,"A1_NOME")
		EndIf         

	ElseIf nTp == 2
		If SF1->F1_TIPO == "D" .or. SF1->F1_TIPO == "B"
			cRet := Posicione("SA1",1,xFilial("SA1") + SF1->F1_FORNECE + SF1->F1_LOJA,"A1_NOME")
		Else
			cRet := Posicione("SA2",1,xFilial("SA2") + SF1->F1_FORNECE + SF1->F1_LOJA,"A2_NOME")
		EndIf

	ElseIf nTp == 3
		If SF2->F2_TIPO == "B" .Or. SF2->F2_TIPO == "D"
			cRet := Posicione("SA2",1,xFilial("SA2") + SF2->F2_CLIENTE + SF2->F2_LOJA,"A2_NOME")
		Else
			cRet := Posicione("SA1",1,xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA,"A1_NOME")
		EndIf         
	
	ElseIf nTp == 4
		If M->C5_TIPO$"DB"
			cRet := Posicione("SA2",1,xFilial("SA2") + M->C5_CLIENTE + M->C5_LOJACLI,"A2_NOME")
		Else
			cRet := Posicione("SA1",1,xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI,"A1_NOME")
		EndIf         

	ElseIf nTp == 5
		If M->F1_TIPO$"DB"
			cRet := Posicione("SA1",1,xFilial("SA1") + M->F1_FORNECE + M->F1_LOJA,"A1_NOME")
		Else
			cRet := Posicione("SA2",1,xFilial("SA2") + M->F1_FORNECE + M->F1_LOJA,"A2_NOME")
		EndIf

	ElseIf nTp == 6
		If M->F2_TIPO$"DB"
			cRet := Posicione("SA2",1,xFilial("SA2") + M->F2_CLIENTE + M->F2_LOJA,"A2_NOME")
		Else
			cRet := Posicione("SA1",1,xFilial("SA1") + M->F2_CLIENTE + M->F2_LOJA,"A1_NOME")
		EndIf

	ElseIf nTp == 7
		If alltrim(SCR->CR_TIPO)=="NF"
			nTamCodCF := FWSX3Util():GetFieldStruct( "F1_DOC" )[3]
			nTamLoj   := FWSX3Util():GetFieldStruct( "F1_SERIE" )[3]
			cCodF := ALLTRIM(substr(SCR->CR_NUM,nTamCodCF+nTamLoj+1))
			cRet := Posicione("SA2",1,xFilial("SA2") + cCodF,"A2_NOME")
		ElseIf alltrim(SCR->CR_TIPO)=="IP"
			SC7->(dbSetOrder(1))
			If SC7->(dbSeek(SCR->CR_FILIAL+alltrim(SCR->CR_NUM)))
				cRet := Posicione("SA2",1,xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,"A2_NOME")
			EndIf
			RestArea(aAreaSC7)
		EndIf

	EndIf
                        
RestArea(aArea)
Return cRet
