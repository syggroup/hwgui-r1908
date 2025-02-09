#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oList
   LOCAL aItems := {"Item1", "Item2", "Item3", "Item4", "Item5"}

   INIT DIALOG oDialog TITLE "Teste com ListBox" AT 0, 0 SIZE 640, 480 STYLE DS_CENTER

   @ 20,20 LISTBOX oList ITEMS aItems OF oDialog INIT 1 SIZE 640 - 40, 480 - 100

   @ (640 - 100) / 2, 480 - 80 BUTTON "&Fechar" SIZE 100, 32 ON CLICK {||oDialog:Close()}

   ACTIVATE DIALOG oDialog
   
   hwg_MsgInfo(AllTrim(Str(oList:value)), "Info")

RETURN NIL
