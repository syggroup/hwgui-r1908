//
// $Id: htrackbr.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// HTrackBar class
//
// Copyright 2004 Marcos Antonio Gambeta <marcosgambeta AT outlook DOT com>
// www - http://github.com/marcosgambeta/
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define TBS_AUTOTICKS                1
#define TBS_VERT                     2
#define TBS_TOP                      4
#define TBS_LEFT                     4
#define TBS_BOTH                     8
#define TBS_NOTICKS                 16

CLASS HTrackBar INHERIT HControl

   CLASS VAR winclass INIT "msctls_trackbar32"

   DATA value
   DATA bChange
   DATA bThumbDrag
   DATA nLow
   DATA nHigh
   DATA hCursor

   METHOD New(oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, bInit, bSize, bPaint, ;
              cTooltip, bChange, bDrag, nLow, nHigh, lVertical, TickStyle, TickMarks)
   METHOD Activate()
   METHOD onEvent(msg, wParam, lParam)
   METHOD Init()
   METHOD SetValue(nValue)
   METHOD GetValue()
   METHOD GetNumTics() INLINE hwg_SendMessage(::handle, TBM_GETNUMTICS, 0, 0)

ENDCLASS

METHOD New(oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, bInit, bSize, bPaint, ;
           cTooltip, bChange, bDrag, nLow, nHigh, lVertical, TickStyle, TickMarks) CLASS HTrackBar

   IF TickStyle == NIL
      TickStyle := TBS_AUTOTICKS
   ENDIF
   IF TickMarks == NIL
      TickMarks := 0
   ENDIF
   IF bPaint != NIL
      TickStyle := hwg_BitOr(TickStyle, TBS_AUTOTICKS)
   ENDIF
   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), WS_CHILD + WS_VISIBLE + WS_TABSTOP)
   nStyle += IIf(lVertical != NIL .AND. lVertical, TBS_VERT, 0)
   nStyle += TickStyle + TickMarks

   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, , bInit, bSize, bPaint, cTooltip)

   ::value := IIf(hb_IsNumeric(vari), vari, 0)
   ::bChange := bChange
   ::bThumbDrag := bDrag
   ::nLow := IIf(nLow == NIL, 0, nLow)
   ::nHigh := IIf(nHigh == NIL, 100, nHigh)

   HWG_InitCommonControlsEx()
   ::Activate()

RETURN Self

METHOD Activate() CLASS HTrackBar

   IF !Empty(::oParent:handle)
      ::handle := InitTrackBar(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                               ::nLow, ::nHigh)
      ::Init()
   ENDIF

RETURN NIL

#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HTrackBar

   LOCAL aCoors

   IF msg == WM_PAINT
      IF hb_IsBlock(::bPaint)
         Eval(::bPaint, Self)
         RETURN 0
      ENDIF

   ELSEIF msg == WM_MOUSEMOVE
      IF ::hCursor != NIL
         hwg_SetCursor(::hCursor)
      ENDIF

   ELSEIF msg == WM_ERASEBKGND
      IF ::brush != NIL
         aCoors := hwg_GetClientRect(::handle)
         FillRect(wParam, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, ::brush:handle)
         RETURN 1
      ENDIF

   ELSEIF msg == WM_DESTROY
      ::END()

   ELSEIF msg == WM_CHAR
      IF wParam == VK_TAB
         GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN 0
      ENDIF

   ELSEIF msg == WM_KEYDOWN
      IF ProcKeyList(Self, wParam)
         RETURN 0
      ENDIF

   ELSEIF hb_IsBlock(::bOther)
      RETURN Eval(::bOther, Self, msg, wParam, lParam)

   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HTrackBar

   LOCAL aCoors

   SWITCH msg

   CASE WM_PAINT
      IF hb_IsBlock(::bPaint)
         Eval(::bPaint, Self)
         RETURN 0
      ENDIF
      EXIT

   CASE WM_MOUSEMOVE
      IF ::hCursor != NIL
         hwg_SetCursor(::hCursor)
      ENDIF
      EXIT

   CASE WM_ERASEBKGND
      IF ::brush != NIL
         aCoors := hwg_GetClientRect(::handle)
         FillRect(wParam, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, ::brush:handle)
         RETURN 1
      ENDIF
      EXIT

   CASE WM_DESTROY
      ::END()
      EXIT

   CASE WM_CHAR
      IF wParam == VK_TAB
         GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN 0
      ENDIF
      EXIT

   CASE WM_KEYDOWN
      IF ProcKeyList(Self, wParam)
         RETURN 0
      ENDIF
      EXIT

#ifdef __XHARBOUR__
   DEFAULT
#else
   OTHERWISE
#endif
      IF hb_IsBlock(::bOther)
         RETURN Eval(::bOther, Self, msg, wParam, lParam)
      ENDIF

   ENDSWITCH

   RETURN -1
#endif

METHOD Init() CLASS HTrackBar

   IF !::lInit
      ::Super:Init()
      TrackBarSetRange(::handle, ::nLow, ::nHigh)
      hwg_SendMessage(::handle, TBM_SETPOS, 1, ::value)
      IF ::bPaint != NIL
         ::nHolder := 1
         hwg_SetWindowObject(::handle, Self)
         hwg_InitTrackProc(::handle)
      ENDIF
   ENDIF

RETURN NIL

METHOD SetValue(nValue) CLASS HTrackBar

   IF hb_IsNumeric(nValue)
      hwg_SendMessage(::handle, TBM_SETPOS, 1, nValue)
      ::value := nValue
   ENDIF

RETURN NIL

METHOD GetValue() CLASS HTrackBar

   ::value := hwg_SendMessage(::handle, TBM_GETPOS, 0, 0)

RETURN ::value

#pragma BEGINDUMP

#include "hwingui.h"
#include <commctrl.h>

HB_FUNC(INITTRACKBAR)
{
  hwg_ret_HWND(CreateWindowEx(0, TRACKBAR_CLASS, 0, hwg_par_DWORD(3), hwg_par_int(4), hwg_par_int(5), hwg_par_int(6),
                              hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL));
}

HB_FUNC(TRACKBARSETRANGE)
{
  SendMessage(hwg_par_HWND(1), TBM_SETRANGE, TRUE, MAKELONG(hb_parni(2), hb_parni(3)));
}

#pragma ENDDUMP
