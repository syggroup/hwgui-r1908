//
// $Id: hwindow.prg 1904 2012-09-21 11:43:56Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HChildWindow class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define FIRST_MDICHILD_ID 501
#define MAX_MDICHILD_WINDOWS 18
#define WM_NOTIFYICON WM_USER + 1000
#define ID_NOTIFYICON 1
#define FLAG_CHECK 2

//-------------------------------------------------------------------------------------------------------------------//

CLASS HChildWindow INHERIT HWindow

   DATA oNotifyMenu

   METHOD New(oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, bInit, bExit, bSize, bPaint, bGfocus, ;
      bLfocus, bOther, cAppName, oBmp, cHelp, nHelpId, bRefresh)
   METHOD Activate(lShow, lMaximized, lMinimized, lCentered, bActivate, lModal)
   METHOD onEvent(msg, wParam, lParam)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, bInit, bExit, bSize, bPaint, bGfocus, ;
   bLfocus, bOther, cAppName, oBmp, cHelp, nHelpId, bRefresh) CLASS HChildWindow

   ::Super:New(oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, bInit, bExit, bSize, bPaint, bGfocus, ;
      bLfocus, bOther, cAppName, oBmp, cHelp, nHelpId, , bRefresh)
   ::oParent := HWindow():GetMain()
   ::Type := WND_CHILD
   ::rect := hwg_GetWindowRect(::handle)
   IF ISOBJECT(::oParent)
      ::handle := hwg_InitChildWindow(Self, ::szAppName, cTitle, cMenu, IIf(oIcon != NIL, oIcon:handle, NIL), ;
         IIf(oBmp != NIL, -1, clr), nStyle, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::oParent:handle)
   ELSE
      hwg_MsgStop("Create Main window first !", "HChildWindow():New()")
      RETURN NIL
   ENDIF
   //IF hb_IsBlock(::bInit)
   //   Eval(::bInit, Self)
   //ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate(lShow, lMaximized, lMinimized, lCentered, bActivate, lModal) CLASS HChildWindow

   LOCAL nReturn

   HB_SYMBOL_UNUSED(lModal)

   DEFAULT lShow TO .T.
   lMinimized := !Empty(lMinimized) .AND. lMinimized .AND. hwg_BitAnd(::style, WS_MINIMIZE) != 0
   lMaximized := !Empty(lMaximized) .AND. lMaximized .AND. hwg_BitAnd(::style, WS_MAXIMIZE) != 0

   ::Type := WND_CHILD

   CreateGetList(Self)
   InitControls(SELF)
   InitObjects(Self, .T.)
   hwg_SendMessage(::handle, WM_UPDATEUISTATE, makelong(UIS_CLEAR, UISF_HIDEFOCUS), 0)
   IF hb_IsBlock(::bInit)
      //::hide()
      IF !hb_IsNumeric(nReturn := Eval(::bInit, Self))
         IF hb_IsLogical(nReturn) .AND. !nReturn
            ::Close()
            RETURN NIL
         ENDIF
      ENDIF
   ENDIF

   hwg_ActivateChildWindow(lShow, ::handle, lMaximized, lMinimized)

   IF !Empty(lCentered) .AND. lCentered
      IF !Empty(::oParent)
        ::nLeft := (::oParent:nWidth - ::nWidth) / 2
        ::nTop := (::oParent:nHeight - ::nHeight) / 2
      ENDIF
   ENDIF

   hwg_SetWindowPos(::handle, HWND_TOP, ::nLeft, ::nTop, 0, 0, SWP_NOSIZE + SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
   IF bActivate != NIL
      Eval(bActivate, Self)
   ENDIF

   IF hb_IsObject(::nInitFocus) .OR. ::nInitFocus > 0
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

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HChildWindow

   LOCAL i
   LOCAL oCtrl

   IF msg == WM_DESTROY
      RETURN onDestroy(Self)
   ELSEIF msg == WM_SIZE
      RETURN onSize(Self, wParam, lParam)
   ELSEIF msg == WM_SETFOCUS .AND. ::nFocus != 0
      hwg_SetFocus(::nFocus)
   ELSEIF (i := AScan(HMainWindow():aMessages[1], msg)) != 0
      RETURN Eval(HMainWindow():aMessages[2, i], Self, wParam, lParam)
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .OR. msg == WM_MOUSEWHEEL
         onTrackScroll(Self, msg, wParam, lParam)
      ELSEIF msg == WM_NOTIFY .AND. !::lSuspendMsgsHandling
         IF (oCtrl := ::FindControl(wParam)) != NIL .AND. oCtrl:className != "HTAB"
            ::nFocus := oCtrl:handle
            hwg_SendMessage(oCtrl:handle, msg, wParam, lParam)
         ENDIF
      ENDIF
      RETURN ::Super:onEvent(msg, wParam, lParam)
   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HChildWindow

   LOCAL oCtrl

   SWITCH msg

   CASE WM_DESTROY
      RETURN onDestroy(Self)

   CASE WM_SIZE
      RETURN onSize(Self, wParam, lParam)

   CASE WM_SETFOCUS
      IF ::nFocus != 0
         hwg_SetFocus(::nFocus)
      ENDIF
      RETURN ::Super:onEvent(msg, wParam, lParam)

   CASE WM_COMMAND
      RETURN onCommand(Self, wParam, lParam)

   CASE WM_ERASEBKGND
      RETURN onEraseBk(Self, wParam)

   CASE WM_MOVE
      RETURN onMove(Self)

   CASE WM_SYSCOMMAND
      RETURN onSysCommand(Self, wParam, lParam)

   CASE WM_NOTIFYICON
      RETURN onNotifyIcon(Self, wParam, lParam)

   CASE WM_ENTERIDLE
      RETURN onEnterIdle(Self, wParam, lParam)

   CASE WM_CLOSE
      RETURN onCloseQuery(Self)

   CASE WM_ENDSESSION
      RETURN onEndSession(Self, wParam)

   CASE WM_ACTIVATE
      RETURN onActivate(Self, wParam, lParam)

   CASE WM_HELP
      RETURN onHelp(Self, wParam, lParam)

   CASE WM_HSCROLL
   CASE WM_VSCROLL
   CASE WM_MOUSEWHEEL
      onTrackScroll(Self, msg, wParam, lParam)
      RETURN ::Super:onEvent(msg, wParam, lParam)

   CASE WM_NOTIFY
      IF !::lSuspendMsgsHandling
         IF (oCtrl := ::FindControl(wParam)) != NIL .AND. oCtrl:className != "HTAB"
            ::nFocus := oCtrl:handle
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
      //hwg_MoveWindow(HWindow():aWindows[2]:handle, oWnd:aOffset[1], oWnd:aOffset[2], aCoors[3] - oWnd:aOffset[1] - oWnd:aOffset[3], aCoors[4] - oWnd:aOffset[2] - oWnd:aOffset[4])
      //aCoors := hwg_GetClientRect(HWindow():aWindows[2]:handle)
      hwg_SetWindowPos(HWindow():aWindows[2]:handle, NIL, oWnd:aOffset[1], oWnd:aOffset[2], aCoors[3] - oWnd:aOffset[1] - oWnd:aOffset[3], aCoors[4] - oWnd:aOffset[2] - oWnd:aOffset[4] , SWP_NOZORDER + SWP_NOACTIVATE + SWP_NOSENDCHANGING)
      aCoors := hwg_GetWindowRect(HWindow():aWindows[2]:handle)
      HWindow():aWindows[2]:nWidth := aCoors[3] - aCoors[1]
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
      IF !Empty(oWnd := oWnd:GetMdiActive()) .AND. oWnd:type == WND_MDICHILD .AND. oWnd:lMaximized .AND. ;
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

STATIC FUNCTION onCommand(oWnd, wParam, lParam)

   LOCAL iItem
   LOCAL iCont
   LOCAL aMenu
   LOCAL iParHigh
   LOCAL iParLow
   LOCAL nHandle
   LOCAL oChild
   LOCAL i

   HB_SYMBOL_UNUSED(lParam)

   IF wParam >= FIRST_MDICHILD_ID .AND. wparam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS .AND. !Empty(oWnd:Screen)
      IF wParam >= FIRST_MDICHILD_ID
         hwg_SetWindowPos(ownd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, ;
            SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE)
      ENDIF
      //-wParam += IIf(hwg_IsWindowEnabled(oWnd:Screen:handle), 0, 1)
   ENDIF
   IF wParam == SC_CLOSE
      IF Len(HWindow():aWindows) > 2 .AND. ;
         (nHandle := hwg_SendMessage(HWindow():aWindows[2]:handle, WM_MDIGETACTIVE, 0, 0)) > 0
         // CLOSE ONLY MDICHILD HERE
         oChild := oWnd:FindWindow(nHandle)
         IF oChild != NIL
            IF !oChild:Closable
               RETURN 0
            ELSEIF hb_IsBlock(oChild:bDestroy)
               oChild:lSuspendMsgsHandling := .T.
               i := Eval(oChild:bDestroy, oChild)
               oChild:lSuspendMsgsHandling := .F.
               i := IIf(hb_IsLogical(i), i, .T.)
               IF !i
                  RETURN 0
               ENDIF
            ENDIF
         ENDIF
         hwg_SendMessage(HWindow():aWindows[2]:handle, WM_MDIDESTROY, nHandle, 0)
      ENDIF
   ELSEIF wParam == SC_RESTORE
      IF Len(HWindow():aWindows) > 2 .AND. ;
         (nHandle := hwg_SendMessage(HWindow():aWindows[2]:handle, WM_MDIGETACTIVE, 0, 0)) > 0
         hwg_SendMessage(HWindow():aWindows[2]:handle, WM_MDIRESTORE, nHandle, 0)
      ENDIF
   ELSEIF wParam == SC_MAXIMIZE
      IF Len(HWindow():aWindows) > 2 .AND. ;
         (nHandle := hwg_SendMessage(HWindow():aWindows[2]:handle, WM_MDIGETACTIVE, 0, 0)) > 0
         hwg_SendMessage(HWindow():aWindows[2]:handle, WM_MDIMAXIMIZE, nHandle, 0)
      ENDIF
   ELSEIF wParam > FIRST_MDICHILD_ID .AND. wParam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS
      IF oWnd:bMdiMenu != NIL
         Eval(oWnd:bMdiMenu, HWindow():aWindows[wParam - FIRST_MDICHILD_ID + 2], wParam)
      ENDIF
      nHandle := HWindow():aWindows[wParam - FIRST_MDICHILD_ID + 2]:handle
      hwg_SendMessage(HWindow():aWindows[2]:handle, WM_MDIACTIVATE, nHandle, 0)
   ENDIF
   iParHigh := hwg_HIWORD(wParam)
   iParLow := hwg_LOWORD(wParam)
   IF oWnd:aEvents != NIL .AND. !oWnd:lSuspendMsgsHandling .AND. ;
      (iItem := AScan(oWnd:aEvents, {|a|a[1] == iParHigh .AND. a[2] == iParLow})) > 0
      Eval(oWnd:aEvents[iItem, 3], oWnd, iParLow)
   ELSEIF hb_IsArray(oWnd:menu) .AND. ;
      (aMenu := hwg_FindMenuItem(oWnd:menu, iParLow, @iCont)) != NIL
      IF hwg_BitAnd(aMenu[1, iCont, 4], FLAG_CHECK) > 0
         CheckMenuItem(, aMenu[1, iCont, 3], !IsCheckedMenuItem(, aMenu[1, iCont, 3]))
      ENDIF
      IF aMenu[1, iCont, 1] != NIL
         Eval(aMenu[1, iCont, 1], iCont, iParLow)
      ENDIF
   ELSEIF oWnd:oPopup != NIL .AND. (aMenu := hwg_FindMenuItem(oWnd:oPopup:aMenu, wParam, @iCont)) != NIL ;
      .AND. aMenu[1, iCont, 1] != NIL
      Eval(aMenu[1, iCont, 1], iCont, wParam)
   ELSEIF oWnd:oNotifyMenu != NIL .AND. (aMenu := hwg_FindMenuItem(oWnd:oNotifyMenu:aMenu, wParam, @iCont)) != NIL ;
      .AND. aMenu[1, iCont, 1] != NIL
      Eval(aMenu[1, iCont, 1], iCont, wParam)
   ELSEIF wParam != SC_CLOSE .AND. wParam != SC_MINIMIZE .AND. wParam != SC_MAXIMIZE .AND. ;
      wParam != SC_RESTORE .AND. oWnd:Type == WND_MDI //.AND. oWnd:bMdiMenu != NIL
      /*
      // ADDED
      IF !Empty(oWnd:Screen)
         IF wParam == FIRST_MDICHILD_ID // first menu
            IF hwg_IsWindowEnabled(oWnd:Screen:handle)
               hwg_SetWindowPos(oWnd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, ;
                  SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER + SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
            ENDIF
            RETURN -1
         ENDIF
      ENDIF
      // menu MDICHILD
      IF oWnd:bMdiMenu != NIL
         Eval(oWnd:bMdiMenu, oWnd:GetMdiActive(), wParam)
      ENDIF
      */
      RETURN IIf(!Empty(oWnd:Screen), -1, 0)
      // end added
   ENDIF

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
      RETURN -1
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
      // ctrl+tab   IN Mdi child
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
            RETURN -2
            // MNC_IGNORE = 0  MNC_CLOSE = 1  MNC_EXECUTE = 2  MNC_SELECT = 3
         ENDIF
      ENDIF
   ELSEIF wParam == SC_HOTKEY
   //ELSEIF wParam == SC_MOUSEMENU //0xF090
   ELSEIF wParam == SC_MENU .AND. (oWnd:type == WND_MDICHILD .OR. !Empty(oWnd := oWnd:GetMdiActive())) .AND. oWnd:lModal
      hwg_MsgBeep()
      RETURN 0
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onEndSession(oWnd, wParam)

   LOCAL i

   HB_SYMBOL_UNUSED(wParam)

   IF hb_IsBlock(oWnd:bDestroy)
      i := Eval(oWnd:bDestroy, oWnd)
      i := IIf(hb_IsLogical(i), i, .T.)
      IF !i
         RETURN 0
      ENDIF
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onNotifyIcon(oWnd, wParam, lParam)

   LOCAL ar

   IF wParam == ID_NOTIFYICON
      IF PtrtoUlong(lParam) == WM_LBUTTONDOWN
         IF hb_IsBlock(oWnd:bNotify)
            Eval(oWnd:bNotify)
         ENDIF
      ELSEIF PtrtoUlong(lParam) == WM_MOUSEMOVE
         //IF hb_IsBlock(oWnd:bNotify)
         //   oWnd:lSuspendMsgsHandling := .T.
         //   Eval(oWnd:bNotify)
         //   oWnd:lSuspendMsgsHandling := .F.
         //ENDIF
      ELSEIF PtrtoUlong(lParam) == WM_RBUTTONDOWN
         IF oWnd:oNotifyMenu != NIL
            ar := hwg_GetCursorPos()
            oWnd:oNotifyMenu:Show(oWnd, ar[1], ar[2])
         ENDIF
      ENDIF
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onEnterIdle(oDlg, wParam, lParam)

   LOCAL oItem

   HB_SYMBOL_UNUSED(oDlg)

   IF wParam == 0 .AND. (oItem := ATail(HDialog():aModalDialogs)) != NIL .AND. ;
      oItem:handle == lParam .AND. !oItem:lActivated
      oItem:lActivated := .T.
      IF oItem:bActivate != NIL
         Eval(oItem:bActivate, oItem)
      ENDIF
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

//add by sauli
STATIC FUNCTION onCloseQuery(o)

   IF hb_IsBlock(o:bCloseQuery)
      IF Eval(o:bCloseQuery)
         ReleaseAllWindows(o:handle)
      END
   ELSE
      ReleaseAllWindows(o:handle)
   END

RETURN -1
// end sauli

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onActivate(oWin, wParam, lParam)

   LOCAL iParLow := hwg_LOWORD(wParam)
   LOCAL iParHigh := hwg_HIWORD(wParam)

   HB_SYMBOL_UNUSED(lParam)

   IF (iParLow == WA_ACTIVE .OR. iParLow == WA_CLICKACTIVE) .AND. hwg_IsWindowVisible(oWin:handle)
      IF (oWin:type == WND_MDICHILD .AND. PtrtoUlong(lParam) == 0) .OR. (oWin:type != WND_MDICHILD .AND. iParHigh == 0)
         IF oWin:bGetFocus != NIL //.AND. hwg_IsWindowVisible(::handle)
            oWin:lSuspendMsgsHandling := .T.
            IF iParHigh > 0 // MINIMIZED
               //oWin:restore()
            ENDIF
            Eval(oWin:bGetFocus, oWin, lParam)
            oWin:lSuspendMsgsHandling := .F.
         ENDIF
      ENDIF
   ELSEIF iParLow == WA_INACTIVE
      IF (oWin:type == WND_MDICHILD .AND. PtrtoUlong(lParam) != 0) .OR. ;
         (oWin:type != WND_MDICHILD .AND. iParHigh == 0 .AND. PtrtoUlong(lParam) == 0)
         IF oWin:bLostFocus != NIL //.AND. hwg_IsWindowVisible(::handle)
            oWin:lSuspendMsgsHandling := .T.
            Eval(oWin:bLostFocus, oWin, lParam)
            oWin:lSuspendMsgsHandling := .F.
         ENDIF
      ENDIF
   ENDIF

RETURN 1

//-------------------------------------------------------------------------------------------------------------------//
