#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oIP
   LOCAL aIP := {168, 0, 0, 1}

   INIT DIALOG oDialog TITLE "Test" AT 20, 20 SIZE 320, 240

   @ 20, 20 GET IPADDRESS oIP VAR aIP SIZE 140, 26

   ACTIVATE DIALOG oDialog

RETURN NIL
