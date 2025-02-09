#include "hwgui.ch"
#include "nice.h"

REQUEST nicebuttproc

FUNCTION Main()

   LOCAL o
   lOCAL o1

   INIT DIALOG o FROM RESOURCE DIALOG_1 TITLE "nice button test"
   REDEFINE NICEBUTTON o1 CAPTION "teste" OF o ID IDC_1 RED 125 GREEN 201 BLUE 36
   ACTIVATE DIALOG o

RETURN NIL
