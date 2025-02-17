#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"


/*/{Protheus.doc} TIPAC022
Função que da carga de conta contábil ou item contábil de cliente ou fornecedor
* Licença       :   fonte cedido ao cliente o qual passa a gerir pelo mesmo.
@type function
@version  12.1.2210
@author Totvs IP
@since 12/20/2022
@return variant, return_description
/*/

User Function TIPAC022()
    Private nParam := 0
    Private oDlg, oButton, oButton1, oRadio, nRadio:=0
    Private aOptions := {"Cliente","Fornecedor"}

    nParam := SuperGetMV("ZZ_TPCTA", .f., 9)

    if nParam == 9
        MsgAlert("o parâmetro ZZ_TPCTA não existe e não será possível processar a função", "#ERP+TIPAC022")
        Return
    ElseIf nParam == 0
        MsgAlert("Parâmetro ZZ_TPCTA definido pra não criar a conta", "#ERP+TIPAC022")
        Return
    EndIf

    DEFINE MSDIALOG oDlg FROM 0,0 TO 250,450 PIXEL TITLE "Carga de Cadastro"
        DEFINE FONT oBold  SIZE 0, -14 
        oRadio := tRadMenu():New(50,10,aOptions, {|u|if(PCount()>0,nRadio:=u,nRadio)}, oDlg,,,,,,,,100,50,,,,.T.)
        @ 10,10 SAY "O objetivo dessa rotina é dar carga de  conta contábil ou item contabil para Cliente ou Fornecedor" SIZE 200,100 FONT oBold OF oDlg PIXEL
        oTButton := TButton():New( 100, 130, "Processar",oDlg,{||Processa({|| caixa()}, "Processando..."), oDlg:End() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )   
        oTButton1 := TButton():New( 100, 170, "Cancelar",oDlg,{|| oDlg:End()}, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )   
    ACTIVATE MSDIALOG oDlg CENTERED

    if nRadio == 0 
        MsgAlert("Cancelado", "#ERP+TIPAC022")
    EndIf

Return

Static Function caixa()
    Private cEntRef := ""
    Private cCodPla := ""
    Private cVersao := ""
    Private cRefNor := ""
    Private cCusto  := ""
    Private cLog    := ""
    Private cEOL    := CHR(13) + CHR(10)

    if nRadio == 1 //Processa Clientes 
        SA1->(DbSelectArea("SA1"))
        SA1->(DbSetOrder(1))
        ProcRegua(SA1->(LastRec()))
        SA1->(DbGoTop())
        While SA1->(!EOF())
            incProc("Processando Clientes...")            
            If SA1->A1_MSBLQL == "1"
                SA1->(dbSkip())
                Loop
            Else
                CargaCliente()
            EndIf
            SA1->(dbSkip())
        EndDo

    ElseIf nRadio == 2 //Processa Fornecedores
        SA2->(DbSelectArea("SA2"))
        SA2->(DbSetOrder(1))
        ProcRegua(SA1->(LastRec()))
        SA2->(DbGoTop())
        While SA2->(!EOF())
            incProc("Processando Fornecedores...")        
            If SA2->A2_MSBLQL == "1"
                SA2->(dbSkip())
                Loop
            Else
                CargaForn()
            EndIf
            SA2->(dbSkip())
        EndDo
    EndIf

Return

Static Function CargaCliente()
    if nParam == 1
        //Defina aqui a regra do Cliente...
        If SA1->A1_EST=="EX"
            cPrefNor := "" //informe prefixo da conta de clientes
            cRefNor  := "" //informe referencial ref.a clientes
            cPrefAdt := "" //informe prefixo da conta da conta de adiantamento a clientes
            cRefAdt  := "" //informe referencial ref.adiantamento a clientes
            cEntRef  := "10" //verificar de acordo com o clientes
        else
            cPrefNor := "" //informe prefixo da conta de clientes
            cRefNor  := "" //informe referencial ref.a clientes
            cPrefAdt := "" //informe prefixo da conta da conta de adiantamento a clientes
            cRefAdt  := "" //informe referencial ref.adiantamento a clientes
            cEntRef  := "10" //verificar de acordo com o clientes
        EndIf

        //Conta do cliente
        cCtaCli :=  cPrefNor + SA1->A1_COD+SA1->A1_LOJA

        //Conta de adiantamento (caso necessário)
        cCtaAdt :=  cPrefAdt + SA1->A1_COD+SA1->A1_LOJA

        
            If Empty(SA1->A1_CONTA) .And. !Empty(cCtaCli)
                //Criação de conta do cliente
                If U_TIPAC018(cCtaCli,SA1->A1_NOME,1,3,cRefNor,cEntRef,cCodPla,cVersao,cCusto) //Código, Desc.Conta, 1-Cliente/2-Fornecedor,3-Inclusão/5-Exclusão,cCtaRef,cEntRef,cCodPla,cVersao,cCusto                       
                    If SA1->(RecLock("SA1", .F.))
                        SA1->A1_CONTA := cCtaCli // Atualiza o cadastro                       
                        SA1->(MSUnlock())
                    Else
                        cLog += "Erro - Não foi possível fazer RecLock;" + SA1->A1_COD + "/" + SA1->A1_LOJA + cEOL
                    EndIf
                Else
                    cLog += "Erro - Não foi possível criar conta/item contábil. Verifique se o cliente já tem conta no plano de contas;"  + SA1->A1_COD + "/" + SA1->A1_LOJA + cEOL
                EndIf
            EndIf

            If SA1->(FieldPos("A1_ZZCTAAD")) > 0
                If Empty(SA1->A1_ZZCTAAD) .And. !Empty(cCtaAdt)
                    If U_TIPAC018(cCtaAdt,SA1->A1_NOME,1,3,cRefAdt,cEntRef,cCodPla,cVersao,cCusto) //Código, Desc.Conta, 1-Cliente/2-Fornecedor,3-Inclusão/5-Exclusão,cCtaRef,cEntRef,cCodPla,cVersao,cCusto
                        If SA1->(RecLock("SA1", .F.))
                            SA1->A1_ZZCTAAD := cCtaAdt
                            SA1->(MSUnlock())
                        Else
                            cLog += "Não foi possível fazer RecLock" + SA1->A1_COD + "/" + SA1->A1_LOJA + cEOL
                        Endif
                    Else
                        cLog += "Erro - Não foi possível criar conta/item contábil;"  + SA1->A1_COD + "/" + SA1->A1_LOJA + cEOL
                    EndIf
                EndIf
            Else
                MsgAlert("Não foi possível atualizar registro, pois está bloqueado por outro usuário", "#ERP+TIPAC022")
                SA1->(dbSkip())
            Return
        EndIf

    elseif nParam == 2
        cPrefNor := "C" // Defina aqui qual o prefixo desejado para o código do item contábil
        cCtaCli :=  cPrefNor + SA1->A1_COD+SA1->A1_LOJA
        U_TIPAC018(cCtaCli,SA1->A1_NOME,1,3,cRefNor,cEntRef,cCodPla,cVersao,cCusto) //Código, Desc.Conta, 1-Cliente/2-Fornecedor,3-Inclusão/5-Exclusão,cCtaRef,cEntRef,cCodPla,cVersao,cCusto,Filial

        If Empty(EJEFOR("MVCONTROL-CLI")) .OR. EJEFOR("MVCONTROL-CLI") == NIL
            MsgInfo("Como esta sendo usado Item Contábil para controlar cliente/fornecedor, a chave MVCONTROL-CLI da tabela CWK " + ;
                "precisa ser configurada com a composição do código do cliente.", "#ERP+PECUSTOMERVENDOR")
        EndIf
    EndIf
    MemoWrite( "c:\temp\log-conta-sa1.txt", Iif(Empty(cLog),"Aviso;Cod/Loja Cliente" + cEOL + "Nenhum erro encontrado",cLog) ) 
Return

Static Function CargaForn()
    if nParam == 1
        If !ExistBlock("TIPAC018",.F.,.T.)
            MsgStop("Progama TIPAC018 não encontra-se no RPO. Conta/Item não será criado", "#CUSTOMERVENDOR: Erro")
            Return xRet
        EndIf

        //Aqui você pode definir regras para compor a conta usando Z2_ZZTIPO (precisa configurar o campo como usado)

        //Defina aqui a regra do Fornecedor...
        If SA2->A2_EST=="EX"
            cPrefNor := "" //informe prefixo da conta de fornecedores
            cRefNor  := "" //informe referencial ref.a fornecedores
            cPrefAdt := "" //informe prefixo da conta da conta de adiantamento a fornecedores
            cRefAdt  := "" //informe referencial ref.adiantamento a fornecedores
            cEntRef  := "10" //verificar de acordo com o cliente
        else
            cPrefNor := "21101001" //informe prefixo da conta de fornecedores
            cRefNor  := "" //informe referencial ref.a fornecedores
            cPrefAdt := "11202001" //informe prefixo da conta da conta de adiantamento a fornecedores
            cRefAdt  := "" //informe referencial ref.adiantamento a fornecedores
            cEntRef  := "10" //verificar de acordo com o cliente
        EndIf

        //Conta do fornecedor
        cCtaFor :=  cPrefNor + SA2->A2_COD+SA2->A2_LOJA

        //Conta de adiantamento (caso necessário)
        cCtaAdt :=  cPrefAdt + SA2->A2_COD+SA2->A2_LOJA

            If Empty(SA2->A2_CONTA) .And. !Empty(cCtaFor)
                //Criação de conta do fornecedor
                If U_TIPAC018(cCtaFor,SA2->A2_NOME,2,3,cRefNor,cEntRef,cCodPla,cVersao,cCusto) //Código, Desc.Conta, 1-Cliente/2-Fornecedor,3-Inclusão/5-Exclusão,cCtaRef,cEntRef,cCodPla,cVersao,cCusto,Filial
                    If SA2->(RecLock("SA2", .F.))
                        SA2->A2_CONTA := cCtaFor // Atualiza o cadastro
                        SA2->(MSUnlock())
                    Else
                        cLog += "Não foi possível fazer RecLock" + SA2->A2_COD + "/" + SA2->A2_LOJA + cEOL
                    Endif
                Else
                    cLog += "Erro - Não foi possível criar conta/item contábil. Verifique se o fornecedor já tem conta no plano de contas;" + SA2->A2_COD + "/" + SA2->A2_LOJA + cEOL
                EndIf
            EndIf

            If SA2->(FieldPos("A2_ZZCTAAD")) > 0
                If Empty(SA2->A2_ZZCTAAD) .And. !Empty(cCtaAdt)
                    If U_TIPAC018(cCtaAdt,SA2->A2_NOME,2,3,cRefAdt,cEntRef,cCodPla,cVersao,cCusto) //Código, Desc.Conta, 1-Cliente/2-Fornecedor,3-Inclusão/5-Exclusão,cCtaRef,cEntRef,cCodPla,cVersao,cCusto,Filial
                        If SA2->(RecLock("SA2", .F.))
                            SA2->A2_ZZCTAAD := cCtaAdt
                            SA2->(MSUnlock())
                        Else
                            cLog += "Não foi possível fazer RecLock" + SA2->A2_COD + "/" + SA2->A2_LOJA + cEOL
                        EndIf
                    Else
                        cLog += "Erro - Não foi possível criar conta/item contábil;" + SA2->A2_COD + "/" + SA2->A2_LOJA + cEOL
                    EndIf
                EndIf
            Else
                MsgAlert("Não foi possível atualizar registro, pois está bloqueado por outro usuário", "#ERP+TIPAC022")
                SA2->(dbSkip())
            Return
        EndIf

    elseif nParam == 2
        If !ExistBlock("TIPAC018",.F.,.T.)
            MsgStop("Progama TIPAC018 não encontra-se no RPO. Conta/Item não será criado", "#CUSTOMERVENDOR: Erro")
            Return xRet
        EndIf

        cPrefNor := "F" // Defina aqui qual o prefixo desejado para o código do item contábil
        cCtaFor :=  cPrefNor + SA2->A2_COD+SA2->A2_LOJA
        U_TIPAC018(cCtaFor,SA2->A2_NOME,2,3,cRefNor,cEntRef,cCodPla,cVersao,cCusto) //Código, Desc.Conta, 1-Cliente/2-Fornecedor,3-Inclusão/5-Exclusão,cCtaRef,cEntRef,cCodPla,cVersao,cCusto,Filial

        If Empty(EJEFOR("MVCONTROL-FOR")) .OR. EJEFOR("MVCONTROL-FOR") == NIL
            MsgInfo("Como esta sendo usado Item Contábil para controlar cliente/fornecedor, a chave MVCONTROL-FOR da tabela CWK " + ;
                "precisa ser configurada com a composição do código do fornecedor.", "#ERP+PECUSTOMERVENDOR")
        EndIf
    EndIf
    MemoWrite( "c:\temp\log-conta-sa2.txt", Iif(Empty(cLog),"Aviso;Cod/Loja Cliente" + cEOL + "Nenhum erro encontrado",cLog) )
Return
