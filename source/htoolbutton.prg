//
// $Id: htool.prg 1901 2012-09-19 23:12:50Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HToolButton class
//
// Copyright 2004 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
// www - http://sites.uol.com.br/culikr/
//

#include "windows.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

//-------------------------------------------------------------------------------------------------------------------//

CLASS HToolButton INHERIT HObject

   DATA Name
   DATA id
   DATA nBitIp INIT -1
   DATA bState INIT TBSTATE_ENABLED
   DATA bStyle INIT 0x0000
   DATA tooltip
   DATA aMenu INIT {}
   DATA hMenu
   DATA Title
   DATA lEnabled INIT .T. HIDDEN
   DATA lChecked INIT .F. HIDDEN
   DATA lPressed INIT .F. HIDDEN
   DATA bClick
   DATA oParent
   //DATA oFont // not implemented

   METHOD New(oParent, cName, nBitIp, nId, bState, bStyle, cText, bClick, ctip, aMenu)
   METHOD Enable() INLINE ::oParent:EnableButton(::id, .T.)
   METHOD Disable() INLINE ::oParent:EnableButton(::id, .F.)
   METHOD Show() INLINE hwg_SendMessage(::oParent:handle, TB_HIDEBUTTON, INT(::id), MAKELONG(0, 0))
   METHOD Hide() INLINE hwg_SendMessage(::oParent:handle, TB_HIDEBUTTON, INT(::id), MAKELONG(1, 0))
   METHOD Enabled(lEnabled) SETGET
   METHOD Checked(lCheck) SETGET
   METHOD Pressed(lPressed) SETGET
   METHOD onClick()
   METHOD Caption(cText) SETGET

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oParent, cName, nBitIp, nId, bState, bStyle, cText, bClick, ctip, aMenu) CLASS HToolButton

   ::Name := cName
   ::iD := nId
   ::title := cText
   ::nBitIp := nBitIp
   ::bState := bState
   ::bStyle := bStyle
   ::tooltip := ctip
   ::bClick := bClick
   ::aMenu := amenu
   ::oParent := oParent
   __objAddData(::oParent, cName)
   ::oParent:&(cName) := Self

   //::oParent:oParent:AddEvent(BN_CLICKED, Self, {||::ONCLICK()}, , "click")

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Caption(cText) CLASS HToolButton

   IF cText != NIL
      ::Title := cText
      TOOLBAR_SETBUTTONINFO(::oParent:handle, ::id, cText)
   ENDIF

RETURN ::Title

//-------------------------------------------------------------------------------------------------------------------//

METHOD onClick() CLASS HToolButton

   IF hb_IsBlock(::bClick)
      Eval(::bClick, self, ::id)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Enabled(lEnabled) CLASS HToolButton

   IF lEnabled != NIL
      IF lEnabled
         ::enable()
      ELSE
         ::disable()
      ENDIF
      ::lEnabled := lEnabled
   ENDIF

RETURN ::lEnabled

//-------------------------------------------------------------------------------------------------------------------//

METHOD Pressed(lPressed) CLASS HToolButton

   LOCAL nState

   IF lPressed != NIL
      nState := hwg_SendMessage(::oParent:handle, TB_GETSTATE, INT(::id), 0)
      hwg_SendMessage(::oParent:handle, TB_SETSTATE, INT(::id), ;
         MAKELONG(IIf(lPressed, HWG_BITOR(nState, TBSTATE_PRESSED), ;
         nState - HWG_BITAND(nState, TBSTATE_PRESSED)), 0))
      ::lPressed := lPressed
   ENDIF

RETURN ::lPressed

//-------------------------------------------------------------------------------------------------------------------//

METHOD Checked(lcheck) CLASS HToolButton

   LOCAL nState

   IF lCheck != NIL
      nState := hwg_SendMessage(::oParent:handle, TB_GETSTATE, INT(::id), 0)
      hwg_SendMessage(::oParent:handle, TB_SETSTATE, INT(::id), ;
         MAKELONG(IIf(lCheck, HWG_BITOR(nState, TBSTATE_CHECKED), ;
         nState - HWG_BITAND(nState, TBSTATE_CHECKED)), 0))
      ::lChecked := lCheck
   ENDIF

RETURN ::lChecked

//-------------------------------------------------------------------------------------------------------------------//
