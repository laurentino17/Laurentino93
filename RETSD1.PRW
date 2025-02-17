#INCLUDE "PROTHEUS.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} RETSD1
Este programa e usado no LP de devolucao de compras. Objetivo do mesmo e retornar
informacoes da nota fiscal original que encontra-se no SD1.

* Licença       :   fonte cedido ao cliente o qual passa a gerir pelo mesmo.

@type function
@author Totvs IP
@since 06/2021
@version P12.1.27
@param [cCampo], Campo da no fiscal origina cujo conteudo deve ser retornado. Pode ser campo do SD1/SF4
@return cCampo
/*/
//-------------------------------------------------------------------
User Function RETSD1(cCampo)

Local xRet
Local xArea		:= GetArea()
Local xAreaSD1	:= SD1->(GetArea())
Local xAreaSF4	:= SF4->(GetArea())
Local cChaveSD1	:= ""
Local cTab		:= ""
Local aRet		:= TamSX3(cCampo) 

cCampo := Alltrim(cCampo)
If Left(cCampo,3)=="F4_"
	cTab := "SF4"
ElseIf Left(cCampo,3)=="D1_
	cTab := "SD1"
EndIf

cCampo := cTab + "->" + cCampo

cChaveSD1 := SD2->(D2_FILIAL+D2_NFORI+D2_SERIORI+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEMORI)

dbSelectArea("SD1")
dbSetOrder(1)

If dbSeek(cChaveSD1)
	If cTab=="SD1"
		xRet := &(cCampo)
	ElseIf cTab=="SF4" 
		dbSelectArea("SF4")
		dbSetOrder(1)
		If dbSeek(SD1->(D1_FILIAL+D1_TES))
			xRet := &(cCampo)
		EndIf
	EndIf
Else                                   
	If ValType(xRet)=="U"
		If aRet[3]=="C"
			xRet := ""
		ElseIf aRet[3]=="D"
			xRet := ctod(space(8))
		ElseIf aRet[3]=="N"
			xRet := 0
		EndIf
	EndIf

EndIf

RestArea(xAreaSF4)
RestArea(xAreaSD1)
Restarea(xArea)

Return xRet
