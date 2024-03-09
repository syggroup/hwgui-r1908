#include "hwgui.ch"

PROCEDURE Main()

   LOCAL oDialog

   INIT DIALOG oDialog TITLE "Test" SIZE 800, 600

   MENU OF oDialog
      MENU TITLE "Menu A"
         MENUITEM "Option A1" ACTION MsgInfo("A1")
         MENUITEM "Option A2" ACTION MsgInfo("A2")
         MENUITEM "Option A3" ACTION MsgInfo("A3")
         SEPARATOR
         MENUITEM "Exit" ACTION oDialog:Close()
      ENDMENU
      MENU TITLE "Menu B"
         MENUITEM "Option B1" ACTION MsgInfo("B1")
         MENUITEM "Option B2" ACTION MsgInfo("B2")
         MENUITEM "Option B3" ACTION MsgInfo("B3")
      ENDMENU
      MENU TITLE "Menu C"
         MENUITEM "Option C1" ACTION MsgInfo("C1")
         MENUITEM "Option C2" ACTION MsgInfo("C2")
         MENUITEM "Option C3" ACTION MsgInfo("C3")
      ENDMENU
   ENDMENU

   ACTIVATE DIALOG oDialog

RETURN
