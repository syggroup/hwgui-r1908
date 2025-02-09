#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow MAIN TITLE "Example" ;
     AT 200, 0 SIZE 400, 150

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Get a value" ACTION DlgGet()
   ENDMENU

   ACTIVATE WINDOW oMainWindow

RETURN NIL

FUNCTION DlgGet()

   LOCAL oModDlg
   LOCAL oFont := HFont():Add("MS Sans Serif", 0, -13)
   LOCAL cRes
   LOCAL aCombo := {"First", "Second"}
   LOCAL oGet
   LOCAL e1 := "Dialog from prg"
   LOCAL c1 := .F.
   LOCAL c2 := .T.
   LOCAL r1 := 2
   LOCAL cm := 1
   LOCAL upd := 12
   LOCAL d1 := Date() + 1
   LOCAL aIP := {10, 1, 2, 3}

   INIT DIALOG oModDlg TITLE "Get a value"  ;
   AT 210, 10 SIZE 300, 300                  ;
   FONT oFont

   @ 20, 10 SAY "Input something:" SIZE 260, 22
   @ 20, 35 GET oGet VAR e1  ;
        STYLE WS_DLGFRAME   ;
        SIZE 260, 26 COLOR VColor("FF0000")

   @ 20, 70 GET CHECKBOX c1 CAPTION "Check 1" SIZE 90, 20
   @ 20, 95 GET CHECKBOX c2 CAPTION "Check 2" SIZE 90, 20 COLOR VColor("0000FF")


   @ 160, 70 GROUPBOX "RadioGroup" SIZE 130, 75

   GET RADIOGROUP r1
   @ 180, 90 RADIOBUTTON "Radio 1"  ;
        SIZE 90, 20 ON CLICK {||oGet:SetColor(VColor("0000FF"),, .T.)}
   @ 180, 115 RADIOBUTTON "Radio 2" ;
        SIZE 90, 20 ON CLICK {||oGet:SetColor(VColor("FF0000"),, .T.)}
   END RADIOGROUP

   @ 20, 120 GET COMBOBOX cm ITEMS aCombo SIZE 100, 150

   @ 20, 170 GET UPDOWN upd RANGE 0, 80 SIZE 50, 30
   @ 160, 170 GET DATEPICKER d1 SIZE 80, 20

   @ 20, 200 GET IPADDRESS ip1 VAR aIP SIZE 140, 26 ON GETFOCUS {|value, o|NIL} ON LOSTFOCUS {|value, o|NIL}

   @ 20, 240 BUTTON "Ok" ID IDOK SIZE 100, 32
   @ 180, 240 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oModDlg
   oFont:Release()

   IF oModDlg:lResult
      hwg_MsgInfo(e1 + Chr(10) + Chr(13) +                               ;
               "Check1 - " + IIf(c1, "On", "Off") + Chr(10) + Chr(13) + ;
               "Check2 - " + IIf(c2, "On", "Off") + Chr(10) + Chr(13) + ;
               "Radio: " + Str(r1, 1) + Chr(10) + Chr(13) +            ;
               "Combo: " + aCombo[cm] + Chr(10) + Chr(13) +           ;
               "UpDown: " + Str(upd) + Chr(10) + Chr(13) +              ;
               "DatePicker: " + Dtoc(d1) +                              ;
               "IpAddress: " + StrZero(aIP[1], 3, 0) + "." + StrZero(aIP[2], 3, 0) + "." + StrZero(aIP[3], 3, 0) + "." +  StrZero(aIP[4], 3, 0) ;
               , "Results:")
   ENDIF

RETURN NIL

FUNCTION IpGetFocus()

   hwg_MsgInfo("GetFocus")

RETURN NIL

FUNCTION IpLostFocus()

   hwg_MsgInfo("LostFocus")

RETURN NIL
