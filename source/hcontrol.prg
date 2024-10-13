/*
 * $Id: hcontrol.prg 1902 2012-09-20 11:51:37Z lfbasso $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HControl class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define CONTROL_FIRST_ID 34000
#define TRANSPARENT 1

//-------------------------------------------------------------------------------------------------------------------//

CLASS HControl INHERIT HCustomWindow

   DATA id
   DATA tooltip
   DATA lInit INIT .F.
   DATA lnoValid INIT .F.
   DATA lnoWhen INIT .F.
   DATA nGetSkip INIT 0
   DATA Anchor INIT 0
   DATA BackStyle INIT OPAQUE
   DATA lNoThemes INIT .F.
   DATA DisablebColor
   DATA DisableBrush
   DATA xControlSource
   DATA xName HIDDEN
   ACCESS Name INLINE ::xName
   ASSIGN Name(cName) INLINE ::AddName(cName)

   METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
      bColor)
   METHOD Init()
   METHOD AddName(cName) HIDDEN
   //METHOD SetColor(tcolor, bColor, lRepaint)
   METHOD NewId()
   METHOD Show(nShow) INLINE ::Super:Show(nShow), IIF(::oParent:lGetSkipLostFocus, ;
      PostMessage(GetActiveWindow(), WM_NEXTDLGCTL, IIF(::oParent:FindControl(, GetFocus()) != NIL, ;
      0, ::handle), 1), .T.)
   METHOD Hide() INLINE (::oParent:lGetSkipLostFocus := .F., ::Super:Hide())
   //METHOD Disable() INLINE EnableWindow(::handle, .F.)
   METHOD Disable() INLINE (IIF(SELFFOCUS(::handle), SendMessage(GetActiveWindow(), WM_NEXTDLGCTL, 0, 0),), ;
      EnableWindow(::handle, .F.))
   METHOD Enable()
   METHOD IsEnabled() INLINE IsWindowEnabled(::handle)
   METHOD Enabled(lEnabled) SETGET
   METHOD SetFont(oFont)
   METHOD SetFocus(lValid)
   METHOD GetText() INLINE GetWindowText(::handle)
   METHOD VarGet()      INLINE ::GetText()   
   METHOD SetText(c) INLINE SetWindowText(::handle, c), ::title := c, ::Refresh()
   METHOD Refresh() VIRTUAL
   METHOD onAnchor(x, y, w, h)
   METHOD SetToolTip(ctooltip)
   METHOD ControlSource(cControlSource) SETGET
   METHOD DisableBackColor(DisableBColor) SETGET
   METHOD FontBold(lTrue) SETGET
   METHOD FontItalic(lTrue) SETGET
   METHOD FontUnderline(lTrue) SETGET
   METHOD END()

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
   bColor) CLASS HControl

   ::oParent := IIf(oWndParent == NIL, ::oDefaultParent, oWndParent)
   ::id := IIf(nId == NIL, ::NewId(), nId)
   ::style := Hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), WS_VISIBLE + WS_CHILD)
   ::nLeft := IIF(nLeft == NIL, 0, nLeft)
   ::nTop := IIF(nTop == NIL, 0, nTop)
   ::nWidth := IIF(nWidth == NIL, 0, nWidth)
   ::nHeight := IIF(nHeight == NIL, 0, nHeight)
   ::oFont := oFont
   ::bInit := bInit
   ::bSize := bSize
   ::bPaint := bPaint
   ::tooltip := cTooltip

   ::SetColor(tcolor, bColor)
   ::oParent:AddControl(Self)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD NewId() CLASS HControl

   LOCAL oParent := ::oParent
   LOCAL i := 0
   LOCAL nId

   DO WHILE oParent != NIL
      nId := CONTROL_FIRST_ID + 1000 * i + Len(::oParent:aControls)
      oParent := oParent:oParent
      i++
   ENDDO
   IF AScan(::oParent:aControls, {|o|o:id == nId}) != 0
      nId--
      DO WHILE nId >= CONTROL_FIRST_ID .AND. AScan(::oParent:aControls, {|o|o:id == nId}) != 0
         nId--
      ENDDO
   ENDIF

RETURN nId

//-------------------------------------------------------------------------------------------------------------------//

METHOD AddName(cName) CLASS HControl

   IF !Empty(cName) .AND. hb_IsChar(cName) .AND. !(":" $ cName) .AND. !("[" $ cName) .AND. !("->" $ cName)
      ::xName := cName
      __objAddData(::oParent, cName)
      ::oParent:&(cName) := Self
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD INIT() CLASS HControl

   LOCAL oForm := ::GetParentForm()

   IF !::lInit
      //IF ::tooltip != NIL
      //   AddToolTip(::oParent:handle, ::handle, ::tooltip)
      //ENDIF
      ::oparent:lSuspendMsgsHandling := .T.
      IF Len(::aControls) == 0 .AND. ::winclass != "SysTabControl32" .AND. !hb_IsNumeric(oForm)
         AddToolTip(oForm:handle, ::handle, ::tooltip)
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
      IF ::oFont != NIL .AND. !hb_IsNumeric(::oFont) .AND. ::oParent != NIL
         SetCtrlFont(::oParent:handle, ::id, ::oFont:handle)
      ELSEIF oForm != NIL .AND. !hb_IsNumeric(oForm) .AND. oForm:oFont != NIL
         SetCtrlFont(::oParent:handle, ::id, oForm:oFont:handle)
      ELSEIF ::oParent != NIL .AND. ::oParent:oFont != NIL
         SetCtrlFont(::handle, ::id, ::oParent:oFont:handle)
      ENDIF
      IF oForm != NIL .AND. oForm:Type != WND_DLG_RESOURCE .AND. (::nLeft + ::nTop + ::nWidth + ::nHeight != 0)
         // fix init position in FORM reduce  flickering
         SetWindowPos(::handle, NIL, ::nLeft, ::nTop, ::nWidth, ::nHeight, SWP_NOACTIVATE + SWP_NOSIZE + SWP_NOZORDER + SWP_NOOWNERZORDER + SWP_NOSENDCHANGING) //+ SWP_DRAWFRAME)
      ENDIF

      IF hb_IsBlock(::bInit)
        ::oparent:lSuspendMsgsHandling := .T.
        Eval(::bInit, Self)
        ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
      IF ::lnoThemes
         HWG_SETWINDOWTHEME(::handle, 0)
      ENDIF

      ::lInit := .T.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // moved to HCWINDOW
METHOD SetColor(tcolor, bColor, lRepaint) CLASS HControl

   IF tcolor != NIL
      ::tcolor := tcolor
      IF bColor == NIL .AND. ::bColor == NIL
         bColor := GetSysColor(COLOR_3DFACE)
      ENDIF
   ENDIF

   IF bColor != NIL
      ::bColor := bColor
      IF ::brush != NIL
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add(bColor)
   ENDIF

   IF lRepaint != NIL .AND. lRepaint
      RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
   ENDIF

RETURN NIL
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetFocus(lValid) CLASS HControl

   LOCAL lSuspend := ::oParent:lSuspendMsgsHandling

   IF !IsWindowEnabled(::handle)
      ::oParent:lSuspendMsgsHandling := .T.
      //GetSkip(::oParent, ::handle, , 1)
      SendMessage(GetActiveWindow(), WM_NEXTDLGCTL, 0, 0)
      ::oParent:lSuspendMsgsHandling := lSuspend
   ELSE
      ::oParent:lSuspendMsgsHandling := !Empty(lValid)
      IF ::GetParentForm():Type < WND_DLG_RESOURCE
         SetFocus(::handle)
      ELSE
         SendMessage(GetActiveWindow(), WM_NEXTDLGCTL, ::handle, 1)
      ENDIF
      ::oParent:lSuspendMsgsHandling := lSuspend
   ENDIF
   IF ::GetParentForm():Type < WND_DLG_RESOURCE
      ::GetParentForm():nFocus := ::handle
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Enable() CLASS HControl

   LOCAL lEnable := IsWindowEnabled(::handle)
   LOCAL nPos
   LOCAL nNext

   EnableWindow(::handle, .T.)
   IF ::oParent:lGetSkipLostFocus .AND. !lEnable .AND. Hwg_BitaND(HWG_GETWINDOWSTYLE(::handle), WS_TABSTOP) > 0
      nNext := Ascan(::oParent:aControls, {|o|PtrtouLong(o:handle) == PtrtouLong(GetFocus())})
      nPos := Ascan(::oParent:acontrols, {|o|PtrtouLong(o:handle) == PtrtouLong(::handle)})
      IF nPos < nNext
         SendMessage(GetActiveWindow(), WM_NEXTDLGCTL, ::handle, 1)
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD DisableBackColor(DisableBColor)

   IF DisableBColor != NIL
      ::DisableBColor := DisableBColor
      IF ::Disablebrush != NIL
         ::Disablebrush:Release()
      ENDIF
      ::Disablebrush := HBrush():Add(::DisableBColor)
      IF !::IsEnabled() .AND. IsWindowVisible(::handle)
         InvalidateRect(::handle, 0)
      ENDIF
   ENDIF

RETURN ::DisableBColor

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetFont(oFont) CLASS HControl

   IF oFont != NIL
      IF hb_IsObject(oFont)
         ::oFont := oFont:SetFontStyle()
         SetWindowFont(::handle, ::oFont:handle, .T.)
      ENDIF
   ELSEIF ::oParent:oFont != NIL
      SetWindowFont(::handle, ::oParent:oFont:handle, .T.)
   ENDIF

RETURN ::oFont

//-------------------------------------------------------------------------------------------------------------------//

METHOD FontBold(lTrue) CLASS HControl

   LOCAL oFont

   IF ::oFont == NIL
      IF ::GetParentForm() != NIL .AND. ::GetParentForm():oFont != NIL
         oFont := ::GetParentForm():oFont
      ELSEIF ::oParent:oFont != NIL
         oFont := ::oParent:oFont
      ENDIF
      IF oFont == NIL .AND. lTrue == NIL
          RETURN .T.
      ENDIF
      ::oFont := IIF(oFont != NIL, HFont():Add(oFont:name, oFont:Width, , , , ,), ;
         HFont():Add("", 0, , IIF(!Empty(lTrue), FW_BOLD, FW_REGULAR), , ,))
   ENDIF
   IF lTrue != NIL
      ::oFont := ::oFont:SetFontStyle(lTrue)
      SendMessage(::handle, WM_SETFONT, ::oFont:handle, MAKELPARAM(0, 1))
      RedrawWindow(::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT)
   ENDIF

RETURN ::oFont:weight == FW_BOLD

//-------------------------------------------------------------------------------------------------------------------//

METHOD FontItalic(lTrue) CLASS HControl

   LOCAL oFont

   IF ::oFont == NIL
      IF ::GetParentForm() != NIL .AND. ::GetParentForm():oFont != NIL
         oFont := ::GetParentForm():oFont
      ELSEIF ::oParent:oFont != NIL
         oFont := ::oParent:oFont
      ENDIF
      IF oFont == NIL .AND. lTrue == NIL
          RETURN .F.
      ENDIF
      ::oFont := IIF(oFont != NIL, HFont():Add(oFont:name, oFont:width, , , , IIF(lTrue, 1, 0)), ;
         HFont():Add("", 0, , , , IIF(lTrue, 1, 0)))
   ENDIF
   IF lTrue != NIL
      ::oFont := ::oFont:SetFontStyle(, , lTrue)
      SendMessage(::handle, WM_SETFONT, ::oFont:handle, MAKELPARAM(0, 1))
      RedrawWindow(::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT)
   ENDIF

RETURN ::oFont:Italic == 1

//-------------------------------------------------------------------------------------------------------------------//

METHOD FontUnderline(lTrue) CLASS HControl

   LOCAL oFont

   IF ::oFont == NIL
      IF ::GetParentForm() != NIL .AND. ::GetParentForm():oFont != NIL
         oFont := ::GetParentForm():oFont
      ELSEIF ::oParent:oFont != NIL
         oFont := ::oParent:oFont
      ENDIF
      IF oFont == NIL .AND. lTrue == NIL
         RETURN .F.
      ENDIF
      ::oFont := IIF(oFont != NIL, HFont():Add(oFont:name, oFont:width, , , , , IIF(lTrue, 1, 0)), ;
         HFont():Add("", 0, , , , , IIF(lTrue, 1, 0)))
   ENDIF
   IF lTrue != NIL
      ::oFont := ::oFont:SetFontStyle(, , , lTrue)
      SendMessage(::handle, WM_SETFONT, ::oFont:handle, MAKELPARAM(0, 1))
      RedrawWindow(::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT)
   ENDIF

RETURN ::oFont:Underline == 1

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetToolTip (cToolTip) CLASS HControl

   IF hb_IsChar(cToolTip) .AND. cToolTip != ::ToolTip
      SETTOOLTIPTITLE(::GetparentForm():handle, ::handle, ctooltip)
      ::Tooltip := cToolTip
   ENDIF

RETURN ::tooltip

//-------------------------------------------------------------------------------------------------------------------//

METHOD Enabled(lEnabled) CLASS HControl

  IF lEnabled != NIL
     IF lEnabled
        ::enable()
     ELSE
        ::disable()
     ENDIF
  ENDIF

RETURN ::isEnabled()

//-------------------------------------------------------------------------------------------------------------------//

METHOD ControlSource(cControlSource) CLASS HControl

   LOCAL temp

   IF cControlSource != NIL .AND. !Empty(cControlSource) .AND. __objHasData(Self, "BSETGETFIELD")
      ::xControlSource := cControlSource
      temp := SUBSTR(cControlSource, AT("->", cControlSource) + 2)
      ::bSetGetField := IIF("->" $ cControlSource, FieldWBlock(temp, SELECT(SUBSTR(cControlSource, 1, ;
         AT("->", cControlSource) - 1))),FieldBlock(cControlSource))
   ENDIF

RETURN ::xControlSource

//-------------------------------------------------------------------------------------------------------------------//

METHOD END() CLASS HControl

   ::Super:END()

   IF ::tooltip != NIL
      DelToolTip(::oParent:handle, ::handle)
      ::tooltip := NIL
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD onAnchor(x, y, w, h) CLASS HControl

   LOCAL nAnchor
   LOCAL nXincRelative
   LOCAL nYincRelative
   LOCAL nXincAbsolute
   LOCAL nYincAbsolute
   LOCAL x1
   LOCAL y1
   LOCAL w1
   LOCAL h1
   LOCAL x9
   LOCAL y9
   LOCAL w9
   LOCAL h9
   LOCAL nCxv := IIF(HWG_BITAND(::style, WS_VSCROLL) != 0, GetSystemMetrics(SM_CXVSCROLL) + 1, 3)
   LOCAL nCyh := IIF(HWG_BITAND(::style, WS_HSCROLL) != 0, GetSystemMetrics(SM_CYHSCROLL) + 1, 3)

   nAnchor := ::anchor
   x9 := ::nLeft
   y9 := ::nTop
   w9 := ::nWidth  //- IIF(::winclass = "EDIT" .AND. __ObjHasMsg(Self,"hwndUpDown", GetClientRect(::hwndUpDown)[3], 0)
   h9 := ::nHeight

   x1 := ::nLeft
   y1 := ::nTop
   w1 := ::nWidth  //- IIF(::winclass = "EDIT" .AND. __ObjHasMsg(Self,"hwndUpDown"), GetClientRect(::hwndUpDown)[3], 0)
   h1 := ::nHeight
   //- calculo relativo
   IF x > 0
      nXincRelative := w / x
   ENDIF
   IF y > 0
      nYincRelative := h / y
   ENDIF
   //- calculo ABSOLUTE
   nXincAbsolute := (w - x)
   nYincAbsolute := (h - y)

   IF nAnchor >= ANCHOR_VERTFIX
      //- vertical fixed center
      nAnchor := nAnchor - ANCHOR_VERTFIX
      y1 := y9 + Round((h - y) * ((y9 + h9 / 2) / y), 2)
   ENDIF
   IF nAnchor >= ANCHOR_HORFIX
      //- horizontal fixed center
      nAnchor := nAnchor - ANCHOR_HORFIX
      x1 := x9 + Round((w - x) * ((x9 + w9 / 2) / x), 2)
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTREL
      // relative - RIGHT RELATIVE
      nAnchor := nAnchor - ANCHOR_RIGHTREL
      x1 := w - Round((x - x9 - w9) * nXincRelative, 2) - w9
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMREL
      // relative - BOTTOM RELATIVE
      nAnchor := nAnchor - ANCHOR_BOTTOMREL
      y1 := h - Round((y - y9 - h9) * nYincRelative, 2) - h9
   ENDIF
   IF nAnchor >= ANCHOR_LEFTREL
      // relative - LEFT RELATIVE
      nAnchor := nAnchor - ANCHOR_LEFTREL
      IF x1 != x9
         w1 := x1 - (Round(x9 * nXincRelative, 2)) + w9
      ENDIF
      x1 := Round(x9 * nXincRelative, 2)
   ENDIF
   IF nAnchor >= ANCHOR_TOPREL
      // relative  - TOP RELATIVE
      nAnchor := nAnchor - ANCHOR_TOPREL
      IF y1 != y9
         h1 := y1 - (Round(y9 * nYincRelative, 2)) + h9
      ENDIF
      y1 := Round(y9 * nYincRelative, 2)
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTABS
      // Absolute - RIGHT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_RIGHTABS
      IF HWG_BITAND(::Anchor, ANCHOR_LEFTREL) != 0
         w1 := INT(nxIncAbsolute) - (x1 - x9) + w9
      ELSE
         IF x1 != x9
            w1 := x1 - (x9 +  INT(nXincAbsolute)) + w9
         ENDIF
         x1 := x9 +  INT(nXincAbsolute)
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMABS
      // Absolute - BOTTOM ABSOLUTE
      nAnchor := nAnchor - ANCHOR_BOTTOMABS
      IF HWG_BITAND(::Anchor, ANCHOR_TOPREL) != 0
         h1 := INT(nyIncAbsolute) - (y1 - y9) + h9
      ELSE
         IF y1 != y9
            h1 := y1 - (y9 +  Int(nYincAbsolute)) + h9
         ENDIF
         y1 := y9 +  Int(nYincAbsolute)
      ENDIF
   ENDIF
   IF nAnchor >= ANCHOR_LEFTABS
      // Absolute - LEFT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_LEFTABS
      IF x1 != x9
         w1 := x1 - x9 + w9
      ENDIF
      x1 := x9
   ENDIF
   IF nAnchor >= ANCHOR_TOPABS
      // Absolute - TOP ABSOLUTE
      //nAnchor := nAnchor - 1
      IF y1 != y9
         h1 := y1 - y9 + h9
      ENDIF
      y1 := y9
   ENDIF
   // REDRAW AND INVALIDATE SCREEN
   IF x1 != X9 .OR. y1 != y9 .OR. w1 != w9 .OR. h1 != h9
      IF isWindowVisible(::handle)
         IF (x1 != x9 .OR. y1 != y9) .AND. x9 < ::oParent:nWidth
            InvalidateRect(::oParent:handle, 1, MAX(x9 - 1, 0), MAX(y9 - 1, 0), x9 + w9 + nCxv, y9 + h9 + nCyh)
         ELSE
             IF w1 < w9
                InvalidateRect(::oParent:handle, 1, x1 + w1 - nCxv - 1, MAX(y1 - 2, 0), x1 + w9 + 2, y9 + h9 + nCxv + 1)
             ENDIF
             IF h1 < h9
                InvalidateRect(::oParent:handle, 1, MAX(x1 - 5, 0), y1 + h1 - nCyh - 1, x1 + w9 + 2, y1 + h9 + nCYh)
             ENDIF
         ENDIF
         //::Move(x1, y1, w1, h1, HWG_BITAND(::Style, WS_CLIPSIBLINGS + WS_CLIPCHILDREN) == 0)

         IF ((x1 != x9 .OR. y1 != y9) .AND. (hb_IsBlock(::bPaint) .OR. x9 + w9 > ::oParent:nWidth)) .OR. ;
            (::backstyle == TRANSPARENT .AND. (::Title != NIL .AND. !Empty(::Title))) .OR. __ObjHasMsg(Self,"oImage")
            IF __ObjHasMsg(Self, "oImage") .OR. ::backstyle == TRANSPARENT //.OR. w9 != w1
               InvalidateRect(::oParent:handle, 1, MAX(x1 - 1, 0), MAX(y1 - 1, 0), x1 + w1 + 1, y1 + h1 + 1)
            ELSE
               RedrawWindow(::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT)
            ENDIF
         ELSE
             IF LEN(::aControls) == 0 .AND. ::Title != NIL
               InvalidateRect(::handle, 0)
             ENDIF
             IF w1 > w9
                InvalidateRect(::oParent:handle, 1, MAX(x1 + w9 - nCxv - 1, 0), MAX(y1, 0), x1 + w1 + nCxv, y1 + h1 + 2)
             ENDIF
             IF h1 > h9
                InvalidateRect(::oParent:handle, 1, MAX(x1, 0), MAX(y1 + h9 - nCyh - 1, 1), x1 + w1 + 2, y1 + h1 + nCyh)
             ENDIF
         ENDIF
         // redefine new position e new size
         ::Move(x1, y1, w1, h1, HWG_BITAND(::Style, WS_CLIPSIBLINGS + WS_CLIPCHILDREN) == 0)
         IF ::winClass == "ToolbarWindow32" .OR. ::winClass == "msctls_statusbar32"
            ::Resize(nXincRelative, w1 != w9, h1 != h9)
         ENDIF
      ELSE
         ::Move(x1, y1, w1, h1, 0)
         IF ::winClass == "ToolbarWindow32" .OR. ::winClass == "msctls_statusbar32"
            ::Resize(nXincRelative, w1 != w9, h1 != h9)
         ENDIF
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

INIT PROCEDURE starttheme()

   INITTHEMELIB()

RETURN

//-------------------------------------------------------------------------------------------------------------------//

EXIT PROCEDURE endtheme()

   ENDTHEMELIB()

RETURN

//-------------------------------------------------------------------------------------------------------------------//
