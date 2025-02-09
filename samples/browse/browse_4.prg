//
// Demo by HwGUI Alexander Kresin
//
// Copyright (c) Sandro R R Freire <sandro@lumainformatica.com.br>
//
// Demo for Browse using Set Relatarion
//

#include "hwgui.ch"
#include "dbstruct.ch"

FUNCTION Main()

   LOCAL aField := {{"CODIGO", "N", 3, 0}, {"NOME", "C", 30, 0}}
   LOCAL oDlg
   LOCAL i

   PRIVATE oBrowse
   PRIVATE oSai
   PRIVATE oConsulta
   PRIVATE vConsulta

   If !File("browse_4.dbf")
      dBCreate("browse_4.dbf", aField)
   end
   Use browse_4 Exclusiv alias TESTE  NEW
   for i := 1 to 200
      Append Blank
      Teste->CODIGO := i
      TESTE->NOME := "NOME " + AllTrim(STR(I))
   end
   go top
   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "Browse MultiSelect";
        AT 218, 143 SIZE 487, 270 FONT HFont():Add("Arial", 0, -11)

   @  9, 8 BROWSE oBrowse DATABASE SIZE 466, 196 STYLE WS_VSCROLL + WS_HSCROLL;
      MULTISELECT

   @ 9, 214 say "Pressione a tecla CTRL e clique no registro a selecionar," + Chr(13) + Chr(10) + "se clicar sem o CTRL a multiseleção é limpa" size 466, 42

   @ 393, 214 BUTTON oSai CAPTION "Sair"  ON CLICK {||sair()} SIZE 80, 32

   oBrowse:alias := "Teste"
   oBrowse:aColumns := {}

    ADD COLUMN FieldBlock(Fieldname(1) ) TO oBrowse ;
        HEADER "Código";
        TYPE "N";
        LENGTH 3 ;
        DEC 0 ;
        PICTURE "@E 999";
        JUSTIFY HEAD DT_CENTER ;
        JUSTIFY LINE DT_RIGHT

    ADD COLUMN FieldBlock(Fieldname(2) ) TO oBrowse ;
        HEADER "Descrição" ;
        PICTURE "@!" ;
        JUSTIFY HEAD DT_CENTER ;
        JUSTIFY LINE DT_LEFT

   oBrowse:Refresh()

   ACTIVATE DIALOG oDlg

   fErase("browse_4.dbf")

RETURN NIL

STATIC FUNCTION sair()

   hwg_MsgInfo("Registros selecionados" + Chr(13) + Chr(10) + valToPrg(oBrowse:aSelected))
   EndDialog()

RETURN .T.
