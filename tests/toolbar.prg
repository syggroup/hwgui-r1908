#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oToolBar

   INIT DIALOG oDialog TITLE "Test" SIZE 800, 600

   @ 0, 0 TOOLBAR oToolBar OF oDialog SIZE 800, 40

   TOOLBUTTON oToolBar ID oToolBar:id + 1 BITMAP 2 STYLE 0 STATE 4 TEXT "Button1" TOOLTIP "Button1" ;
      ON CLICK {|x, y|hwg_MsgInfo("Button 1 clicked", "Info")}
   TOOLBUTTON oToolBar ID oToolBar:id + 2 BITMAP 3 STYLE 0 STATE 4 TEXT "Button2" TOOLTIP "Button2" ;
      ON CLICK {|x, y|hwg_MsgInfo("Button 2 clicked", "Info")}
   TOOLBUTTON oToolBar ID oToolBar:id + 3 BITMAP 4 STYLE 0 STATE 4 TEXT "Button3" TOOLTIP "Button3" ;
      ON CLICK {|x, y|hwg_MsgInfo("Button 3 clicked", "Info")}
   TOOLBUTTON oToolBar ID oToolBar:id + 4 BITMAP 5 STYLE 0 STATE 4 TEXT "Button4" TOOLTIP "Button4" ;
      ON CLICK {|x, y|hwg_MsgInfo("Button 4 clicked", "Info")}

   ACTIVATE DIALOG oDialog

RETURN NIL
