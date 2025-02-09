#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oTab

   INIT DIALOG oDialog TITLE "Test" SIZE 800, 600

   @ 40, 40 TAB oTab ITEMS {"Tab1", "Tab2", "Tab3", "Tab4", "Tab5"} OF oDialog SIZE 800 - 80, 600 - 80

   ACTIVATE DIALOG oDialog

RETURN NIL
