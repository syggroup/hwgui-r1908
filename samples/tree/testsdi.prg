//
// $Id: testsdi.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// This sample demonstrates the using of a TREE control
//

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMainWindow
   LOCAL oFont := HFont():Add("MS Sans Serif", 0, -13)
   LOCAL oTree
   LOCAL oSplit
   LOCAL oTab

   INIT WINDOW oMainWindow ;
      MAIN ;
      TITLE "Example" ;
      AT 200, 0 ;
      SIZE 400, 150 ;
      COLOR COLOR_3DLIGHT + 1 ;
      FONT oFont

   MENU OF oMainWindow
      MENU TITLE "&File"
         MENUITEM "&New" ACTION hwg_MsgInfo("New")
         MENUITEM "&Open" ACTION hwg_MsgInfo("Open")
         SEPARATOR
         MENUITEM "&Font" ACTION hwg_MsgInfo("font")
         SEPARATOR
         MENUITEM "&Exit" ACTION hwg_EndWindow()
      ENDMENU
   ENDMENU

   @ 10, 10 TREE oTree ;
      OF oMainWindow ;
      SIZE 200, 280 ;
      EDITABLE ;
      BITMAP {"..\image\cl_fl.bmp", "..\image\op_fl.bmp"} ;
      ON SIZE {|o, x, y|o:Move(, , , y - 20)}

   @ 214, 10 EDITBOX oGet ;
      CAPTION "Command" ;
      SIZE 106, 20 ;
      COLOR VColor("FF0000") ;
      ON SIZE {|o, x, y|o:Move(, , x - oSplit:nLeft - oSplit:nWidth - 50)}

   @ 214, 35 TAB oTab ;
      ITEMS {} ;
      SIZE 206, 280 ;
      ON SIZE {|o, x, y|o:Move(, , x - oSplit:nLeft - oSplit:nWidth - 10, y - 20)} ;
      ON CHANGE {|o|hwg_MsgInfo(Str(Len(o:aPages)))}

   @ 414, 10 BUTTON "X" ;
      SIZE 24, 24 ;
      ON CLICK {||hwg_MsgInfo("Delete " + Str(oTab:GetActivePage())), oTab:DeletePage(oTab:GetActivePage())} ;
      ON SIZE {|o, x, y|o:Move(oTab:nLeft + oTab:nWidth - 26)}

   @ 210, 10 SPLITTER oSplit ;
      SIZE 4, 260 ;
      DIVIDE {oTree} FROM {oTab, oGet} ;
      ON SIZE {|o, x, y|o:Move(, , , y - 20)}

   oSplit:bEndDrag := {||hwg_RedrawWindow(oTab:handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW)}

   BuildTree(oMainWindow, oTree, oTab)

   ACTIVATE WINDOW oMainWindow MAXIMIZED

   oFont:Release()

RETURN NIL

FUNCTION BuildTree(oMainWindow, oTree, oTab)

   LOCAL oNode

   INSERT NODE "First" TO oTree ON CLICK {||NodeOut(1, oTab)}
   INSERT NODE "Second" TO oTree ON CLICK {||NodeOut(2, oTab)}
   INSERT NODE oNode CAPTION "Third" TO oTree ON CLICK {||NodeOut(0, oTab)}
   INSERT NODE "Third-1" TO oNode BITMAP {"..\image\book.bmp"} ON CLICK {||NodeOut(3, oTab)}
   INSERT NODE "Third-2" TO oNode BITMAP {"..\image\book.bmp"} ON CLICK {||NodeOut(4, oTab)}
   INSERT NODE "Forth" TO oTree ON CLICK {||NodeOut(5, oTab)}

   oTree:bExpand := {||.T.}

RETURN NIL

STATIC FUNCTION NodeOut(n, oTab)

   LOCAL cTitle := "Page " + Str(Len(oTab:aPages) + 1)

   oTab:StartPage(cTitle)

   cTitle := "Pages " + Str(Len(oTab:aPages))

   @ 30, 60 SAY cTitle SIZE 100, 26

   oTab:EndPage()

RETURN NIL
