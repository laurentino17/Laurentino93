#INCLUDE "PROTHEUS.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} LP596
Programa para retornar informacoes para o lancamento de compesacao.
Este LP faz o devido tratamento de posicionar nas tabelas com base
na sequencia de operacao que o usuario fez.

* Licença       :   fonte cedido ao cliente o qual passa a gerir pelo mesmo.

@param   Caracter, cCampoCt5, campo desejado para retorno de informação DEBITO, CREDITO, HISTORICO, VALOR

@author	Totvs IP
@since	19/12/2003, revisao para 12.1.27 em 08/06/21
@version P12.1.27
@return xRet, informacoes para o LP

/*/
//-------------------------------------------------------------------
User Function LP596(cCampoCt5)

Local xRet
Local xArea		:= GetArea()
Local xAreaSE1	:= SE1->(getArea())
Local xAreaSE5	:= SE5->(getArea())
Local xAreaSA1	:= SA1->(getArea())
Local xAreaSED	:= SED->(getArea())
Local cTipoE5   := Alltrim(SE5->E5_TIPO)
Local cTipAb	:= ""
lOCAL cTipNF	:= ""
Local lUsaTempl	:= .f.

Local cChavNF	:= ""
Local cNumNF	:= ""
Local cCliNF 	:= ""
Local cNomNF	:= ""
Local cNatNF	:= ""
Local cCtaDeb	:= ""

Local cChavRA	:= ""
Local cNumRA	:= ""
Local cCliRA 	:= ""
Local cNomRA	:= ""
Local cNatRA	:= ""
Local cCtaCre	:= ""
Local cItemCre   := ""
Local cItemDeb   := ""

If EXISTBLOCK("IPCWK")
	lUsaTempl := .t.
EndIf

cCampoCt5 := upper(alltrim(cCampoCt5))

// Necessário pois o sistema desposiciona quando usa variável de memória para
// obter valores da compensação
if SE5->(eof())
	if type("NSE5REC")<>"U"
		SE5->(dbgoto(NSE5REC))
	else
		SE5->(dbgoto(AFLAGCTB[1][4]))
	endif
endif

If cTipoE5$"RA,NCC" // Posicionado em títulos de abatimento
	cChavNF	:= SE5->E5_FILORIG+SE5->E5_DOCUMEN
	cChavRA	:= SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIENTE+E5_LOJA)
Else // Posicionado em títulos normais (NF, boleto, etc)
	cChavNF	:= SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIENTE+E5_LOJA)
	cChavRA	:= SE5->E5_FILORIG+SE5->E5_DOCUMEN
EndIf

// Obtém dados a partir da NF/Outro que não seja o título de abatimento (RA/NCC)
dbSelectArea("SE1")
dbSetOrder(1)
If dbSeek(cChavNF)
	cTipNF := Alltrim(SE1->E1_TIPO)
	cCliNF := SE1->E1_CLIENTE+SE1->E1_LOJA
	cNatNF := SE1->E1_NATUREZ
	dbSelectArea("SA1")
	dbSetOrder(1)
	If dbSeek(xFilial("SA1")+cCliNF)
		If lUsaTempl
			cCtaCre := U_IPCWK("CTCLIENTE")
			cItemCre  := U_IPCWK("MVCONTROL-CLI")
			cNomNF := alltrim(SE1->E1_NOMCLI)
			cNumNF := Alltrim(SE1->E1_PREFIXO)+"/"+Alltrim(SE1->E1_NUM)+"/"+Alltrim(SE1->E1_PARCELA)
		Else
			cCtaCre := SA1->A1_CONTA
			cNomNF := alltrim(SE1->E1_NOMCLI)
			cNumNF := Alltrim(SE1->E1_PREFIXO)+"/"+Alltrim(SE1->E1_NUM)+"/"+Alltrim(SE1->E1_PARCELA)
			cItemCre := ""
		EndIf
	EndIf
EndIf

// Obtém dados a partir do título de abatimento (RA/NCC)
dbSelectArea("SE1")
dbSetOrder(1)
If dbSeek(cChavRA)
	cTipAb := Alltrim(SE1->E1_TIPO)
	cCliRA := SE1->E1_CLIENTE+SE1->E1_LOJA
	cNatRA := SE1->E1_NATUREZ
	cCtaDeb := SE1->E1_CREDIT

	dbSelectArea("SA1")
	dbSetOrder(1)
	If dbSeek(xFilial("SA1")+cCliRA)
		If lUsaTempl
			cItemDeb := U_IPCWK("MVCONTROL-CLI")
			cNomRA := alltrim(SE1->E1_NOMCLI)
			cNumRA := Alltrim(SE1->E1_PREFIXO)+"/"+Alltrim(SE1->E1_NUM)+"/"+Alltrim(SE1->E1_PARCELA)
		Else
			cNomRA := alltrim(SE1->E1_NOMCLI)
			cNumRA := Alltrim(SE1->E1_PREFIXO)+"/"+Alltrim(SE1->E1_NUM)+"/"+Alltrim(SE1->E1_PARCELA)
			cItemDeb := ""
		EndIf
	EndIf
	If cNomRA==cNomNF // Se for o mesmo cliente não levo para o histórico
		cNomRA := ""
	EndIf
	If Empty(cCtaDeb)
		dbSelectArea("SED")
		dbSetOrder(1)
		If dbSeek(xFilial("SED")+cNatRA)
			If lUsaTempl
				If cTipAb=="NCC"
					cCtaDeb := U_IPCWK("CTPAS-DEVVEN")
				Else
					cCtaDeb := U_IPCWK("CTCRE-SE1")
				Endif
			Else
				cCtaDeb := SED->ED_CONTA
			EndIf
		EndIf
	Endif
EndIf

If cCampoCt5=="DEBITO"
	xRet := cCtaDeb
ElseIf cCampoCt5=="CREDITO"
	xRet := cCtaCre
ElseIf cCampoCt5=="HISTORICO"
	xRet := "BX.COMP.CR."+cNumNF+" CONTRA "+cNumRA+" "+cNomRA
ElseIf cCampoCt5=="VALOR"
	// Aqui pode testar a variável cTipAb para decidir se contabiliza ou não quando for por exemplo NCC.
	If SE5->E5_MOEDA=="01"
		xRet := VALOR
	Else
		xRet := VALORMF
	Endif
ElseIf cCampoCt5=="TIPO_NF"
	xRet := cTipNF
ElseIf cCampoCt5=="TIPO_ABAT"
	xRet := cTipAb
ElseIf cCampoCt5=="TIPOS"
	xRet := cTipNF+"/"+cTipAb
ElseIf cCampoCt5=="CLINF"
	xRet := cCliNF
ElseIf cCampoCt5=="CLIRA"
	xRet := cCliRA
ElseIf cCampoCt5=="ITEMD"
	xRet := cItemDeb
ElseIf cCampoCt5=="ITEMC"
	xRet := cItemCre
ElseIf cCampoCt5=="DECRESCIMO"
	// Ref: https://tdn.totvs.com/pages/releaseview.action?pageId=233747403
	if FWIsInCallStack("CTBAFIN")
		xRet := VALOR9
	else
		xRet := VALOR7
	endif
EndIf

RestArea(xAreaSE1)
RestArea(xAreaSE5)
RestArea(xAreaSA1)
RestArea(xAreaSED)
RestArea(xArea)

Return xRet
