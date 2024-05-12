/*
 *$Id: hwindow.prg 1904 2012-09-21 11:43:56Z lfbasso $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HChildWindow class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  FIRST_MDICHILD_ID     501
#define  MAX_MDICHILD_WINDOWS   18
#define  WM_NOTIFYICON         WM_USER + 1000
#define  ID_NOTIFYICON           1

CLASS HChildWindow INHERIT HWindow

   DATA oNotifyMenu

   METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
               bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
               cAppName, oBmp, cHelp, nHelpId, bRefresh )
   METHOD Activate(lShow, lMaximized, lMinimized, lCentered, bActivate, lModal)
   METHOD onEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
            bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bRefresh ) CLASS HChildWindow

   ::Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
              bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
              cAppName, oBmp, cHelp, nHelpId,, bRefresh )
   ::oParent := HWindow():GetMain()
   ::Type := WND_CHILD
   ::rect := GetWindowRect(::handle)
   IF ISOBJECT(::oParent)
      ::handle := Hwg_InitChildWindow(Self, ::szAppName, cTitle, cMenu, ;
                                      IIf( oIcon != Nil, oIcon:handle, Nil ), IIf( oBmp != Nil, - 1, clr ), nStyle, ::nLeft, ;
                                      ::nTop, ::nWidth, ::nHeight, ::oParent:handle)
   ELSE
      MsgStop("Create Main window first !", "HChildWindow():New()")
      RETURN Nil
   ENDIF
   /*
   IF hb_IsBlock(::bInit)
      Eval( ::bInit, Self )
   ENDIF
    */
   RETURN Self

METHOD Activate(lShow, lMaximized, lMinimized, lCentered, bActivate, lModal) CLASS HChildWindow
   LOCAL nReturn

   HB_SYMBOL_UNUSED(lModal)

   DEFAULT lShow := .T.
   lMinimized := !Empty(lMinimized) .AND. lMinimized .AND. Hwg_BitAnd(::style, WS_MINIMIZE) != 0
   lMaximized := !Empty(lMaximized) .AND. lMaximized .AND. Hwg_BitAnd(::style, WS_MAXIMIZE) != 0

   ::Type := WND_CHILD

   CreateGetList( Self )
   InitControls( SELF )
   InitObjects( Self, .T. )
   SendMessage(::handle, WM_UPDATEUISTATE, makelong(UIS_CLEAR, UISF_HIDEFOCUS), 0)
   IF hb_IsBlock(::bInit)
      //::hide()
      IF !hb_IsNumeric(nReturn := Eval( ::bInit, Self ))
         IF hb_IsLogical(nReturn) .AND. !nReturn
            ::Close()
            RETURN Nil
         ENDIF
      ENDIF
   ENDIF

   Hwg_ActivateChildWindow(lShow, ::handle, lMaximized, lMinimized)

   IF !Empty(lCentered) .AND. lCentered
      IF !Empty(::oParent)
        ::nLeft := (::oParent:nWidth - ::nWidth ) / 2
        ::nTop  := (::oParent:nHeight - ::nHeight) / 2
      ENDIF
   ENDIF

   SetWindowPos( ::handle, HWND_TOP, ::nLeft, ::nTop, 0, 0,;
                  SWP_NOSIZE + SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
   IF ( bActivate  != NIL )
      Eval( bActivate, Self )
   ENDIF

   IF ( hb_IsObject(::nInitFocus) .OR. ::nInitFocus > 0 )
      ::nInitFocus := IIf( hb_IsObject(::nInitFocus), ::nInitFocus:handle, ::nInitFocus )
      SETFOCUS( ::nInitFocus )
      ::nFocus := ::nInitFocus
   ELSEIF PtrtoUlong( GETFOCUS() ) = PtrtoUlong(::handle) .AND. Len( ::acontrols ) > 0
      ::nFocus := ASCAN( ::aControls,{|o| Hwg_BitaND(HWG_GETWINDOWSTYLE(o:handle), WS_TABSTOP) != 0 .AND. ;
           Hwg_BitaND(HWG_GETWINDOWSTYLE(o:handle), WS_DISABLED) = 0 } )
      IF ::nFocus > 0
         SETFOCUS( ::acontrols[::nFocus]:handle )
         ::nFocus := GetFocus() //get::acontrols[1]:handle
      ENDIF
   ENDIF
   RETURN Nil


#if 0 // old code for reference (to be deleted)
METHOD onEvent( msg, wParam, lParam ) CLASS HChildWindow
   LOCAL i, oCtrl

   IF msg == WM_DESTROY
      RETURN onDestroy( Self )
   ELSEIF msg == WM_SIZE
      RETURN onSize(Self, wParam, lParam)
   ELSEIF msg = WM_SETFOCUS .AND. ::nFocus != 0
      SETFOCUS( ::nFocus )
   ELSEIF ( i := AScan( HMainWindow():aMessages[1], msg ) ) != 0
      RETURN Eval( HMainWindow():aMessages[2, i], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         onTrackScroll( Self, msg, wParam, lParam )
      ELSEIF msg = WM_NOTIFY .AND. !::lSuspendMsgsHandling
         IF ( oCtrl := ::FindControl( wParam ) ) != Nil .AND. oCtrl:className != "HTAB"
            ::nFocus := oCtrl:handle
            SendMessage(oCtrl:handle, msg, wParam, lParam)
         ENDIF
      ENDIF
      RETURN ::Super:onEvent( msg, wParam, lParam )
   ENDIF

   RETURN - 1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HChildWindow

   LOCAL i
   LOCAL oCtrl

   SWITCH msg

   CASE WM_DESTROY
      RETURN onDestroy(Self)

   CASE WM_SIZE
      RETURN onSize(Self, wParam, lParam)

   CASE WM_SETFOCUS
      IF ::nFocus != 0
         SETFOCUS(::nFocus)
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
            SendMessage(oCtrl:handle, msg, wParam, lParam)
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

   #define  FLAG_CHECK      2

STATIC FUNCTION onSize(oWnd, wParam, lParam)
   LOCAL aCoors := GetWindowRect( oWnd:handle )

   IF oWnd:oEmbedded != Nil
      oWnd:oEmbedded:Resize(LOWORD(lParam), HIWORD(lParam))
   ENDIF
   //InvalidateRect(oWnd:handle, 0)
   oWnd:Super:onEvent( WM_SIZE, wParam, lParam )

   oWnd:nWidth  := aCoors[3] - aCoors[1]
   oWnd:nHeight := aCoors[4] - aCoors[2]

   IF hb_IsBlock(oWnd:bSize)
      Eval( oWnd:bSize, oWnd, LOWORD(lParam), HIWORD(lParam) )
   ENDIF
   IF oWnd:Type == WND_MDI .AND. Len( HWindow():aWindows ) > 1
      aCoors := GetClientRect( oWnd:handle )
      //MoveWindow(HWindow():aWindows[2]:handle, oWnd:aOffset[1], oWnd:aOffset[2], aCoors[3] - oWnd:aOffset[1] - oWnd:aOffset[3], aCoors[4] - oWnd:aOffset[2] - oWnd:aOffset[4])
      //aCoors := GetClientRect(HWindow():aWindows[2]:handle )
      SetWindowPos( HWindow():aWindows[2]:handle, Nil, oWnd:aOffset[1], oWnd:aOffset[2], aCoors[3] - oWnd:aOffset[1] - oWnd:aOffset[3], aCoors[4] - oWnd:aOffset[2] - oWnd:aOffset[4] , SWP_NOZORDER + SWP_NOACTIVATE + SWP_NOSENDCHANGING )
      aCoors := GetWindowRect( HWindow():aWindows[2]:handle )
      HWindow():aWindows[2]:nWidth  := aCoors[3] - aCoors[1]
      HWindow():aWindows[2]:nHeight := aCoors[4] - aCoors[2]
      // ADDED                                                   =
      IF !Empty(oWnd:Screen)
          oWnd:Screen:nWidth  := aCoors[3] - aCoors[1]
          oWnd:Screen:nHeight := aCoors[4] - aCoors[2]
          //InvalidateRect(oWnd:Screen:handle, 1) // flick in screen in resize window
          SetWindowPos( oWnd:screen:handle, Nil, 0, 0, oWnd:Screen:nWidth, oWnd:Screen:nHeight, SWP_NOACTIVATE + SWP_NOSENDCHANGING + SWP_NOZORDER )
          InvalidateRect(oWnd:Screen:handle, 1)
      ENDIF
      IF !Empty(oWnd := oWnd:GetMdiActive()) .AND.oWnd:type = WND_MDICHILD .AND. oWnd:lMaximized .AND.;
           ( oWnd:lModal .OR. oWnd:lChild )
         oWnd:lMaximized := .F.
         //-SendMessage(oWnd:handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0)
      ENDIF
      //
      RETURN 0
   ENDIF

   RETURN - 1

STATIC FUNCTION onDestroy( oWnd )

   IF oWnd:oEmbedded != Nil
      oWnd:oEmbedded:END()
   ENDIF
   oWnd:Super:onEvent( WM_DESTROY )
   HWindow():DelItem( oWnd )

   RETURN 0

STATIC FUNCTION onCommand(oWnd, wParam, lParam)
   LOCAL iItem, iCont, aMenu, iParHigh, iParLow, nHandle, oChild, i

   HB_SYMBOL_UNUSED(lParam)

   IF wParam >= FIRST_MDICHILD_ID .AND. wparam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS .AND. !Empty(oWnd:Screen)
      IF wParam >= FIRST_MDICHILD_ID
         SetWindowPos( ownd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE )
      ENDIF
      //-wParam += IIF( IsWindowEnabled(oWnd:Screen:handle ), 0, 1)
   ENDIF
   IF wParam == SC_CLOSE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage(HWindow():aWindows[2]:handle, WM_MDIGETACTIVE, 0, 0) ) > 0
         // CLOSE ONLY MDICHILD HERE
         oChild := oWnd:FindWindow(nHandle)
         IF oChild != Nil
            IF !oChild:Closable
               RETURN 0
            ELSEIF hb_IsBlock(oChild:bDestroy)
               oChild:lSuspendMsgsHandling := .T.
               i := Eval( oChild:bDestroy, oChild )
               oChild:lSuspendMsgsHandling := .F.
               i := IIf( hb_IsLogical(i), i, .T. )
               IF !i
                  Return 0
               ENDIF
            ENDIF
         ENDIF
         SendMessage(HWindow():aWindows[2]:handle, WM_MDIDESTROY, nHandle, 0)
      ENDIF
   ELSEIF wParam == SC_RESTORE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage(HWindow():aWindows[2]:handle, WM_MDIGETACTIVE, 0, 0) ) > 0
         SendMessage(HWindow():aWindows[2]:handle, WM_MDIRESTORE, nHandle, 0)
      ENDIF
   ELSEIF wParam == SC_MAXIMIZE
      IF Len( HWindow():aWindows ) > 2 .AND. ( nHandle := SendMessage(HWindow():aWindows[2]:handle, WM_MDIGETACTIVE, 0, 0) ) > 0
         SendMessage(HWindow():aWindows[2]:handle, WM_MDIMAXIMIZE, nHandle, 0)
      ENDIF
   ELSEIF wParam > FIRST_MDICHILD_ID .AND. wParam < FIRST_MDICHILD_ID + MAX_MDICHILD_WINDOWS
      IF oWnd:bMdiMenu != Nil
         Eval( oWnd:bMdiMenu, HWindow():aWindows[wParam - FIRST_MDICHILD_ID + 2], wParam  )
      ENDIF
      nHandle := HWindow():aWindows[wParam - FIRST_MDICHILD_ID + 2]:handle
      SendMessage(HWindow():aWindows[2]:handle, WM_MDIACTIVATE, nHandle, 0)
   ENDIF
   iParHigh := HIWORD(wParam)
   iParLow := LOWORD(wParam)
   IF oWnd:aEvents != Nil .AND. !oWnd:lSuspendMsgsHandling  .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[1] == iParHigh.and.a[2] == iParLow } ) ) > 0
      Eval( oWnd:aEvents[iItem, 3], oWnd, iParLow )
   ELSEIF hb_IsArray(oWnd:menu) .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:menu, iParLow, @iCont ) ) != Nil
      IF Hwg_BitAnd(aMenu[1, iCont, 4], FLAG_CHECK) > 0
         CheckMenuItem( , aMenu[1, iCont, 3], !IsCheckedMenuItem( , aMenu[1, iCont, 3] ) )
      ENDIF
      IF aMenu[1, iCont, 1] != Nil
         Eval( aMenu[1, iCont, 1], iCont, iParLow )
      ENDIF
   ELSEIF oWnd:oPopup != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu, wParam, @iCont ) ) != Nil ;
      .AND. aMenu[1, iCont, 1] != Nil
      Eval( aMenu[1, iCont, 1], iCont, wParam )
   ELSEIF oWnd:oNotifyMenu != Nil .AND. ;
      ( aMenu := Hwg_FindMenuItem( oWnd:oNotifyMenu:aMenu, wParam, @iCont ) ) != Nil ;
      .AND. aMenu[1, iCont, 1] != Nil
      Eval( aMenu[1, iCont, 1], iCont, wParam )
   ELSEIF wParam != SC_CLOSE .AND. wParam != SC_MINIMIZE .AND. wParam != SC_MAXIMIZE .AND.;
           wParam != SC_RESTORE .AND. oWnd:Type = WND_MDI //.AND. oWnd:bMdiMenu != Nil
      /*
      // ADDED
      IF !Empty(oWnd:Screen)
         IF wParam = FIRST_MDICHILD_ID  // first menu
            IF IsWindowEnabled(oWnd:Screen:handle)
               SetWindowPos( oWnd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER + ;
                                                                          SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
            ENDIF
            RETURN -1
         ENDIF
      ENDIF
      // menu MDICHILD
          IF oWnd:bMdiMenu != Nil
         Eval( oWnd:bMdiMenu, oWnd:GetMdiActive(), wParam  )
      ENDIF
      */
      RETURN IIF( !Empty(oWnd:Screen) , -1 , 0 )
      // end added
   ENDIF

   RETURN 0

STATIC FUNCTION onEraseBk( oWnd, wParam )
LOCAL aCoors, oWndArea

  IF oWnd:oBmp != Nil .AND. oWnd:type != WND_MDI
       oWndArea := IIF( oWnd:type != WND_MAIN, oWnd:oClient, oWnd )
       IF oWnd:lBmpCenter
          CenterBitmap(wParam, oWndArea:handle, oWnd:oBmp:handle, , oWnd:nBmpClr)
       ELSE
          SpreadBitmap(wParam, oWndArea:handle, oWnd:oBmp:handle)
       ENDIF
       Return 1
  ELSEIF oWnd:type != WND_MDI //.AND. oWnd:type != WND_MAIN
      aCoors := GetClientRect( oWnd:handle )
      IF oWnd:brush != Nil
         IF !hb_IsNumeric(oWnd:brush)
            FillRect( wParam, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, oWnd:brush:handle )
            IF !Empty(oWnd:Screen) .AND. SELFFOCUS( oWnd:handle, oWnd:Screen:handle )
               SetWindowPos( oWnd:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER +;
                                                         SWP_NOOWNERZORDER )
            ENDIF
            RETURN 1
         ENDIF
      ELSEIF oWnd:Type != WND_MAIN
         FillRect( wParam, aCoors[1], aCoors[2], aCoors[3] + 1, aCoors[4] + 1, COLOR_3DFACE + 1 )
         RETURN 1
      ENDIF

   ENDIF
   RETURN - 1

STATIC FUNCTION onSysCommand(oWnd, wParam, lParam)
   Local i, ars, oChild, oCtrl

   IF wParam == SC_CLOSE
      IF hb_IsBlock(oWnd:bDestroy)
         oWnd:lSuspendMsgsHandling := .T.
         i := Eval( oWnd:bDestroy, oWnd )
         oWnd:lSuspendMsgsHandling := .F.
         i := IIf( hb_IsLogical(i), i, .T. )
         IF !i
            RETURN 0
         ENDIF
         oWnd:bDestroy := Nil
      ENDIF
      IF __ObjHasMsg( oWnd, "ONOTIFYICON" ) .AND. oWnd:oNotifyIcon != Nil
         ShellNotifyIcon( .F., oWnd:handle, oWnd:oNotifyIcon:handle )
      ENDIF
      IF __ObjHasMsg( oWnd, "HACCEL" ) .AND. oWnd:hAccel != Nil
         DestroyAcceleratorTable(oWnd:hAccel)
      ENDIF
      RETURN - 1
   ENDIF

   oWnd:WindowState := GetWindowPlacement( oWnd:handle )
   IF wParam == SC_MINIMIZE
      IF __ObjHasMsg( oWnd, "LTRAY" ) .AND. oWnd:lTray
         oWnd:Hide()
         RETURN 0
      ENDIF
      SetWindowPos( oWnd:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER +;
                                                         SWP_NOOWNERZORDER + SWP_FRAMECHANGED)

   ELSEIF ( wParam == SC_MAXIMIZE .OR. wparam == SC_MAXIMIZE2 ) .AND. ;
      oWnd:type == WND_MDICHILD .AND. ( oWnd:lChild .OR. oWnd:lModal )
      IF oWnd:WindowState == SW_SHOWMINIMIZED
          SendMessage(oWnd:handle, WM_SYSCOMMAND, SC_RESTORE, 0)
          SendMessage(oWnd:handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0)
          RETURN 0
      ENDIF
      ars := aClone(oWnd:aRectSave)
      IF oWnd:lMaximized
          // restore
          IF oWnd:lSizeBox
             HWG_SETWINDOWSTYLE(oWnd:handle ,HWG_GETWINDOWSTYLE(oWnd:handle) + WS_SIZEBOX)
         ENDIF
         MoveWindow(oWnd:handle, oWnd:aRectSave[1], oWnd:aRectSave[2], oWnd:aRectSave[3], oWnd:aRectSave[4] )
         MoveWindow(oWnd:handle, oWnd:aRectSave[1] - ( oWnd:nLeft - oWnd:aRectSave[1] ), ;
                                  oWnd:aRectSave[2] - ( oWnd:nTop - oWnd:aRectSave[2] ), ;
                                  oWnd:aRectSave[3], oWnd:aRectSave[4] )
      ELSE
          // maximized
          IF oWnd:lSizeBox
             HWG_SETWINDOWSTYLE(oWnd:handle ,HWG_GETWINDOWSTYLE(oWnd:handle) - WS_SIZEBOX)
          ENDIF
         MoveWindow(oWnd:handle, oWnd:oClient:nLeft, oWnd:oClient:nTop, oWnd:oClient:nWidth, oWnd:oClient:nHeight)
      ENDIF
      oWnd:aRectSave := aClone(ars)
      oWnd:lMaximized := !oWnd:lMaximized
      RETURN 0
   ELSEIF (wParam == SC_MAXIMIZE .OR. wparam == SC_MAXIMIZE2 ) //.AND. oWnd:type != WND_MDICHILD

   ELSEIF wParam == SC_RESTORE .OR. wParam == SC_RESTORE2

   ELSEIF wParam = SC_NEXTWINDOW .OR. wParam = SC_PREVWINDOW
      // ctrl+tab   IN Mdi child
      IF !Empty(oWnd:lDisableCtrlTab) .AND. oWnd:lDisableCtrlTab
          RETURN 0
      ENDIF
   ELSEIF wParam = SC_KEYMENU
      // accelerator MDICHILD
      IF Len( HWindow():aWindows) > 2 .AND. ( ( oChild:=oWnd ):Type = WND_MDICHILD .OR. !Empty(oChild := oWnd:GetMdiActive()) )
         IF ( oCtrl := FindAccelerator( oChild, lParam ) ) != Nil
            oCtrl:SetFocus()
            SendMessage(oCtrl:handle, WM_SYSKEYUP, lParam, 0)
            RETURN - 2
           /*  MNC_IGNORE = 0  MNC_CLOSE = 1  MNC_EXECUTE = 2  MNC_SELECT = 3 */
         ENDIF
      ENDIF
   ELSEIF wParam = SC_HOTKEY
   //ELSEIF wParam = SC_MOUSEMENU  //0xF090
   ELSEIF wParam = SC_MENU .AND. ( oWnd:type == WND_MDICHILD .OR. !Empty(oWnd := oWnd:GetMdiActive())) .AND. oWnd:lModal
      MSGBEEP()
      RETURN 0
   ENDIF

   RETURN - 1

STATIC FUNCTION onEndSession( oWnd, wParam )

   LOCAL i

   HB_SYMBOL_UNUSED(wParam)

   IF hb_IsBlock(oWnd:bDestroy)
      i := Eval( oWnd:bDestroy, oWnd )
      i := IIf( hb_IsLogical(i), i, .T. )
      IF !i
         RETURN 0
      ENDIF
   ENDIF

   RETURN - 1

STATIC FUNCTION onNotifyIcon( oWnd, wParam, lParam )
   LOCAL ar

   IF wParam == ID_NOTIFYICON
      IF PtrtoUlong(lParam) == WM_LBUTTONDOWN
         IF hb_IsBlock(oWnd:bNotify)
            Eval( oWnd:bNotify )
         ENDIF
      ELSEIF PtrtoUlong(lParam) == WM_MOUSEMOVE
         /*
         IF hb_IsBlock(oWnd:bNotify)
            oWnd:lSuspendMsgsHandling := .T.
            Eval( oWnd:bNotify )
            oWnd:lSuspendMsgsHandling := .F.
         ENDIF
         */
      ELSEIF PtrtoUlong(lParam) == WM_RBUTTONDOWN
         IF oWnd:oNotifyMenu != Nil
            ar := hwg_GetCursorPos()
            oWnd:oNotifyMenu:Show( oWnd, ar[1], ar[2] )
         ENDIF
      ENDIF
   ENDIF
   RETURN - 1

#if 0
STATIC FUNCTION onMdiCreate(oWnd, lParam)
   LOCAL nReturn
   HB_SYMBOL_UNUSED(lParam)

   IF hb_IsBlock(oWnd:bSetForm)
      EVAL( oWnd:bSetForm, oWnd )
   ENDIF
   IF !EMPTY ( oWnd:oWndParent )
       oWnd:oParent := oWnd:oWndParent
   ENDIF
   IF !oWnd:lClosable
      oWnd:Closable(.F.)
   ENDIF
   IF oWnd:oFont != Nil
      SendMessage(oWnd:handle, WM_SETFONT, oWnd:oFont:handle, 0)
   ENDIF
   InitControls( oWnd )
   InitObjects( oWnd, .T. )
   IF oWnd:bInit != Nil
      IF !hb_IsNumeric(nReturn := Eval( oWnd:bInit, oWnd ))
         IF hb_IsLogical(nReturn) .AND. !nReturn
            oWnd:Close()
            RETURN Nil
         ENDIF
      ENDIF
   ENDIF
   //draw rect focus
   oWnd:nInitFocus := IIF(hb_IsObject(oWnd:nInitFocus), oWnd:nInitFocus:handle, oWnd:nInitFocus )
   SendMessage(oWnd:handle, WM_UPDATEUISTATE, makelong(UIS_CLEAR, UISF_HIDEFOCUS), 0)
   SendMessage(oWnd:handle, WM_UPDATEUISTATE, makelong(UIS_CLEAR, UISF_HIDEACCEL), 0)
   IF oWnd:WindowState > 0
      onMove(oWnd)
   ENDIF
   RETURN - 1
#endif

#if 0
STATIC FUNCTION onMdiCommand(oWnd, wParam)
   LOCAL iParHigh, iParLow, iItem, aMenu, oCtrl

   IF wParam == SC_CLOSE
      SendMessage(HWindow():aWindows[2]:handle, WM_MDIDESTROY, oWnd:handle, 0)
   ENDIF
   iParHigh := HIWORD(wParam)
   iParLow := LOWORD(wParam)
   IF ISWINDOWVISIBLE(oWnd:handle)
      oCtrl := oWnd:FindControl( iParLow )
   ENDIF
   IF oWnd:aEvents != Nil .AND. !oWnd:lSuspendMsgsHandling  .AND. ;
      ( iItem := AScan( oWnd:aEvents, { | a | a[1] == iParHigh.and.a[2] == iParLow } ) ) > 0
      IF PtrtouLong( GetParent( GetFocus() ) ) = PtrtouLong( oWnd:handle )
         oWnd:nFocus := GetFocus()
      ENDIF
      Eval( oWnd:aEvents[iItem, 3], oWnd, iParLow )
   ELSEIF __ObjHasMsg( oWnd ,"OPOPUP") .AND. oWnd:oPopup != Nil .AND. ;
         ( aMenu := Hwg_FindMenuItem( oWnd:oPopup:aMenu, wParam, @iItem ) ) != Nil ;
         .AND. aMenu[1, iItem, 1] != Nil
          Eval( aMenu[1, iItem, 1], wParam )
   ELSEIF iParHigh = 1  // acelerator

   ENDIF
   IF oCtrl != Nil .AND. Hwg_BitaND(HWG_GETWINDOWSTYLE(oCtrl:handle), WS_TABSTOP) != 0 .AND.;
      GetFocus() == oCtrl:handle
      oWnd:nFocus := oCtrl:handle
   ENDIF
   RETURN 0
#endif

#if 0
STATIC FUNCTION onMdiNcActivate(oWnd, wParam)

   IF !Empty(oWnd:Screen)
      IF wParam = 1 .AND. SelfFocus( oWnd:Screen:handle, oWnd:handle )
         SetWindowPos( oWnd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE )
         RETURN 1
      ENDIF
      IF wParam == 1 .AND. !SelfFocus( oWnd:Screen:handle, oWnd:handle )
         // triggered ON GETFOCUS MDI CHILD MAXIMIZED
         IF hb_IsBlock(oWnd:bSetForm)
            EVAL( oWnd:bSetForm, oWnd )
         ENDIF
         IF !oWnd:lSuspendMsgsHandling .AND.;
            oWnd:bGetFocus != Nil .AND. !Empty(GetFocus()) .AND. oWnd:IsMaximized()
            oWnd:lSuspendMsgsHandling := .T.
            Eval( oWnd:bGetFocus, oWnd )
            oWnd:lSuspendMsgsHandling := .F.
          ENDIF
      ENDIF
   ENDIF
   RETURN - 1
#endif

#if 0
Static Function onMdiActivate(oWnd,wParam, lParam)
   Local  lScreen := oWnd:Screen != NIL, aWndMain ,oWndDeact
   Local lConf

   If ValType(wParam) == ValType(oWnd:handle)
      lConf := wParam = oWnd:handle
   Else
      lConf := .F.
   EndIf
   // added

   IF !Empty(wParam)
      oWndDeact := oWnd:FindWindow(wParam)
      IF oWnd:lChild .AND. oWnd:lmaximized .AND. oWnd:IsMaximized()
         oWnd:Restore()
      ENDIF
      IF oWndDeact != Nil .AND. oWndDeact:lModal
         AADD(oWndDeact:aChilds, lParam)
         AADD(oWnd:aChilds, wParam)
         oWnd:lModal := .T.
      ELSEIF oWndDeact != Nil .AND. !oWndDeact:lModal
         oWnd:hActive := wParam
      ENDIF
   ENDIF

   IF lScreen .AND. ( Empty(lParam) .OR. ;
       SelfFocus( lParam, oWnd:Screen:handle ) ) .AND. !lConf //wParam != oWnd:handle
      //-SetWindowPos( oWnd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE )
      RETURN 0
   ELSEIF lConf //oWnd:handle = wParam
      IF !SelfFocus( oWnd:Screen:handle, wParam ) .AND. oWnd:bLostFocus != Nil //.AND.wParam == 0
         oWnd:lSuspendMsgsHandling := .T.
         //IF oWnd:Screen:handle = lParam
         //   SetWindowPos( oWnd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE )
         //ENDIF
         Eval( oWnd:bLostFocus, oWnd )
         oWnd:lSuspendMsgsHandling := .F.
      ENDIF
      IF oWnd:lModal
         aWndMain := oWnd:GETMAIN():aWindows
         AEVAL( aWndMain,{| w | IIF( w:Type >= WND_MDICHILD .AND.;
             PtrtoUlong( w:handle ) != PtrtoUlong( wParam ), EnableWindow(w:handle, .T.), ) })
      ENDIF
   ELSEIF SelfFocus( oWnd:handle, lParam ) //.AND. ownd:screen:handle != WPARAM
      IF hb_IsBlock(oWnd:bSetForm)
         EVAL( oWnd:bSetForm, oWnd )
      ENDIF
      IF oWnd:lModal
         aWndMain := oWnd:GETMAIN():aWindows
         AEVAL( aWndMain,{| w | IIF( w:Type >= WND_MDICHILD .AND.;
             PtrtoUlong( w:handle ) != PtrtoUlong( lParam ), EnableWindow(w:handle, .F.), ) })
         AEVAL( oWnd:aChilds,{| wH | EnableWindow(wH, .T.) })
     ENDIF
      IF oWnd:bGetFocus != Nil .AND. !oWnd:lSuspendMsgsHandling .AND. !oWnd:IsMaximized()
         oWnd:lSuspendMsgsHandling := .T.
         IF Empty(oWnd:nFocus)
             UpdateWindow(oWnd:handle)
         ENDIF
         Eval( oWnd:bGetFocus, oWnd )
         oWnd:lSuspendMsgsHandling := .F.
      ENDIF
   ENDIF

   RETURN 0
#endif

STATIC FUNCTION onEnterIdle(oDlg, wParam, lParam)
   LOCAL oItem

   HB_SYMBOL_UNUSED(oDlg)

   IF wParam == 0 .AND. ( oItem := ATail( HDialog():aModalDialogs ) ) != Nil ;
                          .AND. oItem:handle == lParam .AND. !oItem:lActivated
      oItem:lActivated := .T.
      IF oItem:bActivate != Nil
         Eval( oItem:bActivate, oItem )
      ENDIF
   ENDIF
   RETURN 0

//add by sauli
STATIC FUNCTION onCloseQuery( o )
   IF hb_IsBlock(o:bCloseQuery)
      IF Eval( o:bCloseQuery )
         ReleaseAllWindows( o:handle )
      END
   ELSE
      ReleaseAllWindows( o:handle )
   END

   RETURN - 1
// end sauli

STATIC FUNCTION onActivate(oWin, wParam, lParam)
   LOCAL iParLow := LOWORD(wParam), iParHigh := HIWORD(wParam)

   HB_SYMBOL_UNUSED(lParam)

   IF ( iParLow = WA_ACTIVE .OR. iParLow = WA_CLICKACTIVE ) .AND. IsWindowVisible(oWin:handle)
      IF ( oWin:type = WND_MDICHILD .AND. PtrtoUlong( lParam ) = 0  ) .OR.;
          ( oWin:type != WND_MDICHILD .AND. iParHigh = 0 )
         IF oWin:bGetFocus != Nil //.AND. IsWindowVisible(::handle)
            oWin:lSuspendMsgsHandling := .T.
            IF iParHigh > 0  // MINIMIZED
               //oWin:restore()
            ENDIF
            Eval( oWin:bGetFocus, oWin, lParam )
            oWin:lSuspendMsgsHandling := .F.
         ENDIF
      ENDIF
   ELSEIF iParLow = WA_INACTIVE
      IF ( oWin:type = WND_MDICHILD .AND. PtrtoUlong( lParam ) != 0 ).OR.;
          ( oWin:type != WND_MDICHILD .AND. iParHigh = 0 .AND. PtrtoUlong( lParam ) = 0 )
         IF oWin:bLostFocus != Nil //.AND. IsWindowVisible(::handle)
            oWin:lSuspendMsgsHandling := .T.
            Eval( oWin:bLostFocus, oWin, lParam )
            oWin:lSuspendMsgsHandling := .F.
         ENDIF
      ENDIF
   ENDIF
   RETURN 1
