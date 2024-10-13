#include "hwgui.ch"

REQUEST DBFCDX
REQUEST DBFFPT

PROCEDURE Main()

   LOCAL oDialog
   LOCAL oGroupBox
   LOCAL oCheckBox1
   LOCAL oCheckBox2
   LOCAL oCheckBox3
   LOCAL oCheckBox4
   LOCAL oCheckBox5

   #IfDef __XHARBOUR__
      SetUnhandledExceptionFilter( @GpfHandler() ) // testar simulando um GPF forçado no sistema
   #endif   
   
   INIT DIALOG oDialog TITLE "Test" SIZE 640, 480

   @ 20, 20 GROUPBOX oGroupBox CAPTION "GroupBox" SIZE 640 - 40, 220

   @ 20, 20 CHECKBOX oCheckBox1 CAPTION "CheckBox1" SIZE 300, 26 OF oGroupBox

   @ 20, 60 CHECKBOX oCheckBox2 CAPTION "CheckBox2" SIZE 300, 26 OF oGroupBox

   @ 20, 100 CHECKBOX oCheckBox3 CAPTION "CheckBox3" SIZE 300, 26 OF oGroupBox

   @ 20, 140 CHECKBOX oCheckBox4 CAPTION "CheckBox4" SIZE 300, 26 OF oGroupBox

   @ 20, 180 CHECKBOX oCheckBox5 CAPTION "CheckBox5" SIZE 300, 26 OF oGroupBox

   @ (320 - 100) / 2, 320 BUTTON "&Ok" OF oDialog ID IDOK SIZE 100, 32;
   ON CLICK {|| SELECIONA_SERVIDOR_SQL() }       

   @ (320 - 100) / 2 + 320, 320 BUTTON "&Cancel" OF oDialog ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDialog

RETURN

*******************************
FUNCTION SELECIONA_SERVIDOR_SQL
*******************************
local oGroup1, oBrowse_sel_bal, oBUTTONEX1_CONECTA,oDlgSelCon, oTIME_CONECTA, nTEMPO_CONECTA:=31

   DBSELECTAREA(0) // SELECIONA A PROXIMA AREA LIVRE
   DbUseArea(.T.,"DBFCDX","SYGECOM","SYGECOM",.T.,.T.,,)

   SELE SYGECOM
   dbgotop()

   INIT DIALOG oDlgSelCon TITLE "Selecione o banco de dados" ;
   AT 0,0 SIZE 230,260 ;
   FONT HFont():Add( '',0,-13,400,,,) CLIPPER  NOEXIT  ;
   STYLE WS_POPUP+WS_CAPTION+DS_CENTER +WS_SYSMENU+WS_MINIMIZEBOX

   @ 18,26 BROWSE oBrowse_sel_bal DATABASE OF oGroup1 SIZE 195,170 ;
   STYLE WS_TABSTOP        ;
   ON CLICK {|o,key| Enddialog() };
   ON POSCHANGE {|| oBrowse_sel_bal:SetFocus() };
   FONT HFont():Add( '',0,-11,400,,,)

   oBrowse_sel_bal:freeze:= 1
   oBrowse_sel_bal:alias := 'SYGECOM'

   SELECT (oBrowse_sel_bal:alias)

   oBrowse_sel_bal:AddColumn( HColumn():New('Descricao'     , FieldBlock( 'obs' )      ,'C',42, 0 ,.F.,0,0,'@!',,,,,))

   oBrowse_sel_bal:bKeyDown := {|o,key| BRW_SELECIONA_SQL(o, key, oDlgSelCon ) }

   @ 5,6 GROUPBOX oGroup1 CAPTION "Selecione o banco de dados"  SIZE 220,202  ;
   COLOR 16711680

   @ 10,210 BUTTONEX oBUTTONEX1_CONECTA CAPTION "Co&nectar"  SIZE 100,38 ;
   STYLE WS_TABSTOP   ;
   BITMAP (HBitmap():AddResource(1002)):handle  ;
   FONT HFont():Add( '',0,-11,400,,,);
   TOOLTIP 'Clique aqui para Fechar' ;
   ON CLICK {|| oTIME_CONECTA:END(), ENDDIALOG() }

   @ 120,210 BUTTONEX "&Cancelar" SIZE 100,38 ;
   BITMAP (HBitmap():AddResource(1003)):handle  ;
   FONT HFont():Add( '',0,-11,400,,,);
   TOOLTIP "Sair e Voltar ao Menu";
   ON CLICK {|| oTIME_CONECTA:END(),oDlgSelCon:Close() };
   STYLE WS_TABSTOP

   SET TIMER oTIME_CONECTA OF oDlgSelCon ID 9111 VALUE 1000 ACTION {|| ATUALIZA_BUTTONEX(oDlgSelCon,@nTEMPO_CONECTA) }

   ACTIVATE DIALOG oDlgSelCon

RETURN NIL

***************************************
STATIC FUNCTION ATUALIZA_BUTTONEX(oOBJ,nTEMPO_CONECTA)
***************************************
nTEMPO_CONECTA:=nTEMPO_CONECTA-1

oOBJ:oBUTTONEX1_CONECTA:SetText("Co&nectar-"+ALLTRIM(STR(nTEMPO_CONECTA)))

IF nTEMPO_CONECTA<=0
   oOBJ:oTIME_CONECTA:interval:=0 // para TIMER
   oOBJ:oTIME_CONECTA:END()
   oOBJ:close()
ENDIF

RETURN .T.

*************************************************
STATIC FUNCTION BRW_SELECIONA_SQL( oBrowse, key, oOBJ )
*************************************************
DO CASE
   CASE KEY = VK_RETURN
        EndDialog()
   CASE KEY= VK_ESCAPE
        EndDialog()
   CASE KEY = VK_F9
        //ABRE_CALCULADORA_WINDOWS()
   otherwise
   if key=70  .or. key=102  // tecla "F"  e ESC
      oOBJ:CLOSE()
   ENDIF
ENDCASE
Return .T.

#IfDef __XHARBOUR__
#include "hbexcept.ch"

*******************
STATIC FUNCTION GPFHANDLER( Exception )
*******************
local cMsg:='', nCode, oError
IF Exception <> NIL
   nCode := Exception:ExceptionRecord:ExceptionCode
   SWITCH nCode
      CASE EXCEPTION_ACCESS_VIOLATION
           cMsg := "EXCEPTION_ACCESS_VIOLATION - O thread tentou ler/escrever num endereço virtual ao qual não tinha acesso."
           EXIT

      CASE EXCEPTION_DATATYPE_MISALIGNMENT
           cMsg := "EXCEPTION_DATATYPE_MISALIGNMENT - O thread tentou ler/escrever dados desalinhados em hardware que não oferece alinhamento. Por exemplo, valores de 16 bits precisam ser alinhados em limites de 2 bytes; valores de 32 bits em limites de 4 bytes, etc. "
           EXIT

      CASE EXCEPTION_ARRAY_BOUNDS_EXCEEDED

           cMsg := "EXCEPTION_ARRAY_BOUNDS_EXCEEDED - O thread tentou acessar um elemento de array fora dos limites e o hardware possibilita a checagem de limites."
           EXIT

      CASE EXCEPTION_FLT_DENORMAL_OPERAND
           cMsg := "EXCEPTION_FLT_DENORMAL_OPERAND - Um dos operandos numa operação de ponto flutuante está desnormatizado. Um valor desnormatizado é um que seja pequeno demais para poder ser representado no formato de ponto flutuante padrão."
           EXIT

      CASE EXCEPTION_FLT_DIVIDE_BY_ZERO
           cMsg := "EXCEPTION_FLT_DIVIDE_BY_ZERO - O thread tentou dividir um valor em ponto flutuante por um divisor em ponto flutuante igual a zero."
           EXIT

      CASE EXCEPTION_FLT_INEXACT_RESULT
           cMsg := "EXCEPTION_FLT_INEXACT_RESULT - O resultado de uma operação de ponto flutuante não pode ser representado como uma fração decimal exata."
           EXIT

      CASE EXCEPTION_FLT_INVALID_OPERATION
           cMsg := "EXCEPTION_FLT_INVALID_OPERATION - Qualquer operação de ponto flutuante não incluída na lista."
           EXIT

      CASE EXCEPTION_FLT_OVERFLOW
           cMsg := "EXCEPTION_FLT_OVERFLOW - O expoente de uma operação de ponto flutuante é maior que a magnitude permitida pelo tipo correspondente."
           EXIT

      CASE EXCEPTION_FLT_STACK_CHECK
           cMsg := 'EXCEPTION_FLT_STACK_CHECK - A pilha ficou desalinhada ("estourou" ou "ficou abaixo") como resultado de uma operação de ponto flutuante.'
           EXIT

      CASE EXCEPTION_FLT_UNDERFLOW
           cMsg := "EXCEPTION_FLT_UNDERFLOW - O expoente de uma operação de ponto flutuante é menor que a magnitude permitida pelo tipo correspondente."
           EXIT

      CASE EXCEPTION_INT_DIVIDE_BY_ZERO
           cMsg := "EXCEPTION_INT_DIVIDE_BY_ZERO - O thread tentou dividir um valor inteiro por um divisor inteiro igual a zero."
           EXIT

      CASE EXCEPTION_INT_OVERFLOW
           cMsg := "EXCEPTION_INT_OVERFLOW - O resultado de uma operação com inteiros causou uma transposição (carry) além do bit mais significativo do resultado."
           EXIT

      CASE EXCEPTION_PRIV_INSTRUCTION
           cMsg := "EXCEPTION_PRIV_INSTRUCTION - O thread tentou executar uma instrução cuja operação não é permitida no modo de máquina atual."
           EXIT

      CASE EXCEPTION_IN_PAGE_ERROR
           cMsg := "EXCEPTION_IN_PAGE_ERROR - O thread tentou acessar uma página que não estava presente e o sistema não foi capaz de carregar a página. Esta exceção pode ocorrer, por exemplo, se uma conexão de rede é perdida durante a execução do programa via rede."
           EXIT

      CASE EXCEPTION_ILLEGAL_INSTRUCTION
           cMsg := "EXCEPTION_ILLEGAL_INSTRUCTION - O thread tentou executar uma instrução inválida."
           EXIT

      CASE EXCEPTION_NONCONTINUABLE_EXCEPTION
           cMsg := "EXCEPTION_NONCONTINUABLE_EXCEPTION - O thread tentou continuar a execução após a ocorrência de uma exceção irrecuperável."
           EXIT

      CASE EXCEPTION_STACK_OVERFLOW
           cMsg := "EXCEPTION_STACK_OVERFLOW - O thread esgotou sua pilha (estouro de pilha)."
           EXIT

      CASE EXCEPTION_INVALID_DISPOSITION
           cMsg := "EXCEPTION_INVALID_DISPOSITION - Um manipulador (handle) de exceções retornou uma disposição inválida para o tratador de exceções. Uma exceção deste tipo nunca deveria ser encontrada em linguagens de médio/alto nível."
           EXIT

      CASE EXCEPTION_GUARD_PAGE
           cMsg := "CASE EXCEPTION_GUARD_PAGE"
           EXIT

      CASE EXCEPTION_INVALID_HANDLE
           cMsg := "EXCEPTION_INVALID_HANDLE"
           EXIT

      CASE EXCEPTION_SINGLE_STEP
           cMsg := "EXCEPTION_SINGLE_STEP Um interceptador de passos ou outro mecanismo de instrução isolada sinalizou que uma instrução foi executada."
           EXIT

      CASE EXCEPTION_BREAKPOINT
           cMsg := "EXCEPTION_BREAKPOINT - Foi encontrado um ponto de parada (breakpoint)."
           EXIT

      DEFAULT
         cMsg := "UNKNOWN EXCEPTION (" + cStr( Exception:ExceptionRecord:ExceptionCode ) + ")"
   ENDSWITCH
ENDIF

Throw( ErrorNew( "GPFHANDLER", 0, 0, ProcName(), "Erro de GPF"+cMsg, { cMsg, Exception, nCode } ) )

RETURN EXCEPTION_EXECUTE_HANDLER
#endif
