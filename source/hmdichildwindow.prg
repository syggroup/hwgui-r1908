//
// $Id: hwindow.prg 1904 2012-09-21 11:43:56Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HMDIChildWindow class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

//-------------------------------------------------------------------------------------------------------------------//

CLASS HMDIChildWindow INHERIT HWindow

#if 0 // old code for reference (to be deleted)
CLASS VAR aMessages INIT { ;
                           { ;
                             WM_CREATE, ;
                             WM_COMMAND, ;
                             WM_ERASEBKGND, ;
                             WM_MOVE, ;
                             WM_SIZE, ;
                             WM_NCACTIVATE, ;
                             WM_SYSCOMMAND, ;
                             WM_ENTERIDLE, ;
                             WM_MDIACTIVATE, ;
                             WM_DESTROY ;
                           }, ;
                           { ;
                             {|o, w, l|HB_SYMBOL_UNUSED(w), onMdiCreate(o, l)},        ;
                             {|o, w|onMdiCommand(o, w)},         ;
                             {|o, w|onEraseBk(o, w)},            ;
                             {|o|onMove(o)},                   ;
                             {|o, w, l|onSize(o, w, l)},           ;
                             {|o, w|onMdiNcActivate(o, w)},      ;
                             {|o, w, l|onSysCommand(o, w, l)},         ;
                             {|o, w, l|onEnterIdle(o, w, l)},      ;
                             {|o, w, l|onMdiActivate(o, w, l)},     ;
                             {|o|onDestroy(o)}                 ;
                           } ;
                         }
#endif

   DATA aRectSave
   DATA oWndParent
   DATA lMaximized INIT .F.
   DATA lSizeBox INIT .F.
   DATA lResult INIT .F.
   DATA aChilds INIT {}
   DATA hActive

   METHOD Activate(lShow, lMaximized, lMinimized, lCentered, bActivate, lModal)
   METHOD onEvent(msg, wParam, lParam)
   METHOD SetParent(oParent) INLINE ::oWndParent := oParent

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate(lShow, lMaximized, lMinimized, lCentered, bActivate, lModal) CLASS HMDIChildWindow

   LOCAL l3d := .F.

   HB_SYMBOL_UNUSED(lShow)
   HB_SYMBOL_UNUSED(lMaximized)
   HB_SYMBOL_UNUSED(lMinimized)
   HB_SYMBOL_UNUSED(lCentered)

   DEFAULT lShow := .T.
   lMinimized := !Empty(lMinimized) .AND. lMinimized .AND. hwg_BitAnd(::style, WS_MINIMIZE) != 0
   lMaximized := !Empty(lMaximized) .AND. lMaximized .AND. (hwg_BitAnd(::style, WS_MAXIMIZE) != 0 .OR. ;
      hwg_BitAnd(::style, WS_SIZEBOX) != 0)
   lCentered := (!lMaximized .AND. !Empty(lCentered) .AND. lCentered) .OR. hwg_BitAND(::Style, DS_CENTER) != 0
   ::lModal := !Empty(lModal) .AND. lModal
   ::lChild := ::lModal .OR. ::lChild .OR. ::minWidth > -1 .OR. ::maxWidth > -1 .OR. ::minHeight > -1 .OR. ;
      ::maxHeight > -1
   ::lSizeBox := hwg_BitAnd(::style, WS_SIZEBOX) != 0
   ::WindowState := IIf(lMinimized, SW_SHOWMINIMIZED, IIf(lMaximized, SW_SHOWMAXIMIZED, IIf(lShow, SW_SHOWNORMAL, 0)))

   CreateGetList(Self)
   // hwg_CreateMdiChildWindow(Self)

   ::Type := WND_MDICHILD
   ::rect := hwg_GetWindowRect(::handle)

   ::GETMDIMAIN():WindowState := GetWindowPlacement(::GETMDIMAIN():handle)
   ::oClient := HWindow():aWindows[2]
   IF lCentered
      ::nLeft := (::oClient:nWidth - ::nWidth) / 2
      ::nTop := (::oClient:nHeight - ::nHeight) / 2
   ENDIF
   ::aRectSave := {::nLeft, ::nTop, ::nwidth, ::nHeight}
   IF hwg_BitAND(::Style, DS_3DLOOK) > 0
      //- efect  border 3d in mdichilds with no sizebox
      ::Style -= DS_3DLOOK
      l3d := .T.
   ENDIF
   ::Style := hwg_BitOr(::Style, WS_VISIBLE) - IIf(!lshow, WS_VISIBLE, 0) + ;
      IIf(lMaximized .AND. !::lChild .AND. !::lModal, WS_MAXIMIZE, 0)
   ::handle := hwg_CreateMdiChildWindow(Self)
   IF hb_IsNumeric(::TITLE) .AND. ::title == -1 // screen
      RETURN .T.
   ENDIF

   IF lCentered
      ::nLeft := (::oClient:nWidth - ::nWidth) / 2
      ::nTop := (::oClient:nHeight - ::nHeight) / 2
   ENDIF

   // is necessary for set zorder control
   //InitControls(Self) ??? maybe

   /*  in ONMDICREATE
   /*
   InitObjects(Self, .T.)
   IF hb_IsBlock(::bInit)
      Eval(::bInit, Self)
   ENDIF
   */
   IF l3D
      // does not allow resizing
      ::minWidth := ::nWidth
      ::minHeight := ::nHeight
      ::maxWidth := ::nWidth
      ::maxHeight := ::nHeight
   ENDIF

   IF lShow
      //-onMove(Self)
      IF lMinimized .OR. ::WindowState == SW_SHOWMINIMIZED
         ::Minimize()
      ELSEIF ::WindowState == SW_SHOWMAXIMIZED .AND. !::IsMaximized()
         ::maximize()
      ENDIF
      //::show()
      //-upDateWindow(::handle)
   ELSE
      hwg_SetWindowPos(::handle, NIL, ::nLeft, ::nTop, ::nWidth, ::nHeight, SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOZORDER)
   ENDIF

   // SCROLLSBARS
   ::RedefineScrollbars()
   /*
   IF ::nScrollBars > - 1
      AEval(::aControls, {|o|::ncurHeight := max(o:nTop + o:nHeight + hwg_GetSystemMetrics(SM_CYMENU) + hwg_GetSystemMetrics(SM_CYCAPTION) + 12 , ::ncurHeight)})
      AEval(::aControls, {|o|::ncurWidth := max(o:nLeft + o:nWidth + 24, ::ncurWidth)})
      ::ResetScrollbars()
      ::SetupScrollbars()
   ENDIF
   */

   IF (hb_IsObject(::nInitFocus) .OR. ::nInitFocus > 0)
      ::nInitFocus := IIf(hb_IsObject(::nInitFocus), ::nInitFocus:handle, ::nInitFocus)
      hwg_SetFocus(::nInitFocus)
      ::nFocus := ::nInitFocus
   ELSEIF PtrtoUlong(hwg_GetFocus()) == PtrtoUlong(::handle) .AND. Len(::acontrols) > 0
      ::nFocus := ASCAN(::aControls, {|o|hwg_BitaND(HWG_GETWINDOWSTYLE(o:handle), WS_TABSTOP) != 0 .AND. ;
         hwg_BitaND(HWG_GETWINDOWSTYLE(o:handle), WS_DISABLED) == 0})
      IF ::nFocus > 0
         hwg_SetFocus(::acontrols[::nFocus]:handle)
         ::nFocus := hwg_GetFocus() //get::acontrols[1]:handle
      ENDIF
   ENDIF

   IF bActivate != NIL
      Eval(bActivate, Self)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HMDIChildWindow

   LOCAL i
   LOCAL oCtrl
   LOCAL nFocus

   nFocus := If(Hb_IsNumeric(::nFocus), ::nFocus, 0)
   //IF msg == WM_NCLBUTTONDBLCLK .AND. ::lChild
   //   RETURN 0

   IF msg == WM_GETMINMAXINFO //= &H24
      IF ::minWidth > -1 .OR. ::maxWidth > -1 .OR. ::minHeight > -1 .OR. ::maxHeight > -1
         MINMAXWINDOW(::handle, lParam, ;
         IIf(::minWidth > -1, ::minWidth, NIL), ;
         IIf(::minHeight > -1, ::minHeight, NIL), ;
         IIf(::maxWidth > -1, ::maxWidth, NIL), ;
         IIf(::maxHeight > -1, ::maxHeight, NIL))
         RETURN 0
      ENDIF
   ELSEIF msg == WM_MOVING .AND. ::lMaximized
      ::Maximize()
   ELSEIF msg == WM_SETFOCUS .AND. nFocus != 0
      hwg_SetFocus(nFocus)
      //-::nFocus := 0
   ELSEIF msg == WM_DESTROY .AND. ::lModal .AND. !hwg_SelfFocus(::Screen:handle, ::handle)
      IF !Empty(::hActive) .AND. !hwg_SelfFocus(::hActive, ::Screen:handle)
         hwg_PostMessage(nFocus, WM_SETFOCUS, 0, 0)
         hwg_PostMessage(::hActive , WM_SETFOCUS, 0, 0)
      ENDIF
      ::GETMDIMAIN():lSuspendMsgsHandling := .F.
   ENDIF

   IF (i := AScan(::aMessages[1], msg)) != 0
      RETURN Eval(::aMessages[2, i], Self, wParam, lParam)
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1
             ::ScrollHV(Self, msg, wParam, lParam)
         ENDIF
         onTrackScroll(Self, msg, wParam, lParam)
      ELSEIF msg == WM_NOTIFY .AND.!::lSuspendMsgsHandling
         IF (oCtrl := ::FindControl(, hwg_GetFocus())) != NIL .AND. oCtrl:ClassName != "HTAB"
            hwg_SendMessage(oCtrl:handle, msg, wParam, lParam)
         ENDIF
      ENDIF
      RETURN ::Super:onEvent(msg, wParam, lParam)
   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HMDIChildWindow

   LOCAL oCtrl
   LOCAL nFocus

   nFocus := IIf(Hb_IsNumeric(::nFocus), ::nFocus, 0)
   //IF msg == WM_NCLBUTTONDBLCLK .AND. ::lChild
   //   RETURN 0

   SWITCH msg

   CASE WM_GETMINMAXINFO //= &H24
      IF ::minWidth > -1 .OR. ::maxWidth > -1 .OR. ::minHeight > -1 .OR. ::maxHeight > -1
         MINMAXWINDOW(::handle, lParam, ;
         IIf(::minWidth > -1, ::minWidth, NIL), ;
         IIf(::minHeight > -1, ::minHeight, NIL), ;
         IIf(::maxWidth > -1, ::maxWidth, NIL), ;
         IIf(::maxHeight > -1, ::maxHeight, NIL))
         RETURN 0
      ENDIF
      EXIT

   CASE WM_MOVING
      IF ::lMaximized
         ::Maximize()
      ENDIF
      EXIT

   CASE WM_SETFOCUS
      IF nFocus != 0
         hwg_SetFocus(nFocus)
         //-::nFocus := 0
      ENDIF
      EXIT

   CASE WM_DESTROY
      IF ::lModal .AND. !hwg_SelfFocus(::Screen:handle, ::handle)
         IF !Empty(::hActive) .AND. !hwg_SelfFocus(::hActive, ::Screen:handle)
            hwg_PostMessage(nFocus, WM_SETFOCUS, 0, 0)
            hwg_PostMessage(::hActive , WM_SETFOCUS, 0, 0)
         ENDIF
         ::GETMDIMAIN():lSuspendMsgsHandling := .F.
      ENDIF

   ENDSWITCH

   SWITCH msg // TODO: juntar com o primeiro SWITCH

   CASE WM_CREATE
      RETURN onMdiCreate(Self, lParam)

   CASE WM_COMMAND
      RETURN onMdiCommand(Self, wParam)

   CASE WM_ERASEBKGND
      RETURN onEraseBk(Self, wParam)

   CASE WM_MOVE
      RETURN onMove(Self)

   CASE WM_SIZE
      RETURN onSize(Self, wParam, lParam)

   CASE WM_NCACTIVATE
      RETURN onMdiNcActivate(Self, wParam)

   CASE WM_SYSCOMMAND
      RETURN onSysCommand(Self, wParam, lParam)

   CASE WM_ENTERIDLE
      RETURN onEnterIdle(Self, wParam, lParam)

   CASE WM_MDIACTIVATE
      RETURN onMdiActivate(Self, wParam, lParam)

   CASE WM_DESTROY
      RETURN onDestroy(Self)

   CASE WM_HSCROLL
   CASE WM_VSCROLL
   CASE WM_MOUSEWHEEL
      IF ::nScrollBars != -1
         ::ScrollHV(Self, msg, wParam, lParam)
      ENDIF
      onTrackScroll(Self, msg, wParam, lParam)
      RETURN ::Super:onEvent(msg, wParam, lParam)

   CASE WM_NOTIFY
      IF !::lSuspendMsgsHandling
         IF (oCtrl := ::FindControl(, hwg_GetFocus())) != NIL .AND. oCtrl:ClassName != "HTAB"
            hwg_SendMessage(oCtrl:handle, msg, wParam, lParam)
         ENDIF
      ENDIF
      RETURN ::Super:onEvent(msg, wParam, lParam)

   #ifdef __XHARBOUR__
   DEFAULT
   #else
   OTHERWISE
   #endif

      RETURN ::Super:onEvent(msg, wParam, lParam)

   ENDSWITCH

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onSize(oWnd, wParam, lParam)

   LOCAL aCoors := hwg_GetWindowRect(oWnd:handle)

   IF oWnd:oEmbedded != NIL
      oWnd:oEmbedded:Resize(hwg_LOWORD(lParam), hwg_HIWORD(lParam))
   ENDIF
   //hwg_InvalidateRect(oWnd:handle, 0)
   oWnd:Super:onEvent(WM_SIZE, wParam, lParam)

   oWnd:nWidth := aCoors[3] - aCoors[1]
   oWnd:nHeight := aCoors[4] - aCoors[2]

   IF hb_IsBlock(oWnd:bSize)
      Eval(oWnd:bSize, oWnd, hwg_LOWORD(lParam), hwg_HIWORD(lParam))
   ENDIF
   IF oWnd:Type == WND_MDI .AND. Len(HWindow():aWindows) > 1
      aCoors := hwg_GetClientRect(oWnd:handle)
      //hwg_MoveWindow(HWindow():aWindows[2]:handle, oWnd:aOffset[1], oWnd:aOffset[2], ;
      //   aCoors[3] - oWnd:aOffset[1] - oWnd:aOffset[3], aCoors[4] - oWnd:aOffset[2] - oWnd:aOffset[4])
      //aCoors := hwg_GetClientRect(HWindow():aWindows[2]:handle)
      hwg_SetWindowPos(HWindow():aWindows[2]:handle, NIL, oWnd:aOffset[1], oWnd:aOffset[2], ;
         aCoors[3] - oWnd:aOffset[1] - oWnd:aOffset[3], aCoors[4] - oWnd:aOffset[2] - oWnd:aOffset[4], ;
         SWP_NOZORDER + SWP_NOACTIVATE + SWP_NOSENDCHANGING)
      aCoors := hwg_GetWindowRect(HWindow():aWindows[2]:handle)
      HWindow():aWindows[2]:nWidth  := aCoors[3] - aCoors[1]
      HWindow():aWindows[2]:nHeight := aCoors[4] - aCoors[2]
      // ADDED =
      IF !Empty(oWnd:Screen)
          oWnd:Screen:nWidth := aCoors[3] - aCoors[1]
          oWnd:Screen:nHeight := aCoors[4] - aCoors[2]
          //hwg_InvalidateRect(oWnd:Screen:handle, 1) // flick in screen in resize window
          hwg_SetWindowPos(oWnd:screen:handle, NIL, 0, 0, oWnd:Screen:nWidth, oWnd:Screen:nHeight, ;
             SWP_NOACTIVATE + SWP_NOSENDCHANGING + SWP_NOZORDER)
          hwg_InvalidateRect(oWnd:Screen:handle, 1)
      ENDIF
      IF !Empty(oWnd := oWnd:GetMdiActive()) .AND.oWnd:type == WND_MDICHILD .AND. oWnd:lMaximized .AND. ;
         (oWnd:lModal .OR. oWnd:lChild)
         oWnd:lMaximized := .F.
         //-hwg_SendMessage(oWnd:handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0)
      ENDIF
      //
      RETURN 0
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onDestroy(oWnd)

   IF oWnd:oEmbedded != NIL
      oWnd:oEmbedded:END()
   ENDIF
   oWnd:Super:onEvent(WM_DESTROY)
   HWindow():DelItem(oWnd)

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onEraseBk(oWnd, wParam)

   LOCAL aCoors
   LOCAL oWndArea

   IF oWnd:oBmp != NIL .AND. oWnd:type != WND_MDI
       oWndArea := IIf(oWnd:type != WND_MAIN, oWnd:oClient, oWnd)
       IF oWnd:lBmpCenter
          CenterBitmap(wParam, oWndArea:handle, oWnd:oBmp:handle, , oWnd:nBmpClr)
       ELSE
          SpreadBitmap(wParam, oWndArea:handle, oWnd:oBmp:handle)
       ENDIF
       RETURN 1
   ELSEIF oWnd:type != WND_MDI //.AND. oWnd:type != WND_MAIN
      aCoors := hwg_GetClientRect(oWnd:handle)
      IF oWnd:brush != NIL
         IF !hb_IsNumeric(oWnd:brush)
            FillRect(wParam, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, oWnd:brush:handle)
            IF !Empty(oWnd:Screen) .AND. hwg_SelfFocus(oWnd:handle, oWnd:Screen:handle)
               hwg_SetWindowPos(oWnd:handle, HWND_BOTTOM, 0, 0, 0, 0, ;
                  SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER + SWP_NOOWNERZORDER)
            ENDIF
            RETURN 1
         ENDIF
      ELSEIF oWnd:Type != WND_MAIN
         FillRect(wParam, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, COLOR_3DFACE + 1)
         RETURN 1
      ENDIF
    ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onSysCommand(oWnd, wParam, lParam)

   LOCAL i
   LOCAL ars
   LOCAL oChild
   LOCAL oCtrl

   IF wParam == SC_CLOSE
      IF hb_IsBlock(oWnd:bDestroy)
         oWnd:lSuspendMsgsHandling := .T.
         i := Eval(oWnd:bDestroy, oWnd)
         oWnd:lSuspendMsgsHandling := .F.
         i := IIf(hb_IsLogical(i), i, .T.)
         IF !i
            RETURN 0
         ENDIF
         oWnd:bDestroy := NIL
      ENDIF
      IF __ObjHasMsg(oWnd, "ONOTIFYICON") .AND. oWnd:oNotifyIcon != NIL
         hwg_ShellNotifyIcon(.F., oWnd:handle, oWnd:oNotifyIcon:handle)
      ENDIF
      IF __ObjHasMsg(oWnd, "HACCEL") .AND. oWnd:hAccel != NIL
         DestroyAcceleratorTable(oWnd:hAccel)
      ENDIF
      RETURN - 1
   ENDIF

   oWnd:WindowState := GetWindowPlacement(oWnd:handle)
   IF wParam == SC_MINIMIZE
      IF __ObjHasMsg(oWnd, "LTRAY") .AND. oWnd:lTray
         oWnd:Hide()
         RETURN 0
      ENDIF
      hwg_SetWindowPos(oWnd:handle, HWND_BOTTOM, 0, 0, 0, 0, ;
         SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER + SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
   ELSEIF (wParam == SC_MAXIMIZE .OR. wparam == SC_MAXIMIZE2) .AND. oWnd:type == WND_MDICHILD .AND. ;
      (oWnd:lChild .OR. oWnd:lModal)
      IF oWnd:WindowState == SW_SHOWMINIMIZED
          hwg_SendMessage(oWnd:handle, WM_SYSCOMMAND, SC_RESTORE, 0)
          hwg_SendMessage(oWnd:handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0)
          RETURN 0
      ENDIF
      ars := aClone(oWnd:aRectSave)
      IF oWnd:lMaximized
         // restore
         IF oWnd:lSizeBox
            HWG_SETWINDOWSTYLE(oWnd:handle, HWG_GETWINDOWSTYLE(oWnd:handle) + WS_SIZEBOX)
         ENDIF
         hwg_MoveWindow(oWnd:handle, oWnd:aRectSave[1], oWnd:aRectSave[2], oWnd:aRectSave[3], oWnd:aRectSave[4])
         hwg_MoveWindow(oWnd:handle, oWnd:aRectSave[1] - (oWnd:nLeft - oWnd:aRectSave[1]), ;
            oWnd:aRectSave[2] - (oWnd:nTop - oWnd:aRectSave[2]), oWnd:aRectSave[3], oWnd:aRectSave[4])
      ELSE
          // maximized
          IF oWnd:lSizeBox
             HWG_SETWINDOWSTYLE(oWnd:handle, HWG_GETWINDOWSTYLE(oWnd:handle) - WS_SIZEBOX)
          ENDIF
         hwg_MoveWindow(oWnd:handle, oWnd:oClient:nLeft, oWnd:oClient:nTop, oWnd:oClient:nWidth, oWnd:oClient:nHeight)
      ENDIF
      oWnd:aRectSave := aClone(ars)
      oWnd:lMaximized := !oWnd:lMaximized
      RETURN 0
   ELSEIF (wParam == SC_MAXIMIZE .OR. wparam == SC_MAXIMIZE2) //.AND. oWnd:type != WND_MDICHILD
   ELSEIF wParam == SC_RESTORE .OR. wParam == SC_RESTORE2
   ELSEIF wParam == SC_NEXTWINDOW .OR. wParam == SC_PREVWINDOW
      // ctrl+tab IN Mdi child
      IF !Empty(oWnd:lDisableCtrlTab) .AND. oWnd:lDisableCtrlTab
         RETURN 0
      ENDIF
   ELSEIF wParam == SC_KEYMENU
      // accelerator MDICHILD
      IF Len(HWindow():aWindows) > 2 .AND. ((oChild := oWnd):Type == WND_MDICHILD .OR. ;
         !Empty(oChild := oWnd:GetMdiActive()))
         IF (oCtrl := FindAccelerator(oChild, lParam)) != NIL
            oCtrl:SetFocus()
            hwg_SendMessage(oCtrl:handle, WM_SYSKEYUP, lParam, 0)
            RETURN - 2
            // MNC_IGNORE = 0  MNC_CLOSE = 1  MNC_EXECUTE = 2  MNC_SELECT = 3
         ENDIF
      ENDIF
   ELSEIF wParam == SC_HOTKEY
   //ELSEIF wParam == SC_MOUSEMENU  //0xF090
   ELSEIF wParam == SC_MENU .AND. (oWnd:type == WND_MDICHILD .OR. !Empty(oWnd := oWnd:GetMdiActive())) .AND. oWnd:lModal
      hwg_MsgBeep()
      RETURN 0
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onMdiCreate(oWnd, lParam)

   LOCAL nReturn

   HB_SYMBOL_UNUSED(lParam)

   IF hb_IsBlock(oWnd:bSetForm)
      Eval(oWnd:bSetForm, oWnd)
   ENDIF
   IF !EMPTY(oWnd:oWndParent)
      oWnd:oParent := oWnd:oWndParent
   ENDIF
   IF !oWnd:lClosable
      oWnd:Closable(.F.)
   ENDIF
   IF oWnd:oFont != NIL
      hwg_SendMessage(oWnd:handle, WM_SETFONT, oWnd:oFont:handle, 0)
   ENDIF
   InitControls(oWnd)
   InitObjects(oWnd, .T.)
   IF oWnd:bInit != NIL
      IF !hb_IsNumeric(nReturn := Eval(oWnd:bInit, oWnd))
         IF hb_IsLogical(nReturn) .AND. !nReturn
            oWnd:Close()
            RETURN NIL
         ENDIF
      ENDIF
   ENDIF
   //draw rect focus
   oWnd:nInitFocus := IIf(hb_IsObject(oWnd:nInitFocus), oWnd:nInitFocus:handle, oWnd:nInitFocus)
   hwg_SendMessage(oWnd:handle, WM_UPDATEUISTATE, makelong(UIS_CLEAR, UISF_HIDEFOCUS), 0)
   hwg_SendMessage(oWnd:handle, WM_UPDATEUISTATE, makelong(UIS_CLEAR, UISF_HIDEACCEL), 0)
   IF oWnd:WindowState > 0
      onMove(oWnd)
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onMdiCommand(oWnd, wParam)

   LOCAL iParHigh
   LOCAL iParLow
   LOCAL iItem
   LOCAL aMenu
   LOCAL oCtrl

   IF wParam == SC_CLOSE
      hwg_SendMessage(HWindow():aWindows[2]:handle, WM_MDIDESTROY, oWnd:handle, 0)
   ENDIF
   iParHigh := hwg_HIWORD(wParam)
   iParLow := hwg_LOWORD(wParam)
   IF hwg_IsWindowVisible(oWnd:handle)
      oCtrl := oWnd:FindControl(iParLow)
   ENDIF
   IF oWnd:aEvents != NIL .AND. !oWnd:lSuspendMsgsHandling .AND. ;
      (iItem := AScan(oWnd:aEvents, {|a|a[1] == iParHigh .AND. a[2] == iParLow})) > 0
      IF PtrtouLong(hwg_GetParent(hwg_GetFocus())) == PtrtouLong(oWnd:handle)
         oWnd:nFocus := hwg_GetFocus()
      ENDIF
      Eval(oWnd:aEvents[iItem, 3], oWnd, iParLow)
   ELSEIF __ObjHasMsg(oWnd, "OPOPUP") .AND. oWnd:oPopup != NIL .AND. ;
      (aMenu := hwg_FindMenuItem(oWnd:oPopup:aMenu, wParam, @iItem)) != NIL .AND. aMenu[1, iItem, 1] != NIL
      Eval(aMenu[1, iItem, 1], wParam)
   ELSEIF iParHigh == 1 // acelerator
   ENDIF
   IF oCtrl != NIL .AND. hwg_BitaND(HWG_GETWINDOWSTYLE(oCtrl:handle), WS_TABSTOP) != 0 .AND. hwg_GetFocus() == oCtrl:handle
      oWnd:nFocus := oCtrl:handle
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onMdiNcActivate(oWnd, wParam)

   IF !Empty(oWnd:Screen)
      IF wParam == 1 .AND. hwg_SelfFocus(oWnd:Screen:handle, oWnd:handle)
         hwg_SetWindowPos(oWnd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE)
         RETURN 1
      ENDIF
      IF wParam == 1 .AND. !hwg_SelfFocus(oWnd:Screen:handle, oWnd:handle)
         // triggered ON GETFOCUS MDI CHILD MAXIMIZED
         IF hb_IsBlock(oWnd:bSetForm)
            Eval(oWnd:bSetForm, oWnd)
         ENDIF
         IF !oWnd:lSuspendMsgsHandling .AND.;
            oWnd:bGetFocus != NIL .AND. !Empty(hwg_GetFocus()) .AND. oWnd:IsMaximized()
            oWnd:lSuspendMsgsHandling := .T.
            Eval(oWnd:bGetFocus, oWnd)
            oWnd:lSuspendMsgsHandling := .F.
          ENDIF
      ENDIF
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onMdiActivate(oWnd, wParam, lParam)

   LOCAL lScreen := oWnd:Screen != NIL
   LOCAL aWndMain
   LOCAL oWndDeact
   LOCAL lConf

   IF ValType(wParam) == ValType(oWnd:handle)
      lConf := wParam == oWnd:handle
   ELSE
      lConf := .F.
   ENDIF
   // added

   IF !Empty(wParam)
      oWndDeact := oWnd:FindWindow(wParam)
      IF oWnd:lChild .AND. oWnd:lmaximized .AND. oWnd:IsMaximized()
         oWnd:Restore()
      ENDIF
      IF oWndDeact != NIL .AND. oWndDeact:lModal
         AAdd(oWndDeact:aChilds, lParam)
         AAdd(oWnd:aChilds, wParam)
         oWnd:lModal := .T.
      ELSEIF oWndDeact != NIL .AND. !oWndDeact:lModal
         oWnd:hActive := wParam
      ENDIF
   ENDIF

   IF lScreen .AND. (Empty(lParam) .OR. hwg_SelfFocus(lParam, oWnd:Screen:handle)) .AND. !lConf //wParam != oWnd:handle
      //-hwg_SetWindowPos(oWnd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE)
      RETURN 0
   ELSEIF lConf //oWnd:handle == wParam
      IF !hwg_SelfFocus(oWnd:Screen:handle, wParam) .AND. oWnd:bLostFocus != NIL //.AND.wParam == 0
         oWnd:lSuspendMsgsHandling := .T.
         //IF oWnd:Screen:handle == lParam
         //   hwg_SetWindowPos(oWnd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE)
         //ENDIF
         Eval(oWnd:bLostFocus, oWnd)
         oWnd:lSuspendMsgsHandling := .F.
      ENDIF
      IF oWnd:lModal
         aWndMain := oWnd:GETMAIN():aWindows
         AEval(aWndMain, {|w|IIf(w:Type >= WND_MDICHILD .AND. PtrtoUlong(w:handle) != PtrtoUlong(wParam), ;
            hwg_EnableWindow(w:handle, .T.),)})
      ENDIF
   ELSEIF hwg_SelfFocus(oWnd:handle, lParam) //.AND. ownd:screen:handle != WPARAM
      IF hb_IsBlock(oWnd:bSetForm)
         Eval(oWnd:bSetForm, oWnd)
      ENDIF
      IF oWnd:lModal
         aWndMain := oWnd:GETMAIN():aWindows
         AEval(aWndMain, {|w|IIf(w:Type >= WND_MDICHILD .AND. PtrtoUlong(w:handle) != PtrtoUlong(lParam), ;
            hwg_EnableWindow(w:handle, .F.),)})
         AEval(oWnd:aChilds,{|wH|hwg_EnableWindow(wH, .T.)})
     ENDIF
      IF oWnd:bGetFocus != NIL .AND. !oWnd:lSuspendMsgsHandling .AND. !oWnd:IsMaximized()
         oWnd:lSuspendMsgsHandling := .T.
         IF Empty(oWnd:nFocus)
            UpdateWindow(oWnd:handle)
         ENDIF
         Eval(oWnd:bGetFocus, oWnd)
         oWnd:lSuspendMsgsHandling := .F.
      ENDIF
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onEnterIdle(oDlg, wParam, lParam)

   LOCAL oItem

   HB_SYMBOL_UNUSED(oDlg)

   IF wParam == 0 .AND. (oItem := ATail(HDialog():aModalDialogs)) != NIL .AND. oItem:handle == lParam .AND. ;
      !oItem:lActivated
      oItem:lActivated := .T.
      IF oItem:bActivate != NIL
         Eval(oItem:bActivate, oItem)
      ENDIF
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//
