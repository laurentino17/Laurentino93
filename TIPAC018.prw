#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"

Static __oModelAut := NIL //variavel oModel para substituir msexecauto em MVC

//-------------------------------------------------------------------
/*/{Protheus.doc} TIPAC018
Função para criar conta ou item contábil quando inclui um cliente ou fornecedor.
* Licença       :   fonte cedido ao cliente o qual passa a gerir pelo mesmo.

@type function
@author Totvs IP
@since 10/2021
@param cCodigo,cNome,cNormal,nOpExec

cCodigo: código do cliente/fornecedor
cNome: do cliente/fornecedor
nTpCad: 1-Cadastro de Cliente, 2-Fornecedor
nOpExec: 3=Inclusão, 5=Exclusão

@Return lRetOk
/*/
//-------------------------------------------------------------------

User Function TIPAC018(cCodigo,cNome,nTpCad,nOpExec,cCtaRef,cEntRef,cCodPla,cVersao,cCusto,cFilEnt,;
cAcCust,cAcItem,cAcCl,cCcObr,cItObr,cClObr)

//Variáveis
Local xArea		 := GetArea()
Local lRetOk	 := .t.
Local aDados 	 :=	{}
Local lAchou	 := .f.
Local nTabela	 := SuperGetMV("ZZ_TPCTA", .f., 0)
Local cNormal	 := "0"

Local oCT1
Local oCVD
Local nX		 := 0
Local aLog		 := {}
Local cLog       := ""
Local cFilBkp	 := cFilAnt
Local cNtSped 	 := ""

Private lMsErroauto	:=	.f.

Default cCtaRef := ""
Default cEntRef := ""
Default cCodPla := ""
Default cVersao := ""
Default cCusto  := ""
Default cFilEnt := xFilial("CT1")

Default cAcCust	:= "2"
Default cAcItem := "2"
Default cAcCl   := "2"
Default cCcObr  := "2"
Default cItObr  := "2"
Default cClObr  := "2"

// Ajuse no tamanho do nome para dar problemas com a rotina automática
cNome := Left(cNome,40)
cNome := Padr(cNome,TamSX3("CT1_DESC01")[1]," ")

// Verifica onde será criado a conta para Fornecedor/Cliente
If nTabela == 0
	Return .t.
EndIF

// Valida os parâmetros
If Empty(cCodigo) .Or. Empty(cNome) .Or. nTpCad==Nil .Or. nTpCad < 1 .Or. nTpCad > 2 .Or. (nOpExec<>3 .And. nOpExec<>5)
	MsgStop("Parâmetros para inclusão do cadastro inválidos", "#ERP+TIPAC018")
	Return .f.
EndIf

If nTabela==1 // Conta contábil

	If left(cCodigo,1)=="1" //Ativo
		cNormal := "1"
	ElseIf left(cCodigo,1)=="2" //Passivo
		cNormal := "2"
	EndIf

	//Verifica se a conta já existe
	CT1->(dbsetorder(1))
	lAchou := CT1->(dbseek( cFilEnt+ cCodigo , .f. ))

	If nOpExec==3 //Inclusão
	
		If lAchou
			lRetOk := .f.
			MsgStop("já existe conta contábil na contabilidade -> "+cCodigo+".", "#ERP+TIPAC018")
		Else

			//somente uma unica vez carrega o modelo CTBA020-Plano de Contas CT1
			If __oModelAut == Nil
				__oModelAut := FWLoadModel('CTBA020')
			EndIf

			__oModelAut:SetOperation(nOpExec) // 3 - Inclusão | 4 - Alteração | 5 - Exclusão
			__oModelAut:Activate() //ativa modelo

			cFilAnt := cFilEnt

			If Left(cCodigo,1)=="1"
				cNtSped := "01"
			ElseIf Left(cCodigo,1)=="2"
				cNtSped := "02"
			Else
				cNtSped := ""
			EndIf
			
			//Objeto similar enchoice CT1
			oCT1 := __oModelAut:GetModel('CT1MASTER')
			oCT1:SETVALUE('CT1_FILIAL'  ,cFilEnt) 
			oCT1:SETVALUE('CT1_CONTA'	,cCodigo)
			oCT1:SETVALUE('CT1_DESC01'	,cNome)
			oCT1:SETVALUE('CT1_CLASSE'	,"2")
			oCT1:SETVALUE('CT1_NORMAL' 	,cNormal)
			oCT1:SETVALUE('CT1_ACCUST' 	,cAcCust)
			oCT1:SETVALUE('CT1_ACITEM' 	,cAcItem)
			oCT1:SETVALUE('CT1_ACCLVL' 	,cAcCl)
			oCT1:SETVALUE('CT1_CCOBRG' 	,cCcObr)
			oCT1:SETVALUE('CT1_ITOBRG' 	,cItObr)
			oCT1:SETVALUE('CT1_CLOBRG' 	,cClObr)
			oCT1:SETVALUE('CT1_DTEXIS' 	,CriaVar("CT1_DTEXIS",.t.))
			oCT1:SETVALUE('CT1_NTSPED' 	,cNtSped)

			If !Empty(cCtaRef)
				oCVD := __oModelAut:GetModel('CVDDETAIL') //Objeto similar getdados CVD
				oCVD:SETVALUE('CVD_FILIAL' ,cFilEnt) 
				oCVD:SETVALUE('CVD_ENTREF',PadR(cEntRef,Len(CVD->CVD_ENTREF)))
				oCVD:SETVALUE('CVD_CODPLA',PadR(cCodPla,Len(CVD->CVD_CODPLA))) 
				oCVD:SETVALUE('CVD_CTAREF',PadR(cCtaRef, Len(CVD->CVD_CTAREF)))
				oCVD:SETVALUE('CVD_TPUTIL','A')
				oCVD:SETVALUE('CVD_CLASSE','2') 
				oCVD:SETVALUE('CVD_VERSAO',PadR(cVersao,Len(CVD->CVD_VERSAO)))
				oCVD:SETVALUE('CVD_CUSTO' ,PadR(cCusto,Len(CVD->CVD_CUSTO)))
			EndIf

		EndIf

	ElseIf nOpExec==5 //Exclusão
		MsgStop("Após exclusão do registro, avise o Contador para que a conta contábil seja excluída. Conta -> "+cCodigo+".", "#ERP+TIPAC018")
		/*
		If !lAchou
			lRetOk := .f.
			MsgStop("Conta contábil não encontrada na contabilidade -> "+cCodigo+".", "#ERP+TIPAC018")
		Else
			MsgStop("Após exclusão do fornecedor, avise o Contador para que a conta contábil seja excluída. Conta -> "+cCodigo+".", "#ERP+TIPAC018")
		EndIf
		*/
	Endif

	If lRetOk .And. nOpExec==3

		If __oModelAut:VldData() //validacao dos dados pelo modelo

			__oModelAut:CommitData() //gravacao dos dados

		Else
			aLog := __oModelAut:GetErrorMessage() //Recupera o erro do model quando nao passou no VldData

			//laco para gravar em string cLog conteudo do array aLog
			For nX := 1 to Len(aLog)
				If !Empty(aLog[nX])
					cLog += Alltrim(aLog[nX]) + CRLF
				EndIf
			Next nX
			
			lMsErroAuto := .T. //seta variavel private como erro
			AutoGRLog(cLog) //grava log para exibir com funcao mostraerro
			mostraerro()
			lRetOk := .f.
			
		EndIf
		
		__oModelAut:DeActivate() //desativa modelo

	EndIf

ElseIf nTabela==2 //Item Contábil

	If nTpCad==1 // Cliente
		cNormal := "2"
	Else // Fornecedor
		cNormal := "1"
	EndIf

	// Verifica se controla saldo por item contábil.
	If !CtbMovSaldo("CTD")
		MsgStop("Item contabil nao criado. A entidade não esta em uso, configure na contabilidade.", "#ERP+TIPAC018")
		Return .f.
	EndIf
		
	// Alimenta array com dados
	aAdd( aDados , { "CTD_FILIAL" , cFilEnt				, Nil } )
	aAdd( aDados , { "CTD_ITEM"   , cCodigo		    	, Nil } )
	aAdd( aDados , { "CTD_CLASSE" , '2'            		, Nil } )
	aAdd( aDados , { "CTD_NORMAL" , cNormal        		, Nil } )
	aAdd( aDados , { "CTD_DESC01" , cNome          		, Nil } )
	aAdd( aDados , { "CTD_DESC02" , cNome          		, Nil } )
	aAdd( aDados , { "CTD_DESC03" , cNome          		, Nil } )
	aAdd( aDados , { "CTD_DESC04" , cNome          		, Nil } )
	aAdd( aDados , { "CTD_DESC05" , cNome          		, Nil } )

	CTD->(dbsetorder(1))
	lAchou := CTD->(dbseek( xFilial("CTD") + cCodigo , .f. ))

	If nOpExec==3 //Inclusão
		If lAchou
			lRetOk := .f.
			MsgStop("já existe item contábil na contabilidade -> "+cCodigo+".", "#ERP+TIPAC018")
		Else
			MsExecAuto( { |x,y| CTBA040(x,y) } , aDados , nOpExec ) 
			if	lMsErroAuto
				lRetOk := .f.
				MostraErro()
			else
				lRetOk := .t.
			endif
		EndIf
	ElseIf nOpExec==5 //Exclusão
		If !lAchou
			lRetOk := .f.
			MsgStop("Item contábil não encontrado na contabilidade -> "+cCodigo+".", "#ERP+TIPAC018")
		Else
			MsExecAuto( { |x,y| CTBA040(x,y) } , aDados , nOpExec ) 
			if	lMsErroAuto
				lRetOk := .f.
				MostraErro()
			else
				lRetOk := .t.
			endif
		EndIf
	endif
EndIf

cFilAnt := cFilBkp

RestArea(xArea)

Return lRetOk



