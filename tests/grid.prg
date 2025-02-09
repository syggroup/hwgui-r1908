#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oGrid
   LOCAL aData
   LOCAL n

   aData := Array(1000)
   FOR n := 1 TO 1000
      aData[n] := {AllTrim(Str(n)) + "," + "1", ;
                   AllTrim(Str(n)) + "," + "2", ;
                   AllTrim(Str(n)) + "," + "3", ;
                   AllTrim(Str(n)) + "," + "4", ;
                   AllTrim(Str(n)) + "," + "5"}
   NEXT n

   INIT DIALOG oDialog TITLE "Test" AT 0, 0 SIZE 640, 480 STYLE DS_CENTER

   @ 20, 20 GRID oGrid SIZE 640 - 40, 480 - 100 ITEMCOUNT Len(aData) ;
      ON DISPINFO {|oCtrl, nRow, nCol|HB_SYMBOL_UNUSED(oCtrl), aData[nRow, nCol]}

   ADD COLUMN TO GRID oGrid HEADER "Column 1" WIDTH 100
   ADD COLUMN TO GRID oGrid HEADER "Column 2" WIDTH 100
   ADD COLUMN TO GRID oGrid HEADER "Column 3" WIDTH 100
   ADD COLUMN TO GRID oGrid HEADER "Column 4" WIDTH 100
   ADD COLUMN TO GRID oGrid HEADER "Column 5" WIDTH 100

   @ (640 - 100) / 2, 480 - 80 BUTTON "&Ok" OF oDialog ID IDOK SIZE 100, 32

   ACTIVATE DIALOG oDialog ON ACTIVATE {||hwg_SetFocus(oGrid:handle)}

RETURN NIL
