#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oTrackBar
   LOCAL oSay
   LOCAL bUpdateSay := {||oSay:SetValue(AllTrim(Str(oTrackBar:GetValue())))}

   INIT DIALOG oDialog TITLE "Test" SIZE 500, 300

   @ 20, 20 TRACKBAR oTrackBar ;
      SIZE 400,50 ;
      RANGE 0,100 ;
      INIT 25 ;
      ON INIT {||hwg_MsgInfo("On Init", "TrackBar")} ;
      ON CHANGE bUpdateSay ;
      AUTOTICKS ;
      TOOLTIP "trackbar control"

   @ 300, 100 BUTTON "Get Value" ON CLICK {||hwg_MsgInfo(Str(oTrackBar:GetValue()))} SIZE 100,40
   @ 300, 200 BUTTON "Set Value" ON CLICK {||oTrackBar:SetValue(25), Eval(bUpdateSay)} SIZE 100,40

   @ 100, 100 SAY oSay CAPTION "25" SIZE 40, 40

   ACTIVATE DIALOG oDialog

RETURN NIL
