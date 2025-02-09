#include "hwgui.ch"

FUNCTION Main()

   LOCAL oDialog
   LOCAL oGroupBox
   LOCAL oCheckBox1
   LOCAL oCheckBox2
   LOCAL oCheckBox3
   LOCAL oCheckBox4
   LOCAL oCheckBox5

   INIT DIALOG oDialog TITLE "Test" SIZE 640, 480

   @ 20, 20 GROUPBOX oGroupBox CAPTION "GroupBox" SIZE 640 - 40, 220

   @ 20, 20 CHECKBOX oCheckBox1 CAPTION "CheckBox1" SIZE 300, 26 OF oGroupBox

   @ 20, 60 CHECKBOX oCheckBox2 CAPTION "CheckBox2" SIZE 300, 26 OF oGroupBox

   @ 20, 100 CHECKBOX oCheckBox3 CAPTION "CheckBox3" SIZE 300, 26 OF oGroupBox

   @ 20, 140 CHECKBOX oCheckBox4 CAPTION "CheckBox4" SIZE 300, 26 OF oGroupBox

   @ 20, 180 CHECKBOX oCheckBox5 CAPTION "CheckBox5" SIZE 300, 26 OF oGroupBox

   @ (320 - 100) / 2, 320 BUTTON "&Ok" OF oDialog ID IDOK SIZE 100, 32

   @ (320 - 100) / 2 + 320, 320 BUTTON "&Cancel" OF oDialog ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDialog

RETURN NIL
