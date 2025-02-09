//
// $Id: hownbtn.prg 1866 2012-08-27 16:23:17Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HOwnButton class, which implements owner drawn buttons
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define TRANSPARENT 1

//-------------------------------------------------------------------------------------------------------------------//

CLASS HOwnButton INHERIT HControl

   CLASS VAR cPath SHARED

   DATA winclass INIT "OWNBTN"
   DATA lFlat
   DATA state
   DATA bClick
   DATA lPress INIT .F.
   DATA lCheck INIT .F.
   DATA xt
   DATA yt
   DATA widtht
   DATA heightt
   DATA oBitmap
   DATA xb
   DATA yb
   DATA widthb
   DATA heightb
   DATA lTransp
   DATA trColor
   DATA lEnabled INIT .T.
   DATA nOrder
   DATA m_bFirstTime INIT .T.
   DATA hTheme
   DATA Themed INIT .F.

   METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, bSize, bPaint, bClick, lflat, cText, ;
      color, oFont, xt, yt, widtht, heightt, bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, cTooltip, lEnabled, ;
      lCheck, bColor, bGfocus, bLfocus, themed)
   METHOD Activate()
   METHOD onEvent(msg, wParam, lParam)
   METHOD Init()
   METHOD Redefine(oWndParent, nId, bInit, bSize, bPaint, bClick, lflat, cText, color, font, xt, yt, widtht, heightt, ;
      bmp, lResour, xb, yb, widthb, heightb, lTr, cTooltip, lEnabled, lCheck)
   METHOD Paint()
   METHOD DrawItems(hDC)
   METHOD MouseMove(wParam, lParam)
   METHOD MDown()
   METHOD MUp()
   METHOD Press() INLINE (::lPress := .T., ::MDown())
   METHOD Release()
   METHOD END()
   METHOD Enable()
   METHOD Disable()
   METHOD onClick()
   METHOD onGetFocus()
   METHOD onLostFocus()
   METHOD Refresh()
   METHOD SetText(cCaption) INLINE ::title := cCaption, ;
      hwg_RedrawWindow(::oParent:handle, RDW_ERASE + RDW_INVALIDATE, ::nLeft, ::nTop, ::nWidth, ::nHeight)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, bInit, bSize, bPaint, bClick, lflat, cText, color, ;
   oFont, xt, yt, widtht, heightt, bmp, lResour, xb, yb, widthb, heightb, lTr, trColor, cTooltip, lEnabled, lCheck, ;
   bColor, bGfocus, bLfocus, themed) CLASS HOwnButton

   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, cTooltip)

   //HB_SYMBOL_UNUSED(bGFocus)
   //HB_SYMBOL_UNUSED(bLFocus)

   IF oFont == NIL
      ::oFont := ::oParent:oFont
   ENDIF
   ::lflat := IIf(lflat == NIL, .F., lflat)
   ::bClick := bClick
   ::bGetFocus := bGFocus
   ::bLostFocus := bLfocus
   ::state := OBTN_INIT
   ::nOrder := IIf(oWndParent == NIL, 0, Len(oWndParent:aControls))
   ::title := cText
   ::tcolor := IIf(color == NIL, GetSysColor(COLOR_BTNTEXT), color)
   IF bColor != NIL
      ::bcolor := bcolor
      ::brush := HBrush():Add(bcolor)
   ENDIF
   ::xt := IIf(xt == NIL, 0, xt)
   ::yt := IIf(yt == NIL, 0, yt)
   ::widtht := IIf(widtht == NIL, 0, widtht)
   ::heightt := IIf(heightt == NIL, 0, heightt)
   IF lEnabled != NIL
      ::lEnabled := lEnabled
   ENDIF
   IF lCheck != NIL
      ::lCheck := lCheck
   ENDIF
   ::themed := IIf(themed == NIL, .F., themed)
   IF bmp != NIL
      IF hb_IsObject(bmp)
         ::oBitmap := bmp
      ELSE
         ::oBitmap := IIf((lResour != NIL .AND. lResour) .OR. hb_IsNumeric(bmp), HBitmap():AddResource(bmp), ;
            HBitmap():AddFile(IIf(::cPath != NIL, ::cPath + bmp, bmp)))
      ENDIF
   ENDIF
   ::xb := xb
   ::yb := yb
   ::widthb := IIf(widthb == NIL, 0, widthb)
   ::heightb := IIf(heightb == NIL, 0, heightb)
   ::lTransp := IIf(lTr != NIL, lTr, .F.)
   ::trColor := trColor
   IF bClick != NIL
      ::oParent:AddEvent(0, Self, {||::onClick()}, ,)
   ENDIF
   hwg_RegOwnBtn()
   ::Activate()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HOwnButton

   IF !Empty(::oParent:handle)
      ::handle := CreateOwnBtn(::oParent:handle, ::id, ::nLeft, ::nTop, ::nWidth, ::nHeight)
      ::Init()
      IF !::lEnabled
         hwg_EnableWindow(::handle, .F.)
         ::Disable()
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HOwnButton

   IF msg == WM_THEMECHANGED
      IF ::Themed
         IF hb_IsPointer(::hTheme)
            HB_CLOSETHEMEDATA(::htheme)
            ::hTheme := NIL
         ENDIF
         ::Themed := .F.
      ENDIF
      ::m_bFirstTime := .T.
      hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
      RETURN 0

   ELSEIF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg == WM_PAINT
      IF hb_IsBlock(::bPaint)
         Eval(::bPaint, Self)
      ELSE
         ::Paint()
      ENDIF
   ELSEIF msg == WM_MOUSEMOVE
      ::MouseMove(wParam, lParam)
   ELSEIF msg == WM_LBUTTONDOWN
      ::MDown()
   ELSEIF msg == WM_LBUTTONUP
      ::MUp()
   ELSEIF msg == WM_DESTROY
      ::END()
   ELSEIF msg == WM_SETFOCUS
      /*
      IF hb_IsBlock(::bGetfocus)
         Eval(::bGetfocus, Self, msg, wParam, lParam)
      ENDIF
      */
      ::onGetFocus()
   ELSEIF msg == WM_KILLFOCUS
      /*
      IF hb_IsBlock(::bLostfocus)
         Eval(::bLostfocus, Self, msg, wParam, lParam)
      ENDIF
      */
      IF !::lCheck
         ::release()
      ENDIF
      ::onLostFocus()
   ELSEIF msg == WM_CHAR .OR. msg == WM_KEYDOWN .OR. msg == WM_KEYUP
      IF wParam == VK_SPACE
         ::Press()
         ::onClick()
         ::Release()
      ENDIF
   ELSE
      IF hb_IsBlock(::bOther)
         Eval(::bOther, Self, msg, wParam, lParam)
      ENDIF
   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HOwnButton

   SWITCH msg

   CASE WM_THEMECHANGED
      IF ::Themed
         IF hb_IsPointer(::hTheme)
            HB_CLOSETHEMEDATA(::htheme)
            ::hTheme := NIL
         ENDIF
         ::Themed := .F.
      ENDIF
      ::m_bFirstTime := .T.
      hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
      RETURN 0

   CASE WM_ERASEBKGND
      RETURN 0

   CASE WM_PAINT
      IF hb_IsBlock(::bPaint)
         Eval(::bPaint, Self)
      ELSE
         ::Paint()
      ENDIF
      EXIT

   CASE WM_MOUSEMOVE
      ::MouseMove(wParam, lParam)
      EXIT

   CASE WM_LBUTTONDOWN
      ::MDown()
      EXIT

   CASE WM_LBUTTONUP
      ::MUp()
      EXIT

   CASE WM_DESTROY
      ::END()
      EXIT

   CASE WM_SETFOCUS
      /*
      IF hb_IsBlock(::bGetfocus)
         Eval(::bGetfocus, Self, msg, wParam, lParam)
      ENDIF
      */
      ::onGetFocus()
      EXIT

   CASE WM_KILLFOCUS
      /*
      IF hb_IsBlock(::bLostfocus)
         Eval(::bLostfocus, Self, msg, wParam, lParam)
      ENDIF
      */
      IF !::lCheck
         ::release()
      ENDIF
      ::onLostFocus()
      EXIT

   CASE WM_CHAR
   CASE WM_KEYDOWN
   CASE WM_KEYUP
      IF wParam == VK_SPACE
         ::Press()
         ::onClick()
         ::Release()
      ENDIF
      EXIT

   #ifdef __XHARBOUR__
   DEFAULT
   #else
   OTHERWISE
   #endif
      IF hb_IsBlock(::bOther)
         Eval(::bOther, Self, msg, wParam, lParam)
      ENDIF

   ENDSWITCH

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD Init() CLASS HOwnButton

   IF !::lInit
      ::nHolder := 1
      hwg_SetWindowObject(::handle, Self)
      ::Super:Init()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, bInit, bSize, bPaint, bClick, lflat, cText, color, font, xt, yt, widtht, heightt, ;
   bmp, lResour, xb, yb, widthb, heightb, lTr, cTooltip, lEnabled, lCheck) CLASS HOwnButton

   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0,, bInit, bSize, bPaint, cTooltip)

   ::lflat := IIf(lflat == NIL, .F., lflat)
   ::bClick := bClick
   ::state := OBTN_INIT
   ::title := cText
   ::tcolor := IIf(color == NIL, GetSysColor(COLOR_BTNTEXT), color)
   ::ofont := font
   ::xt := IIf(xt == NIL, 0, xt)
   ::yt := IIf(yt == NIL, 0, yt)
   ::widtht := IIf(widtht == NIL, 0, widtht)
   ::heightt := IIf(heightt == NIL, 0, heightt)

   IF lEnabled != NIL
      ::lEnabled := lEnabled
   ENDIF
   //IF lEnabled != NIL
   //   ::lEnabled := lEnabled
   //ENDIF
   IF lCheck != NIL
      ::lCheck := lCheck
   ENDIF
   IF bmp != NIL
      IF hb_IsObject(bmp)
         ::oBitmap := bmp
      ELSE
         ::oBitmap := IIf(lResour, HBitmap():AddResource(bmp), HBitmap():AddFile(bmp))
      ENDIF
   ENDIF
   ::xb := xb
   ::yb := yb
   ::widthb := IIf(widthb == NIL, 0, widthb)
   ::heightb := IIf(heightb == NIL, 0, heightb)
   ::lTransp := IIf(lTr != NIL, lTr, .F.)

   hwg_RegOwnBtn()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Paint() CLASS HOwnButton

   LOCAL pps
   LOCAL hDC
   LOCAL aCoors
   LOCAL state

   pps := hwg_DefinePaintStru()

   hDC := hwg_BeginPaint(::handle, pps)

   aCoors := hwg_GetClientRect(::handle)

   IF ::state == OBTN_INIT
      ::state := OBTN_NORMAL
   ENDIF
   IF ::nWidth != aCoors[3] .OR. ::nHeight != aCoors[4]
      ::nWidth := aCoors[3]
      ::nHeight := aCoors[4]
   ENDIF
   IF ::Themed .AND. ::m_bFirstTime
      ::m_bFirstTime := .F.
      IF ISTHEMEDLOAD()
         IF hb_IsPointer(::hTheme)
            HB_CLOSETHEMEDATA(::htheme)
         ENDIF
         IF ::WindowsManifest
            ::hTheme := hb_OpenThemeData(::handle, "BUTTON")
         ENDIF
         ::hTheme := IIf(Empty(::hTheme), NIL, ::hTheme)
      ENDIF
      IF Empty(::hTheme)
         ::Themed := .F.
      ENDIF
   ENDIF
   IF ::Themed
      IF !::lEnabled
         state := PBS_DISABLED
      ELSE
         state := IIf(::state == OBTN_PRESSED, PBS_PRESSED, PBS_NORMAL)
      ENDIF
      IF ::lCheck
         state := OBTN_PRESSED
      ENDIF
   ENDIF

   IF ::lFlat
      IF ::Themed
         //SetBkMode(hdc, TRANSPARENT)
         IF ::handle == hwg_GetFocus() .AND. ::lCheck
            hb_DrawThemeBackground(::hTheme, hdc, BP_PUSHBUTTON, PBS_PRESSED, aCoors, NIL)
         ELSEIF ::state != OBTN_NORMAL
             hb_DrawThemeBackground(::hTheme, hdc, BP_PUSHBUTTON, state, aCoors, NIL)
         ELSE
            //SetBkMode(hdc, 1)
            DrawButton(hDC, 0, 0, aCoors[3], aCoors[4], 0)
         ENDIF
      ELSE
         IF ::state == OBTN_NORMAL
            IF !hwg_SelfFocus(::handle, hwg_GetFocus())
               // NORM
               DrawButton(hDC, 0, 0, aCoors[3], aCoors[4], 0)
            ELSE
               DrawButton(hDC, 0, 0, aCoors[3], aCoors[4], 1)
            ENDIF
         ELSEIF ::state == OBTN_MOUSOVER
            DrawButton(hDC, 0, 0, aCoors[3], aCoors[4], 1)
         ELSEIF ::state == OBTN_PRESSED
            DrawButton(hDC, 0, 0, aCoors[3], aCoors[4], 2)
         ENDIF
      ENDIF
   ELSE
      IF ::Themed
         //SetBkMode(hdc, TRANSPARENT)
         IF hwg_SelfFocus(::handle, hwg_GetFocus()) .AND. ::lCheck
            hb_DrawThemeBackground(::hTheme, hdc, BP_PUSHBUTTON, PBS_PRESSED, aCoors, NIL)
         ELSE //IF ::state != OBTN_NORMAL
            hb_DrawThemeBackground(::hTheme, hdc, BP_PUSHBUTTON, state, aCoors, NIL)
         //ELSE
         //   DrawButton(hDC, 0, 0, aCoors[3], aCoors[4], 0)
         ENDIF
      ELSE
         IF ::state == OBTN_NORMAL
            DrawButton(hDC, 0, 0, aCoors[3], aCoors[4], 5)
         ELSEIF ::state == OBTN_PRESSED
            DrawButton(hDC, 0, 0, aCoors[3], aCoors[4], 6)
         ENDIF
      ENDIF
   ENDIF

   ::DrawItems(hDC)

   hwg_EndPaint(::handle, pps)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD DrawItems(hDC) CLASS HOwnButton

   LOCAL x1
   LOCAL y1
   LOCAL x2
   LOCAL y2
   LOCAL aCoors

   aCoors := hwg_GetClientRect(::handle)
   IF !Empty(::brush)
      FillRect(hDC, aCoors[1] + 2, aCoors[2] + 2, aCoors[3] - 2, aCoors[4] - 2, ::Brush:handle)
   ENDIF

   IF ::oBitmap != NIL
      IF ::widthb == 0
         ::widthb := ::oBitmap:nWidth
         ::heightb := ::oBitmap:nHeight
      ENDIF
      x1 := IIf(::xb != NIL .AND. ::xb != 0, ::xb, Round((::nWidth - ::widthb) / 2, 0))
      y1 := IIf(::yb != NIL .AND. ::yb != 0, ::yb, Round((::nHeight - ::heightb) / 2, 0))
      IF ::lEnabled
         IF ::oBitmap:ClassName() == "HICON"
            DrawIcon(hDC, ::oBitmap:handle, x1, y1)
         ELSE
            IF ::lTransp
               DrawTransparentBitmap(hDC, ::oBitmap:handle, x1, y1, ::trColor)
            ELSE
               DrawBitmap(hDC, ::oBitmap:handle,, x1, y1, ::widthb, ::heightb)
            ENDIF
         ENDIF
      ELSE
         DrawGrayBitmap(hDC, ::oBitmap:handle, x1, y1)
      ENDIF
   ENDIF

   IF ::title != NIL
      IF ::oFont != NIL
         hwg_SelectObject(hDC, ::oFont:handle)
      ENDIF
      IF ::lEnabled
         SetTextColor(hDC, ::tcolor)
      ELSE
         //SetTextColor(hDC, RGB(255, 255, 255))
         SetTextColor(hDC, GETSYSCOLOR(COLOR_INACTIVECAPTION))
      ENDIF
      x1 := IIf(::xt != 0, ::xt, 4)
      y1 := IIf(::yt != 0, ::yt, 4)
      x2 := ::nWidth - 4
      y2 := ::nHeight - 4
      SetTransparentMode(hDC, .T.)
      DrawText(hDC, ::title, x1, y1, x2, y2, ;
         IIf(::xt != 0, DT_LEFT, DT_CENTER) + IIf(::yt != 0, DT_TOP, DT_VCENTER + DT_SINGLELINE))
      SetTransparentMode(hDC, .F.)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD MouseMove(wParam, lParam) CLASS HOwnButton

   LOCAL xPos
   LOCAL yPos
   LOCAL res := .F.

   HB_SYMBOL_UNUSED(wParam)

   IF ::state != OBTN_INIT
      xPos := hwg_LOWORD(lParam)
      yPos := hwg_HIWORD(lParam)
      IF xPos > ::nWidth .OR. yPos > ::nHeight
         ReleaseCapture()
         res := .T.
      ENDIF
      IF res .AND. !::lPress
         ::state := OBTN_NORMAL
         hwg_InvalidateRect(::handle, 0)
         hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
         //hwg_PostMessage(::handle, WM_PAINT, 0, 0)
      ENDIF
      IF ::state == OBTN_NORMAL .AND. !res
         ::state := OBTN_MOUSOVER
         hwg_InvalidateRect(::handle, 0)
         //hwg_PostMessage(::handle, WM_PAINT, 0, 0)
         hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
         SetCapture(::handle)
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD MDown() CLASS HOwnButton

   IF ::state != OBTN_PRESSED
      ::state := OBTN_PRESSED
      //hwg_InvalidateRect(::handle, 0)
      //::SetFocus()
      hwg_SendMessage(::handle, WM_SETFOCUS, 0, 0)
      hwg_InvalidateRect(::handle, 0)
      hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
   ELSEIF ::lCheck
      ::state := OBTN_NORMAL
      hwg_InvalidateRect(::handle, 0)
      hwg_PostMessage(::handle, WM_PAINT, 0, 0)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD MUp() CLASS HOwnButton

   //IF ::state == OBTN_PRESSED
   IF !::lPress
      //::state := OBTN_NORMAL // IIf(::lFlat, OBTN_MOUSOVER, OBTN_NORMAL)
      ::state := IIf(::lFlat, OBTN_MOUSOVER, OBTN_NORMAL)
   ENDIF
   IF ::lCheck
      IF ::lPress
         ::Release()
      ELSE
         ::Press()
      ENDIF
   ENDIF
   IF hb_IsBlock(::bClick)
      ReleaseCapture()
      Eval(::bClick, ::oParent, ::id)
      Release()
   ENDIF
   hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Refresh() CLASS HOwnButton

   hwg_InvalidateRect(::handle, 0)
   hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Release() CLASS HOwnButton

   ::lPress := .F.
   ::state := OBTN_NORMAL
   hwg_InvalidateRect(::handle, 0)
   hwg_RedrawWindow(::handle, RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW + RDW_INVALIDATE)
   //hwg_PostMessage(::handle, WM_PAINT, 0, 0)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD onGetFocus() CLASS HOwnButton

   LOCAL res := .T.
   LOCAL nSkip

   IF ::bGetFocus == NIL .OR. !CheckFocus(Self, .F.)
      RETURN .T.
   ENDIF
   nSkip := iif(GetKeyState(VK_UP) < 0 .OR. (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0), -1, 1)
   IF hb_IsBlock(::bGetFocus)
      ::oparent:lSuspendMsgsHandling := .T.
      res := Eval(::bGetFocus, ::title, Self)
      IF res != NIL .AND. Empty(res)
         WhenSetFocus(Self, nSkip)
      ENDIF
   ENDIF
   ::oparent:lSuspendMsgsHandling := .F.

RETURN res

//-------------------------------------------------------------------------------------------------------------------//

METHOD onLostFocus() CLASS HOwnButton

   IF ::bLostFocus != NIL .AND. !CheckFocus(Self, .T.)
      RETURN .T.
   ENDIF
   IF hb_IsBlock(::bLostFocus)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bLostFocus, ::title, Self)
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD onClick() CLASS HOwnButton

   IF hb_IsBlock(::bClick)
      //::oParent:lSuspendMsgsHandling := .T.
      Eval(::bClick, Self, ::id)
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD END() CLASS HOwnButton

   ::Super:END()
   ::oFont := NIL
   IF ::oBitmap != NIL
      ::oBitmap:Release()
      ::oBitmap := NIL
   ENDIF
   hwg_PostMessage(::handle, WM_CLOSE, 0, 0)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Enable() CLASS HOwnButton

   hwg_EnableWindow(::handle, .T.)
   ::lEnabled := .T.
   hwg_InvalidateRect(::handle, 0)
   hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
   //::Init() BECAUSE ERROR GPF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Disable() CLASS HOwnButton

   ::state := OBTN_INIT
   ::lEnabled := .F.
   hwg_InvalidateRect(::handle, 0)
   hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
   hwg_EnableWindow(::handle, .F.)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//
