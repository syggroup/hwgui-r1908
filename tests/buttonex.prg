#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog

   INIT DIALOG oDialog TITLE "Test" SIZE 640, 480

   @ (320 - 100) / 2, 280 BUTTONEX "&Ok" OF oDialog ID IDOK SIZE 100, 32 ;
      COLOR 0xFFFFFF BACKCOLOR 0xFF0000 STYLE WS_TABSTOP

   @ (320 - 100) / 2 + 320, 280 BUTTONEX "&Cancel" OF oDialog ID IDCANCEL SIZE 100, 32 ;
      COLOR 0xFFFFFF BACKCOLOR 0xFF0000 STYLE WS_TABSTOP

   ACTIVATE DIALOG oDialog

   IF oDialog:lResult
      hwg_MsgInfo("OK", "Info")
   ELSE
      hwg_MsgInfo("CANCEL", "Info")
   ENDIF

RETURN NIL
