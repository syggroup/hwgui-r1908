#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow
   LOCAL oTrayMenu
   LOCAL oIcon := HIcon():AddResource("ICON_1")

   INIT WINDOW oMainWindow MAIN TITLE "Example"

   CONTEXT MENU oTrayMenu
      MENUITEM "Message"  ACTION hwg_MsgInfo("Tray Message !")
      SEPARATOR
      MENUITEM "Exit"  ACTION hwg_EndWindow()
   ENDMENU

   oMainWindow:InitTray(oIcon, , oTrayMenu, "TestTray")

   ACTIVATE WINDOW oMainWindow NOSHOW
   oTrayMenu:End()

RETURN NIL
