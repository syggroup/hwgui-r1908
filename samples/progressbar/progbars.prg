//
// $Id: progbars.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library
// Sample of using HProgressBar class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
// Copyright 2004 Rodrigo Moreno <rodrigo_moreno@yahoo.com>
//

#include "hwgui.ch"

STATIC oMain
STATIC oForm
STATIC oFont
STATIC oBar := NIL

FUNCTION Main()

        INIT WINDOW oMain MAIN TITLE "Progress Bar Sample"

        MENU OF oMain
             MENUITEM "&Exit" ACTION oMain:Close()
             MENUITEM "&Demo" ACTION Test()
        ENDMENU

        ACTIVATE WINDOW oMain MAXIMIZED

RETURN NIL

FUNCTION Test()

   LOCAL cMsgErr := "Bar doesn't exist"

        PREPARE FONT oFont NAME "Courier New" WIDTH 0 HEIGHT -11

        INIT DIALOG oForm CLIPPER NOEXIT TITLE "Progress Bar Demo";
             FONT oFont ;
             AT 0, 0 SIZE 700, 425 ;
             STYLE DS_CENTER + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU ;
             ON EXIT {||IIf(oBar == Nil, .T.,(oBar:Close(), .T.))}

             @ 115, 390 BUTTON "Step Bar" SIZE 95, 26 ON CLICK {||IIf(oBar == Nil, hwg_MsgStop(cMsgErr), (oBar:Step()))}
             @ 210, 390 BUTTON "Show Text" SIZE 95, 26 ON CLICK {||IIf(oBar == Nil, hwg_MsgStop(cMsgErr), (oBar:setLabel("New Text here")))}
             @ 305, 390 BUTTON "Create Bar" SIZE 95, 26 ON CLICK {||oBar := HProgressBar():NewBox("Testing ...",,,,, 10, 100)}
             @ 400, 390 BUTTON "Create Bar %" SIZE 95, 26 ON CLICK {||oBar := HProgressBar():NewBox("Testing ...",,,,, 10, 100,, .T.)}
             @ 495, 390 BUTTON "Close Bar" SIZE 95, 26 ON CLICK {||IIf(oBar == Nil, hwg_MsgStop(cMsgErr),(oBar:Close(), oBar := Nil))}
             @ 590, 390 BUTTON "Close" SIZE 95, 26 ON CLICK {||oForm:Close()}

        ACTIVATE DIALOG oForm

RETURN NIL
