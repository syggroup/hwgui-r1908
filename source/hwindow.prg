//
// $Id: hwindow.prg 1904 2012-09-21 11:43:56Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HWindow class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

//-------------------------------------------------------------------------------------------------------------------//

CLASS HWindow INHERIT HCustomWindow

   CLASS VAR aWindows SHARED INIT {}
   CLASS VAR szAppName SHARED INIT "HwGUI_App"
   CLASS VAR Screen SHARED

   DATA menu
   DATA oPopup
   DATA hAccel
   DATA oIcon
   DATA oBmp
   DATA lBmpCenter INIT .F.
   DATA nBmpClr
   DATA lUpdated INIT .F. // TRUE, if any GET is changed
   DATA lClipper INIT .F.
   DATA GetList INIT {} // The array of GET items in the dialog
   DATA KeyList INIT {} // The array of keys (as Clipper's SET KEY)
   DATA nLastKey INIT 0
   DATA lExitOnEnter INIT .F.
   DATA lExitOnEsc INIT .T.
   DATA lGetSkiponEsc INIT .F.
   DATA bCloseQuery
   Data nFocus INIT 0
   DATA WindowState INIT 0
   DATA oClient
   DATA lChild INIT .F.
   DATA lDisableCtrlTab INIT .F.
   DATA lModal INIT .F.
   DATA aOffset
   DATA oEmbedded
   DATA bScroll
   DATA bSetForm

   METHOD New(oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, bInit, bExit, bSize, bPaint, bGfocus, ;
      bLfocus, bOther, cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, lChild, lClipper, lNoClosable, bSetForm)
   METHOD AddItem(oWnd)
   METHOD DelItem(oWnd)
   METHOD FindWindow(hWndTitle)
   METHOD GetMain()
   METHOD GetMdiMain() INLINE IIf(::GetMain() != NIL, ::aWindows[1], NIL)
   METHOD Center() INLINE hwg_CenterWindow(::handle, ::Type)
   METHOD Restore() INLINE hwg_SendMessage(::handle, WM_SYSCOMMAND, SC_RESTORE, 0)
   METHOD Maximize() INLINE hwg_SendMessage(::handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0)
   METHOD Minimize() INLINE hwg_SendMessage(::handle, WM_SYSCOMMAND, SC_MINIMIZE, 0)
   METHOD Close() INLINE hwg_SendMessage(::handle, WM_SYSCOMMAND, SC_CLOSE, 0)
   METHOD Release() INLINE ::Close(), ::super:Release(), Self := NIL
   METHOD isMaximized() INLINE GetWindowPlacement(::handle) == SW_SHOWMAXIMIZED
   METHOD isMinimized() INLINE GetWindowPlacement(::handle) == SW_SHOWMINIMIZED
   METHOD isNormal() INLINE GetWindowPlacement(::handle) == SW_SHOWNORMAL


ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oIcon, clr, nStyle, x, y, width, height, cTitle, cMenu, oFont, bInit, bExit, bSize, bPaint, bGfocus, ;
   bLfocus, bOther, cAppName, oBmp, cHelp, nHelpId, bCloseQuery, bRefresh, lChild, lClipper, lNoClosable, bSetForm) ;
   CLASS HWindow

   HB_SYMBOL_UNUSED(clr)
   HB_SYMBOL_UNUSED(cMenu)
   HB_SYMBOL_UNUSED(cHelp)

   ::oDefaultParent := Self
   ::title := cTitle
   ::style := IIf(nStyle == NIL, 0, nStyle)
   ::oIcon := oIcon
   ::oBmp := oBmp
   ::nTop := IIf(y == NIL, 0, y)
   ::nLeft := IIf(x == NIL, 0, x)
   ::nWidth := IIf(width == NIL, 0, width)
   ::nHeight := IIf(height == NIL, 0, height)
   ::oFont := oFont
   ::bInit := bInit
   ::bDestroy := bExit
   ::bSize := bSize
   ::bPaint := bPaint
   ::bGetFocus := bGfocus
   ::bLostFocus := bLfocus
   ::bOther := bOther
   ::bCloseQuery := bCloseQuery
   ::bRefresh := bRefresh
   ::lChild := IIf(Empty(lChild), ::lChild, lChild)
   ::lClipper := IIf(Empty(lClipper), ::lClipper, lClipper)
   ::lClosable := Iif(Empty(lnoClosable), .T., !lnoClosable)

   //IF clr != NIL
   //   ::brush := HBrush():Add(clr)
   //   ::bColor := clr
   //ENDIF
   ::SetColor(, clr)

   IF cAppName != NIL
      ::szAppName := cAppName
   ENDIF

   IF nHelpId != NIL
      ::HelpId := nHelpId
   ENDIF

   ::aOffset := Array(4)
   AFill(::aOffset, 0)

   IF !hb_IsNumeric(cTitle)
      ::AddItem(Self)
   ENDIF
   IF hwg_Bitand(nStyle, WS_HSCROLL) > 0
      ::nScrollBars++
   ENDIF
   IF hwg_Bitand(nStyle, WS_VSCROLL) > 0
      ::nScrollBars += 2
   ENDIF
   ::bSetForm := bSetForm

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD AddItem(oWnd) CLASS HWindow

   AAdd(::aWindows, oWnd)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD DelItem(oWnd) CLASS HWindow

   LOCAL i
   LOCAL h := oWnd:handle

   IF (i := AScan(::aWindows, {|o|o:handle == h})) > 0
      ADel(::aWindows, i)
      ASize(::aWindows, Len(::aWindows) - 1)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD FindWindow(hWndTitle) CLASS HWindow

   LOCAL cType := ValType(hWndTitle)
   LOCAL i

   IF cType != "C"
      i := AScan(::aWindows, {|o|PtrtoUlong(o:handle) == PtrtoUlong(hWndTitle)})
   ELSE
      i := AScan(::aWindows, {|o|hb_IsChar(o:Title) .AND. o:Title == hWndTitle})
   ENDIF

RETURN IIf(i == 0, NIL, ::aWindows[i])

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetMain() CLASS HWindow
RETURN IIf(Len(::aWindows) > 0, IIf(::aWindows[1]:Type == WND_MAIN, ::aWindows[1], ;
   IIf(Len(::aWindows) > 1, ::aWindows[2], NIL)), NIL)

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION ReleaseAllWindows(hWnd)

   LOCAL oItem

   FOR EACH oItem IN HWindow():aWindows
      IF oItem:oParent != NIL .AND. PtrToUlong(oItem:oParent:handle) == PtrToUlong(hWnd)
         hwg_SendMessage(oItem:handle, WM_CLOSE, 0, 0)
      ENDIF
   NEXT
   IF PtrToUlong(HWindow():aWindows[1]:handle) == PtrToUlong(hWnd)
      PostQuitMessage(0)
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION onMove(oWnd)

   LOCAL aControls := hwg_GetWindowRect(oWnd:handle)

   oWnd:nLeft := aControls[1]
   oWnd:nTop := aControls[2]
   IF oWnd:type == WND_MDICHILD .AND. !oWnd:lMaximized
      //oWnd:aRectSave := {oWnd:nLeft, oWnd:nTop, oWnd:nWidth, oWnd:nHeight}
      IF oWnd:nHeight > hwg_GetSystemMetrics(SM_CYCAPTION) + 6
          oWnd:aRectSave := {oWnd:nLeft, oWnd:nTop, oWnd:nWidth, oWnd:nHeight}
      ELSE
        oWnd:aRectSave[1] := oWnd:nLeft
        oWnd:aRectSave[2] := oWnd:nTop
      ENDIF
   ENDIF
   IF oWnd:isMinimized() .AND. !Empty(oWnd:Screen)
      hwg_SetWindowPos(oWnd:Screen:handle, HWND_BOTTOM, 0, 0, 0, 0, ;
         SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOOWNERZORDER + SWP_NOSIZE + SWP_NOMOVE)
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//
