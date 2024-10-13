#include "hwgui.ch"

PROCEDURE Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow TITLE "Test" SIZE 800, 600

   MENU OF oMainWindow
      MENU TITLE "Menu A"
         MENUITEM "Option A1" ACTION HWG_MSGINFO("A1")
         MENUITEM "Option A2" ACTION HWG_MSGINFO("A2")
         MENUITEM "Option A3" ACTION HWG_MSGINFO("A3")
         SEPARATOR
         MENUITEM "Exit" ACTION EndWindow()
      ENDMENU
      MENU TITLE "Menu B"
         MENUITEM "Option B1" ACTION HWG_MSGINFO("B1")
         MENUITEM "Option B2" ACTION HWG_MSGINFO("B2")
         MENUITEM "Option B3" ACTION HWG_MSGINFO("B3")
      ENDMENU
      MENU TITLE "Menu C"
         MENUITEM "Option C1" ACTION HWG_MSGINFO("C1")
         MENUITEM "Option C2" ACTION HWG_MSGINFO("C2")
         MENUITEM "Option C3" ACTION HWG_MSGINFO("C3")
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow

RETURN
