#include "Protheus.ch"
#include "TopConn.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} IPCWK(cCodForm)

Este programa tem a função de executar as fórmulas do cadastro de fórmulas da contabilidade (CWK).
O funcionamento é praticament e o mesmo da função EJEFOR. A diferença é que o sistema não deixa usar o 
EJERFOR mais de uam vez no mesmo campo no CT5, por exemplo EJEFOR().AND.EJEFOR().

* Licença       :   fonte cedido ao cliente o qual passa a gerir pelo mesmo.

Parâmetros:
- Código da fórmula

Retorno:
- Resultado da macro execução da expressão da fórmula

@author	Totvs IP
@since	Jun/2021
@param cCodForm, código da fórmula para macro executar
@return xRet, resultado na macro execução
/*/
//-------------------------------------------------------------------

user function IPCWK(cCodForm)

// Declaração de variáveis
local xRet      := Nil
local xArea		:= GetArea()
local xAreaCWK  := CWK->(GetArea())
local cTipo     := ""
local cForm     := ""

// Ativa áreas CWK para buscar a fórmula
dbSelectArea("CWK")
dbSetOrder(1)

// Posiciona na fórmula para macro executar
If dbseek(xFilial("CWK")+cCodForm)

    cTipo := CWK->CWK_TIPO
    
    // Verifica o tipo de dado da CWK
    If cTipo == "1" // Conta
        xRet := ALLTRIM(CWK->CWK_CUENTA)
    ElseIf cTipo == "2" // Centro de custos
        xRet := ALLTRIM(CWK->CWK_CC)
    ElseIf cTipo == "3" // Item contábil
        xRet := ALLTRIM(CWK->CWK_ITECTB)
    ElseIf cTipo == "4" // Classe de Valor
        xRet := ALLTRIM(CWK->CWK_CLVALO)
    ElseIf cTipo == "5" // Expressão ADVPL
        cForm := AllTrim(CWK->CWK_ADVPL)
        xRet := &cForm
    Endif
Else
    // Tratamento para mostrar msg de fórmula não quebrar e tentativa do
    // código não quebrar
    If Left(cCodForm,2)=="VR"
        xRet := 0
    ElseIf Left(cCodForm,2)$"CT,IT,CL,CC,HS"
        xRet := ""
    EndIf
    Aviso( OemToAnsi("Erro"),OemToAnsi("Fórmula ") + cCodForm + OemToAnsi(" não encontrada no cadastro de fórmulas CWK"), {OemToAnsi("OK")} )
EndIf

// Este bloco é apenas para validar e ver na tela de lançamentos contábeis o código da fórmula que seria executada
/*
If Valtype(xRet)=="C"
    if empty(xRet)
        xRet := cCodForm
    Endif
EndIf
*/
RestArea(xAreaCWK)
RestArea(xArea)

Return xRet


/*/{Protheus.doc} CWKGRP
Programa chamados em gatilhos SC, PC, Doc.Entrada, Ctas Pag/Rec, Mov Banc para retornar conta contábil do
movimento.

* Licença       :   fonte cedido ao cliente o qual passa a gerir pelo mesmo.

@type function
@author Totvs IP
@since 07/2023
@version P12.1.2210
@param 
@Return lRetOk
/*/

//-------------------------------------------------------------------
user function CWKGRP(nProc,nTipoRegr)

    local cRet      := ""
    local xArea     := getarea()
    local xAreaSF4  := SF4->(getarea())
    local xAreaSB1  := SB1->(getarea())
    local xAreaSED  := SED->(getarea())
    local xAreaCTT  := CTT->(getarea())
    local xAreaCWK  := CWK->(getarea())

    default nTipoRegr := 1 // Letra por Regra no C.Custo
    
    if nProc == 1
        cRet := FMODDE(nTipoRegr) //Doc.Entrada
    elseif nProc == 2
        cRet := FMODCP(nTipoRegr) //Ctas.A pagar
    elseif nProc == 3
        cRet := FMODCR(nTipoRegr) //Ctas A Receber
    elseif nProc == 4
        cRet := FMODMB(nTipoRegr) //Movimento Bancário
    elseif nProc == 5
        cRet := FMODMI(nTipoRegr) //Movimento Interno
    elseif nProc == 6
        cRet := FMODSC(nTipoRegr) //Solicitação de compras
    elseif nProc == 7
        cRet := FMODPC(nTipoRegr) //Pedido de compras
    Endif

    cRet := padr(cRet,tamsx3("CT1_CONTA")[1])

    restArea(xAreaCWK)
    restArea(xAreaCTT)
    restArea(xAreaSED)
    restArea(xAreaSB1)
    restArea(xAreaSF4)
    restArea(xArea)

Return cRet

//-------------------------------------------------------------------
static function FMODDE(nTipoRegr)

    local cRet      := ""
    local lEst		:= .f.
    local lDup		:= .f.
    Local cConta	:= ""
    Local cCcusto	:= ""
    local cGrpCtb   := ""

    If ValType(aCols) == "U"
        Return cRet
    ElseIf Len(aCols) == 0
        Return cRet
    Elseif GDFieldPos("D1_COD")==0 .Or.  GDFieldPos("D1_TES")==0 .Or. GDFieldPos("D1_CONTA")==0 .Or. GDFieldPos("D1_CC")==0
        Return cRet
    EndIf

    cProduto	:= alltrim(aCols[n,GDFieldPos("D1_COD",aHeader)])
    cCodTES		:= alltrim(aCols[n,GDFieldPos("D1_TES",aHeader)])
    cConta		:= alltrim(aCols[n,GDFieldPos("D1_CONTA")])
    cCcusto		:= alltrim(Iif(X3USADO("D1_CC"),aCols[n, GDFieldPos("D1_CC")],""))
    cRet        := cConta

    If empty(cCodTES) .or. empty(cProduto)
        return cRet
    endif

    SB1->(dbSetOrder(1))
    SB1->(dbSeek(xFilial("SB1")+cProduto))

    SF4->(dbsetorder(1))
    SF4->(dbseek(xFilial("SF4")+cCodTES))

    lEst := If(SF4->F4_ESTOQUE=="S",.t.,.f.)
    lDup := If(SF4->F4_DUPLIC=="S",.t.,.f.)
    cCfop := alltrim(SF4->F4_CF)

    if lEst .and. !Empty(cConta)
        cRet := cConta
    ElseIf SubStr(cCfop,2,3) $ SuperGetMV("ZZ_ERPM013", .f.,"406,551")
        cRet := cConta
    elseif !lEst .and. lDup
        If SB1->(FieldPos("B1_ZZGRCTB")) > 0
            cGrpCtb := alltrim(SB1->B1_ZZGRCTB)
        endif
        If !Empty(cGrpCtb)
            cRet := retCta(nTipoRegr,cGrpCtb,cCcusto,"")
        else
            cRet := cConta
        endif
    else
        cRet := cConta
    endif

return cRet


//-------------------------------------------------------------------
static function FMODCP(nTipoRegr)

    local cRet      := ""
    local cNaturez  := ""
    Local cConta	:= ""
    Local cCcusto	:= ""
    local cGrpCtb   := ""

    cNaturez	:= alltrim(M->E2_NATUREZ)
    cConta		:= alltrim(M->E2_DEBITO)
    cCcusto		:= alltrim(M->E2_CCD)
    cRet        := cConta

    if empty(cNaturez)
        return cRet
    endif

    SED->(dbsetorder(1))
    SED->(dbseek(xFilial("SED")+cNaturez))

    If SED->(FieldPos("ED_ZZGRCTB")) > 0
        cGrpCtb := alltrim(SED->ED_ZZGRCTB)
    endif

    If !Empty(cGrpCtb)
        cRet := retCta(nTipoRegr,cGrpCtb,cCcusto,"")
    elseif empty(cRet) .and. !empty(cConta)
        cRet := cConta
    elseif empty(cRet) .And. !empty(SED->ED_CONTA)
        cRet := SED->ED_CONTA
    endif
    
return cRet

//-------------------------------------------------------------------
static function FMODCR(nTipoRegr)

    local cRet      := ""
    local cNaturez  := ""
    Local cConta	:= ""
    Local cCcusto	:= ""
    local cGrpCtb   := ""

    cNaturez	:= alltrim(M->E1_NATUREZ)
    cConta		:= alltrim(M->E1_CREDIT)
    cCcusto		:= alltrim(M->E1_CCC)
    cRet        := cConta

    if empty(cNaturez)
        return cRet
    endif

    SED->(dbsetorder(1))
    SED->(dbseek(xFilial("SED")+cNaturez))

    If SED->(FieldPos("ED_ZZGRCTB")) > 0
        cGrpCtb := alltrim(SED->ED_ZZGRCTB)
    endif

    If !Empty(cGrpCtb)
        cRet := retCta(nTipoRegr,cGrpCtb,cCcusto,"")
    elseif empty(cRet) .and. !empty(cConta)
        cRet := cConta
    elseif empty(cRet) .And. !empty(SED->ED_CONTA)
        cRet := SED->ED_CONTA
    endif

return cRet

//-------------------------------------------------------------------
static function FMODMB(nTipoRegr)

    local cRet      := ""
    local cNaturez  := ""
    Local cConta	:= ""
    Local cCcusto	:= ""
    local cGrpCtb   := ""

    cNaturez	:= alltrim(M->E5_NATUREZ)

    if empty(cNaturez)
        return cRet
    endif

    If cRecPag=="P"
        cConta		:= alltrim(M->E5_DEBITO)
        cCcusto		:= alltrim(M->E5_CCD)
    Else
        cConta		:= alltrim(M->E5_CREDIT)
        cCcusto		:= alltrim(M->E5_CCC)
    Endif

    SED->(dbsetorder(1))
    SED->(dbseek(xFilial("SED")+cNaturez))

    If SED->(FieldPos("ED_ZZGRCTB")) > 0
        cGrpCtb := alltrim(SED->ED_ZZGRCTB)
    endif

    If !Empty(cGrpCtb)
        cRet := retCta(nTipoRegr,cGrpCtb,cCcusto,"")
    elseif empty(cRet) .and. !empty(cConta)
        cRet := cConta
    elseif empty(cRet) .And. !empty(SED->ED_CONTA)
        cRet := SED->ED_CONTA
    endif
    
return cRet

//-------------------------------------------------------------------
static function FMODMI(nTipoRegr)

    local cRet      := ""
    Local cConta	:= ""
    Local cCcusto	:= ""
    local cGrpCtb   := ""
    local cOP       := ""

    cProduto	:= alltrim(aCols[n,GDFieldPos("D3_COD",aHeader)])
    cConta		:= alltrim(aCols[n, GDFieldPos("D3_CONTA")])
    cRet        := cConta
    
    If GDFieldPos("D3_CC") > 0
        cCcusto		:= alltrim(Iif(X3USADO("D3_CC"),aCols[ n, GDFieldPos("D3_CC")],""))
    endif

    if empty(cCcusto) .and. !empty(CCC)
        cCcusto := alltrim(CCC)
    endif

    if empty(cProduto)
        return cRet
    endif

    SB1->(dbSetOrder(1))
    SB1->(dbSeek(xFilial("SB1")+cProduto))

    If SB1->(FieldPos("B1_ZZGRCTB")) > 0
        cGrpCtb := alltrim(SB1->B1_ZZGRCTB)
    endif

    If EMPTY(cOP) .And. !Empty(cGrpCtb)
        cRet := retCta(nTipoRegr,cGrpCtb,cCcusto,"")
    else
        cRet := cConta
    endif
    
return cRet

//-------------------------------------------------------------------
static function FMODSC(nTipoRegr)

    local cRet      := ""
    Local cConta	:= ""
    Local cCcusto	:= ""
    local cGrpCtb   := ""

    cProduto	:= alltrim(aCols[n,GDFieldPos("C1_PRODUTO",aHeader)])
    cConta		:= alltrim(aCols[n, GDFieldPos("C1_CONTA")])
    cCcusto		:= alltrim(Iif(X3USADO("C1_CC"),aCols[ n, GDFieldPos("C1_CC")],""))
    cRet        := cConta

    if empty(cProduto)
        return cRet
    endif

    SB1->(dbSetOrder(1))
    SB1->(dbSeek(xFilial("SB1")+cProduto))

    If SB1->(FieldPos("B1_ZZGRCTB")) > 0
        cGrpCtb := alltrim(SB1->B1_ZZGRCTB)
    endif

    If !Empty(cGrpCtb)
        cRet := retCta(nTipoRegr,cGrpCtb,cCcusto,"")
    else
        cRet := cConta
    endif

return cRet

//-------------------------------------------------------------------
static function FMODPC(nTipoRegr)

    local cRet      := ""
    Local cConta	:= ""
    Local cCcusto	:= ""
    local cGrpCtb   := ""

    cProduto	:= alltrim(aCols[n,GDFieldPos("C7_PRODUTO",aHeader)])
    cConta		:= alltrim(aCols[n, GDFieldPos("C7_CONTA")])
    cCcusto		:= alltrim(Iif(X3USADO("C7_CC"),aCols[ n, GDFieldPos("C7_CC")],""))
    cRet        := cConta

    if empty(cProduto)
        return cRet
    endif

    SB1->(dbSetOrder(1))
    SB1->(dbSeek(xFilial("SB1")+cProduto))

    If SB1->(FieldPos("B1_ZZGRCTB")) > 0
        cGrpCtb := alltrim(SB1->B1_ZZGRCTB)
    endif

    If !Empty(cGrpCtb)
        cRet := retCta(nTipoRegr,cGrpCtb,cCcusto,"")
    else
        cRet := cConta
    endif
    
return cRet

//-------------------------------------------------------------------
static function retCta(nTipoRegr,cGrpCtb,cCusto,cRegraCC)

local cCpoCWK := ""
local cRet    := ""

default nTipoRegr := 1
    //1=Pelo C.Custo, 
    //2=Pelo inicio do C.Custo (padrão)
default cCusto   := ""
default cRegraCC := ""

CWK->(dbSetorder(1))
If !CWK->(dbSeek(xFilial("CWK")+cGrpCtb))
    return cRet
endif

if !empty(CWK->CWK_CUENTA)
    return CWK->CWK_CUENTA
endif

If nTipoRegr==1
    cRegraCC := alltrim(posicione("CTT",1,xFilial("CTT")+cCusto,"CTT_CRGNV1"))
elseIf nTipoRegr==2
    If left(cCusto,1)=="1"
        cRegraCC := "A"
    elseif left(cCusto,1)=="2"
        cRegraCC := "C"
    elseif left(cCusto,2)=="31"
        cRegraCC := "D"
    elseif left(cCusto,2)=="32"
        cRegraCC := "I"
    elseif left(cCusto,1)=="4"
        cRegraCC := "S"
    endif
endif

If valtype(cRegraCC)=="C"
    If !Empty(cRegraCC)
        cCpoCWK := "CWK_ZZCTA" + cRegraCC
        If CWK->(FieldPos(cCpoCWK)) > 0
            cCpoCWK := "CWK->" + cCpoCWK
            xResult := &(cCpoCWK)
            If valtype(xResult)=="N"
                cRet := str(xResult)
            elseif valtype(xResult)=="C"
                cRet := xResult
            else
                cRet := ""
            endif
        Else
            MsgAlert("Não existe campo com esta regra na CWK -> " + cRegraCC, "#ERP+IPCWK")
        endif
    endif
endif

return cRet
