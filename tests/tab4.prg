#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oTab
   // TAB-A
   LOCAL oGetA1
   LOCAL cGetA1
   LOCAL oGetA2
   LOCAL cGetA2
   LOCAL oGetA3
   LOCAL cGetA3
   LOCAL oGetA4
   LOCAL cGetA4
   LOCAL oGetA5
   LOCAL cGetA5
   // TAB-B
   LOCAL oGetB1
   LOCAL cGetB1
   LOCAL oGetB2
   LOCAL cGetB2
   LOCAL oGetB3
   LOCAL cGetB3
   LOCAL oGetB4
   LOCAL cGetB4
   LOCAL oGetB5
   LOCAL cGetB5
   // TAB-C
   LOCAL oGetC1
   LOCAL cGetC1
   LOCAL oGetC2
   LOCAL cGetC2
   LOCAL oGetC3
   LOCAL cGetC3
   LOCAL oGetC4
   LOCAL cGetC4
   LOCAL oGetC5
   LOCAL cGetC5

   INIT DIALOG oDialog TITLE "Test" SIZE 800, 600 ;

   @ 40, 40 TAB oTab ITEMS {} OF oDialog SIZE 800 - 80, 600 - 100 ;
      ON CLICK {|o, n|hwg_MsgInfo("Tab "+alltrim(str(n))+ " clicked", "Info")} ;
      ON RIGHTCLICK {|o, n|hwg_MsgInfo("Tab "+alltrim(str(n))+ " right clicked", "Info")}

   BEGIN PAGE "&First Tab" OF oTab
      @ 20, 40 SAY "Field A&1 (ALT+1):" SIZE 120, 26
      @ 160, 40 GET oGetA1 VAR cGetA1 SIZE 300, 26
      @ 20, 80 SAY "Field A&2 (ALT+2):" SIZE 120, 26
      @ 160, 80 GET oGetA2 VAR cGetA2 SIZE 300, 26
      @ 20, 120 SAY "Field A&3 (ALT+3):" SIZE 120, 26
      @ 160, 120 GET oGetA3 VAR cGetA3 SIZE 300, 26
      @ 20, 160 SAY "Field A&4 (ALT+4):" SIZE 120, 26
      @ 160, 160 GET oGetA4 VAR cGetA4 SIZE 300, 26
      @ 20, 200 SAY "Field A&5 (ALT+5):" SIZE 120, 26
      @ 160, 200 GET oGetA5 VAR cGetA5 SIZE 300, 26
   END PAGE OF oTab

   BEGIN PAGE "&Second Tab" OF oTab
      @ 20, 40 SAY "Field B&1 (ALT+1):" SIZE 120, 26
      @ 160, 40 GET oGetB1 VAR cGetB1 SIZE 300, 26
      @ 20, 80 SAY "Field B&2 (ALT+2):" SIZE 120, 26
      @ 160, 80 GET oGetB2 VAR cGetB2 SIZE 300, 26
      @ 20, 120 SAY "Field B&3 (ALT+3):" SIZE 120, 26
      @ 160, 120 GET oGetB3 VAR cGetB3 SIZE 300, 26
      @ 20, 160 SAY "Field B&4 (ALT+4):" SIZE 120, 26
      @ 160, 160 GET oGetB4 VAR cGetB4 SIZE 300, 26
      @ 20, 200 SAY "Field B&5 (ALT+5):" SIZE 120, 26
      @ 160, 200 GET oGetB5 VAR cGetB5 SIZE 300, 26
   END PAGE OF oTab

   BEGIN PAGE "&Third Tab" OF oTab
      @ 20, 40 SAY "Field C&1 (ALT+1):" SIZE 120, 26
      @ 160, 40 GET oGetC1 VAR cGetC1 SIZE 300, 26
      @ 20, 80 SAY "Field C&2 (ALT+2):" SIZE 120, 26
      @ 160, 80 GET oGetC2 VAR cGetC2 SIZE 300, 26
      @ 20, 120 SAY "Field C&3 (ALT+3):" SIZE 120, 26
      @ 160, 120 GET oGetC3 VAR cGetC3 SIZE 300, 26
      @ 20, 160 SAY "Field C&4 (ALT+4):" SIZE 120, 26
      @ 160, 160 GET oGetC4 VAR cGetC4 SIZE 300, 26
      @ 20, 200 SAY "Field C&5 (ALT+5):" SIZE 120, 26
      @ 160, 200 GET oGetC5 VAR cGetC5 SIZE 300, 26
   END PAGE OF oTab

   @ (400 - 100) / 2, 600 - 52 BUTTON "&Ok" OF oDialog ID IDOK SIZE 100, 32

   @ (400 - 100) / 2 + 400, 600 - 52 BUTTON "&Cancel" OF oDialog ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDialog ON ACTIVATE {||oGetA1:SetFocus()}

   IF oDialog:lResult
      hwg_MsgInfo("OK", "Info")
   ELSE
      hwg_MsgInfo("CANCEL", "Info")
   ENDIF

RETURN NIL
