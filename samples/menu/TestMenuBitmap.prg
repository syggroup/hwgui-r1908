//
// $Id: TestMenuBitmap.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// C level menu functions
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://www.geocities.com/alkresin/
// Copyright 2004 Sandro R. R. Freire <sandrorrfreire@yahoo.com.br>
// Demo for use Bitmap in menu
//

#include "hwgui.ch"

FUNCTION Main()

   LOCAL oMain

   PRIVATE oMenu

   INIT WINDOW oMain MAIN TITLE "Teste" ;
      AT 0, 0 ; // BACKGROUND BITMAP OBMP ;
      SIZE hwg_GetDesktopWidth(), hwg_GetDesktopHeight() - 28

   MENU OF oMain
      MENU TITLE "Samples"
         MENUITEM "&Exit" ID 1001 ACTION oMain:Close() BITMAP "\hwgui\samples\image\exit_m.bmp"
         SEPARATOR
         MENUITEM "&New " ID 1002 ACTION hwg_MsgInfo("New") BITMAP "\hwgui\samples\image\new_m.bmp"
         MENUITEM "&Open" ID 1003 ACTION hwg_MsgInfo("Open") BITMAP "\hwgui\samples\image\open_m.bmp"
         MENUITEM "&Demo" ID 1004 ACTION Test()
         SEPARATOR
         MENUITEM "&Bitmap and a Text" ID 1005 ACTION Test()
      ENDMENU
   ENDMENU
   //The number ID is very important to use bitmap in menu
   MENUITEMBITMAP oMain ID 1005 BITMAP "\hwgui\samples\image\logo.bmp"
   //hwg_InsertBitmapMenu(oMain:Menu, 1005, "\hwgui\sourceoBmp:handle)   //do not use bitmap empty
   ACTIVATE WINDOW oMain

RETURN NIL

FUNCTION Test()

   hwg_MsgInfo("Test")

RETURN NIL
