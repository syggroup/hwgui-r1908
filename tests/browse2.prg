#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oBrowse
   LOCAL aData
   LOCAL n

   INIT DIALOG oDialog TITLE "Teste com Browse" AT 0, 0 SIZE 640, 480 STYLE DS_CENTER

   // Notas:
   // Click: seleciona o registro
   // Double Click ou ENTER: executa o codeblock definido no 'ON CLICK'
   // Right Click: executa o codeblock definido no 'ON RIGHTCLICK'

   @ 20, 20 BROWSE oBrowse ARRAY SIZE 640 - 40, 480 - 100 AUTOEDIT NO VSCROLL ;
      ON CLICK {||hwg_MsgInfo("ON CLICK", "Aviso")} ;
      ON RIGHTCLICK {||hwg_MsgInfo("ON RIGHTCLICK", "Aviso")}

   aData := Array(1000)
   FOR n := 1 TO 1000
      aData[n] := {AllTrim(Str(n)) + "," + "1", ;
                   AllTrim(Str(n)) + "," + "2", ;
                   AllTrim(Str(n)) + "," + "3", ;
                   AllTrim(Str(n)) + "," + "4", ;
                   AllTrim(Str(n)) + "," + "5"}
   NEXT n

   hwg_CreateArList(oBrowse, aData)

   oBrowse:aColumns[1]:heading := "Coluna 1"
   oBrowse:aColumns[2]:heading := "Coluna 2"
   oBrowse:aColumns[3]:heading := "Coluna 3"
   oBrowse:aColumns[4]:heading := "Coluna 4"
   oBrowse:aColumns[5]:heading := "Coluna 5"

   @ (640 - 100) / 2, 480 - 80 BUTTON "&Fechar" OF oDialog SIZE 100, 32 ON CLICK {||oDialog:Close()}

   ACTIVATE DIALOG oDialog

RETURN NIL
