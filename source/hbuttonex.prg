//
// $Id: hcontrol.prg 1902 2012-09-20 11:51:37Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HButtonEx class
//
// Copyright 2007 Luiz Rafael Culik Guimaraes <luiz at xharbour.com.br >
// www - http://sites.uol.com.br/culikr/
//

#translate :hBitmap       => :m_csbitmaps\[1\]
//#translate :dwWidth       => :m_csbitmaps\[2\] // not used
//#translate :dwHeight      => :m_csbitmaps\[3\] // not used
//#translate :hMask         => :m_csbitmaps\[4\] // not used
//#translate :crTransparent => :m_csbitmaps\[5\] // not used

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define TRANSPARENT 1
#define BTNST_COLOR_BK_IN     1            // Background color when mouse is INside
#define BTNST_COLOR_FG_IN     2            // Text color when mouse is INside
#define BTNST_COLOR_BK_OUT    3             // Background color when mouse is OUTside
#define BTNST_COLOR_FG_OUT    4             // Text color when mouse is OUTside
#define BTNST_COLOR_BK_FOCUS  5           // Background color when the button is focused
#define BTNST_COLOR_FG_FOCUS  6            // Text color when the button is focused
#define BTNST_MAX_COLORS      6
#define WM_SYSCOLORCHANGE               0x0015
#define BS_TYPEMASK SS_TYPEMASK
#define OFS_X   10 // distance from left/right side to beginning/end of text

// TODO: alterar para funcionar com ponteiros

//-------------------------------------------------------------------------------------------------------------------//

CLASS HButtonEX INHERIT HButton

   DATA hBitmap
   DATA hIcon
   DATA m_dcBk
   DATA m_bFirstTime INIT .T.
   DATA Themed INIT .F.
   //DATA lnoThemes  INIT .F. HIDDEN
   DATA m_crColors INIT Array(6)
   DATA m_crBrush INIT Array(6)
   DATA hTheme
   // DATA Caption
   DATA state
   DATA m_bIsDefault INIT .F.
   DATA m_nTypeStyle INIT 0
   DATA m_bSent
   DATA m_bLButtonDown
   DATA m_bIsToggle
   DATA m_rectButton           // button rect in parent window coordinates
   DATA m_dcParent INIT hdc():new()
   DATA m_bmpParent
   DATA m_pOldParentBitmap
   DATA m_csbitmaps INIT {,,,,}
   DATA m_bToggled INIT .F.
   DATA PictureMargin INIT 0
   DATA m_bDrawTransparent INIT .F.
   DATA iStyle
   DATA m_bmpBk
   DATA m_pbmpOldBk
   DATA bMouseOverButton INIT .F.

   METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, hBitmap, iStyle, hicon, Transp, bGFocus, nPictureMargin, lnoThemes, bOther)
   METHOD Paint(lpDis)
   METHOD SetBitmap(hBitMap)
   METHOD SetIcon(hIcon)
   METHOD Init()
   METHOD onevent(msg, wParam, lParam)
   METHOD CancelHover()
   METHOD END()
   METHOD Redefine(oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, tcolor, bColor, cCaption, hBitmap, ;
      iStyle, hIcon, bGFocus, nPictureMargin)
   METHOD PaintBk(hdc)
   METHOD SetColor(tcolor, bcolor) INLINE ::SetDefaultColor(tcolor, bcolor) //, ::SetDefaultColor(.T.)
   METHOD SetDefaultColor(tColor, bColor, lPaint)
   //METHOD SetDefaultColor(lRepaint)
   METHOD SetColorEx(nIndex, nColor, lPaint)
   //METHOD SetText(c) INLINE ::title := c, ::caption := c, ;
   METHOD SetText(c) INLINE ;
      ::title := c, ;
      hwg_RedrawWindow(::handle, RDW_NOERASE + RDW_INVALIDATE), ;
      IIf(::oParent != NIL .AND. hwg_IsWindowVisible(::handle), ;
          hwg_InvalidateRect(::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight),), ;
      hwg_SetWindowText(::handle, ::title)
   //METHOD SaveParentBackground()

END CLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, bSize, bPaint, bClick, ;
   cTooltip, tcolor, bColor, hBitmap, iStyle, hicon, Transp, bGFocus, nPictureMargin, lnoThemes, bOther) ;
   CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT Transp TO .T.
   DEFAULT nPictureMargin TO 1
   DEFAULT lnoThemes  TO .F.

   ::m_bLButtonDown := .F.
   ::m_bSent := .F.
   ::m_bLButtonDown := .F.
   ::m_bIsToggle := .F.

   cCaption := IIf(cCaption == NIL, "", cCaption)
   ::Caption := cCaption
   ::iStyle := iStyle
   ::hBitmap := IIf(Empty(hBitmap), NIL, hBitmap)
   ::hicon := IIf(Empty(hicon), NIL, hIcon)
   ::m_bDrawTransparent := Transp
   ::PictureMargin := nPictureMargin
   ::lnoThemes := lnoThemes
   ::bOther := bOther
   bPaint := {|o, p|o:paint(p)}

   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, bGFocus)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, tcolor, bColor, cCaption, hBitmap, ;
   iStyle, hIcon, bGFocus, nPictureMargin) CLASS HButtonEx

   DEFAULT iStyle TO ST_ALIGN_HORIZ
   DEFAULT nPictureMargin TO 1
   bPaint := {|o, p|o:paint(p)}
   ::m_bLButtonDown := .F.
   ::m_bIsToggle := .F.

   ::m_bLButtonDown := .F.
   ::m_bSent := .F.

   ::title := cCaption

   ::Caption := cCaption
   ::iStyle := iStyle
   ::hBitmap := hBitmap
   ::hIcon := hIcon
   ::m_crColors[BTNST_COLOR_BK_IN] := GetSysColor(COLOR_BTNFACE)
   ::m_crColors[BTNST_COLOR_FG_IN] := GetSysColor(COLOR_BTNTEXT)
   ::m_crColors[BTNST_COLOR_BK_OUT] := GetSysColor(COLOR_BTNFACE)
   ::m_crColors[BTNST_COLOR_FG_OUT] := GetSysColor(COLOR_BTNTEXT)
   ::m_crColors[BTNST_COLOR_BK_FOCUS] := GetSysColor(COLOR_BTNFACE)
   ::m_crColors[BTNST_COLOR_FG_FOCUS] := GetSysColor(COLOR_BTNTEXT)
   ::PictureMargin := nPictureMargin

   ::Super:Redefine(oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, tcolor, bColor, cCaption, ;
      hBitmap, iStyle, hIcon, bGFocus)
   ::title := cCaption

   ::Caption := cCaption

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetBitmap(hBitMap) CLASS HButtonEX

   DEFAULT hBitmap TO ::hBitmap

   IF hb_IsNumeric(hBitmap) // TODO: verificar
      ::hBitmap := hBitmap
      hwg_SendMessage(::handle, BM_SETIMAGE, IMAGE_BITMAP, ::hBitmap)
      hwg_RedrawWindow(::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT)
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetIcon(hIcon) CLASS HButtonEX

   DEFAULT hIcon TO ::hIcon

   IF hb_IsNumeric(::hIcon) // TODO: verificar
      ::hIcon := hIcon
      hwg_SendMessage(::handle, BM_SETIMAGE, IMAGE_ICON, ::hIcon)
      hwg_RedrawWindow(::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT)
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD END() CLASS HButtonEX

   ::Super:END()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD INIT() CLASS HButtonEx

   LOCAL nbs

   IF !::lInit
      ::nHolder := 1
      //hwg_SetWindowObject(::handle, Self)
      //HWG_INITBUTTONPROC(::handle)
      // call in HBUTTON CLASS

      //::SetDefaultColor(, , .F.)
      IF HB_IsNumeric(::handle) .AND. ::handle > 0 // TODO: verificar
         nbs := HWG_GETWINDOWSTYLE(::handle)

         ::m_nTypeStyle := GetTheStyle(nbs, BS_TYPEMASK)

         // Check if this is a checkbox

         // Set initial default state flag
         IF ::m_nTypeStyle == BS_DEFPUSHBUTTON

            // Set default state for a default button
            ::m_bIsDefault := .T.

            // Adjust style for default button
            ::m_nTypeStyle := BS_PUSHBUTTON
         ENDIF
         nbs := modstyle(nbs, BS_TYPEMASK, BS_OWNERDRAW)
         HWG_SETWINDOWSTYLE(::handle, nbs)

      ENDIF

      ::Super:init()
      ::SetBitmap()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

/*
  Caso tenha problemas com o novo código usando SWITCH,
  altere '#if 0' para '#if 1' para usar o código original.
  Se possível, informe o problema encontrado em 'Issues' no
  GitHub.
*/

#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HBUTTONEx

   LOCAL pt := {,}
   LOCAL rectButton
   LOCAL acoor
   LOCAL pos
   LOCAL nID
   LOCAL oParent
   LOCAL nEval

   IF msg == WM_THEMECHANGED
      IF ::Themed
         IF hb_IsPointer(::hTheme)
            HB_CLOSETHEMEDATA(::htheme)
            ::hTheme := NIL
            //::m_bFirstTime := .T.
         ENDIF
         ::Themed := .F.
      ENDIF
      ::m_bFirstTime := .T.
      hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
      RETURN 0
   ELSEIF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg == BM_SETSTYLE
      RETURN BUTTONEXONSETSTYLE(wParam, lParam, ::handle, @::m_bIsDefault)

   ELSEIF msg == WM_MOUSEMOVE
      IF wParam == MK_LBUTTON
         pt[1] := hwg_LOWORD(lParam)
         pt[2] := hwg_HIWORD(lParam)
         acoor := hwg_ClientToScreen(::handle, pt[1], pt[2])
         rectButton := hwg_GetWindowRect(::handle)
         IF !PtInRect(rectButton, acoor)
            hwg_SendMessage(::handle, BM_SETSTATE, ::m_bToggled, 0)
            ::bMouseOverButton := .F.
            RETURN 0
         ENDIF
      ENDIF
      IF(!::bMouseOverButton)
         ::bMouseOverButton := .T.
         hwg_InvalidateRect(::handle, .F.)
         TRACKMOUSEVENT(::handle)
      ENDIF
      RETURN 0
   ELSEIF msg == WM_MOUSELEAVE
      ::CancelHover()
      RETURN 0
   ENDIF

   IF hb_IsBlock(::bOther)
      IF (nEval := Eval(::bOther, Self, msg, wParam, lParam)) != -1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF

   IF msg == WM_KEYDOWN

#ifdef __XHARBOUR__
      IF hb_BitIsSet(PtrtoUlong(lParam), 30)  // the key was down before ?
#else
      IF hb_BitTest(lParam, 30)   // the key was down before ?
#endif
         RETURN 0
      ENDIF
      IF wParam == VK_SPACE .OR. wParam == VK_RETURN
         /*
         IF ::GetParentForm(Self):Type < WND_DLG_RESOURCE
            hwg_SendMessage(::handle, WM_LBUTTONDOWN, 0, hwg_MAKELPARAM(1, 1))
         ELSE
            hwg_SendMessage(::handle, WM_LBUTTONDOWN, 0, hwg_MAKELPARAM(1, 1))
         ENDIF
         */
         hwg_SendMessage(::handle, WM_LBUTTONDOWN, 0, hwg_MAKELPARAM(1, 1))
         RETURN 0
      ENDIF
      IF wParam == VK_LEFT .OR. wParam == VK_UP
         GetSkip(::oParent, ::handle, , -1)
         RETURN 0
      ELSEIF wParam == VK_RIGHT .OR. wParam == VK_DOWN
         GetSkip(::oParent, ::handle, , 1)
         RETURN 0
      ELSEIF wParam == VK_TAB
         GetSkip(::oparent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
      ENDIF
      ProcKeyList(Self, wParam)

   ELSEIF msg == WM_SYSKEYUP .OR. (msg == WM_KEYUP .AND. ;
                     AScan({VK_SPACE, VK_RETURN, VK_ESCAPE}, wParam) == 0)
     IF CheckBit(lParam, 23) .AND. (wParam > 95 .AND. wParam < 106)
        wParam -= 48
     ENDIF
     IF !Empty(::title) .AND. (pos := At("&", ::title)) > 0 .AND. wParam == Asc(Upper(SubStr(::title, ++pos, 1)))
        IF hb_IsBlock(::bClick) .OR. ::id < 3
           hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(::id, BN_CLICKED), ::handle)
        ENDIF
     ELSEIF (nID := AScan(::oparent:acontrols, {|o|IIf(hb_IsChar(o:title), (pos := At("&", o:title)) > 0 .AND. ;
              wParam == Asc(Upper(SubStr(o:title, ++pos, 1))),)})) > 0
        IF __ObjHasMsg(::oParent:aControls[nID], "BCLICK") .AND. ;
           hb_IsBlock(::oParent:aControls[nID]:bClick) .OR. ::oParent:aControls[nID]:id < 3
           hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(::oParent:aControls[nID]:id, BN_CLICKED), ::oParent:aControls[nID]:handle)
        ENDIF
     ENDIF
     IF msg != WM_SYSKEYUP
         RETURN 0
     ENDIF

   ELSEIF msg == WM_KEYUP
      IF wParam == VK_SPACE .OR. wParam == VK_RETURN
         ::bMouseOverButton := .T.
         hwg_SendMessage(::handle, WM_LBUTTONUP, 0, hwg_MAKELPARAM(1, 1))
         ::bMouseOverButton := .F.
         RETURN 0
      ENDIF

   ELSEIF msg == WM_LBUTTONUP
      ::m_bLButtonDown := .F.
      IF ::m_bSent
         hwg_SendMessage(::handle, BM_SETSTATE, 0, 0)
         ::m_bSent := .F.
      ENDIF
      IF ::m_bIsToggle
         pt[1] := hwg_LOWORD(lParam)
         pt[2] := hwg_HIWORD(lParam)
         acoor := hwg_ClientToScreen(::handle, pt[1], pt[2])

         rectButton := hwg_GetWindowRect(::handle)

         IF !PtInRect(rectButton, acoor)
            ::m_bToggled := !::m_bToggled
            hwg_InvalidateRect(::handle, 0)
            hwg_SendMessage(::handle, BM_SETSTATE, 0, 0)
            ::m_bLButtonDown := .T.
         ENDIF
      ENDIF
      IF !::bMouseOverButton
         hwg_SetFocus(0)
         ::SETFOCUS()
         RETURN 0
      ENDIF
      RETURN -1

   ELSEIF msg == WM_LBUTTONDOWN
      ::m_bLButtonDown := .T.
      IF ::m_bIsToggle
         ::m_bToggled := !::m_bToggled
         hwg_InvalidateRect(::handle, 0)
      ENDIF
      RETURN -1

   ELSEIF msg == WM_LBUTTONDBLCLK

      IF ::m_bIsToggle

         // for toggle buttons, treat doubleclick as singleclick
         hwg_SendMessage(::handle, BM_SETSTATE, ::m_bToggled, 0)

      ELSE

         hwg_SendMessage(::handle, BM_SETSTATE, 1, 0)
         ::m_bSent := .T.

      ENDIF
      RETURN 0

   ELSEIF msg == WM_GETDLGCODE
         IF wParam == VK_ESCAPE .AND. (GETDLGMESSAGE(lParam) == WM_KEYDOWN .OR. GETDLGMESSAGE(lParam) == WM_KEYUP)
           oParent := ::GetParentForm()
           IF !ProcKeyList(Self, wParam) .AND. (oParent:Type < WND_DLG_RESOURCE .OR. !oParent:lModal)
              hwg_SendMessage(oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(IDCANCEL, 0), ::handle)
           ELSEIF oParent:FindControl(IDCANCEL) != NIL .AND. !oParent:FindControl(IDCANCEL):IsEnabled() .AND. oParent:lExitOnEsc
              hwg_SendMessage(oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(IDCANCEL, 0), ::handle)
              RETURN 0
           ENDIF
        ENDIF
      RETURN IIf(wParam == VK_ESCAPE, -1, ButtonGetDlgCode(lParam))

   ELSEIF msg == WM_SYSCOLORCHANGE
      ::SetDefaultColors()
   ELSEIF msg == WM_CHAR
      IF wParam == VK_RETURN .OR. wParam == VK_SPACE
         IF ::m_bIsToggle
            ::m_bToggled := !::m_bToggled
            hwg_InvalidateRect(::handle, 0)
         ELSE
            hwg_SendMessage(::handle, BM_SETSTATE, 1, 0)
            //::m_bSent := .T.
         ENDIF
         // remove because repet click  2 times
         //hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(::id, BN_CLICKED), ::handle)
      ELSEIF wParam == VK_ESCAPE
         hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(IDCANCEL, BN_CLICKED), ::handle)
      ENDIF
      RETURN 0
   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HBUTTONEx

   LOCAL pt := {,}
   LOCAL rectButton
   LOCAL acoor
   LOCAL pos
   LOCAL nID
   LOCAL oParent
   LOCAL nEval

   SWITCH msg

   CASE WM_THEMECHANGED
      IF ::Themed
         IF hb_IsPointer(::hTheme)
            HB_CLOSETHEMEDATA(::htheme)
            ::hTheme := NIL
            //::m_bFirstTime := .T.
         ENDIF
         ::Themed := .F.
      ENDIF
      ::m_bFirstTime := .T.
      hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
      RETURN 0

   CASE WM_ERASEBKGND
      RETURN 0

   CASE BM_SETSTYLE
      RETURN BUTTONEXONSETSTYLE(wParam, lParam, ::handle, @::m_bIsDefault)

   CASE WM_MOUSEMOVE
      IF wParam == MK_LBUTTON
         pt[1] := hwg_LOWORD(lParam)
         pt[2] := hwg_HIWORD(lParam)
         acoor := hwg_ClientToScreen(::handle, pt[1], pt[2])
         rectButton := hwg_GetWindowRect(::handle)
         IF !PtInRect(rectButton, acoor)
            hwg_SendMessage(::handle, BM_SETSTATE, ::m_bToggled, 0)
            ::bMouseOverButton := .F.
            RETURN 0
         ENDIF
      ENDIF
      IF !::bMouseOverButton
         ::bMouseOverButton := .T.
         hwg_InvalidateRect(::handle, .F.)
         TRACKMOUSEVENT(::handle)
      ENDIF
      RETURN 0

   CASE WM_MOUSELEAVE
      ::CancelHover()
      RETURN 0

   CASE WM_KEYDOWN
      #ifdef __XHARBOUR__
      IF hb_BitIsSet(PtrtoUlong(lParam), 30)  // the key was down before ?
      #else
      IF hb_BitTest(lParam, 30)   // the key was down before ?
      #endif
         RETURN 0
      ENDIF
      SWITCH wParam
      CASE VK_SPACE
      CASE VK_RETURN
         /*
         IF ::GetParentForm(Self):Type < WND_DLG_RESOURCE
            hwg_SendMessage(::handle, WM_LBUTTONDOWN, 0, hwg_MAKELPARAM(1, 1))
         ELSE
            hwg_SendMessage(::handle, WM_LBUTTONDOWN, 0, hwg_MAKELPARAM(1, 1))
         ENDIF
         */
         hwg_SendMessage(::handle, WM_LBUTTONDOWN, 0, hwg_MAKELPARAM(1, 1))
         RETURN 0
      CASE VK_LEFT
      CASE VK_UP
         GetSkip(::oParent, ::handle, , -1)
         RETURN 0
      CASE VK_RIGHT
      CASE VK_DOWN
         GetSkip(::oParent, ::handle, , 1)
         RETURN 0
      CASE VK_TAB
         GetSkip(::oparent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
      ENDSWITCH
      ProcKeyList(Self, wParam)
      EXIT

   CASE WM_SYSKEYUP
      IF CheckBit(lParam, 23) .AND. (wParam > 95 .AND. wParam < 106)
         wParam -= 48
      ENDIF
      IF !Empty(::title) .AND. (pos := At("&", ::title)) > 0 .AND. wParam == Asc(Upper(SubStr(::title, ++pos, 1)))
         IF hb_IsBlock(::bClick) .OR. ::id < 3
            hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(::id, BN_CLICKED), ::handle)
         ENDIF
      ELSEIF (nID := AScan(::oparent:acontrols, {|o|IIf(hb_IsChar(o:title), (pos := At("&", o:title)) > 0 .AND. ;
              wParam == Asc(Upper(SubStr(o:title, ++pos, 1))),)})) > 0
         IF __ObjHasMsg(::oParent:aControls[nID], "BCLICK") .AND. ;
            hb_IsBlock(::oParent:aControls[nID]:bClick) .OR. ::oParent:aControls[nID]:id < 3
            hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(::oParent:aControls[nID]:id, BN_CLICKED), ::oParent:aControls[nID]:handle)
         ENDIF
     ENDIF
     EXIT

   CASE WM_KEYUP
      IF AScan({VK_SPACE, VK_RETURN, VK_ESCAPE}, wParam) == 0
         IF CheckBit(lParam, 23) .AND. (wParam > 95 .AND. wParam < 106)
            wParam -= 48
         ENDIF
         IF !Empty(::title) .AND. (pos := At("&", ::title)) > 0 .AND. wParam == Asc(Upper(SubStr(::title, ++pos, 1)))
            IF hb_IsBlock(::bClick) .OR. ::id < 3
               hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(::id, BN_CLICKED), ::handle)
            ENDIF
         ELSEIF (nID := AScan(::oparent:acontrols, {|o|IIf(hb_IsChar(o:title), (pos := At("&", o:title)) > 0 .AND. ;
                 wParam == Asc(Upper(SubStr(o:title, ++pos, 1))),)})) > 0
            IF __ObjHasMsg(::oParent:aControls[nID], "BCLICK") .AND. ;
               hb_IsBlock(::oParent:aControls[nID]:bClick) .OR. ::oParent:aControls[nID]:id < 3
               hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(::oParent:aControls[nID]:id, BN_CLICKED), ::oParent:aControls[nID]:handle)
            ENDIF
         ENDIF
         RETURN 0
      ENDIF
      IF wParam == VK_SPACE .OR. wParam == VK_RETURN
         ::bMouseOverButton := .T.
         hwg_SendMessage(::handle, WM_LBUTTONUP, 0, hwg_MAKELPARAM(1, 1))
         ::bMouseOverButton := .F.
         RETURN 0
      ENDIF
      EXIT

   CASE WM_LBUTTONUP
      ::m_bLButtonDown := .F.
      IF ::m_bSent
         hwg_SendMessage(::handle, BM_SETSTATE, 0, 0)
         ::m_bSent := .F.
      ENDIF
      IF ::m_bIsToggle
         pt[1] := hwg_LOWORD(lParam)
         pt[2] := hwg_HIWORD(lParam)
         acoor := hwg_ClientToScreen(::handle, pt[1], pt[2])
         rectButton := hwg_GetWindowRect(::handle)
         IF !PtInRect(rectButton, acoor)
            ::m_bToggled := !::m_bToggled
            hwg_InvalidateRect(::handle, 0)
            hwg_SendMessage(::handle, BM_SETSTATE, 0, 0)
            ::m_bLButtonDown := .T.
         ENDIF
      ENDIF
      IF !::bMouseOverButton
         hwg_SetFocus(0)
         ::SETFOCUS()
         RETURN 0
      ENDIF
      RETURN -1

   CASE WM_LBUTTONDOWN
      ::m_bLButtonDown := .T.
      IF ::m_bIsToggle
         ::m_bToggled := !::m_bToggled
         hwg_InvalidateRect(::handle, 0)
      ENDIF
      RETURN -1

   CASE WM_LBUTTONDBLCLK
      IF ::m_bIsToggle
         // for toggle buttons, treat doubleclick as singleclick
         hwg_SendMessage(::handle, BM_SETSTATE, ::m_bToggled, 0)
      ELSE
         hwg_SendMessage(::handle, BM_SETSTATE, 1, 0)
         ::m_bSent := .T.
      ENDIF
      RETURN 0

   CASE WM_GETDLGCODE
      IF wParam == VK_ESCAPE .AND. (GETDLGMESSAGE(lParam) == WM_KEYDOWN .OR. GETDLGMESSAGE(lParam) == WM_KEYUP)
         oParent := ::GetParentForm()
         IF !ProcKeyList(Self, wParam) .AND. (oParent:Type < WND_DLG_RESOURCE .OR. !oParent:lModal)
            hwg_SendMessage(oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(IDCANCEL, 0), ::handle)
         ELSEIF oParent:FindControl(IDCANCEL) != NIL .AND. !oParent:FindControl(IDCANCEL):IsEnabled() .AND. oParent:lExitOnEsc
            hwg_SendMessage(oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(IDCANCEL, 0), ::handle)
            RETURN 0
         ENDIF
      ENDIF
      RETURN IIf(wParam == VK_ESCAPE, -1, ButtonGetDlgCode(lParam))

   CASE WM_SYSCOLORCHANGE
      ::SetDefaultColors()
      EXIT

   CASE WM_CHAR
      SWITCH wParam
      CASE VK_RETURN
      CASE VK_SPACE
         IF ::m_bIsToggle
            ::m_bToggled := !::m_bToggled
            hwg_InvalidateRect(::handle, 0)
         ELSE
            hwg_SendMessage(::handle, BM_SETSTATE, 1, 0)
            //::m_bSent := .T.
         ENDIF
         // remove because repet click  2 times
         //hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(::id, BN_CLICKED), ::handle)
         EXIT
      CASE VK_ESCAPE
         hwg_SendMessage(::oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(IDCANCEL, BN_CLICKED), ::handle)
      ENDSWITCH
      RETURN 0

   ENDSWITCH

   IF hb_IsBlock(::bOther)
      IF (nEval := Eval(::bOther, Self, msg, wParam, lParam)) != -1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD CancelHover() CLASS HBUTTONEx

   IF ::bMouseOverButton .AND. ::id != IDOK //NANDO
      ::bMouseOverButton := .F.
      IF !::lflat
         hwg_InvalidateRect(::handle, .F.)
      ELSE
         hwg_InvalidateRect(::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight)
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetDefaultColor(tColor, bColor, lPaint) CLASS HBUTTONEx

   DEFAULT lPaint TO .F.

   IF !Empty(tColor)
      ::tColor := tColor
   ENDIF
   IF !Empty(bColor)
      ::bColor := bColor
   ENDIF
   ::m_crColors[BTNST_COLOR_BK_IN] := IIf(::bColor == NIL, GetSysColor(COLOR_BTNFACE), ::bColor)
   ::m_crColors[BTNST_COLOR_FG_IN] := IIf(::tColor == NIL, GetSysColor(COLOR_BTNTEXT), ::tColor)
   ::m_crColors[BTNST_COLOR_BK_OUT] := IIf(::bColor == NIL, GetSysColor(COLOR_BTNFACE), ::bColor)
   ::m_crColors[BTNST_COLOR_FG_OUT] := IIf(::tColor == NIL, GetSysColor(COLOR_BTNTEXT), ::tColor)
   ::m_crColors[BTNST_COLOR_BK_FOCUS] := IIf(::bColor == NIL, GetSysColor(COLOR_BTNFACE), ::bColor)
   ::m_crColors[BTNST_COLOR_FG_FOCUS] := IIf(::tColor == NIL, GetSysColor(COLOR_BTNTEXT), ::tColor)
   //
   ::m_crBrush[BTNST_COLOR_BK_IN] := HBrush():Add(::m_crColors[BTNST_COLOR_BK_IN])
   ::m_crBrush[BTNST_COLOR_BK_OUT] := HBrush():Add(::m_crColors[BTNST_COLOR_BK_OUT])
   ::m_crBrush[BTNST_COLOR_BK_FOCUS] := HBrush():Add(::m_crColors[BTNST_COLOR_BK_FOCUS])
   /*
   ::m_crColors[BTNST_COLOR_BK_IN] := GetSysColor(COLOR_BTNFACE)
   ::m_crColors[BTNST_COLOR_FG_IN] := GetSysColor(COLOR_BTNTEXT)
   ::m_crColors[BTNST_COLOR_BK_OUT] := GetSysColor(COLOR_BTNFACE)
   ::m_crColors[BTNST_COLOR_FG_OUT] := GetSysColor(COLOR_BTNTEXT)
   ::m_crColors[BTNST_COLOR_BK_FOCUS] := GetSysColor(COLOR_BTNFACE)
   ::m_crColors[BTNST_COLOR_FG_FOCUS] := GetSysColor(COLOR_BTNTEXT)
   */
   IF lPaint
      hwg_InvalidateRect(::handle, .F.)
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetColorEx(nIndex, nColor, lPaint) CLASS HBUTTONEx

   DEFAULT lPaint TO .F.

   IF nIndex > BTNST_MAX_COLORS
      RETURN -1
   ENDIF

   ::m_crColors[nIndex] := nColor

   IF lPaint
      hwg_InvalidateRect(::handle, .F.)
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

METHOD Paint(lpDis) CLASS HBUTTONEx

   LOCAL drawInfo := hwg_GetDrawItemInfo(lpDis)
   LOCAL dc := drawInfo[3]
   LOCAL bIsPressed := HWG_BITAND(drawInfo[9], ODS_SELECTED) != 0
   LOCAL bIsFocused := HWG_BITAND(drawInfo[9], ODS_FOCUS) != 0
   LOCAL bIsDisabled := HWG_BITAND(drawInfo[9], ODS_DISABLED) != 0
   LOCAL bDrawFocusRect := !HWG_BITAND(drawInfo[9], ODS_NOFOCUSRECT) != 0
   LOCAL focusRect
   LOCAL captionRect
   LOCAL centerRect
   LOCAL bHasTitle
   LOCAL itemRect := copyrect({drawInfo[4], drawInfo[5], drawInfo[6], drawInfo[7]})
   LOCAL state
   LOCAL crColor
   LOCAL brBackground
   LOCAL br
   LOCAL brBtnShadow
   LOCAL uState
   LOCAL captionRectHeight
   LOCAL centerRectHeight
   //LOCAL captionRectWidth
   //LOCAL centerRectWidth
   LOCAL uAlign
   LOCAL uStyleTmp
   LOCAL aTxtSize := IIf(!Empty(::caption), TxtRect(::caption, Self), {0, 0})
   LOCAL aBmpSize := IIf(!Empty(::hbitmap), GetBitmapSize(::hbitmap), {0, 0})
   LOCAL itemRectOld
   LOCAL saveCaptionRect
   LOCAL bmpRect
   LOCAL itemRect1
   LOCAL captionRect1
   LOCAL fillRect
   LOCAL lMultiLine
   LOCAL nHeight := 0

   IF ::m_bFirstTime
      ::m_bFirstTime := .F.
      IF ISTHEMEDLOAD()
         IF hb_IsPointer(::hTheme)
            HB_CLOSETHEMEDATA(::htheme)
         ENDIF
         ::hTheme := NIL
         IF ::WindowsManifest
            ::hTheme := hb_OpenThemeData(::handle, "BUTTON")
         ENDIF
      ENDIF
   ENDIF
   IF !Empty(::hTheme) .AND. !::lnoThemes
      ::Themed := .T.
   ENDIF

   SetBkMode(dc, TRANSPARENT)
   IF ::m_bDrawTransparent
//        ::PaintBk(DC)
   ENDIF

   // Prepare draw... paint button background

   IF ::Themed

      IF bIsDisabled
         state := PBS_DISABLED
      ELSE
         state := IIf(bIsPressed, PBS_PRESSED, PBS_NORMAL)
      ENDIF
      IF state == PBS_NORMAL
         IF bIsFocused
            state := PBS_DEFAULTED
         ENDIF
         IF ::bMouseOverButton .OR. ::id == IDOK
            state := PBS_HOT
         ENDIF
      ENDIF
      IF !::lFlat
         hb_DrawThemeBackground(::hTheme, dc, BP_PUSHBUTTON, state, itemRect, NIL)
      ELSEIF bIsDisabled
         FillRect(dc, itemRect[1] + 1, itemRect[2] + 1, itemRect[3] - 1, itemRect[4] - 1, GetSysColorBrush(GetSysColor(COLOR_BTNFACE)))
      ELSEIF ::bMouseOverButton .OR. bIsFocused
         hb_DrawThemeBackground(::hTheme, dc, BP_PUSHBUTTON, state, itemRect, NIL) // + PBS_DEFAULTED
      ENDIF
   ELSE

      IF bIsFocused .OR. ::id == IDOK
         br := HBRUSH():Add(RGB(1, 1, 1))
         FrameRect(dc, itemRect, br:handle)
         InflateRect(@itemRect, -1, -1)
      ENDIF
      crColor := GetSysColor(COLOR_BTNFACE)
      brBackground := HBRUSH():Add(crColor)
      FillRect(dc, itemRect, brBackground:handle)

      IF bIsPressed
         brBtnShadow := HBRUSH():Add(GetSysColor(COLOR_BTNSHADOW))
         FrameRect(dc, itemRect, brBtnShadow:handle)
      ELSE
         IF !::lFlat .OR. ::bMouseOverButton
            uState := HWG_BITOR(HWG_BITOR(DFCS_BUTTONPUSH, IIf(::bMouseOverButton, DFCS_HOT, 0)), ;
               IIf(bIsPressed, DFCS_PUSHED, 0))
            DrawFrameControl(dc, itemRect, DFC_BUTTON, uState)
         ELSEIF bIsFocused
            uState := HWG_BITOR(HWG_BITOR(DFCS_BUTTONPUSH + DFCS_MONO, ; // DFCS_FLAT , ;
               IIf(::bMouseOverButton, DFCS_HOT, 0)), IIf(bIsPressed, DFCS_PUSHED, 0))
            DrawFrameControl(dc, itemRect, DFC_BUTTON, uState)
         ENDIF
      ENDIF
   ENDIF

//      if ::iStyle ==  ST_ALIGN_HORIZ
//         uAlign := DT_RIGHT
//      else
//         uAlign := DT_LEFT
//      endif
//
//      IF !hb_IsNumeric(::hbitmap)
//         uAlign := DT_CENTER
//      ENDIF

   uAlign := 0 //DT_LEFT
   IF hb_IsNumeric(::hbitmap) .OR. hb_IsNumeric(::hicon)
      uAlign := DT_CENTER + DT_VCENTER
   ENDIF
   /*
   IF hb_IsNumeric(::hicon)
      uAlign := DT_CENTER
   ENDIF
   */
   IF uAlign != DT_CENTER + DT_VCENTER
      uAlign := IIf(HWG_BITAND(::Style, BS_TOP) != 0, DT_TOP, DT_VCENTER)
      uAlign += IIf(HWG_BITAND(::Style, BS_BOTTOM) != 0, DT_BOTTOM - DT_VCENTER, 0)
      uAlign += IIf(HWG_BITAND(::Style, BS_LEFT) != 0, DT_LEFT, DT_CENTER)
      uAlign += IIf(HWG_BITAND(::Style, BS_RIGHT) != 0, DT_RIGHT - DT_CENTER, 0)
   ELSE   
      uAlign := IIf(uAlign == 0, DT_CENTER + DT_VCENTER, uAlign)
   ENDIF   


//             DT_CENTER | DT_VCENTER | DT_SINGLELINE
//   uAlign += DT_WORDBREAK + DT_CENTER + DT_CALCRECT +  DT_VCENTER + DT_SINGLELINE  // DT_SINGLELINE + DT_VCENTER + DT_WORDBREAK
 //  uAlign += DT_VCENTER
   uStyleTmp := HWG_GETWINDOWSTYLE(::handle)
   itemRectOld := aclone(itemRect)
   IF hb_BitAnd(uStyleTmp, BS_MULTILINE) != 0 .AND. !Empty(::caption) .AND. ;
      INT(aTxtSize[2]) !=  INT(DrawText(dc, ::caption, itemRect[1], itemRect[2],;
          itemRect[3] - IIf(::iStyle == ST_ALIGN_VERT, 0, aBmpSize[1] + 8),;
          itemRect[4], DT_CALCRECT + uAlign + DT_WORDBREAK, itemRectOld))
      //-INT(aTxtSize[2]) !=  INT(DrawText(dc, ::caption, itemRect, DT_CALCRECT + uAlign + DT_WORDBREAK))
      uAlign += DT_WORDBREAK
      lMultiline := .T.
      drawInfo[4] += 2
      drawInfo[6] -= 2
      itemRect[1] += 2
      itemRect[3] -= 2
      aTxtSize[1] := itemRectold[3] - itemRectOld[1] + 1
      aTxtSize[2] := itemRectold[4] - itemRectold[2] + 1
   ELSE
      uAlign += DT_SINGLELINE
      lMultiline := .F.
   ENDIF

   captionRect := {drawInfo[4], drawInfo[5], drawInfo[6], drawInfo[7]}
   //
   IF (hb_IsNumeric(::hbitmap) .OR. hb_IsNumeric(::hicon)) .AND. lMultiline
      IF ::iStyle == ST_ALIGN_HORIZ
         captionRect := {drawInfo[4] + ::PictureMargin, drawInfo[5], drawInfo[6], drawInfo[7]}
      ELSEIF ::iStyle == ST_ALIGN_HORIZ_RIGHT
         captionRect := {drawInfo[4], drawInfo[5], drawInfo[6] - ::PictureMargin, drawInfo[7]}
      ELSEIF ::iStyle == ST_ALIGN_VERT
      ENDIF
   ENDIF

   itemRectOld := AClone(itemRect)

   IF !Empty(::caption) .AND. !Empty(::hbitmap)  //.AND.!Empty(::hicon)
      nHeight := aTxtSize[2] //nHeight := IIf(lMultiLine, DrawText(dc, ::caption, itemRect, DT_CALCRECT + uAlign + DT_WORDBREAK), aTxtSize[2])
      IF ::iStyle == ST_ALIGN_HORIZ
          itemRect[1] := IIf(::PictureMargin == 0, (((::nWidth - aTxtSize[1] - aBmpSize[1] / 2) / 2)) / 2, ::PictureMargin)
         itemRect[1] := IIf(itemRect[1] < 0, 0, itemRect[1])
      ELSEIF ::iStyle == ST_ALIGN_HORIZ_RIGHT
      ELSEIF ::iStyle == ST_ALIGN_VERT .OR. ::iStyle == ST_ALIGN_OVERLAP
         nHeight := IIf(lMultiLine, DrawText(dc, ::caption, itemRect, DT_CALCRECT + DT_WORDBREAK), aTxtSize[2])
         ::iStyle := ST_ALIGN_OVERLAP
         itemRect[1] := (::nWidth - aBmpSize[1]) /  2
         itemRect[2] := IIf(::PictureMargin == 0, (((::nHeight - (nHeight + aBmpSize[2] + 1)) / 2)), ::PictureMargin)
      ENDIF
   ELSEIF !Empty(::caption)
      nHeight := aTxtSize[2] //nHeight := IIf(lMultiLine, DrawText(dc, ::caption, itemRect, DT_CALCRECT + DT_WORDBREAK), aTxtSize[2])
   ENDIF

   bHasTitle := hb_IsChar(::caption) .AND. !Empty(::Caption)

   //   DrawTheIcon(::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle)
   IF hb_IsNumeric(::hbitmap) .AND. ::m_bDrawTransparent .AND. (!bIsDisabled .OR. ::istyle == ST_ALIGN_HORIZ_RIGHT)
      bmpRect := PrepareImageRect(::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, ::hIcon, ::hbitmap, ::iStyle)
      IF ::istyle == ST_ALIGN_HORIZ_RIGHT
         bmpRect[1] -= ::PictureMargin
         captionRect[3] -= ::PictureMargin
      ENDIF
      IF !bIsDisabled
          DrawTransparentBitmap(dc, ::hbitmap, bmpRect[1], bmpRect[2])
      ELSE
          DrawGrayBitmap(dc, ::hbitmap, bmpRect[1], bmpRect[2])
      ENDIF
   ELSEIF hb_IsNumeric(::hbitmap) .OR. hb_IsNumeric(::hicon)
       IF ::istyle == ST_ALIGN_HORIZ_RIGHT             
         captionRect[3] -= ::PictureMargin 
       ENDIF
       DrawTheIcon(::handle, dc, bHasTitle, @itemRect, @captionRect, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle)
   ELSE
       InflateRect(@captionRect, - 3, - 3)       
   ENDIF
   itemRect1 := aclone(itemRect)
   captionRect1 := aclone(captionRect)
   itemRect := aclone(itemRectOld)

   IF bHasTitle

      // If button is pressed then "press" title also
      IF bIsPressed .AND. !::Themed
         OffsetRect(@captionRect, 1, 1)
      ENDIF

      // Center text
      centerRect := copyrect(captionRect)

      IF hb_IsNumeric(::hicon) .OR. hb_IsNumeric(::hbitmap)
          IF !lmultiline .AND. ::iStyle != ST_ALIGN_OVERLAP
             // DrawText(dc, ::caption, captionRect[1], captionRect[2], captionRect[3], captionRect[4], uAlign + DT_CALCRECT, @captionRect)
          ELSEIF !Empty(::caption)
             // figura no topo texto em baixo
             IF ::iStyle == ST_ALIGN_OVERLAP //ST_ALIGN_VERT
                captionRect[2] := itemRect1[2] + aBmpSize[2] //+ 1
                uAlign -= ST_ALIGN_OVERLAP + 1
             ELSE
                captionRect[2] := (::nHeight - nHeight) / 2 + 2
             ENDIF
             savecaptionRect := aclone(captionRect)
             DrawText(dc, ::caption, captionRect[1], captionRect[2], captionRect[3], captionRect[4], uAlign, @captionRect)
          ENDIF
      ELSE
         //- uAlign += DT_CENTER
      ENDIF

      //captionRectWidth := captionRect[3] - captionRect[1]
      captionRectHeight := captionRect[4] - captionRect[2]
      //centerRectWidth := centerRect[3] - centerRect[1]
      centerRectHeight := centerRect[4] - centerRect[2]
//ok      OffsetRect(@captionRect, (centerRectWidth - captionRectWidth) / 2, (centerRectHeight - captionRectHeight) / 2)
//      OffsetRect(@captionRect, (centerRectWidth - captionRectWidth) / 2, (centerRectHeight - captionRectHeight) / 2)
//      OffsetRect(@captionRect, (centerRectWidth - captionRectWidth) / 2, (centerRectHeight - captionRectHeight) / 2)
      OffsetRect(@captionRect, 0, (centerRectHeight - captionRectHeight) / 2)


/*      SetBkMode(dc, TRANSPARENT)
      IF bIsDisabled

         OffsetRect(@captionRect, 1, 1)
         SetTextColor(DC, GetSysColor(COLOR_3DHILIGHT))
         DrawText(DC, ::caption, captionRect[1], captionRect[2], captionRect[3], captionRect[4], DT_WORDBREAK + DT_CENTER, @captionRect)
         OffsetRect(@captionRect, -1, -1)
         SetTextColor(DC, GetSysColor(COLOR_3DSHADOW))
         DrawText(DC, ::caption, captionRect[1], captionRect[2], captionRect[3], captionRect[4], DT_WORDBREAK + DT_VCENTER + DT_CENTER, @captionRect)

      ELSE

         IF ::bMouseOverButton .OR. bIsPressed

            SetTextColor(DC, ::m_crColors[BTNST_COLOR_FG_IN])
            SetBkColor(DC, ::m_crColors[BTNST_COLOR_BK_IN])

         ELSE

            IF bIsFocused

               SetTextColor(DC, ::m_crColors[BTNST_COLOR_FG_FOCUS])
               SetBkColor(DC, ::m_crColors[BTNST_COLOR_BK_FOCUS])

            ELSE

               SetTextColor(DC, ::m_crColors[BTNST_COLOR_FG_OUT])
               SetBkColor(DC, ::m_crColors[BTNST_COLOR_BK_OUT])
            ENDIF
         ENDIF
      ENDIF
  */

      IF ::Themed

         IF hb_IsNumeric(::hicon) .OR. hb_IsNumeric(::hbitmap)
            IF lMultiLine .OR. ::iStyle == ST_ALIGN_OVERLAP
               captionRect := aclone(savecaptionRect)
            ENDIF
         ELSEIF lMultiLine
            captionRect[2] := (::nHeight  - nHeight) / 2 + 2
         ENDIF

         hb_DrawThemeText(::hTheme, dc, BP_PUSHBUTTON, IIf(bIsDisabled, PBS_DISABLED, PBS_NORMAL), ::caption, ;
            uAlign + DT_END_ELLIPSIS, 0, captionRect)

      ELSE

         SetBkMode(dc, TRANSPARENT)

         IF bIsDisabled

            OffsetRect(@captionRect, 1, 1)
            SetTextColor(dc, GetSysColor(COLOR_3DHILIGHT))
            DrawText(dc, ::caption, @captionRect[1], @captionRect[2], @captionRect[3], @captionRect[4], uAlign)
            OffsetRect(@captionRect, -1, -1)
            SetTextColor(dc, GetSysColor(COLOR_3DSHADOW))
            DrawText(dc, ::caption, @captionRect[1], @captionRect[2], @captionRect[3], @captionRect[4], uAlign)
            // if
         ELSE

            //SetTextColor(dc, GetSysColor(COLOR_BTNTEXT))
            //SetBkColor(dc, GetSysColor(COLOR_BTNFACE))
            //DrawText(dc, ::caption, @captionRect[1], @captionRect[2], @captionRect[3], @captionRect[4], uAlign)
            IF ::bMouseOverButton .OR. bIsPressed
               SetTextColor(dc, ::m_crColors[BTNST_COLOR_FG_IN])
               SetBkColor(dc, ::m_crColors[BTNST_COLOR_BK_IN])
               fillRect := COPYRECT(itemRect)
               IF bIsPressed
                  DrawButton(dc, fillRect[1], fillRect[2], fillRect[3], fillRect[4], 6)
               ENDIF
               InflateRect(@fillRect, - 2, - 2)
               FillRect(dc, fillRect[1], fillRect[2], fillRect[3], fillRect[4], ::m_crBrush[BTNST_COLOR_BK_IN]:handle)
            ELSE
               IF bIsFocused
                  SetTextColor(dc, ::m_crColors[BTNST_COLOR_FG_FOCUS])
                  SetBkColor(dc, ::m_crColors[BTNST_COLOR_BK_FOCUS])
                  fillRect := COPYRECT(itemRect)
                  InflateRect(@fillRect, - 2, - 2)
                  FillRect(dc, fillRect[1], fillRect[2], fillRect[3], fillRect[4], ::m_crBrush[BTNST_COLOR_BK_FOCUS]:handle)
               ELSE
                  SetTextColor(dc, ::m_crColors[BTNST_COLOR_FG_OUT])
                  SetBkColor(dc, ::m_crColors[BTNST_COLOR_BK_OUT])
                  fillRect := COPYRECT(itemRect)
                  InflateRect(@fillRect, - 2, - 2)
                  FillRect(dc, fillRect[1], fillRect[2], fillRect[3], fillRect[4], ::m_crBrush[BTNST_COLOR_BK_OUT]:handle)
               ENDIF
            ENDIF
            IF hb_IsNumeric(::hbitmap) .AND. ::m_bDrawTransparent
               DrawTransparentBitmap(dc, ::hbitmap, bmpRect[1], bmpRect[2])
            ELSEIF hb_IsNumeric(::hbitmap) .OR. hb_IsNumeric(::hicon)
               DrawTheIcon(::handle, dc, bHasTitle, @itemRect1, @captionRect1, bIsPressed, bIsDisabled, ::hIcon, ::hbitmap, ::iStyle)
            ENDIF

            IF hb_IsNumeric(::hicon) .OR. hb_IsNumeric(::hbitmap)
               IF lmultiline .OR. ::iStyle == ST_ALIGN_OVERLAP
                  captionRect := aclone(savecaptionRect)
               ENDIF
            ELSEIF lMultiLine
               captionRect[2] := (::nHeight  - nHeight) / 2 + 2
            ENDIF

            DrawText(dc, ::caption, @captionRect[1], @captionRect[2], @captionRect[3], @captionRect[4], uAlign)

         ENDIF
      ENDIF
   ENDIF

   // Draw the focus rect
   IF bIsFocused .AND. bDrawFocusRect .AND. hwg_BitaND(::sTyle, WS_TABSTOP) != 0
      focusRect := COPYRECT(itemRect)
      InflateRect(@focusRect, - 3, - 3)
      DrawFocusRect(dc, focusRect)
   ENDIF

   hwg_DeleteObject(br)
   hwg_DeleteObject(brBackground)
   hwg_DeleteObject(brBtnShadow)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD PAINTBK(hdc) CLASS HBUTTONEx

   LOCAL clDC := HclientDc():New(::oparent:handle)
   LOCAL rect
   LOCAL rect1

   rect := hwg_GetClientRect(::handle)

   rect1 := hwg_GetWindowRect(::handle)
   hwg_ScreenToClient(::oparent:handle, rect1)

   IF ValType(::m_dcBk) == "U"
      ::m_dcBk := hdc():New()
      ::m_dcBk:CreateCompatibleDC(clDC:m_hDC)
      ::m_bmpBk := CreateCompatibleBitmap(clDC:m_hDC, rect[3] - rect[1], rect[4] - rect[2])
      ::m_pbmpOldBk := ::m_dcBk:SelectObject(::m_bmpBk)
      ::m_dcBk:BitBlt(0, 0, rect[3] - rect[1], rect[4] - rect[4], clDC:m_hDc, rect1[1], rect1[2], SRCCOPY)
   ENDIF

   BitBlt(hdc, 0, 0, rect[3] - rect[1], rect[4] - rect[4], ::m_dcBk:m_hDC, 0, 0, SRCCOPY)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//
