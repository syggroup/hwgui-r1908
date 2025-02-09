//
// $Id: grid_1.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// HGrid class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://www.geocities.com/alkresin/
// Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
//

#include "hwgui.ch"

STATIC oMain
STATIC oForm
STATIC oFont
STATIC oGrid

FUNCTION Main()

   INIT WINDOW oMain MAIN TITLE "Grid Sample" ;
      AT 0, 0 ;
      SIZE hwg_GetDesktopWidth(), hwg_GetDesktopHeight() - 28

   MENU OF oMain
      MENUITEM "&Exit" ACTION oMain:Close()
      MENUITEM "&Grid Demo" ACTION Test()
   ENDMENU

   ACTIVATE WINDOW oMain

RETURN NIL

FUNCTION Test()

   PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

   INIT DIALOG oForm CLIPPER NOEXIT TITLE "Grid Demo";
      FONT oFont ;
      AT 0, 0 SIZE 700, 425 ;
      STYLE DS_CENTER + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU

   @ 10, 10 GRID oGrid OF oForm SIZE 680, 375;
      ITEMCOUNT 10000 ;
      ON KEYDOWN {|oCtrl, key|OnKey(oCtrl, key)} ;
      ON POSCHANGE {|oCtrl, nRow|OnPoschange(oCtrl, nRow)} ;
      ON CLICK {|oCtrl|OnClick(oCtrl)} ;
      ON DISPINFO {|oCtrl, nRow, nCol|OnDispInfo(oCtrl, nRow, nCol)} ;
      COLOR VColor("D3D3D3");
      BACKCOLOR VColor("BEBEBE")

   ADD COLUMN TO GRID oGrid HEADER "Column 1" WIDTH 150
   ADD COLUMN TO GRID oGrid HEADER "Column 2" WIDTH 150
   ADD COLUMN TO GRID oGrid HEADER "Column 3" WIDTH 150

   @ 620, 395 BUTTON "Close" SIZE 75, 25 ON CLICK {||oForm:Close()}

   ACTIVATE DIALOG oForm

RETURN NIL

FUNCTION OnKey(o, k)

   // hwg_MsgInfo(str(k))

RETURN NIL

FUNCTION OnPosChange(o, row)

   // hwg_MsgInfo(str(row))

RETURN NIL

FUNCTION OnClick(o)

   // hwg_MsgInfo("click")

RETURN NIL

FUNCTION OnDispInfo(o, x, y)
RETURN "Row: " + ltrim(str(x)) + " Col: " + ltrim(str(y))
