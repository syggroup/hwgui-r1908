#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oTab

   INIT DIALOG oDialog TITLE "Test" SIZE 800, 600

   // teste com TAB vazio
   @ 40, 40 TAB oTab ITEMS {} OF oDialog SIZE 800 - 80, 600 - 80

   ACTIVATE DIALOG oDialog

RETURN NIL
