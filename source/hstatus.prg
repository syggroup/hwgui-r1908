//
// $Id: hcontrol.prg 1902 2012-09-20 11:51:37Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HStatus class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

//#define NM_FIRST                 (0 - 0)
//#define NM_CLICK                (NM_FIRST-2)    // uses NMCLICK struct
#define NM_DBLCLK               (NM_FIRST-3)
#define NM_RCLICK               (NM_FIRST-5)    // uses NMCLICK struct
#define NM_RDBLCLK              (NM_FIRST-6)

//-------------------------------------------------------------------------------------------------------------------//

CLASS HStatus INHERIT HControl

   CLASS VAR winclass INIT "msctls_statusbar32"

   DATA aParts
   DATA nStatusHeight INIT 0
   DATA bDblClick
   DATA bRClick

   METHOD New(oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint, bRClick, bDblClick, nHeight)
   METHOD Activate()
   METHOD Init()
   METHOD Notify(lParam)
   METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aParts)
   METHOD SetTextPanel(nPart, cText, lRedraw)
   METHOD GetTextPanel(nPart)
   METHOD SetIconPanel(nPart, cIcon, nWidth, nHeight)
   METHOD StatusHeight(nHeight)
   METHOD Resize(xIncrSize)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, nStyle, oFont, aParts, bInit, bSize, bPaint, bRClick, bDblClick, nHeight) CLASS HStatus

   bSize := IIf(bSize != NIL, bSize, {|o, x, y|o:Move(0, y - ::nStatusHeight, x, ::nStatusHeight)})
   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), WS_CHILD + WS_VISIBLE + WS_OVERLAPPED + WS_CLIPSIBLINGS)
   ::Super:New(oWndParent, nId, nStyle, 0, 0, 0, 0, oFont, bInit, bSize, bPaint)

   //::nHeight := nHeight
   ::nStatusHeight := IIf(nHeight == NIL, ::nStatusHeight, nHeight)
   ::aParts := aParts
   ::bDblClick := bDblClick
   ::bRClick := bRClick

   ::Activate()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HStatus

   IF !Empty(::oParent:handle)
      ::handle := CreateStatusWindow(::oParent:handle, ::id)
      ::StatusHeight(::nStatusHeight)
      ::Init()
      /*
      IF __ObjHasMsg(::oParent, "AOFFSET")
         aCoors := hwg_GetWindowRect(::handle)
         ::oParent:aOffset[4] := aCoors[4] - aCoors[2]
      ENDIF
      */
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Init() CLASS HStatus

   IF !::lInit
      IF !Empty(::aParts)
         hwg_InitStatus(::oParent:handle, ::handle, Len(::aParts), ::aParts)
      ENDIF
      ::Super:Init()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, ;
   aParts) CLASS hStatus

   HB_SYMBOL_UNUSED(cCaption)
   HB_SYMBOL_UNUSED(lTransp)

   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor)
   HWG_InitCommonControlsEx()
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::aParts := aParts

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Notify(lParam) CLASS HStatus

   LOCAL nCode := hwg_GetNotifyCode(lParam)
   LOCAL nParts := GetNotifySBParts(lParam) - 1

   SWITCH nCode

   //CASE NM_CLICK

   CASE NM_DBLCLK
      IF hb_IsBlock(::bdblClick)
         Eval(::bdblClick, Self, nParts)
      ENDIF
      EXIT

   CASE NM_RCLICK
      IF hb_IsBlock(::bRClick)
         Eval(::bRClick, Self, nParts)
      ENDIF

   ENDSWITCH

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD StatusHeight(nHeight) CLASS HStatus

   LOCAL aCoors

   IF nHeight != NIL
      aCoors := hwg_GetWindowRect(::handle)
      IF nHeight != 0
         IF ::lInit .AND. __ObjHasMsg(::oParent, "AOFFSET")
            ::oParent:aOffset[4] -= (aCoors[4] - aCoors[2])
         ENDIF
         hwg_SendMessage(::handle, SB_SETMINHEIGHT, nHeight, 0)
         hwg_SendMessage(::handle, WM_SIZE, 0, 0)
         aCoors := hwg_GetWindowRect(::handle)
      ENDIF
      ::nStatusHeight := (aCoors[4] - aCoors[2]) - 1
      IF __ObjHasMsg(::oParent, "AOFFSET")
         ::oParent:aOffset[4] += (aCoors[4] - aCoors[2])
      ENDIF
   ENDIF

RETURN ::nStatusHeight

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetTextPanel(nPart) CLASS HStatus

   LOCAL ntxtLen
   LOCAL cText := ""

   ntxtLen := hwg_SendMessage(::handle, SB_GETTEXTLENGTH, nPart - 1, 0)
   cText := Replicate(Chr(0), ntxtLen)
   hwg_SendMessage(::handle, SB_GETTEXT, nPart - 1, @cText)

RETURN cText

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetTextPanel(nPart, cText, lRedraw) CLASS HStatus

   //WriteStatusWindow(::handle, nPart - 1, cText)
   hwg_SendMessage(::handle, SB_SETTEXT, nPart - 1, cText)
   IF lRedraw != NIL .AND. lRedraw
      hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetIconPanel(nPart, cIcon, nWidth, nHeight) CLASS HStatus

   LOCAL oIcon

   DEFAULT nWidth TO 16
   DEFAULT nHeight TO 16
   DEFAULT cIcon TO ""

   IF HB_IsNumeric(cIcon) .OR. At(".", cIcon) == 0
      oIcon := HIcon():addResource(cIcon, nWidth, nHeight)
   ELSE
      oIcon := HIcon():addFile(cIcon, nWidth, nHeight)
   ENDIF
   IF !Empty(oIcon)
      hwg_SendMessage(::handle, SB_SETICON, nPart - 1, oIcon:handle)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Resize(xIncrSize) CLASS HStatus

   LOCAL i

   IF !Empty(::aParts)
      FOR i := 1 TO Len(::aParts)
         ::aParts[i] := ROUND(::aParts[i] * xIncrSize, 0)
      NEXT
      hwg_InitStatus(::oParent:handle, ::handle, Len(::aParts), ::aParts)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//
