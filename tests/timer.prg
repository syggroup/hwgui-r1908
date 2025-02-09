#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oLabel
   LOCAL oTimer

   INIT DIALOG oDialog TITLE "Test" SIZE 640, 480

   @ 20, 20 SAY oLabel CAPTION Time() SIZE 120, 30

   SET TIMER oTimer OF oDialog VALUE 100 ACTION {||oLabel:SetText(Time())}

   ACTIVATE DIALOG oDialog

RETURN NIL
