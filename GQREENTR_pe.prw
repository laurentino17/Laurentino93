#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"

/*/{Protheus.doc} GQREENTR

Ponto de entrada no final da geracao da NF Entrada
utilizado para gravacao de dados adicionais.

@type function
@author Deivid A. C. de Lima
@since 07/06/2010

@see MSGNF01
/*/
User Function GQREENTR()

	//Executa o Wizard do Acelerador de Mensagens da NF no final da geração da NF de Entrada
	If ExistBlock("MSGNF01",.F.,.T.)
		ExecBlock("MSGNF01",.F.,.T.,{})
	Endif

Return
