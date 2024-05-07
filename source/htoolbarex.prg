/*
 * $Id: htool.prg 1901 2012-09-19 23:12:50Z lfbasso $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 *
 *
 * Copyright 2004 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
 * www - http://sites.uol.com.br/culikr/
*/
#include "windows.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define TRANSPARENT 1
#DEFINE IDTOOLBAR 700
#DEFINE IDMAXBUTTONTOOLBAR 64

CLASS HToolBarEX INHERIT HToolBar

//method onevent()
   METHOD init()
   METHOD ExecuteTool( nid )
   DESTRUCTOR MyDestructor
END CLASS


METHOD init() CLASS htoolbarex
   ::Super:init()
   SetWindowObject(::handle, Self)
   SETTOOLHANDLE(::handle)
   Sethook()
   RETURN Self

//method onEvent(msg,w,l) class htoolbarex
//Local nId
//Local nPos
//  if msg == WM_KEYDOWN
//
//  return -1
//  elseif msg==WM_KEYUP
//  unsethook()
//  return -1
//  endif
//return 0

METHOD ExecuteTool( nid ) CLASS htoolbarex

   IF nid > 0
      SendMessage(::oParent:handle, WM_COMMAND, makewparam( nid, BN_CLICKED ), ::handle)
      RETURN 0
   ENDIF
   RETURN - 200

/*
STATIC FUNCTION IsAltShift( lAlt )
   LOCAL cKeyb := GetKeyboardState()

   IF lAlt == Nil ; lAlt := .T. ; ENDIF
   RETURN ( lAlt .AND. ( Asc(SubStr( cKeyb, VK_MENU + 1, 1 )) >= 128 ) )
   */

PROCEDURE MyDestructor CLASS htoolbarex
   unsethook()
   RETURN
