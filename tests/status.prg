#include "hwgui.ch"

PROCEDURE Main()

   LOCAL oMainWindow
   LOCAL oStatus

   INIT WINDOW oMainWindow TITLE "Test" SIZE 800, 600

   ADD STATUS oStatus TO oMainWindow PARTS 800

   ACTIVATE WINDOW oMainWindow

RETURN
