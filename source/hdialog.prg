//
// $Id: hdialog.prg 1907 2012-09-25 23:03:18Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HDialog class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define WM_PSPNOTIFY WM_USER + 1010
#define FLAG_CHECK 2

STATIC s_aSheet := NIL
#if 0 // old code for reference (to be deleted)
STATIC s_aMessModalDlg := { ;
   {WM_COMMAND, {|o, w, l|DlgCommand(o, w, l)}},         ;
   {WM_SYSCOMMAND, {|o, w, l|onSysCommand(o, w, l)}},    ;
   {WM_SIZE, {|o, w, l|onSize(o, w, l)}},                ;
   {WM_INITDIALOG, {|o, w, l|InitModalDlg(o, w, l)}},    ;
   {WM_ERASEBKGND, {|o, w|onEraseBk(o, w)}},             ;
   {WM_DESTROY, {|o|onDestroy(o)}},                      ;
   {WM_ENTERIDLE, {|o, w, l|onEnterIdle(o, w, l)}},      ;
   {WM_ACTIVATE, {|o, w, l|onActivate(o, w, l)}},        ;
   {WM_PSPNOTIFY, {|o, w, l|onPspNotify(o, w, l)}},      ;
   {WM_HELP, {|o, w, l|onHelp(o, w, l)}},                ;
   {WM_CTLCOLORDLG, {|o, w, l|onDlgColor(o, w, l)}}      ;
   }
#endif

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onDestroy(oDlg)

   IF hb_IsObject(oDlg:oEmbedded)
      oDlg:oEmbedded:END()
   ENDIF
   // IN CLASS INHERIT DIALOG DESTROY APLICATION
   IF oDlg:oDefaultParent:CLASSNAME = "HDIALOG" .AND. HWindow():GetMain() == NIL
      oDlg:Super:onEvent(WM_DESTROY)
   ENDIF
   oDlg:Del()

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

CLASS HDialog INHERIT HCustomWindow

   CLASS VAR aDialogs SHARED INIT {}
   CLASS VAR aModalDialogs SHARED INIT {}

   DATA menu
   DATA hAccel
   DATA oPopup                // Context menu for a dialog
   DATA lBmpCenter INIT .F.
   DATA nBmpClr

   DATA lModal INIT .T.
   DATA lResult INIT .F.     // Becomes TRUE if the OK button is pressed
   DATA lUpdated INIT .F.     // TRUE, if any GET is changed
   DATA lClipper INIT .F.     // Set it to TRUE for moving between GETs with ENTER key
   DATA GetList INIT {}      // The array of GET items in the dialog
   DATA KeyList INIT {}      // The array of keys (as Clipper's SET KEY)
   DATA lExitOnEnter INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA lExitOnEsc INIT .T. // Set it to False, if dialog shouldn't be ended after pressing ENTER key,
   // Added by Sandro Freire
   DATA lGetSkiponEsc INIT .F.  // add by Basso - pressing ESC back focus , if first DEFAULT ESC EVENT
   DATA lRouteCommand INIT .F.
   DATA nLastKey INIT 0
   DATA oIcon, oBmp
   DATA bActivate
   DATA lActivated INIT .F.
   DATA xResourceID
   DATA oEmbedded
   DATA bOnActivate
   DATA lOnActivated INIT .F.
   DATA WindowState INIT 0
   DATA nScrollBars INIT -1
   DATA bScroll
   DATA lContainer INIT .F.

   METHOD New(lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, ;
      bOther, lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc, bcolor, bRefresh, lNoClosable)
   METHOD Activate(lNoModal, bOnActivate, nShow)
   METHOD onEvent(msg, wParam, lParam)
   METHOD Add() INLINE AAdd(IIf(::lModal, ::aModalDialogs, ::aDialogs), Self)
   METHOD Del()
   METHOD FindDialog(hWndTitle, lAll)
   METHOD GetActive()
   METHOD Center() INLINE hwg_CenterWindow(::handle, ::Type)
   METHOD Restore() INLINE hwg_SendMessage(::handle, WM_SYSCOMMAND, SC_RESTORE, 0)
   METHOD Maximize() INLINE hwg_SendMessage(::handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0)
   METHOD Minimize() INLINE hwg_SendMessage(::handle, WM_SYSCOMMAND, SC_MINIMIZE, 0)
   METHOD Close() INLINE EndDialog(::handle)
   METHOD Release() INLINE ::Close(), Self := NIL

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD NEW(lType, nStyle, x, y, width, height, cTitle, oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
   lClipper, oBmp, oIcon, lExitOnEnter, nHelpId, xResourceID, lExitOnEsc, bcolor, bRefresh, lNoClosable) CLASS HDialog

   ::oDefaultParent := Self
   ::xResourceID := xResourceID
   ::Type     := lType
   ::title    := cTitle
   ::style    := IIf(nStyle == NIL, DS_ABSALIGN + WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU, nStyle)
   ::oBmp     := oBmp
   ::oIcon    := oIcon
   ::nTop     := IIf(y == NIL, 0, y)
   ::nLeft    := IIf(x == NIL, 0, x)
   ::nWidth   := IIf(width == NIL, 0, width)
   ::nHeight  := IIf(height == NIL, 0, height)
   ::oFont    := oFont
   ::bInit    := bInit
   ::bDestroy := bExit
   ::bSize    := bSize
   ::bPaint   := bPaint
   ::bGetFocus  := bGfocus
   ::bLostFocus := bLfocus
   ::bOther     := bOther
   ::bRefresh   := bRefresh
   ::lClipper   := IIf(lClipper == NIL, .F., lClipper)
   ::lExitOnEnter := IIf(lExitOnEnter == NIL, .T., !lExitOnEnter) 
   ::lExitOnEsc  := IIf(lExitOnEsc == NIL, .T., !lExitOnEsc)
   ::lClosable   := Iif(lnoClosable == NIL, .T., !lnoClosable)

   IF nHelpId != NIL
      ::HelpId := nHelpId
   END
   ::SetColor(, bColor)
   IF hwg_Bitand(nStyle, WS_HSCROLL) > 0
      ::nScrollBars++
   ENDIF
   IF hwg_Bitand(nStyle, WS_VSCROLL) > 0
      ::nScrollBars += 2
   ENDIF
   ::lContainer := hwg_Bitand(nStyle, DS_CONTROL) > 0

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate(lNoModal, bOnActivate, nShow) CLASS HDialog

   LOCAL oWnd
   LOCAL hParent

   ::lOnActivated := .T.
   ::bOnActivate := IIf(bOnActivate != NIL, bOnActivate, ::bOnActivate)
   CreateGetList(Self)
   hParent := IIf(hb_IsObject(::oParent) .AND. ;
                   __ObjHasMsg(::oParent, "HANDLE") .AND. ::oParent:handle != NIL ;
                   .AND. !Empty(::oParent:handle) , ::oParent:handle, ;
                   IIf((oWnd := HWindow():GetMain()) != NIL, oWnd:handle, hwg_GetActiveWindow()))

   ::WindowState := IIf(hb_IsNumeric(nShow), nShow, SW_SHOWNORMAL)

   IF ::Type == WND_DLG_RESOURCE
      IF lNoModal == NIL .OR. !lNoModal
         ::lModal := .T.
         ::Add()
         // hwg_DialogBox(HWindow():GetMain():handle, Self)
         hwg_DialogBox(hwg_GetActiveWindow(), Self)
      ELSE
         ::lModal  := .F.
         ::handle  := 0
         ::lResult := .F.
         ::Add()
         hwg_CreateDialog(hParent, Self)
         /*
         IF ::oIcon != NIL
            hwg_SendMessage(::handle, WM_SETICON, 1, ::oIcon:handle)
         ENDIF
         */
      ENDIF
      /*
      IF ::title != NIL
          hwg_SetWindowText(::handle, ::title)
      ENDIF
      */

   ELSEIF ::Type == WND_DLG_NORESOURCE
      IF lNoModal == NIL .OR. !lNoModal
         ::lModal := .T.
         ::Add()
         // hwg_DlgBoxIndirect(HWindow():GetMain():handle, Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style)
         hwg_DlgBoxIndirect(hwg_GetActiveWindow(), Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style)
      ELSE
         ::lModal  := .F.
         ::handle  := 0
         ::lResult := .F.
         ::Add()
         hwg_CreateDlgIndirect(hParent, Self, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style)
         IF ::WindowState > SW_HIDE
            //hwg_InvalidateRect(::handle, 1)
            //BRINGTOTOP(::handle)
            //UPDATEWINDOW(::handle)
            hwg_SetWindowPos(::handle, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_FRAMECHANGED)
            hwg_RedrawWindow(::handle, RDW_UPDATENOW + RDW_NOCHILDREN)
         ENDIF

         /*
         IF ::oIcon != NIL
            hwg_SendMessage(::handle, WM_SETICON, 1, ::oIcon:handle)
         ENDIF
         */
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HDialog

   LOCAL i
   LOCAL oTab
   LOCAL nPos
   LOCAL aCoors

   IF msg == WM_GETMINMAXINFO
      IF ::minWidth  > -1 .OR. ::maxWidth  > -1 .OR. ;
         ::minHeight > -1 .OR. ::maxHeight > -1
         MINMAXWINDOW(::handle, lParam, ;
                      IIf(::minWidth  > -1, ::minWidth, NIL), ;
                      IIf(::minHeight > -1, ::minHeight, NIL), ;
                      IIf(::maxWidth  > -1, ::maxWidth, NIL), ;
                      IIf(::maxHeight > -1, ::maxHeight, NIL))
         RETURN 0
      ENDIF
   ELSEIF msg == WM_MENUCHAR
      RETURN onSysCommand(Self, SC_KEYMENU, hwg_LOWORD(wParam))
    ELSEIF msg == WM_MOVE //.OR. msg == 0x216
      aCoors := hwg_GetWindowRect(::handle)
      ::nLeft := aCoors[1]
         ::nTop  := aCoors[2]
    ELSEIF msg == WM_UPDATEUISTATE .AND. hwg_HIWORD(wParam) != UISF_HIDEFOCUS
      // prevent the screen flicker
       RETURN 1
   ELSEIF !::lActivated .AND. msg == WM_NCPAINT
      /* triggered on activate the modal dialog is visible only when */
      ::lActivated := .T.
      IF ::lModal .AND. hb_IsBlock(::bOnActivate)
         hwg_PostMessage(::handle, WM_ACTIVATE, MAKEWPARAM(WA_ACTIVE, 0), ::handle)
      ENDIF
   ENDIF
   IF (i := AScan(s_aMessModalDlg, {|a|a[1] == msg})) != 0
      IF ::lRouteCommand .AND. (msg == WM_COMMAND .OR. msg == WM_NOTIFY)
         nPos := AScan(::aControls, {|x|x:className() == "HTAB"})
         IF nPos > 0
            oTab := ::aControls[nPos]
            IF Len(oTab:aPages) > 0
               Eval(s_aMessModalDlg[i, 2], oTab:aPages[oTab:GetActivePage(), 1], wParam, lParam)
            ENDIF
         ENDIF
      ENDIF
      //AgE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling .OR. msg == WM_ERASEBKGND .OR. msg == WM_SIZE
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN Eval(s_aMessModalDlg[i, 2], Self, wParam, lParam)
      ENDIF
   ELSEIF msg == WM_CLOSE
      ::close()
      RETURN 1
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1 .AND. ::bScroll == NIL
            ::Super:ScrollHV(Self, msg, wParam, lParam)
         ENDIF
         onTrackScroll(Self, msg, wParam, lParam)
      ENDIF
      RETURN ::Super:onEvent(msg, wParam, lParam)
   ENDIF

RETURN 0
#else
METHOD onEvent(msg, wParam, lParam) CLASS HDialog

   LOCAL oTab
   LOCAL nPos
   LOCAL aCoors

   SWITCH msg

   CASE WM_GETMINMAXINFO
      IF ::minWidth  > -1 .OR. ::maxWidth  > -1 .OR. ;
         ::minHeight > -1 .OR. ::maxHeight > -1
         MINMAXWINDOW(::handle, lParam, ;
                      IIf(::minWidth  > -1, ::minWidth, NIL), ;
                      IIf(::minHeight > -1, ::minHeight, NIL), ;
                      IIf(::maxWidth  > -1, ::maxWidth, NIL), ;
                      IIf(::maxHeight > -1, ::maxHeight, NIL))
         RETURN 0
      ENDIF
      EXIT

   CASE WM_MENUCHAR
      RETURN onSysCommand(Self, SC_KEYMENU, hwg_LOWORD(wParam))

   CASE WM_MOVE //.OR. msg == 0x216
      aCoors := hwg_GetWindowRect(::handle)
      ::nLeft := aCoors[1]
      ::nTop  := aCoors[2]
      EXIT

   CASE WM_UPDATEUISTATE
      IF hwg_HIWORD(wParam) != UISF_HIDEFOCUS
         // prevent the screen flicker
         RETURN 1
      ENDIF
      EXIT

   CASE WM_NCPAINT
      IF !::lActivated
         /* triggered on activate the modal dialog is visible only when */
         ::lActivated := .T.
         IF ::lModal .AND. hb_IsBlock(::bOnActivate)
            hwg_PostMessage(::handle, WM_ACTIVATE, MAKEWPARAM(WA_ACTIVE, 0), ::handle)
         ENDIF
      ENDIF
      EXIT

   CASE WM_COMMAND
      IF ::lRouteCommand
         nPos := AScan(::aControls, {|x|x:className() == "HTAB"})
         IF nPos > 0
            oTab := ::aControls[nPos]
            IF Len(oTab:aPages) > 0
               Eval({|o, w, l|DlgCommand(o, w, l)}, oTab:aPages[oTab:GetActivePage(), 1], wParam, lParam)
            ENDIF
         ENDIF
      ENDIF
      //AGE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN DlgCommand(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_SYSCOMMAND
      //AGE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN onSysCommand(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_SIZE
      //AGE SOMENTE NO DIALOG
      // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
      RETURN onSize(Self, wParam, lParam)

   CASE WM_INITDIALOG
      //AGE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN InitModalDlg(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_ERASEBKGND
      //AGE SOMENTE NO DIALOG
      // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
      RETURN onEraseBk(Self, wParam)

   CASE WM_DESTROY
      //AGE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN onDestroy(Self)
      ENDIF
      EXIT

   CASE WM_ENTERIDLE
      //AGE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN onEnterIdle(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_ACTIVATE
      //AGE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN onActivate(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_PSPNOTIFY
      //AGE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN onPspNotify(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_HELP
      //AGE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN onHelp(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_CTLCOLORDLG
      //AGE SOMENTE NO DIALOG
      IF !::lSuspendMsgsHandling
         // hwg_WriteLog(Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
         RETURN onDlgColor(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_CLOSE
      ::close()
      RETURN 1

   CASE WM_HSCROLL
   CASE WM_VSCROLL
   CASE WM_MOUSEWHEEL
      IF ::nScrollBars != -1 .AND. ::bScroll == NIL
         ::Super:ScrollHV(Self, msg, wParam, lParam)
      ENDIF
      onTrackScroll(Self, msg, wParam, lParam)
      RETURN ::Super:onEvent(msg, wParam, lParam)

#ifdef __XHARBOUR__
   DEFAULT
#else
   OTHERWISE
#endif
      RETURN ::Super:onEvent(msg, wParam, lParam)

   ENDSWITCH

RETURN 0
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD Del() CLASS HDialog

   LOCAL i

   IF ::lModal
      IF (i := AScan(::aModalDialogs, {|o|o == Self})) > 0
         ADel(::aModalDialogs, i)
         ASize(::aModalDialogs, Len(::aModalDialogs) - 1)
      ENDIF
   ELSE
      IF (i := AScan(::aDialogs, {|o|o == Self})) > 0
         ADel(::aDialogs, i)
         ASize(::aDialogs, Len(::aDialogs) - 1)
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD FindDialog(hWndTitle, lAll) CLASS HDialog
   
   LOCAL cType := ValType(hWndTitle)
   LOCAL i

   IF cType != "C"
      i := AScan(::aDialogs, {|o|hwg_SelfFocus(o:handle, hWndTitle)})
      IF i == 0 .AND. (lAll != NIL .AND. lAll)
          i := AScan(::aModalDialogs, {|o|hwg_SelfFocus(o:handle, hWndTitle)})
          RETURN IIf(i == 0, NIL, ::aModalDialogs[i])
      ENDIF
   ELSE
      i := AScan(::aDialogs, {|o|hb_IsChar(o:Title) .AND. o:Title == hWndTitle})
      IF i == 0 .AND. (lAll != NIL .AND. lAll)
         i := AScan(::aModalDialogs, {|o|hb_IsChar(o:Title) .AND. o:Title == hWndTitle})
         RETURN IIf(i == 0, NIL, ::aModalDialogs[i])
      ENDIF
   ENDIF

RETURN IIf(i == 0, NIL, ::aDialogs[i])

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetActive() CLASS HDialog
   
   LOCAL handle := hwg_GetFocus()
   LOCAL i := AScan(::Getlist, {|o|o:handle == handle})
   
RETURN IIf(i == 0, NIL, ::Getlist[i])

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION InitModalDlg(oDlg, wParam, lParam)

   LOCAL nReturn := 1
   LOCAL uis

   // HB_SYMBOL_UNUSED(wParam)
   HB_SYMBOL_UNUSED(lParam)
   HB_SYMBOL_UNUSED(wParam)

   // oDlg:handle := hDlg
   // hwg_WriteLog(Str(oDlg:handle) + " " + oDlg:title)
   //  .if uMsg == WM_INITDIALOG
   //-EnableThemeDialogTexture(odlg:handle, 6)  //, ETDT_ENABLETAB)

   IF hb_IsArray(oDlg:menu)
      hwg__SetMenu(oDlg:handle, oDlg:menu[5])
   ENDIF

  //- oDlg:rect := hwg_GetWindowRect(odlg:handle)
   oDlg:rect := hwg_GetclientRect(oDlg:handle)

   IF hb_IsObject(oDlg:oIcon)
      hwg_SendMessage(oDlg:handle, WM_SETICON, 1, oDlg:oIcon:handle)
   ENDIF
   IF hb_IsObject(oDlg:oFont)
      hwg_SendMessage(oDlg:handle, WM_SETFONT, oDlg:oFont:handle, 0)
   ENDIF
   IF oDlg:Title != NIL
      hwg_SetWindowText(oDlg:handle, oDlg:Title)
   ENDIF
   IF !oDlg:lClosable
      oDlg:Closable(.F.)
   ENDIF

   InitObjects(oDlg)
   InitControls(oDlg, .T.)

   IF hb_IsBlock(oDlg:bInit)
      oDlg:lSuspendMsgsHandling := .T.
      IF !hb_IsNumeric(nReturn := Eval(oDlg:bInit, oDlg))
         oDlg:lSuspendMsgsHandling := .F.
         IF hb_IsLogical(nReturn) .AND. !nReturn
            oDlg:Close()
            RETURN 0
         ENDIF
         nReturn := 1
      ENDIF
   ENDIF
   oDlg:lSuspendMsgsHandling := .F.

   oDlg:nInitFocus := IIf(hb_IsObject(oDlg:nInitFocus), oDlg:nInitFocus:handle, oDlg:nInitFocus)
   IF !Empty(oDlg:nInitFocus)
      IF PtrtouLong(oDlg:FindControl(, oDlg:nInitFocus):oParent:handle) == PtrtouLong(oDlg:handle)
         hwg_SetFocus(oDlg:nInitFocus)
      ENDIF
      nReturn := 0
   ENDIF

   uis := hwg_SendMessage(oDlg:handle, WM_QUERYUISTATE, 0, 0)
   // draw focus
   IF uis != 0
      // triggered to mouse
      hwg_SendMessage(oDlg:handle, WM_CHANGEUISTATE, makelong(UIS_CLEAR, UISF_HIDEACCEL), 0)
   ELSE
      hwg_SendMessage(oDlg:handle, WM_UPDATEUISTATE, makelong(UIS_CLEAR, UISF_HIDEACCEL), 0)
   ENDIF

   // CALL DIALOG NOT VISIBLE
   IF oDlg:WindowState == SW_HIDE .AND. !oDlg:lModal
      oDlg:Hide()
      oDlg:lHide := .T.
      oDlg:lResult := oDlg
      //-oDlg:WindowState := SW_SHOWNORMAL
      RETURN oDlg
   ENDIF

   hwg_PostMessage(oDlg:handle, WM_CHANGEUISTATE, makelong(UIS_CLEAR, UISF_HIDEFOCUS), 0)

   IF !oDlg:lModal .AND. !hwg_IsWindowVisible(oDlg:handle)
      hwg_ShowWindow(oDlg:handle, SW_SHOWDEFAULT)
   ENDIF

   IF hb_IsBlock(oDlg:bGetFocus)
      oDlg:lSuspendMsgsHandling := .T.
      Eval(oDlg:bGetFocus, oDlg)
      oDlg:lSuspendMsgsHandling := .F.
   ENDIF

   IF oDlg:WindowState == SW_SHOWMINIMIZED //2
      oDlg:minimize()
   ELSEIF oDlg:WindowState == SW_SHOWMAXIMIZED //3
      oDlg:maximize()
   ENDIF

   IF !oDlg:lModal
     //- oDlg:lActivated := .T.
      IF hb_IsBlock(oDlg:bOnActivate)
         Eval(oDlg:bOnActivate, oDlg)
      ENDIF
   ENDIF

   oDlg:rect := hwg_GetclientRect(oDlg:handle)
   IF oDlg:nScrollBars > -1
      AEval(oDlg:aControls, {|o|oDlg:ncurHeight := max(o:nTop + o:nHeight + VERT_PTS * 4, oDlg:ncurHeight)})
      AEval(oDlg:aControls, {|o|oDlg:ncurWidth := max(o:nLeft + o:nWidth  + HORZ_PTS * 4, oDlg:ncurWidth)})
       oDlg:ResetScrollbars()
      oDlg:SetupScrollbars()
   ENDIF

RETURN nReturn

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onEnterIdle(oDlg, wParam, lParam)
   
   LOCAL oItem

   HB_SYMBOL_UNUSED(oDlg)

   IF wParam == 0 .AND. (oItem := ATail(HDialog():aModalDialogs)) != NIL ;
      .AND. oItem:handle == lParam .AND. !oItem:lActivated
      oItem:lActivated := .T.
      IF hb_IsBlock(oItem:bActivate)
         Eval(oItem:bActivate, oItem)
      ENDIF
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onDlgColor(oDlg, wParam, lParam)

   HB_SYMBOL_UNUSED(lParam)

   SetBkMode(wParam, 1) // Transparent mode
   IF oDlg:bcolor != NIL .AND. !hb_IsNumeric(oDlg:brush)
       RETURN oDlg:brush:handle
   ENDIF

RETURN 0 //hBrTemp:handle

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onEraseBk(oDlg, hDC)

    IF __ObjHasMsg(oDlg, "OBMP") .AND. hb_IsObject(oDlg:oBmp)
       IF oDlg:lBmpCenter
          CenterBitmap(hDC, oDlg:handle, oDlg:oBmp:handle, , oDlg:nBmpClr)
       ELSE
          SpreadBitmap(hDC, oDlg:handle, oDlg:oBmp:handle)
       ENDIF
       RETURN 1
    ELSE
       /*
       aCoors := hwg_GetClientRect(oDlg:handle)
       IF oDlg:brush != NIL
          IF !hb_IsNumeric(oDlg:brush)
             FillRect(hDC, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, oDlg:brush:handle)
          ENDIF
       ELSE
          FillRect(hDC, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, COLOR_3DFACE + 1)
       ENDIF
       RETURN 1
       */
       //FillRect(hDC, aCoors[1], aCoors[2], aCoors[1] + 1, aCoors[2] + 1)
    ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION DlgCommand(oDlg, wParam, lParam)
   
   LOCAL iParHigh := hwg_HIWORD(wParam)
   LOCAL iParLow := hwg_LOWORD(wParam)
   LOCAL aMenu
   LOCAL i
   LOCAL hCtrl
   LOCAL oCtrl
   LOCAL nEsc := .F.

   HB_SYMBOL_UNUSED(lParam)

   IF iParHigh == 0
      IF iParLow == IDOK
         hCtrl := hwg_GetFocus()
         oCtrl := oDlg:FindControl(, hCtrl)
         IF oCtrl == NIL .OR. !hwg_SelfFocus(oCtrl:handle, hCtrl)
            hCtrl := hwg_GetAncestor(hCtrl, GA_PARENT)
            IF (oCtrl := oDlg:FindControl(, hCtrl)) != NIL
               GetSkip(oCtrl:oParent, hCtrl, , 1)
            ENDIF
         ENDIF

         IF hb_IsObject(oCtrl) .AND. oCtrl:classname = "HTAB"
            RETURN 1
         ENDIF
         IF hb_IsObject(oCtrl) .AND. (GetNextDlgTabItem(hwg_GetActiveWindow(), hCtrl, 1) == hCtrl .OR. hwg_SelfFocus(oCtrl:handle, hCtrl))
            hwg_SendMessage(oCtrl:handle, WM_KILLFOCUS, 0, 0)
         ENDIF
         IF hb_IsObject(oCtrl) .AND. oCtrl:id == IDOK .AND. __ObjHasMsg(oCtrl, "BCLICK") .AND. oCtrl:bClick == NIL
            oDlg:lResult := .T.
            EndDialog(oDlg:handle)   // VER AQUI
            RETURN 1
         ENDIF
         //
             /*
         IF !oDlg:lExitOnEnter .AND. lParam > 0 .AND. lParam != hCtrl
            IF oCtrl:oParent:oParent != NIL
                GetSkip(oCtrl:oParent, hCtrl, , 1)
            eNDIF
             RETURN 0
         ENDIF
         */
         IF oDlg:lClipper
            IF hb_IsObject(oCtrl) .AND. !GetSkip(oCtrl:oParent, hCtrl, , 1)
               IF oDlg:lExitOnEnter
                  oDlg:lResult := .T.
                  EndDialog(oDlg:handle)
               ENDIF
               RETURN 1
            ENDIF
            //hwg_SetFocus(odlg:handle)
         ENDIF
      ELSEIF iParLow == IDCANCEL
         IF (oCtrl := oDlg:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled() .AND. oDlg:lExitOnEsc
            oDlg:nLastKey := 27
            IF Empty(EndDialog(oDlg:handle))
               RETURN 1
            ENDIF
            oDlg:bDestroy := NIL
            hwg_SendMessage(oCtrl:handle, WM_CLOSE, 0, 0)
            RETURN 0
         ELSEIF hb_IsObject(oCtrl) .AND. oCtrl:IsEnabled() .AND. !hwg_SelfFocus(oCtrl:handle)
            //oCtrl:SetFocus()
            hwg_PostMessage(oDlg:handle, WM_NEXTDLGCTL, oCtrl:handle, 1)
         ELSEIF oDlg:lGetSkiponEsc
            hCtrl := hwg_GetFocus()
            oCtrl := oDlg:FindControl(, hctrl)
            IF hb_IsObject(oCtrl) .AND. __ObjHasMsg(oCtrl, "OGROUP") .AND. hb_IsObject(oCtrl:oGroup:oHGroup)
                oCtrl := oCtrl:oGroup:oHGroup
                hCtrl := oCtrl:handle
            ENDIF
            IF hb_IsObject(oCtrl) .AND. GetSkip(oCtrl:oParent, hCtrl, , -1)
               IF AScan(oDlg:GetList, {|o|o:handle == hCtrl}) > 1
                  RETURN 1
               ENDIF
            ENDIF
         ENDIF
         nEsc := (getkeystate(VK_ESCAPE) < 0)
         //oDlg:nLastKey := VK_ESCAPE
      ELSEIF iParLow == IDHELP  // HELP
         hwg_SendMessage(oDlg:handle, WM_HELP, 0, 0)
      ENDIF
   ENDIF

   //IF oDlg:nInitFocus > 0 //.AND. !hwg_IsWindowVisible(oDlg:handle)
   // comentado, vc não pode testar um ponteiro como se fosse numerico
   IF !Empty(oDlg:nInitFocus)  //.AND. !hwg_IsWindowVisible(oDlg:handle)
      hwg_PostMessage(oDlg:handle, WM_NEXTDLGCTL, oDlg:nInitFocus, 1)
   ENDIF
   IF oDlg:aEvents != NIL .AND. ;
      (i := AScan(oDlg:aEvents, {|a|a[1] == iParHigh .AND. a[2] == iParLow})) > 0
      IF !oDlg:lSuspendMsgsHandling
         Eval(oDlg:aEvents[i, 3], oDlg, iParLow)
      ENDIF
   ELSEIF iParHigh == 0 .AND. ( ; //.AND. !oDlg:lSuspendMsgsHandling .AND. ( ;
      (iParLow == IDOK .AND. oDlg:FindControl(IDOK) != NIL) .OR. iParLow == IDCANCEL)
      IF iParLow == IDOK
         oDlg:lResult := .T.
         IF (oCtrl := oDlg:FindControl(IDOK)) != NIL .AND. __ObjHasMsg(oCtrl, "BCLICK") .AND. oCtrl:bClick != NIL
            RETURN 1
         ELSEIF oDlg:lExitOnEnter .OR. hb_IsObject(oCtrl)
            EndDialog(oDlg:handle)
         ENDIF
      ENDIF
      //Replaced by Sandro
      IF iParLow == IDCANCEL .AND. (oDlg:lExitOnEsc .OR. !nEsc)
         oDlg:nLastKey := 27
         EndDialog(oDlg:handle)
      ELSEIF !oDlg:lExitOnEsc
         oDlg:nLastKey := 0
      ENDIF
   ELSEIF __ObjHasMsg(oDlg, "MENU") .AND. hb_IsArray(oDlg:menu) .AND. ;
      (aMenu := hwg_FindMenuItem(oDlg:menu, iParLow, @i)) != NIL
      IF hwg_BitAnd(aMenu[1, i, 4], FLAG_CHECK) > 0
         CheckMenuItem(, aMenu[1, i, 3], !IsCheckedMenuItem(, aMenu[1, i, 3]))
      ENDIF
      IF hb_IsBlock(aMenu[1, i, 1])
         Eval(aMenu[1, i, 1], i, iParlow)
      ENDIF
   ELSEIF __ObjHasMsg(oDlg, "OPOPUP") .AND. hb_IsObject(oDlg:oPopup) .AND. ;
      (aMenu := hwg_FindMenuItem(oDlg:oPopup:aMenu, wParam, @i)) != NIL .AND. hb_IsBlock(aMenu[1, i, 1])
      Eval(aMenu[1, i, 1], i, wParam)
   ENDIF
   IF !Empty(oDlg:nInitFocus)
      oDlg:nInitFocus := 0
   ENDIF

RETURN 1

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION DlgMouseMove()

   LOCAL oBtn := SetNiceBtnSelected()

   IF hb_IsObject(oBtn) .AND. !oBtn:lPress
      oBtn:state := OBTN_NORMAL
      hwg_InvalidateRect(oBtn:handle, 0)
      // hwg_PostMessage(oBtn:handle, WM_PAINT, 0, 0)
      SetNiceBtnSelected(NIL)
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onSize(oDlg, wParam, lParam)

   LOCAL aControls
   LOCAL iCont
   LOCAL nW1
   LOCAL nH1

   //HB_SYMBOL_UNUSED(wParam)

   IF hb_IsObject(oDlg:oEmbedded)
      oDlg:oEmbedded:Resize(hwg_LOWORD(lParam), hwg_HIWORD(lParam))
   ENDIF
   // VERIFY MIN SIZES AND MAX SIZES
   /*
   IF (oDlg:nHeight == oDlg:minHeight .AND. nH < oDlg:minHeight) .OR. ;
      (oDlg:nHeight == oDlg:maxHeight .AND. nH > oDlg:maxHeight) .OR. ;
      (oDlg:nWidth == oDlg:minWidth .AND. nW < oDlg:minWidth) .OR. ;
      (oDlg:nWidth == oDlg:maxWidth .AND. nW > oDlg:maxWidth)
      RETURN 0
   ENDIF
   */
   nW1 := oDlg:nWidth
   nH1 := oDlg:nHeight
   //aControls := hwg_GetWindowRect(oDlg:handle)
   IF wParam != 1 //SIZE_MINIMIZED
      oDlg:nWidth := hwg_LOWORD(lParam)  //aControls[3]-aControls[1]
      oDlg:nHeight := hwg_HIWORD(lParam) //aControls[4]-aControls[2]
   ENDIF
   // SCROLL BARS code here.
    IF oDlg:nScrollBars > -1 .AND. oDlg:lAutoScroll
      oDlg:ResetScrollbars()
      oDlg:SetupScrollbars()
   ENDIF

   IF hb_IsBlock(oDlg:bSize) .AND. (oDlg:oParent == NIL .OR. !__ObjHasMsg(oDlg:oParent, "ACONTROLS"))
      Eval(oDlg:bSize, oDlg, hwg_LOWORD(lParam), hwg_HIWORD(lParam))
   ENDIF
   aControls := oDlg:aControls
   IF aControls != NIL .AND. !Empty(oDlg:Rect)
      oDlg:Anchor(oDlg, nW1, nH1, oDlg:nWidth, oDlg:nHeight)
      FOR iCont := 1 TO Len(aControls)
         IF hb_IsBlock(aControls[iCont]:bSize)
            Eval(aControls[iCont]:bSize, aControls[iCont], hwg_LOWORD(lParam), hwg_HIWORD(lParam), nW1, nH1)
         ENDIF
      NEXT
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onActivate(oDlg, wParam, lParam)

   LOCAL iParLow := hwg_LOWORD(wParam)
   LOCAL iParHigh := hwg_HIWORD(wParam)

   //HB_SYMBOL_UNUSED(lParam)

   IF (iParLow == WA_ACTIVE .OR. iParLow == WA_CLICKACTIVE) .AND. oDlg:lContainer .AND. !hwg_SelfFocus(lParam, oDlg:handle)
      UpdateWindow(oDlg:handle)
      hwg_SendMessage(lParam, WM_NCACTIVATE, 1, NIL)
      RETURN 0
   ENDIF
   IF iParLow == WA_ACTIVE .AND. hwg_SelfFocus(lParam, oDlg:handle)
      IF hb_IsBlock(oDlg:bOnActivate)
        //- oDlg:lSuspendMsgsHandling := .T.
         Eval(oDlg:bOnActivate, oDlg)
         //-oDlg:lSuspendMsgsHandling := .F.
      ENDIF
   ELSEIF (iParLow == WA_ACTIVE .OR. iParLow == WA_CLICKACTIVE) .AND. hwg_IsWindowVisible(oDlg:handle) //.AND. PtrtoUlong(lParam) == 0
      IF hb_IsBlock(oDlg:bGetFocus) //.AND. hwg_IsWindowVisible(::handle)
         oDlg:lSuspendMsgsHandling := .T.
         IF iParHigh > 0  // MINIMIZED
            //odlg:restore()
         ENDIF
         Eval(oDlg:bGetFocus, oDlg, lParam)
         oDlg:lSuspendMsgsHandling := .F.
      ENDIF
   ELSEIF iParLow == WA_INACTIVE .AND. hb_IsBlock(oDlg:bLostFocus) //.AND. PtrtoUlong(lParam) == 0
      oDlg:lSuspendMsgsHandling := .T.
      Eval(oDlg:bLostFocus, oDlg, lParam)
      oDlg:lSuspendMsgsHandling := .F.
      //IF !oDlg:lModal
      //   RETURN 1
      //ENDIF
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION onHelp(oDlg, wParam, lParam)

   LOCAL oCtrl
   LOCAL nHelpId
   LOCAL oParent
   LOCAL cDir

   HB_SYMBOL_UNUSED(wParam)

   IF !Empty(SetHelpFileName())
      IF "chm" $ Lower(CutPath(SetHelpFileName()))
         cDir := IIf(Empty(FilePath(SetHelpFileName())), Curdir(), FilePath(SetHelpFileName()))
      ENDIF
      IF !Empty(lParam)
         oCtrl := oDlg:FindControl(NIL, GetHelpData(lParam))
      ENDIF
      IF hb_IsObject(oCtrl)
         nHelpId := oCtrl:HelpId
         IF Empty(nHelpId)
            oParent := oCtrl:oParent
            nHelpId := IIf(Empty(oParent:HelpId), oDlg:HelpId, oParent:HelpId)
         ENDIF
         IF "chm" $ Lower(CutPath(SetHelpFileName()))
            nHelpId := IIf(hb_IsNumeric(nHelpId), LTrim(Str(nHelpId)), nHelpId)
            hwg_ShellExecute("hh.exe", "open", CutPath(SetHelpFileName()) + "::" + nHelpId + ".html", cDir)
         ELSE
            WinHelp(oDlg:handle, SetHelpFileName(), IIf(Empty(nHelpId), 3, 1), nHelpId)
         ENDIF
      ELSEIF cDir != NIL
         hwg_ShellExecute("hh.exe", "open", CutPath(SetHelpFileName()), cDir)
      ELSE
         WinHelp(oDlg:handle, SetHelpFileName(), IIf(Empty(oDlg:HelpId), 3, 1), oDlg:HelpId)
      ENDIF
   ENDIF

RETURN 1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onPspNotify(oDlg, wParam, lParam)

   LOCAL nCode := hwg_GetNotifyCode(lParam)
   LOCAL res := .T.

   HB_SYMBOL_UNUSED(wParam)

   SWITCH nCode

   CASE PSN_SETACTIVE //.AND. !oDlg:aEvdisable
      IF hb_IsBlock(oDlg:bGetFocus)
         oDlg:lSuspendMsgsHandling := .T.
         res := Eval(oDlg:bGetFocus, oDlg)
         oDlg:lSuspendMsgsHandling := .F.
      ENDIF
      // 'res' should be 0(Ok) or -1
      hwg_SetDlgResult(oDlg:handle, IIf(res, 0, -1))
      RETURN 1

   CASE PSN_KILLACTIVE //.AND. !oDlg:aEvdisable
      IF hb_IsBlock(oDlg:bLostFocus)
         oDlg:lSuspendMsgsHandling := .T.
         res := Eval(oDlg:bLostFocus, oDlg)
         oDlg:lSuspendMsgsHandling := .F.
      ENDIF
      // 'res' should be 0(Ok) or 1
      hwg_SetDlgResult(oDlg:handle, IIf(res, 0, 1))
      RETURN 1

   //CASE PSN_RESET

   CASE PSN_APPLY
      IF hb_IsBlock(oDlg:bDestroy)
         res := Eval(oDlg:bDestroy, oDlg)
      ENDIF
      // 'res' should be 0(Ok) or 2
      hwg_SetDlgResult(oDlg:handle, IIf(res, 0, 2))
      IF res
         oDlg:lResult := .T.
      ENDIF
      RETURN 1

#ifdef __XHARBOUR__
   DEFAULT
#else
   OTHERWISE
#endif

      IF hb_IsBlock(oDlg:bOther)
         res := Eval(oDlg:bOther, oDlg, WM_NOTIFY, 0, lParam)
         hwg_SetDlgResult(oDlg:handle, IIf(res, 0, 1))
         RETURN 1
      ENDIF

   ENDSWITCH

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION PropertySheet(hParentWindow, aPages, cTitle, x1, y1, width, height, lModeless, lNoApply, lWizard)

   LOCAL hSheet
   LOCAL i
   LOCAL aHandles := Array(Len(aPages))
   LOCAL aTemplates := Array(Len(aPages))

   s_aSheet := Array(Len(aPages))
   FOR i := 1 TO Len(aPages)
      IF aPages[i]:Type == WND_DLG_RESOURCE
         aHandles[i] := hwg__CreatePropertySheetPage(aPages[i])
      ELSE
         aTemplates[i] := hwg_CreateDlgTemplate(aPages[i], x1, y1, width, height, WS_CHILD + WS_VISIBLE + WS_BORDER)
         aHandles[i] := hwg__CreatePropertySheetPage(aPages[i], aTemplates[i])
      ENDIF
      s_aSheet[i] := {aHandles[i], aPages[i]}
      // hwg_WriteLog("h: " + Str(aHandles[i]))
   NEXT
   hSheet := hwg__PropertySheet(hParentWindow, aHandles, Len(aHandles), cTitle, lModeless, lNoApply, lWizard)
   FOR i := 1 TO Len(aPages)
      IF aPages[i]:Type != WND_DLG_RESOURCE
         hwg_ReleaseDlgTemplate(aTemplates[i])
      ENDIF
   NEXT

RETURN hSheet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION GetModalDlg

   LOCAL i := Len(HDialog():aModalDialogs)

RETURN IIf(i > 0, HDialog():aModalDialogs[i], 0)

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION GetModalHandle

   LOCAL i := Len(HDialog():aModalDialogs)

RETURN IIf(i > 0, HDialog():aModalDialogs[i]:handle, 0)

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION EndDialog(handle)

   LOCAL oDlg
   LOCAL hFocus := hwg_GetFocus()
   LOCAL oCtrl
   LOCAL res

   IF handle == NIL
      IF (oDlg := ATail(HDialog():aModalDialogs)) == NIL
         RETURN NIL
      ENDIF
   ELSE
      IF ((oDlg := ATail(HDialog():aModalDialogs)) == NIL .OR. oDlg:handle != handle) .AND. ;
         (oDlg := HDialog():FindDialog(handle)) == NIL
         RETURN NIL
      ENDIF
   ENDIF
   // force control triggered killfocus
   IF !Empty(hFocus) .AND. (oCtrl := oDlg:FindControl(, hFocus)) != NIL .AND. oCtrl:bLostFocus != NIL .AND. oDlg:lModal
      hwg_SendMessage(hFocus, WM_KILLFOCUS, 0, 0)
   ENDIF
   IF hb_IsBlock(oDlg:bDestroy)
      //oDlg:lSuspendMsgsHandling := .T.
      res := Eval(oDlg:bDestroy, oDlg)
      //oDlg:lSuspendMsgsHandling := .F.
      IF !res
         oDlg:nLastKey := 0
         RETURN NIL
      ENDIF
   ENDIF

RETURN IIf(oDlg:lModal, hwg_EndDialog(oDlg:handle), hwg_DestroyWindow(oDlg:handle))

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SetDlgKey(oDlg, nctrl, nkey, block)

   LOCAL i
   LOCAL aKeys
   LOCAL bOldSet

   IF oDlg == NIL
      oDlg := HCustomWindow():oDefaultParent
   ENDIF
   IF nctrl == NIL
      nctrl := 0
   ENDIF

   IF !__ObjHasMsg(oDlg, "KEYLIST")
      RETURN NIL
   ENDIF
   aKeys := oDlg:KeyList
   IF (i := AScan(aKeys, {|a|a[1] == nctrl .AND. a[2] == nkey})) > 0
      bOldSet := aKeys[i, 3]
   ENDIF
   IF block == NIL
      IF i > 0
         ADel(oDlg:KeyList, i)
         ASize(oDlg:KeyList, Len(oDlg:KeyList) - 1)
      ENDIF
   ELSE
      IF i == 0
         AAdd(aKeys, {nctrl, nkey, block})
      ELSE
         aKeys[i, 3] := block
      ENDIF
   ENDIF

RETURN bOldSet

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onSysCommand(oDlg, wParam, lParam)

   LOCAL oCtrl

   SWITCH wParam

   CASE SC_CLOSE
      IF !oDlg:Closable
         RETURN 1
      ENDIF
      EXIT

   //CASE SC_MINIMIZE

   //CASE SC_MAXIMIZE
   //CASE SC_MAXIMIZE2

   //CASE SC_RESTORE
   //CASE SC_RESTORE2

   //CASE SC_NEXTWINDOW
   //CASE SC_PREVWINDOW

   CASE SC_KEYMENU
      // accelerator IN TAB/CONTAINER
      IF (oCtrl := FindAccelerator(oDlg, lParam)) != NIL
         oCtrl:SetFocus()
         hwg_SendMessage(oCtrl:handle, WM_SYSKEYUP, lParam, 0)
         RETURN 2
      ENDIF
      EXIT

   //CASE SC_HOTKEY

   //CASE SC_MENU

   //CASE SC_CONTEXTHELP  //button help

   ENDSWITCH

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

EXIT PROCEDURE hwg_ExitProcedure

   hwg_ExitProc()

RETURN

//-------------------------------------------------------------------------------------------------------------------//
