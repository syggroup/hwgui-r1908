//
// HWGUI using sample
//
// Jose Augusto M de Andrade Jr - jamaj@terra.com.br
//

#include "hwgui.ch"

STATIC aChilds := {}

FUNCTION Main()

   LOCAL oMainWindow

   INIT WINDOW oMainWindow MAIN MDI TITLE "HwGui - Child Windows Example" STYLE WS_CLIPCHILDREN ;

   MENU OF oMainWindow
      MENUITEM "&Exit" ACTION hwg_EndWindow()
      MENUITEM "&Create a child" ACTION CreateChild()
   ENDMENU

   ACTIVATE WINDOW oMainWindow

RETURN NIL

FUNCTION CreateChild(lClip)

   LOCAL oChild
   LOCAL cTitle := "Child Window #" + Str(Len(aChilds) + 1, 2, 0)
   LOCAL oIcon := HIcon():AddFile("..\image\PIM.ICO")
   LOCAL oBmp := HBitMap():AddFile("..\image\logo.bmp")
   LOCAL cMenu := ""
   LOCAL bExit := {|oSelf|hwg_MsgInfo("Bye!" , "Destroy message from " + oSelf:title)}

   DEFAULT lClip := .F.

   /*
   oChild := HWindow():New(WND_CHILD, oIcon, hwg_VColor("0000FF"), NIL, 10, 10, 200, 100, cTitle, cMenu, NIL, NIL, ;
                           NIL, bExit, NIL, NIL, NIL, NIL, NIL, "Child_" + AllTrim(Str(Len(aChilds))), oBmp)
   */

   oChild := HChildWindow():New(oIcon, hwg_VColor("0000FF"), NIL, 10, 10, 200, 100, cTitle, cMenu, NIL, NIL, ;
                          bExit, NIL, NIL, NIL, NIL, NIL, "Child_" + AllTrim(Str(Len(aChilds))), NIL)

   // Test if we could create the window object
   If ISOBJECT(oChild)
      AAdd(aChilds, oChild)
   Else
       hwg_MsgStop("Erro ao tentar criar objeto HWindow!")
   Endif

   oChild:Activate(.T.)

RETURN NIL
