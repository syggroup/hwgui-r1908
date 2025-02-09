#include "hwgui.ch"

FUNCTION Main()

   LOCAL oApp
   LOCAL oMainWindow
   LOCAL oMenuBar
   LOCAL oMenu
   LOCAL oAction1
   LOCAL oAction2

   oApp := QApplication():new()

   oMainWindow := QMainWindow():new()
   oMainWindow:setWindowTitle("Testing Qt Framework and HWGUI dialogs")
   oMainWindow:resize(640, 480)

   oMenuBar := oMainWindow:menuBar()

   oMenu := oMenuBar:addMenu("&Menu")

   oAction1 := oMenu:addAction("Dialog &1 (MODAL)")
   oAction1:onTriggered({||ShowDialog1()})

   oAction2 := oMenu:addAction("Dialog &2 (NOMODAL)")
   oAction2:onTriggered({||ShowDialog2(oMainWindow)})

   oMainWindow:ShowMaximized()

   oApp:exec()

   oMainWindow:delete()

   oApp:delete()

RETURN NIL

STATIC FUNCTION ShowDialog1()

   STATIC n := 0

   LOCAL oDialog
   LOCAL oEdit1
   LOCAL oEdit2
   LOCAL oEdit3
   LOCAL oEdit4
   LOCAL oEdit5

   ++n

   INIT DIALOG oDialog TITLE "Dialog (MODAL) " + AllTrim(Str(n)) ;
      SIZE 640, 480 FONT HFont():Add("Courier New", 0, -13) ;
      STYLE DS_CENTER ;
      ON EXIT {||hwg_MsgYesNo("Confirm exit ?")}

   @ 20, 40 SAY "Field&1 (ALT+1):" SIZE 130, 26
   @ 160, 40 EDITBOX oEdit1 CAPTION "" SIZE 300, 26

   @ 20, 80 SAY "Field&2 (ALT+2):" SIZE 130, 26
   @ 160, 80 EDITBOX oEdit2 CAPTION "" SIZE 300, 26

   @ 20, 120 SAY "Field&3 (ALT+3):" SIZE 130, 26
   @ 160, 120 EDITBOX oEdit3 CAPTION "" SIZE 300, 26

   @ 20, 160 SAY "Field&4 (ALT+4):" SIZE 130, 26
   @ 160, 160 EDITBOX oEdit4 CAPTION "" SIZE 300, 26

   @ 20, 200 SAY "Field&5 (ALT+5):" SIZE 130, 26
   @ 160, 200 EDITBOX oEdit5 CAPTION "" SIZE 300, 26

   @ (320 - 100) / 2, 280 BUTTON "&Ok" OF oDialog ID IDOK SIZE 100, 32

   @ (320 - 100) / 2 + 320, 280 BUTTON "&Cancel" OF oDialog ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDialog

RETURN NIL

// TODO: ALT+KEY not working in NOMODAL dialog
STATIC FUNCTION ShowDialog2(oMainWindow)

   STATIC n := 0

   LOCAL oDialog
   LOCAL oEdit1
   LOCAL oEdit2
   LOCAL oEdit3
   LOCAL oEdit4
   LOCAL oEdit5

   ++n

   INIT DIALOG oDialog TITLE "Dialog (NOMODAL) " + AllTrim(Str(n)) ;
      SIZE 640, 480 FONT HFont():Add("Verdana", 0, -13) ;
      STYLE DS_CENTER ;
      ON EXIT {||IIf(hwg_MsgYesNo("Confirm exit ?"), (oMainWindow:setFocus(), .T.), .F.)}

   @ 20, 40 SAY "Field&1 (ALT+1):" SIZE 130, 26
   @ 160, 40 EDITBOX oEdit1 CAPTION "" SIZE 300, 26

   @ 20, 80 SAY "Field&2 (ALT+2):" SIZE 130, 26
   @ 160, 80 EDITBOX oEdit2 CAPTION "" SIZE 300, 26

   @ 20, 120 SAY "Field&3 (ALT+3):" SIZE 130, 26
   @ 160, 120 EDITBOX oEdit3 CAPTION "" SIZE 300, 26

   @ 20, 160 SAY "Field&4 (ALT+4):" SIZE 130, 26
   @ 160, 160 EDITBOX oEdit4 CAPTION "" SIZE 300, 26

   @ 20, 200 SAY "Field&5 (ALT+5):" SIZE 130, 26
   @ 160, 200 EDITBOX oEdit5 CAPTION "" SIZE 300, 26

   @ (320 - 100) / 2, 280 BUTTON "&Ok" OF oDialog ID IDOK SIZE 100, 32

   @ (320 - 100) / 2 + 320, 280 BUTTON "&Cancel" OF oDialog ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDialog NOMODAL

RETURN NIL
