#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oTab

   INIT DIALOG oDialog TITLE "Test" SIZE 800, 600

   @ 40, 40 TAB oTab ITEMS {} OF oDialog SIZE 800 - 80, 600 - 80

   BEGIN PAGE "TAB1" OF oTab
   END PAGE OF oTab

   BEGIN PAGE "TAB2" OF oTab
   END PAGE OF oTab

   BEGIN PAGE "TAB3" OF oTab
   END PAGE OF oTab

   BEGIN PAGE "TAB4" OF oTab
   END PAGE OF oTab

   BEGIN PAGE "TAB5" OF oTab
   END PAGE OF oTab

   ACTIVATE DIALOG oDialog

RETURN NIL
