//
// $Id: hshbtn.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// HShadeButton class, inherited from HOwnButton
// It implements some kind of owner drawn buttons
//
// Copyright 2006 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "hbclass.ch"
#include "hwgui.ch"

#define STATE_DEFAULT    1
#define STATE_SELECTED   2
#define STATE_FOCUS      4
#define STATE_OVER       8
#define STATE_DISABLED  16

CLASS HShadeButton INHERIT HOwnButton

   DATA hShade

   METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               bInit, bSize, bPaint, bClick, lflat,              ;
               cText, color, font, xt, yt,                       ;
               bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, ;
               cTooltip, lEnabled, shadeID, palette,         ;
               granularity, highlight, coloring, shcolor)
   METHOD Paint()
   METHOD END()

ENDCLASS

METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            bInit, bSize, bPaint, bClick, lFlat,              ;
            cText, color, font, xt, yt,                       ;
            bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, ;
            cTooltip, lEnabled, shadeID, palette,         ;
            granularity, highlight, coloring, shcolor) CLASS HShadeButton

   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight,    ;
              bInit, bSize, bPaint, bClick, lFlat,             ;
              cText, color, font, xt, yt,,,                    ;
              bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, ;
              cTooltip, lEnabled)

   ::hShade := hwg_Shade_New(0, 0, nWidth, nHeight, lFlat)
   hwg_Shade_Set(::hShade, shadeID, palette, granularity, highlight, coloring, shcolor)
   RETURN Self

METHOD Paint() CLASS HShadeButton
   LOCAL pps, hDC
   LOCAL nState

   pps := hwg_DefinePaintStru()
   hDC := hwg_BeginPaint(::handle, pps)

   IF ::state == OBTN_INIT
      ::state := OBTN_NORMAL
   ENDIF

   IF ::lEnabled
      nState := IIf(::state == OBTN_PRESSED, STATE_SELECTED, STATE_DEFAULT + ;
                     IIf(::state == OBTN_MOUSOVER, STATE_OVER, 0)) + ;
                IIf(hwg_GetFocus() == ::handle, STATE_FOCUS, 0)
   ELSE
      nState := STATE_DISABLED
   ENDIF

   hwg_Shade_Draw(::hShade, hDC, nState)

   ::DrawItems(hDC)

   hwg_EndPaint(::handle, pps)
   RETURN NIL

METHOD END() CLASS HShadeButton

   ::Super:END()
   hwg_Shade_Release(::hShade)
   RETURN NIL
