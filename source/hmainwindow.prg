/*
 *$Id: hwindow.prg 1904 2012-09-21 11:43:56Z lfbasso $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HMainWindow class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

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

CLASS HMainWindow INHERIT HWindow

#if 0 // old code for reference (to be deleted)
CLASS VAR aMessages INIT { ;
                           { WM_COMMAND, WM_ERASEBKGND, WM_MOVE, WM_SIZE, WM_SYSCOMMAND, ;
                             WM_NOTIFYICON, WM_ENTERIDLE, WM_CLOSE, WM_DESTROY, WM_ENDSESSION, WM_ACTIVATE, WM_HELP }, ;
                           { ;
                             { | o, w, l | onCommand(o, w, l) },        ;
                             { | o, w | onEraseBk( o, w ) },              ;
                             { | o | onMove(o) },                       ;
                             { | o, w, l | onSize(o, w, l) },           ;
                             { | o, w, l | onSysCommand(o, w, l) },     ;
                             { | o, w, l | onNotifyIcon( o, w, l ) },     ;
                             { | o, w, l | onEnterIdle(o, w, l) },      ;
                             { | o | onCloseQuery( o ) },                 ;
                             { | o | onDestroy( o ) },                    ;
                             { | o, w | onEndSession( o, w ) },           ;
                             { | o, w, l | onActivate(o, w, l) },       ;
                             { | o, w, l | onHelp(o, w, l) }            ;
                           } ;
                         }
#endif

   DATA nMenuPos
   DATA bMdiMenu
   DATA oNotifyIcon
   DATA bNotify
   DATA oNotifyMenu
   DATA lTray INIT .F.

   METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
               oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
               cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, bMdiMenu )
   METHOD Activate(lShow, lMaximized, lMinimized, lCentered, bActivate)
   METHOD onEvent( msg, wParam, lParam )
   METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip )
   METHOD GetMdiActive() INLINE ::FindWindow(IIF( ::GetMain() != Nil, SendMessage(::GetMain():handle, WM_MDIGETACTIVE, 0, 0) , Nil ))

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New( lType, oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, nPos,   ;
            oFont, bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther, ;
            cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, bMdiMenu ) CLASS HMainWindow

   ::Super:New( oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, ;
              bInit, bExit, bSize, bPaint, bGfocus, bLfocus, bOther,  ;
              cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh )
   ::Type := lType

   IF lType == WND_MDI

      //::nMenuPos := nPos
      ::nMenuPos := IIF( nPos = Nil, -1, nPos )     //don't show menu
      ::bMdiMenu := bMdiMenu
      ::Style := nStyle
      ::tColor := clr
      ::oBmp := oBmp
       clr:= NIL  // because error
      ::handle := Hwg_InitMdiWindow(Self, ::szAppName, cTitle, cMenu,  ;
                                    IIf( oIcon != Nil, oIcon:handle, Nil ), , ;  //clr, ;
                                    nStyle, ::nLeft, ::nTop, ::nWidth, ::nHeight)

      IF cHelp != NIL
         SetHelpFileName(cHelp)
      ENDIF

      /* ADDED screen to backgroup to MDI MAIN */
      ::Screen := HMdiChildWindow():New(, ::tcolor, WS_CHILD + WS_MAXIMIZE + MB_USERICON + WS_DISABLED,;
                      0, 0, ::nWidth * 1, ::nheight * 1 - GETSYSTEMMETRICS( SM_CYSMCAPTION ) - GETSYSTEMMETRICS( SM_CYSMCAPTION ) , ;
                     -1 ,,,,,::bSize ,,,,,,::oBmp,,,,,, )
      ::Screen:Type    := WND_MDICHILD

      ::oDefaultParent := Self

   ELSEIF lType == WND_MAIN

      clr := NIL  // because error and WINDOW IS INVISIBLE
      ::handle := Hwg_InitMainWindow(Self, ::szAppName, cTitle, cMenu, ;
                      IIf( oIcon != Nil, oIcon:handle, Nil ), ;
                      IIf( oBmp != Nil, - 1, clr ), nStyle, ::nLeft, ::nTop, ::nWidth, ::nHeight)

      IF cHelp != NIL
         SetHelpFileName(cHelp)
      ENDIF

   ENDIF
   ::rect := GetWindowRect(::handle)
   /*
   IF hb_IsBlock(::bInit)
      Eval( ::bInit, Self )
   ENDIF
    */

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate(lShow, lMaximized, lMinimized, lCentered, bActivate) CLASS HMainWindow

   LOCAL oWndClient
   LOCAL handle
   LOCAL lres

   DEFAULT lMaximized := .F.
   DEFAULT lMinimized := .F.
   lCentered  := ( !lMaximized .AND. !Empty(lCentered) .AND. lCentered ) .OR. Hwg_BitAND(::Style, DS_CENTER) != 0
   DEFAULT lShow := .T.
   CreateGetList( Self )
   AEVAL( ::aControls, { | o | o:lInit := .F. } )

   IF ::Type == WND_MDI

      oWndClient := HWindow():New( ,,, ::style, ::title,, ::bInit, ::bDestroy, ::bSize, ;
                                   ::bPaint, ::bGetFocus, ::bLostFocus, ::bOther, ::obmp )

      handle := Hwg_InitClientWindow(oWndClient, ::nMenuPos, ::nLeft, ::nTop, ::nWidth, ::nHeight)
      ::oClient := HWindow():aWindows[2]

     // SetWindowPos( ::oClient:handle, 0, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER +;
     //                   SWP_NOOWNERZORDER + SWP_FRAMECHANGED)

      /*
      // ADDED screen to backgroup to MDI MAIN
      ::Screen := HMdiChildWindow():New(, ::tcolor, WS_CHILD + MB_USERICON + WS_MAXIMIZE + WS_DISABLED,;
                  0, 0, ::nWidth * 1, ::nheight * 1 - GETSYSTEMMETRICS( SM_CYSMCAPTION ) - GETSYSTEMMETRICS( SM_CYSMCAPTION ) , ;
                 -1 ,,,,,,,,,,,::oBmp,,,,,, )
      */

      IF ::Screen != Nil
         ::Screen:lExitOnEsc := .F.
         //::Screen:lClipper := .F.
         ::Screen:Activate(.T., .T.)
      ENDIF
      ///
      oWndClient:handle := handle
      /* recalculate area offset */
      SendMessage(::handle, WM_SIZE, 0, MAKELPARAM(::nWidth, ::nHeight))

      InitControls( Self )
      IF hb_IsBlock(::bInit)
         lres := Eval( ::bInit, Self )
         IF hb_IsLogical(lres) .AND. !lres
            SendMessage(::handle, WM_DESTROY, 0, 0)
            RETURN Nil
         ENDIF
      ENDIF
      IF ::Screen != Nil
         ::Screen:lBmpCenter := ::lBmpCenter
         ::Screen:Maximize()
         SetWindowPos( ::Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOACTIVATE + SWP_NOMOVE + SWP_NOSIZE + SWP_NOZORDER +;
                                                                 SWP_NOOWNERZORDER + SWP_FRAMECHANGED )
         ::Screen:Restore()
      ENDIF
      IF lMaximized
         ::Maximize()
      ELSEIF lMinimized
         ::Minimize()
      ELSEIF lCentered
         ::Center()
      ENDIF

      IF ( bActivate  != NIL )
         Eval( bActivate, Self )
      ENDIF
       AddToolTip(::handle, ::handle, "")
      Hwg_ActivateMdiWindow(( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized)

   ELSEIF ::Type == WND_MAIN

      IF hb_IsBlock(::bInit)
         lres := Eval( ::bInit, Self )
         IF hb_IsLogical(lres) .AND. !lres
            SendMessage(::handle, WM_DESTROY, 0, 0)
            RETURN Nil
         ENDIF
      ENDIF
      IF lMaximized
         ::maximize()
      ELSEIF lMinimized
         ::minimize()
      ELSEIF lCentered
         ::center()
      ENDIF

      IF ( bActivate  != NIL )
         Eval( bActivate, Self )
      ENDIF

      AddToolTip(::handle, ::handle, "")
      Hwg_ActivateMainWindow(( lShow == Nil .OR. lShow ), ::hAccel, lMaximized, lMinimized)

   ENDIF

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

#if 0
METHOD onEvent( msg, wParam, lParam ) CLASS HMainWindow

   LOCAL i
   LOCAL xPos
   LOCAL yPos
   LOCAL oMdi
   LOCAL aCoors
   LOCAL nFocus := IIf(Hb_IsNumeric(::nFocus), ::nFocus, 0)

   // writelog( str(msg) + str(wParam) + str(lParam) + chr(13) )

   IF msg = WM_MENUCHAR
      // PROCESS ACCELERATOR IN CONTROLS
      RETURN onSysCommand(Self, SC_KEYMENU, LoWord(wParam))
   ENDIF
   // added control MDICHILD MODAL
   IF msg = WM_PARENTNOTIFY
      IF wParam = WM_LBUTTONDOWN .AND. !Empty(::GetMdiActive())
         oMdi := ::GetMdiActive()
         IF oMdi:lModal
            xPos := LoWord(lParam)
            yPos := HiWord(lParam) // + ::nTop + GetSystemMetrics( SM_CYMENU ) + GETSYSTEMMETRICS( SM_CYCAPTION )
            aCoors := ScreenToClient( ::handle, GetWindowRect( oMdi:handle ) ) // acoors[1], acoors[2]  )
            IF ( !PtInRect( aCoors, { xPos, yPos } ) )
               MSGBEEP()
               FOR i = 1 to 6
                  FlashWindow(oMdi:handle, 1)
                  Sleep(60)
               NEXT
               SetWindowPos( oMdi:handle, HWND_TOP, 0, 0, 0, 0, ;
                             SWP_NOMOVE + SWP_NOSIZE +  SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
               ::lSuspendMsgsHandling := .T.
               RETURN 0
            ENDIF
         ENDIF
      ENDIF
   ELSEIF msg = WM_SETFOCUS .AND. nFocus > 0
      SETFOCUS( nFocus )
   ENDIF
   IF ( i := Ascan( ::aMessages[1],msg ) ) != 0 .AND. ;
       ( !::lSuspendMsgsHandling .OR. msg = WM_ERASEBKGND .OR. msg = WM_SIZE )
      Return Eval( ::aMessages[2,i], Self, wParam, lParam )
   ELSE
      IF msg == WM_HSCROLL .OR. msg == WM_VSCROLL .or. msg == WM_MOUSEWHEEL
         IF ::nScrollBars != -1
             ::ScrollHV( Self,msg,wParam,lParam )
         ENDIF
         onTrackScroll( Self, msg, wParam, lParam )
      ENDIF
      RETURN ::Super:onEvent( msg, wParam, lParam )
   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HMainWindow

   LOCAL i
   LOCAL xPos
   LOCAL yPos
   LOCAL oMdi
   LOCAL aCoors
   LOCAL nFocus := IIf(Hb_IsNumeric(::nFocus), ::nFocus, 0)

   // writelog( str(msg) + str(wParam) + str(lParam) + chr(13) )

   SWITCH msg

   CASE WM_MENUCHAR
      // PROCESS ACCELERATOR IN CONTROLS
      RETURN onSysCommand(Self, SC_KEYMENU, LoWord(wParam))
      // added control MDICHILD MODAL

   CASE WM_PARENTNOTIFY
      IF wParam == WM_LBUTTONDOWN .AND. !Empty(::GetMdiActive())
         oMdi := ::GetMdiActive()
         IF oMdi:lModal
            xPos := LoWord(lParam)
            yPos := HiWord(lParam) // + ::nTop + GetSystemMetrics( SM_CYMENU ) + GETSYSTEMMETRICS( SM_CYCAPTION )
            aCoors := ScreenToClient(::handle, GetWindowRect(oMdi:handle)) // acoors[1], acoors[2])
            IF !PtInRect(aCoors, {xPos, yPos})
               MSGBEEP()
               FOR i := 1 TO 6
                  FlashWindow(oMdi:handle, 1)
                  Sleep(60)
               NEXT
               SetWindowPos(oMdi:handle, HWND_TOP, 0, 0, 0, 0, ;
                  SWP_NOMOVE + SWP_NOSIZE + SWP_NOOWNERZORDER + SWP_FRAMECHANGED)
               ::lSuspendMsgsHandling := .T.
               RETURN 0
            ENDIF
         ENDIF
      ENDIF
      EXIT

   CASE WM_SETFOCUS
      IF nFocus > 0
         SETFOCUS(nFocus)
      ENDIF
      EXIT

   CASE WM_COMMAND
      IF !::lSuspendMsgsHandling
         RETURN onCommand(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_ERASEBKGND
      RETURN onEraseBk(Self, wParam)

   CASE WM_MOVE
      IF !::lSuspendMsgsHandling
         RETURN onMove(Self)
      ENDIF
      EXIT

   CASE WM_SIZE
      RETURN onSize(Self, wParam, lParam)

   CASE WM_SYSCOMMAND
      IF !::lSuspendMsgsHandling
         RETURN onSysCommand(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_NOTIFYICON
      IF !::lSuspendMsgsHandling
         RETURN onNotifyIcon(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_ENTERIDLE
      IF !::lSuspendMsgsHandling
         RETURN onEnterIdle(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_CLOSE
      IF !::lSuspendMsgsHandling
         RETURN onCloseQuery(Self)
      ENDIF
      EXIT

   CASE WM_DESTROY
      IF !::lSuspendMsgsHandling
         RETURN onDestroy(Self)
      ENDIF
      EXIT

   CASE WM_ENDSESSION
      IF !::lSuspendMsgsHandling
         RETURN onEndSession(Self, wParam)
      ENDIF
      EXIT

   CASE WM_ACTIVATE
      IF !::lSuspendMsgsHandling
         RETURN onActivate(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_HELP
      IF !::lSuspendMsgsHandling
         RETURN onHelp(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_HSCROLL
   CASE WM_VSCROLL
   CASE WM_MOUSEWHEEL
      IF ::nScrollBars != -1
         ::ScrollHV(Self, msg, wParam, lParam)
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

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD InitTray( oNotifyIcon, bNotify, oNotifyMenu, cTooltip ) CLASS HMainWindow

   ::bNotify     := bNotify
   ::oNotifyMenu := oNotifyMenu
   ::oNotifyIcon := oNotifyIcon
   ShellNotifyIcon( .T., ::handle, oNotifyIcon:handle, cTooltip )
   ::lTray := .T.

RETURN Nil

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onSize(oWnd, wParam, lParam)
   
   LOCAL aCoors := GetWindowRect(oWnd:handle)

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

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onDestroy( oWnd )

   IF oWnd:oEmbedded != Nil
      oWnd:oEmbedded:END()
   ENDIF
   oWnd:Super:onEvent( WM_DESTROY )
   HWindow():DelItem( oWnd )

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

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onEraseBk( oWnd, wParam )

   LOCAL aCoors
   LOCAL oWndArea

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

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

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

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

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

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

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

//-------------------------------------------------------------------------------------------------------------------//

//add by sauli
STATIC FUNCTION onCloseQuery( o )
   IF hb_IsBlock(o:bCloseQuery)
      IF Eval( o:bCloseQuery )
         ReleaseAllWindows( o:handle )
      END
   ELSE
      ReleaseAllWindows( o:handle )
   END

RETURN -1
// end sauli

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onActivate(oWin, wParam, lParam)

   LOCAL iParLow := LOWORD(wParam)
   LOCAL iParHigh := HIWORD(wParam)

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

//-------------------------------------------------------------------------------------------------------------------//
