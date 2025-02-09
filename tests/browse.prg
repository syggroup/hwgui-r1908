#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oBrowse
   LOCAL aData
   LOCAL n

   INIT DIALOG oDialog TITLE "Test" AT 0, 0 SIZE 640, 480 STYLE DS_CENTER

   @ 20, 20 BROWSE oBrowse ARRAY SIZE 640 - 40, 480 - 100 AUTOEDIT NO VSCROLL

   aData := Array(1000)
   FOR n := 1 TO 1000
      aData[n] := {AllTrim(Str(n)) + "," + "1", ;
                   AllTrim(Str(n)) + "," + "2", ;
                   AllTrim(Str(n)) + "," + "3", ;
                   AllTrim(Str(n)) + "," + "4", ;
                   AllTrim(Str(n)) + "," + "5"}
   NEXT n

   hwg_CreateArList(oBrowse, aData)

   oBrowse:aColumns[1]:heading := "Column 1"
   oBrowse:aColumns[2]:heading := "Column 2"
   oBrowse:aColumns[3]:heading := "Column 3"
   oBrowse:aColumns[4]:heading := "Column 4"
   oBrowse:aColumns[5]:heading := "Column 5"

   @ (640 - 100) / 2, 480 - 80 BUTTON "&Ok" OF oDialog ID IDOK SIZE 100, 32

   ACTIVATE DIALOG oDialog

RETURN NIL
