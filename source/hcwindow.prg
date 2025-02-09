//
// $Id: hcwindow.prg 1868 2012-08-27 17:33:11Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HCustomWindow class
//
// Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define TRANSPARENT 1
#define EVENTS_MESSAGES 1
#define EVENTS_ACTIONS  2
#define RT_MANIFEST  24

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
STATIC aCustomEvents := { ;
       { ;
        WM_NOTIFY, ;
        WM_PAINT, ;
        WM_CTLCOLORSTATIC, ;
        WM_CTLCOLOREDIT, ;
        WM_CTLCOLORBTN, ;
        WM_CTLCOLORLISTBOX, ;
        WM_COMMAND, ;
        WM_DRAWITEM, ;
        WM_SIZE, ;
        WM_DESTROY ;
       }, ;
       { ;
        {|o, w, l|onNotify(o, w, l)}                           , ;
        {|o, w|IIf(o:bPaint != NIL, Eval(o:bPaint, o, w), -1)} , ;
        {|o, w, l|onCtlColor(o, w, l)}                         , ;
        {|o, w, l|onCtlColor(o, w, l)}                         , ;
        {|o, w, l|onCtlColor(o, w, l)}                         , ;
        {|o, w, l|onCtlColor(o, w, l)}                         , ;
        {|o, w, l|onCommand(o, w, l)}                          , ;
        {|o, w, l|onDrawItem(o, w, l)}                         , ;
        {|o, w, l|onSize(o, w, l)}                             , ;
        {|o|onDestroy(o)}                                      ;
       } ;
     }
#endif

//-------------------------------------------------------------------------------------------------------------------//

CLASS HCustomWindow INHERIT HObject

   CLASS VAR oDefaultParent SHARED
   CLASS VAR WindowsManifest INIT !Empty(hwg_FindResource(, 1, RT_MANIFEST)) SHARED

   DATA handle INIT 0
   DATA oParent
   DATA title
   ACCESS Caption INLINE ::title
   ASSIGN Caption(x) INLINE ::SetTextClass(x)
   DATA Type INIT 0
   DATA nTop, nLeft, nWidth, nHeight
   DATA minWidth INIT -1
   DATA maxWidth INIT -1
   DATA minHeight INIT -1
   DATA maxHeight INIT -1
   DATA tcolor
   DATA bcolor
   DATA brush
   DATA style
   DATA extStyle INIT 0
   DATA lHide INIT .F.
   DATA oFont
   DATA aEvents INIT {}
   DATA lSuspendMsgsHandling INIT .F.
   DATA lGetSkipLostFocus INIT .F.
   DATA aNotify INIT {}
   DATA aControls INIT {}
   DATA bInit
   DATA bDestroy
   DATA bSize
   DATA bPaint
   DATA bGetFocus
   DATA bLostFocus
   DATA bScroll
   DATA bOther
   DATA bRefresh
   DATA cargo
   DATA HelpId INIT 0
   DATA nHolder INIT 0
   DATA nInitFocus INIT 0  // Keeps the ID of the object to receive focus when dialog is created
                           // you can change the object that receives focus adding
                           // ON INIT {||nInitFocus := object:[handle]}  to the dialog definition
   DATA nCurWidth INIT 0
   DATA nCurHeight INIT 0
   DATA nVScrollPos INIT 0
   DATA nHScrollPos INIT 0
   DATA rect
   DATA nScrollBars INIT -1
   DATA lAutoScroll INIT .T.
   DATA nHorzInc
   DATA nVertInc
   DATA nVscrollMax
   DATA nHscrollMax

   DATA lClosable INIT .T. //disable Menu and Button Close in WINDOW

   METHOD AddControl(oCtrl) INLINE AAdd(::aControls, oCtrl)
   METHOD DelControl(oCtrl)
   METHOD AddEvent(nEvent, oCtrl, bAction, lNotify, cMethName)
   METHOD FindControl(nId, nHandle)
   METHOD Hide() INLINE (::lHide := .T., hwg_HideWindow(::handle))
   //METHOD Show() INLINE (::lHide := .F., hwg_ShowWindow(::handle))
   METHOD Show(nShow) INLINE (::lHide := .F., IIf(nShow == NIL, hwg_ShowWindow(::handle), hwg_ShowWindow(::handle, nShow)))
   METHOD Move(x1, y1, width, height, nRePaint)
   METHOD onEvent(msg, wParam, lParam)
   METHOD END()
   METHOD SetColor(tcolor, bColor, lRepaint)
   METHOD RefreshCtrl(oCtrl, nSeek)
   METHOD SetFocusCtrl(oCtrl)
   METHOD Refresh(lAll, oCtrl)
   METHOD Anchor(oCtrl, x, y, w, h)
   METHOD ScrollHV(oForm, msg, wParam, lParam)
   METHOD ResetScrollbars()
   METHOD SetupScrollbars()
   METHOD RedefineScrollbars()
   METHOD SetTextClass(x) HIDDEN
   METHOD GetParentForm(oCtrl)
   METHOD ActiveControl() INLINE ::FindControl(, hwg_GetFocus())
   METHOD Closable(lClosable) SETGET
   METHOD Release() INLINE ::DelControl(Self)
   METHOD SetAll(cProperty, Value, aControls, cClass)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD AddEvent(nEvent, oCtrl, bAction, lNotify, cMethName) CLASS HCustomWindow

   AAdd(IIf(lNotify == NIL .OR. !lNotify, ::aEvents, ::aNotify), ;
      {nEvent, IIf(hb_IsNumeric(oCtrl), oCtrl, oCtrl:id), bAction})
   IF bAction != NIL .AND. hb_IsObject(oCtrl) //.AND. !hb_IsNumeric(oCtrl)
      IF cMethName != NIL //.AND. !__objHasMethod(oCtrl, cMethName)
         __objAddInline(oCtrl, cMethName, bAction)
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD FindControl(nId, nHandle) CLASS HCustomWindow

   LOCAL bSearch := IIf(nId != NIL, {|o|o:id == nId}, {|o|PtrtoUlong(o:handle) == PtrtoUlong(nHandle)})
   LOCAL i := Len(::aControls)
   LOCAL oCtrl

   DO WHILE i > 0
      IF Len(::aControls[i]:aControls) > 0 .AND. ;
         (oCtrl := ::aControls[i]:FindControl(nId, nHandle)) != NIL
         RETURN oCtrl
      ENDIF
      IF Eval(bSearch, ::aControls[i])
         RETURN ::aControls[i]
      ENDIF
      i--
   ENDDO

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD DelControl(oCtrl) CLASS HCustomWindow

   LOCAL h := oCtrl:handle
   LOCAL id := oCtrl:id
   LOCAL i := AScan(::aControls, {|o|o:handle == h})

   hwg_SendMessage(h, WM_CLOSE, 0, 0)
   IF i != 0
      ADel(::aControls, i)
      ASize(::aControls, Len(::aControls) -1)
   ENDIF

   h := 0
   FOR i := Len(::aEvents) TO 1 STEP -1
      IF ::aEvents[i, 2] == id
         ADel(::aEvents, i)
         h++
      ENDIF
   NEXT

   IF h > 0
      ASize(::aEvents, Len(::aEvents) - h)
   ENDIF

   h := 0
   FOR i := Len(::aNotify) TO 1 STEP -1
      IF ::aNotify[i, 2] == id
         ADel(::aNotify, i)
         h++
      ENDIF
   NEXT

   IF h > 0
      ASize(::aNotify, Len(::aNotify) - h)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Move(x1, y1, width, height, nRePaint) CLASS HCustomWindow

   LOCAL rect
   LOCAL nHx := 0
   LOCAL nWx := 0

   x1 := IIf(x1 == NIL, ::nLeft, x1)
   y1 := IIf(y1 == NIL, ::nTop, y1)
   width := IIf(width == NIL, ::nWidth, width)
   height := IIf(height == NIL, ::nHeight, height)
   IF hwg_BitAnd(::style, WS_CHILD) == 0
      rect := hwg_GetwindowRect(::handle)
      nHx := rect[4] - rect[2]  - hwg_GetclientRect(::handle)[4] - ;
         IIf(hwg_BitAnd(::style, WS_HSCROLL) > 0, hwg_GetSystemMetrics(SM_CYHSCROLL), 0)
      nWx := rect[3] - rect[1]  - hwg_GetclientRect(::handle)[3] - ;
         IIf(hwg_BitAnd(::style, WS_VSCROLL) > 0, hwg_GetSystemMetrics(SM_CXVSCROLL), 0)
   ENDIF

   IF nRePaint == NIL
      hwg_MoveWindow(::handle, x1, y1, Width + nWx, Height + nHx)
   ELSE
      hwg_MoveWindow(::handle, x1, y1, Width + nWx, Height + nHx, nRePaint)
   ENDIF

   //IF x1 != NIL
   ::nLeft := x1
   //ENDIF
   //IF y1 != NIL
   ::nTop := y1
   //ENDIF
   //IF width != NIL
   ::nWidth := width
   //ENDIF
   //IF height != NIL
   ::nHeight := height
   //ENDIF
   //hwg_MoveWindow(::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HCustomWindow

   LOCAL i

   // hwg_WriteLog("== " + ::Classname() + Str(msg) + IIf(wParam != NIL, Str(wParam), "NIL") + ;
   //    IIf(lParam != NIL, Str(lParam), "NIL"))

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
   ENDIF

   IF (i := AScan(aCustomEvents[EVENTS_MESSAGES], msg)) != 0
      RETURN Eval(aCustomEvents[EVENTS_ACTIONS, i], Self, wParam, lParam)

   ELSEIF hb_IsBlock(::bOther)

      RETURN Eval(::bOther, Self, msg, wParam, lParam)

   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HCustomWindow

   // hwg_WriteLog("== " + ::Classname() + Str(msg) + IIf(wParam != NIL, Str(wParam), "NIL") + ;
   //    IIf(lParam != NIL, Str(lParam), "NIL"))

   SWITCH msg

   CASE WM_GETMINMAXINFO
      IF ::minWidth > -1 .OR. ::maxWidth > -1 .OR. ::minHeight > -1 .OR. ::maxHeight > -1
         MINMAXWINDOW(::handle, lParam, ;
                      IIf(::minWidth > -1, ::minWidth, NIL), ;
                      IIf(::minHeight > -1, ::minHeight, NIL), ;
                      IIf(::maxWidth > -1, ::maxWidth, NIL), ;
                      IIf(::maxHeight > -1, ::maxHeight, NIL))
         RETURN 0
      ENDIF
      EXIT

   CASE WM_NOTIFY
      RETURN onNotify(SELF, wParam, lParam)

   CASE WM_PAINT
      IF hb_IsBlock(::bPaint)
         RETURN Eval(::bPaint, SELF, wParam)
      ENDIF
      EXIT

   CASE WM_CTLCOLORSTATIC
   CASE WM_CTLCOLOREDIT
   CASE WM_CTLCOLORBTN
   CASE WM_CTLCOLORLISTBOX
      RETURN onCtlColor(SELF, wParam, lParam)

   CASE WM_COMMAND
      RETURN onCommand(SELF, wParam, lParam)

   CASE WM_DRAWITEM
      RETURN onDrawItem(SELF, wParam, lParam)

   CASE WM_SIZE
      RETURN onSize(SELF, wParam, lParam)

   CASE WM_DESTROY
      RETURN onDestroy(SELF)

   #ifdef __XHARBOUR__
   DEFAULT
   #else
   OTHERWISE
   #endif

      IF hb_IsBlock(::bOther)
         RETURN Eval(::bOther, SELF, msg, wParam, lParam)
      ENDIF

   ENDSWITCH

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD END() CLASS HCustomWindow

   LOCAL aControls
   LOCAL i
   LOCAL nLen

   IF ::nHolder != 0

      ::nHolder := 0
      hwg_DecreaseHolders(::handle) // Self)
      aControls := ::aControls
      nLen := Len(aControls)
      FOR i := 1 TO nLen
         aControls[i]:End()
      NEXT
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetParentForm(oCtrl) CLASS HCustomWindow

   LOCAL oForm := IIf(Empty(oCtrl), Self, oCtrl)

   DO WHILE (oForm:oParent) != NIL .AND. !__ObjHasMsg(oForm, "GETLIST")
      oForm := oForm:oParent
   ENDDO

RETURN IIf(hb_IsObject(oForm), oForm, ::oParent)

//-------------------------------------------------------------------------------------------------------------------//

METHOD RefreshCtrl(oCtrl, nSeek) CLASS HCustomWindow

   LOCAL nPos
   LOCAL n

   DEFAULT nSeek TO 1

   IF nSeek == 1
      n := 1
   ELSE
      n := 3
   ENDIF

   nPos := AScan(::aControls, {|x|x[n] == oCtrl})

   IF nPos > 0
      ::aControls[nPos, 2]:Refresh()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetFocusCtrl(oCtrl) CLASS HCustomWindow

   LOCAL nPos

   nPos := AScan(::aControls, {|x|x[1] == oCtrl})

   IF nPos > 0
      ::aControls[nPos, 2]:SetFocus()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Refresh(lAll, oCtrl) CLASS HCustomWindow

   LOCAL nlen
   LOCAL i
   LOCAL hCtrl := hwg_GetFocus()
   LOCAL oCtrlTmp
   LOCAL lRefresh

   oCtrl := IIf(oCtrl == NIL, Self, oCtrl)
   lAll := IIf(lAll == NIL, .F., lAll)
   nLen := Len(oCtrl:aControls)

   IF hwg_IsWindowVisible(::handle) .OR. nLen > 0
      FOR i := 1 TO nLen
         oCtrlTmp := oCtrl:aControls[i]
         lRefresh := !Empty(__ObjHasMethod(oCtrlTmp, "REFRESH"))
         IF ((oCtrlTmp:handle != hCtrl .OR. Len(oCtrlTmp:aControls) == 0) .OR. lAll) .AND. ;
            (!oCtrlTmp:lHide .OR. __ObjHasMsg(oCtrlTmp, "BSETGET"))
            IF Len(oCtrlTmp:aControls) > 0
               ::Refresh(lAll, oCtrlTmp)
            ELSEIF !Empty(lRefresh) .AND. (lAll .OR. ASCAN(::GetList, {|o|o:handle == oCtrlTmp:handle}) > 0)
               oCtrlTmp:Refresh()
               IF oCtrlTmp:bRefresh != NIL
                  Eval(oCtrlTmp:bRefresh, oCtrlTmp)
               ENDIF
            ELSEIF hwg_IsWindowEnabled(oCtrlTmp:handle) .AND. !oCtrlTmp:lHide .AND. !lRefresh
               oCtrlTmp:SHOW(SW_SHOWNOACTIVATE)
            ENDIF
         ENDIF
      NEXT
      IF oCtrl:bRefresh != NIL .AND. oCtrl:handle != hCtrl
         Eval(oCtrl:bRefresh, Self)
      ENDIF
   ELSEIF oCtrl:bRefresh != NIL
      Eval(oCtrl:bRefresh, Self)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetTextClass(x) CLASS HCustomWindow

   IF __ObjHasMsg(Self, "SETVALUE") .AND. ::winClass != "STATIC" .AND. ::winclass != "BUTTON"
   ELSEIF __ObjHasMsg(Self, "SETTEXT") //.AND. ::classname != "HBUTTONEX"
      ::SetText(x)
   ELSE
      ::title := x
      hwg_SendMessage(::handle, WM_SETTEXT, 0, ::Title)
   ENDIF
   //::Refresh()

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetColor(tcolor, bColor, lRepaint) CLASS HCustomWindow

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
      hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Anchor(oCtrl, x, y, w, h) CLASS HCustomWindow

   LOCAL nlen
   LOCAL i
   LOCAL x1
   LOCAL y1

   IF oCtrl == NIL .OR. ASCAN(oCtrl:aControls, {|o|__ObjHasMsg(o, "ANCHOR") .AND. o:Anchor > 0}) == 0
      RETURN .F.
   ENDIF

   nlen := Len(oCtrl:aControls)
   FOR i := nLen TO 1 STEP -1
      IF __ObjHasMsg(oCtrl:aControls[i], "ANCHOR") .AND. oCtrl:aControls[i]:anchor > 0
         x1 := oCtrl:aControls[i]:nWidth
         y1 := oCtrl:aControls[i]:nHeight
         oCtrl:aControls[i]:onAnchor(x, y, w, h)
         IF Len(oCtrl:aControls[i]:aControls) > 0
            ::Anchor(oCtrl:aControls[i], x1, y1, oCtrl:aControls[i]:nWidth, oCtrl:aControls[i]:nHeight)
            //::Anchor(oCtrl:aControls[i], x, y, oCtrl:nWidth, oCtrl:nHeight)
         ENDIF
      ENDIF
   NEXT

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD ScrollHV(oForm, msg, wParam, lParam) CLASS HCustomWindow

   LOCAL nDelta
   LOCAL nSBCode
   LOCAL nPos
   LOCAL nInc

   HB_SYMBOL_UNUSED(lParam)

   nSBCode := hwg_LOWORD(wParam)
   IF msg == WM_MOUSEWHEEL
      nSBCode := IIf(hwg_HIWORD(wParam) > 32768, hwg_HIWORD(wParam) - 65535, hwg_HIWORD(wParam))
      nSBCode := IIf(nSBCode < 0, SB_LINEDOWN, SB_LINEUP)
   ENDIF
   IF (msg == WM_VSCROLL) .OR. msg == WM_MOUSEWHEEL
     // Handle vertical scrollbar messages
     #ifndef __XHARBOUR__
      DO CASE
         Case nSBCode == SB_TOP
             nInc := -oForm:nVscrollPos
         Case nSBCode == SB_BOTTOM
             nInc := oForm:nVscrollMax - oForm:nVscrollPos
         Case nSBCode == SB_LINEUP
             nInc := -Int(oForm:nVertInc * 0.05 + 0.49)
         Case nSBCode == SB_LINEDOWN
             nInc := Int(oForm:nVertInc * 0.05 + 0.49)
         Case nSBCode == SB_PAGEUP
             nInc := min(-1, -oForm:nVertInc)
         Case nSBCode == SB_PAGEDOWN
            nInc := max(1, oForm:nVertInc)
         Case nSBCode == SB_THUMBTRACK
            nPos := hwg_HIWORD(wParam)
            nInc := nPos - oForm:nVscrollPos
         OTHERWISE
            nInc := 0
       ENDCASE
     #else
      Switch (nSBCode)
         Case SB_TOP
             nInc := -oForm:nVscrollPos
             EXIT
         Case SB_BOTTOM
             nInc := oForm:nVscrollMax - oForm:nVscrollPos
             EXIT
         Case SB_LINEUP
             nInc := -Int(oForm:nVertInc * 0.05 + 0.49)
             EXIT
         Case SB_LINEDOWN
             nInc := Int(oForm:nVertInc * 0.05 + 0.49)
             EXIT
         Case SB_PAGEUP
             nInc := min(-1, -oForm:nVertInc / 2)
             EXIT
         Case SB_PAGEDOWN
            nInc := max(1, oForm:nVertInc / 2)
            EXIT
         Case SB_THUMBTRACK
            nPos := hwg_HIWORD(wParam)
            nInc := nPos - oForm:nVscrollPos
            EXIT
         Default
            nInc := 0
      END
      #endif
      nInc := Max(-oForm:nVscrollPos, Min(nInc, oForm:nVscrollMax - oForm:nVscrollPos))
      oForm:nVscrollPos += nInc
      nDelta := -VERT_PTS * nInc
      ScrollWindow(oForm:handle, 0, nDelta) //, NIL, NIL)
      SetScrollPos(oForm:handle, SB_VERT, oForm:nVscrollPos, .T.)

   ELSEIF (msg == WM_HSCROLL) //.OR. msg == WM_MOUSEWHEEL
    // Handle vertical scrollbar messages
      #ifndef __XHARBOUR__
       DO CASE
         Case nSBCode == SB_TOP
             nInc := -oForm:nHscrollPos
         Case nSBCode == SB_BOTTOM
             nInc := oForm:nHscrollMax - oForm:nHscrollPos
         Case nSBCode == SB_LINEUP
             nInc := -1
         Case nSBCode == SB_LINEDOWN
             nInc := 1
         Case nSBCode == SB_PAGEUP
             nInc := -HORZ_PTS
         Case nSBCode == SB_PAGEDOWN
            nInc := HORZ_PTS
         Case nSBCode == SB_THUMBTRACK
            nPos := hwg_HIWORD(wParam)
            nInc := nPos - oForm:nHscrollPos
         OTHERWISE
            nInc := 0
       ENDCASE
      #else
      Switch (nSBCode)
         Case SB_TOP
             nInc := -oForm:nHscrollPos
             EXIT
         Case SB_BOTTOM
             nInc := oForm:nHscrollMax - oForm:nHscrollPos
             EXIT
         Case SB_LINEUP
             nInc := -1
             EXIT
         Case SB_LINEDOWN
             nInc := 1
             EXIT
         Case SB_PAGEUP
             nInc := -HORZ_PTS
             EXIT
         Case SB_PAGEDOWN
            nInc := HORZ_PTS
            EXIT
         Case SB_THUMBTRACK
            nPos := hwg_HIWORD(wParam)
            nInc := nPos - oForm:nHscrollPos
            EXIT
         Default
            nInc := 0
      END
      #endif
      nInc := max(-oForm:nHscrollPos, min(nInc, oForm:nHscrollMax - oForm:nHscrollPos))
      oForm:nHscrollPos += nInc
      nDelta := -HORZ_PTS * nInc
      ScrollWindow(oForm:handle, nDelta, 0) //, NIL, NIL)
      SetScrollPos(oForm:handle, SB_HORZ, oForm:nHscrollPos, .T.)
   ENDIF
   RETURN NIL
#else
METHOD ScrollHV(oForm, msg, wParam, lParam) CLASS HCustomWindow

   LOCAL nDelta
   LOCAL nSBCode
   LOCAL nPos
   LOCAL nInc

   HB_SYMBOL_UNUSED(lParam)

   nSBCode := hwg_LOWORD(wParam)

   IF msg == WM_MOUSEWHEEL
      nSBCode := IIf(hwg_HIWORD(wParam) > 32768, hwg_HIWORD(wParam) - 65535, hwg_HIWORD(wParam))
      nSBCode := IIf(nSBCode < 0, SB_LINEDOWN, SB_LINEUP)
   ENDIF

   SWITCH msg

   CASE WM_VSCROLL
   CASE WM_MOUSEWHEEL
      // Handle vertical scrollbar messages
      SWITCH nSBCode
      CASE SB_TOP
         nInc := -oForm:nVscrollPos
         EXIT
      CASE SB_BOTTOM
         nInc := oForm:nVscrollMax - oForm:nVscrollPos
         EXIT
      CASE SB_LINEUP
         nInc := -Int(oForm:nVertInc * 0.05 + 0.49)
         EXIT
      CASE SB_LINEDOWN
         nInc := Int(oForm:nVertInc * 0.05 + 0.49)
         EXIT
      CASE SB_PAGEUP
         nInc := min(-1, -oForm:nVertInc)
         EXIT
      CASE SB_PAGEDOWN
         nInc := max(1, oForm:nVertInc)
         EXIT
      CASE SB_THUMBTRACK
         nPos := hwg_HIWORD(wParam)
         nInc := nPos - oForm:nVscrollPos
         EXIT
      #ifdef __XHARBOUR__
      DEFAULT
      #else
      OTHERWISE
      #endif
         nInc := 0
      ENDSWITCH
      nInc := Max(-oForm:nVscrollPos, Min(nInc, oForm:nVscrollMax - oForm:nVscrollPos))
      oForm:nVscrollPos += nInc
      nDelta := -VERT_PTS * nInc
      ScrollWindow(oForm:handle, 0, nDelta) //, NIL, NIL)
      SetScrollPos(oForm:handle, SB_VERT, oForm:nVscrollPos, .T.)

   CASE WM_HSCROLL
      // Handle horizontal scrollbar messages
      SWITCH nSBCode
      CASE SB_TOP
         nInc := -oForm:nHscrollPos
         EXIT
      CASE SB_BOTTOM
         nInc := oForm:nHscrollMax - oForm:nHscrollPos
         EXIT
      CASE SB_LINEUP
         nInc := -1
         EXIT
      CASE SB_LINEDOWN
         nInc := 1
         EXIT
      CASE SB_PAGEUP
         nInc := -HORZ_PTS
         EXIT
      CASE SB_PAGEDOWN
         nInc := HORZ_PTS
         EXIT
      CASE SB_THUMBTRACK
         nPos := hwg_HIWORD(wParam)
         nInc := nPos - oForm:nHscrollPos
         EXIT
      #ifdef __XHARBOUR__
      DEFAULT
      #else
      OTHERWISE
      #endif
         nInc := 0
      ENDSWITCH
      nInc := max(-oForm:nHscrollPos, min(nInc, oForm:nHscrollMax - oForm:nHscrollPos))
      oForm:nHscrollPos += nInc
      nDelta := -HORZ_PTS * nInc
      ScrollWindow(oForm:handle, nDelta, 0) //, NIL, NIL)
      SetScrollPos(oForm:handle, SB_HORZ, oForm:nHscrollPos, .T.)

   ENDSWITCH

RETURN NIL
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD RedefineScrollbars() CLASS HCustomWindow

   ::rect := hwg_GetClientRect(::handle)
   IF ::nScrollBars > -1 .AND. ::bScroll == NIL
      IF ::nVscrollPos == 0
         ::ncurHeight := 0                                                              //* 4
         AEval(::aControls, {|o|::ncurHeight := INT(Max(o:nTop + o:nHeight + VERT_PTS * 1, ::ncurHeight))})
      ENDIF
      IF ::nHscrollPos == 0
         ::ncurWidth := 0                                                           // * 4
         AEval(::aControls, {|o|::ncurWidth := INT(Max(o:nLeft + o:nWidth  + HORZ_PTS * 1, ::ncurWidth))})
      ENDIF
      ::ResetScrollbars()
      ::SetupScrollbars()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetupScrollbars() CLASS HCustomWindow

   LOCAL tempRect
   LOCAL nwMax
   LOCAL nhMax
   LOCAL aMenu
   LOCAL nPos

   tempRect := hwg_GetClientRect(::handle)
   aMenu := IIf(__objHasData(Self, "MENU"), ::menu, NIL)
   // Calculate how many scrolling increments for the client area
   IF ::Type == WND_MDICHILD //.AND. ::aRectSave != NIL
      nwMax := Max(::ncurWidth, tempRect[3]) //::maxWidth
      nhMax := Max(::ncurHeight , tempRect[4]) //::maxHeight
      ::nHorzInc := INT((nwMax - tempRect[3]) / HORZ_PTS)
      ::nVertInc := INT((nhMax - tempRect[4]) / VERT_PTS)
   ELSE
      nwMax := Max(::ncurWidth, ::Rect[3])
      nhMax := Max(::ncurHeight, ::Rect[4])
      ::nHorzInc := INT((nwMax - tempRect[3]) / HORZ_PTS + HORZ_PTS)
      ::nVertInc := INT((nhMax - tempRect[4]) / VERT_PTS + VERT_PTS - ;
         IIf(amenu != NIL, hwg_GetSystemMetrics(SM_CYMENU), 0)) // MENU
   ENDIF
    // Set the vertical and horizontal scrolling info
   IF ::nScrollBars == 0 .OR. ::nScrollBars == 2
      ::nHscrollMax := Max(0, ::nHorzInc)
      IF ::nHscrollMax < HORZ_PTS / 2
         //-  ScrollWindow(::handle, ::nHscrollPos * HORZ_PTS, 0)
      ELSEIF ::nHScrollMax <= HORZ_PTS
         ::nHScrollMax := 0
      ENDIF
      ::nHscrollPos := Min(::nHscrollPos, ::nHscrollMax)
      SetScrollPos(::handle, SB_HORZ, ::nHscrollPos, .T.)
      SetScrollInfo(::handle, SB_HORZ, 1, ::nHScrollPos , HORZ_PTS, ::nHscrollMax)
      IF ::nHscrollPos > 0
         nPos := GetScrollPos(::handle, SB_HORZ)
         IF nPos < ::nHscrollPos
            ScrollWindow(::handle, 0, (::nHscrollPos - nPos) * SB_HORZ)
            ::nVscrollPos := nPos
            SetScrollPos(::handle, SB_HORZ, ::nHscrollPos, .T.)
         ENDIF
      ENDIF
   ENDIF
   IF ::nScrollBars == 1 .OR. ::nScrollBars == 2
      ::nVscrollMax := INT(Max(0, ::nVertInc))
      IF ::nVscrollMax < VERT_PTS / 2
         //-  ScrollWindow(::handle, 0, ::nVscrollPos * VERT_PTS)
      ELSEIF ::nVScrollMax <= VERT_PTS
         ::nVScrollMax := 0
      ENDIF
      SetScrollPos(::handle, SB_VERT, ::nVscrollPos, .T.)
      SetScrollInfo(::handle, SB_VERT, 1, ::nVscrollPos , VERT_PTS, ::nVscrollMax)
      IF ::nVscrollPos > 0 //.AND. nPosVert != ::nVscrollPos
         nPos := GetScrollPos(::handle, SB_VERT)
         IF nPos < ::nVscrollPos
            ScrollWindow(::handle, 0, (::nVscrollPos - nPos) * VERT_PTS)
            ::nVscrollPos := nPos
            SetScrollPos(::handle, SB_VERT, ::nVscrollPos, .T.)
         ENDIF
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD ResetScrollbars() CLASS HCustomWindow
   // Reset our window scrolling information

   LOCAL lMaximized := GetWindowPlacement(::handle) == SW_MAXIMIZE

   IF lMaximized
      ScrollWindow(::handle, ::nHscrollPos * HORZ_PTS, 0)
      ScrollWindow(::handle, 0, ::nVscrollPos * VERT_PTS)
      ::nHscrollPos := 0
      ::nVscrollPos := 0
   ENDIF
   /*
   IF ::nScrollBars == 0 .OR. ::nScrollBars == 2
      ScrollWindow(::handle, 0 * HORZ_PTS, 0)
      SetScrollPos(::handle, SB_HORZ, 0, .T.)
   ENDIF
   IF ::nScrollBars == 1 .OR. ::nScrollBars == 2
      ScrollWindow(::handle, 0, 0 * VERT_PTS)
      SetScrollPos(::handle, SB_VERT, 0, .T.)
   ENDIF
   */

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

/*
METHOD ScrollHV(oForm, msg, wParam, lParam) CLASS HCustomWindow

   LOCAL nDelta
   LOCAL nMaxPos
   LOCAL wmsg
   LOCAL nPos

   HB_SYMBOL_UNUSED(lParam)

   nDelta := 0
   wmsg := hwg_LOWORD(wParam)

   IF msg == WM_VSCROLL .OR. msg == WM_HSCROLL
      nMaxPos := IIf(msg == WM_VSCROLL, oForm:rect[4] - oForm:nCurHeight, oForm:rect[3] - oForm:nCurWidth)
      IF wmsg == SB_LINEDOWN
         IF (oForm:nScrollPos >= nMaxPos)
            RETURN 0
         ENDIF
         nDelta := Min(nMaxPos / 100, nMaxPos - oForm:nScrollPos)
      ELSEIF wmsg == SB_LINEUP
         IF (oForm:nScrollPos <= 0)
            RETURN 0
         ENDIF
         nDelta := -Min(nMaxPos / 100, oForm:nScrollPos)
      ELSEIF wmsg == SB_PAGEDOWN
         IF (oForm:nScrollPos >= nMaxPos)
            RETURN 0
         ENDIF
         nDelta := Min(nMaxPos / 10, nMaxPos - oForm:nScrollPos)
      ELSEIF wmsg == SB_THUMBPOSITION
         nPos := hwg_HIWORD(wParam)
         nDelta := nPos - oForm:nScrollPos
      ELSEIF wmsg == SB_PAGEUP
         IF (oForm:nScrollPos <= 0)
            RETURN 0
         ENDIF
         nDelta := -Min(nMaxPos / 10, oForm:nScrollPos)
      ELSE
         RETURN 0
      ENDIF
      oForm:nScrollPos += nDelta
      IF msg == WM_VSCROLL
         setscrollpos(oForm:handle, SB_VERT, oForm:nScrollPos)
         ScrollWindow(oForm:handle, 0, -nDelta)
      ELSE
         setscrollpos(oForm:handle, SB_HORZ, oForm:nScrollPos)
         ScrollWindow(oForm:handle, -nDelta, 0)
      ENDIF
      RETURN -1

   ENDIF

RETURN NIL
*/
//-------------------------------------------------------------------------------------------------------------------//

METHOD Closable(lClosable) CLASS HCustomWindow

   LOCAL hMenu

   IF lClosable != NIL
      IF !lClosable
         hMenu := EnableMenuSystemItem(::handle, SC_CLOSE, .F.)
      ELSE
         hMenu := EnableMenuSystemItem(::handle, SC_CLOSE, .T.)
      ENDIF
      IF !Empty(hMenu)
         ::lClosable := lClosable
      ENDIF
   ENDIF

RETURN ::lClosable

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetAll(cProperty, Value, aControls, cClass) CLASS HCustomWindow
// cProperty Specifies the property to be set.
// Value Specifies the new setting for the property. The data type of Value depends on the property being set.
 //aControls - property of the Control with objectos inside
 // cClass baseclass hwgui

   LOCAL nLen
   LOCAL i
   //LOCAL oCtrl

   aControls := IIf(Empty(aControls), ::aControls, aControls)
   nLen := IIf(hb_IsChar(aControls), Len(::&aControls), Len(aControls))
   FOR i := 1 TO nLen
      IF hb_IsChar(aControls)
         ::&aControls[i]:&cProperty := Value
      ELSEIF cClass == NIL .OR. Upper(cClass) == aControls[i]:ClassName
         IF Value == NIL
            __mvPrivate("oCtrl")
            &("oCtrl") := aControls[i]
            &("oCtrl:" + cProperty)
         ELSE
            aControls[i]:&cProperty := Value
         ENDIF
      ENDIF
   NEXT

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onNotify(oWnd, wParam, lParam)

   LOCAL iItem
   LOCAL oCtrl := oWnd:FindControl(wParam)
   LOCAL nCode
   LOCAL res
   LOCAL n

   IF oCtrl == NIL
      FOR n := 1 TO Len(oWnd:aControls)
         oCtrl := oWnd:aControls[n]:FindControl(wParam)
         IF oCtrl != NIL
            EXIT
         ENDIF
      NEXT
   ENDIF

   IF oCtrl != NIL .AND. !hb_IsNumeric(oCtrl)
      IF __ObjHasMsg(oCtrl, "NOTIFY")
         RETURN oCtrl:Notify(lParam)
      ELSE
         nCode := hwg_GetNotifyCode(lParam)
         IF nCode == EN_PROTECTED
            RETURN 1
         ELSEIF oWnd:aNotify != NIL .AND. !oWnd:lSuspendMsgsHandling .AND. ;
            (iItem := AScan(oWnd:aNotify, {|a|a[1] == nCode .AND. a[2] == wParam})) > 0
            IF (res := Eval(oWnd:aNotify[iItem, 3], oWnd, wParam)) != NIL
               RETURN res
            ENDIF
         ENDIF
      ENDIF
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onDestroy(oWnd)

   LOCAL aControls := oWnd:aControls
   LOCAL i
   LOCAL nLen := Len(aControls)

   FOR i := 1 TO nLen
      aControls[i]:END()
   NEXT
   nLen := Len(oWnd:aObjects)
   FOR i := 1 TO nLen
      oWnd:aObjects[i]:END()
   NEXT
   oWnd:END()

RETURN 1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onCtlColor(oWnd, wParam, lParam)

   LOCAL oCtrl

   //lParam := HANDLETOPTR(lParam)
   oCtrl := oWnd:FindControl(, lParam)

   IF oCtrl != NIL .AND. !hb_IsNumeric(oCtrl)
      IF oCtrl:tcolor != NIL
         SetTextColor(wParam, oCtrl:tcolor)
      ENDIF
      SetBkMode(wParam, oCtrl:backstyle)
      IF !oCtrl:IsEnabled() .AND. oCtrl:Disablebrush != NIL
         SetBkMode(wParam, TRANSPARENT)
         SetBkColor(wParam, oCtrl:DisablebColor)
         RETURN oCtrl:disablebrush:handle
      ELSEIF oCtrl:bcolor != NIL .AND. oCtrl:BackStyle == OPAQUE
         SetBkColor(wParam, oCtrl:bcolor)
         IF oCtrl:brush != NIL
            RETURN oCtrl:brush:handle
         ELSEIF oCtrl:oParent:brush != NIL
            RETURN oCtrl:oParent:brush:handle
         ENDIF
      ELSEIF oCtrl:BackStyle == TRANSPARENT
         /*
         IF (oCtrl:classname $ "HCHECKBUTTON" .AND. (!oCtrl:lnoThemes .AND. (ISTHEMEACTIVE() .AND. oCtrl:WindowsManifest))) .OR.;
            (oCtrl:classname $ "HGROUP*HRADIOGROUP*HRADIOBUTTON" .AND. !oCtrl:lnoThemes)
                RETURN GetBackColorParent(oCtrl, , .T.):handle
             ENDIF
         */
         IF __ObjHasMsg(oCtrl, "PAINT") .OR. oCtrl:lnoThemes .OR. ;
            (oCtrl:winClass == "BUTTON" .AND. oCtrl:classname != "HCHECKBUTTON")
            RETURN GetStockObject(NULL_BRUSH)
         ENDIF
         RETURN GetBackColorParent(oCtrl, , .T.):handle
      ELSEIF oCtrl:winClass == "BUTTON" .AND. (ISTHEMEACTIVE() .AND. oCtrl:WindowsManifest)
         RETURN GetBackColorParent(oCtrl, , .T.):handle
      ENDIF
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onDrawItem(oWnd, wParam, lParam)

   LOCAL oCtrl

   IF !Empty(wParam) .AND. (oCtrl := oWnd:FindControl(wParam)) != NIL .AND. !hb_IsNumeric(oCtrl) .AND. ;
      oCtrl:bPaint != NIL
      Eval(oCtrl:bPaint, oCtrl, lParam)
      RETURN 1
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onCommand(oWnd, wParam, lParam)

   LOCAL iItem
   LOCAL iParHigh := hwg_HIWORD(wParam)
   LOCAL iParLow := hwg_LOWORD(wParam)
   LOCAL oForm := oWnd:GetParentForm()

   HB_SYMBOL_UNUSED(lParam)

   IF oWnd:aEvents != NIL .AND. !oForm:lSuspendMsgsHandling .AND. !oWnd:lSuspendMsgsHandling .AND. ;
      (iItem := AScan(oWnd:aEvents, {|a|a[1] == iParHigh .AND. a[2] == iParLow})) > 0
      IF oForm:Type < WND_DLG_RESOURCE
         IF hwg_SelfFocus(hwg_GetParent(hwg_GetFocus()) , oForm:handle)
            oForm:nFocus := hwg_GetFocus() //lParam
         ENDIF
      ENDIF
      Eval(oWnd:aEvents[iItem, 3], oWnd, iParLow)
   ENDIF

RETURN 1

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION onSize(oWnd, wParam, lParam)

   LOCAL aControls := oWnd:aControls
   LOCAL oItem
   LOCAL nw1
   LOCAL nh1
   LOCAL aCoors
   LOCAL nWindowState

   nw1 := oWnd:nWidth
   nh1 := oWnd:nHeight
   aCoors := hwg_GetWindowRect(oWnd:handle)
   IF Empty(oWnd:Type)
      oWnd:nWidth := aCoors[3] - aCoors[1]
      oWnd:nHeight := aCoors[4] - aCoors[2]
   ELSE
      nWindowState := oWnd:WindowState
      IF wParam != 1 .AND. (oWnd:GETMDIMAIN() != NIL .AND. !oWnd:GETMDIMAIN():IsMinimized()) //SIZE_MINIMIZED
         oWnd:nWidth := aCoors[3] - aCoors[1]
         oWnd:nHeight := aCoors[4] - aCoors[2]
         IF oWnd:Type == WND_MDICHILD .AND. oWnd:GETMDIMAIN() != NIL .AND. wParam != 1 .AND. ;
            oWnd:GETMDIMAIN():WindowState == 2
            nWindowState := SW_SHOWMINIMIZED
         ENDIF
      ENDIF
   ENDIF
   IF oWnd:nScrollBars > -1 .AND. oWnd:lAutoScroll .AND. !Empty(oWnd:Type)
      onMove(oWnd)
      oWnd:ResetScrollbars()
      oWnd:SetupScrollbars()
   ENDIF
   IF wParam != 1 .AND. nWindowState != 2
      IF !Empty(oWnd:Type) .AND. oWnd:Type == WND_MDI .AND. !Empty(oWnd:Screen)
         oWnd:Anchor(oWnd:Screen, nw1, nh1, oWnd:nWidth, oWnd:nHeight)
      ENDIF
      IF !Empty(oWnd:Type)
         oWnd:Anchor(oWnd, nw1, nh1, oWnd:nWidth, oWnd:nHeight)
      ENDIF
   ENDIF

   FOR EACH oItem IN aControls
      IF oItem:bSize != NIL
         Eval(oItem:bSize, oItem, hwg_LOWORD(lParam), hwg_HIWORD(lParam))
      ENDIF
   NEXT

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
FUNCTION onTrackScroll(oWnd, msg, wParam, lParam)

   LOCAL oCtrl := oWnd:FindControl(, lParam)

   IF oCtrl != NIL
      msg := hwg_LOWORD(wParam)
      IF msg == TB_ENDTRACK
         IF hb_IsBlock(oCtrl:bChange)
            Eval(oCtrl:bChange, oCtrl)
            RETURN 0
         ENDIF
      ELSEIF msg == TB_THUMBTRACK .OR. msg == TB_PAGEUP .OR. msg == TB_PAGEDOWN
         IF hb_IsBlock(oCtrl:bThumbDrag)
            Eval(oCtrl:bThumbDrag, oCtrl)
            RETURN 0
         ENDIF
      ENDIF
   ELSE
      IF hb_IsBlock(oWnd:bScroll)
         Eval(oWnd:bScroll, oWnd, msg, wParam, lParam)
         RETURN 0
      ENDIF
   ENDIF

RETURN -1
#else
FUNCTION onTrackScroll(oWnd, msg, wParam, lParam)

   LOCAL oCtrl := oWnd:FindControl(, lParam)

   IF oCtrl != NIL
      msg := hwg_LOWORD(wParam)
      SWITCH msg
      CASE TB_ENDTRACK
         IF hb_IsBlock(oCtrl:bChange)
            Eval(oCtrl:bChange, oCtrl)
            RETURN 0
         ENDIF
         EXIT
      CASE TB_THUMBTRACK
      CASE TB_PAGEUP
      CASE TB_PAGEDOWN
         IF hb_IsBlock(oCtrl:bThumbDrag)
            Eval(oCtrl:bThumbDrag, oCtrl)
            RETURN 0
         ENDIF
      ENDSWITCH
   ELSE
      IF hb_IsBlock(oWnd:bScroll)
         Eval(oWnd:bScroll, oWnd, msg, wParam, lParam)
         RETURN 0
      ENDIF
   ENDIF

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION ProcKeyList(oCtrl, wParam, oMain)

   LOCAL oParent
   LOCAL nCtrl
   LOCAL nPos

   IF (wParam == VK_RETURN .OR. wParam == VK_ESCAPE) .AND. ProcOkCancel(oCtrl, wParam)
      RETURN .F.
   ENDIF
   IF wParam != VK_SHIFT .AND. wParam != VK_CONTROL .AND. wParam != VK_MENU
      oParent := IIf(oMain != NIL, oMain, ParentGetDialog(oCtrl))
      IF oParent != NIL .AND. !Empty(oParent:KeyList)
         nctrl := IIf(IsCtrlShift(.T., .F.), FCONTROL, IIf(IsCtrlShift(.F., .T.), FSHIFT, 0))
         IF (nPos := AScan(oParent:KeyList, {|a|a[1] == nctrl .AND. a[2] == wParam})) > 0
            Eval(oParent:KeyList[nPos, 3], oCtrl)
            RETURN .T.
         ENDIF
      ENDIF
      IF oParent != NIL .AND. oMain == NIL .AND. HWindow():GetMain() != NIL
          ProcKeyList(oCtrl, wParam, HWindow():GetMain():aWindows[1])
      ENDIF
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION ProcOkCancel(oCtrl, nKey, lForce)

   LOCAL oWin := oCtrl:GetParentForm()
   LOCAL lEscape
   LOCAL iParHigh := IIf(nKey == VK_RETURN, IDOK, IDCANCEL)
   LOCAL oCtrlFocu := oCtrl

   lForce := !Empty(lForce)
   lEscape := nKey == VK_ESCAPE .AND. (oCtrl := oWin:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled()
   IF ((oWin:Type >= WND_DLG_RESOURCE .AND. oWin:lModal) .AND. !lForce .AND. !lEscape) .OR. ;
      (nKey != VK_RETURN .AND. nKey != VK_ESCAPE)
      RETURN .F.
   ENDIF
   IF iParHigh == IDOK
      IF (oCtrl := oWin:FindControl(IDOK)) != NIL .AND. oCtrl:IsEnabled()
         oCtrl:SetFocus()
         oWin:lResult := .T.
         IF lForce
         ELSEIF hb_IsBlock(oCtrl:bClick) .AND. !lForce
            hwg_SendMessage(oCtrl:oParent:handle, WM_COMMAND, makewparam(oCtrl:id, BN_CLICKED), oCtrl:handle)
         ELSEIF oWin:lExitOnEnter
            oWin:close()
         ELSE
            hwg_SendMessage(oWin:handle, WM_COMMAND, makewparam(IDOK, 0), oCtrlFocu:handle)
         ENDIF
         RETURN .T.
      ENDIF
   ELSEIF iParHigh == IDCANCEL
      IF (oCtrl := oWin:FindControl(IDCANCEL)) != NIL .AND. oCtrl:IsEnabled()
         oCtrl:SetFocus()
         oWin:lResult := .F.
         hwg_SendMessage(oCtrl:oParent:handle, WM_COMMAND, makewparam(oCtrl:id, BN_CLICKED), oCtrl:handle)
      ELSEIF oWin:lGetSkiponEsc
         oCtrl := oCtrlFocu
         IF oCtrl != NIL .AND. __ObjHasMsg(oCtrl, "OGROUP") .AND. oCtrl:oGroup:oHGroup != NIL
            oCtrl := oCtrl:oGroup:oHGroup
         ENDIF
         IF oCtrl != NIL .AND. GetSkip(oCtrl:oParent, oCtrl:handle, , -1)
            IF AScan(oWin:GetList, {|o|o:handle == oCtrl:handle}) > 1
               RETURN .T.
            ENDIF
         ENDIF
      ELSEIF oWin:lExitOnEsc
         oWin:close()
      ELSEIF !oWin:lExitOnEsc
         oWin:nLastKey := 0
         hwg_SendMessage(oWin:handle, WM_COMMAND, makewparam(IDCANCEL, 0), oCtrlFocu:handle)
         RETURN .F.
      ENDIF
      RETURN .T.
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION FindAccelerator(oCtrl, lParam)

   LOCAL nlen
   LOCAL i
   LOCAL pos

   nlen := Len(oCtrl:aControls)
   FOR i := 1 TO nLen
      IF oCtrl:aControls[i]:classname = "HTAB"
         IF (pos := FindTabAccelerator(oCtrl:aControls[i], lParam)) > 0 .AND. ;
            oCtrl:aControls[i]:Pages[pos]:Enabled
            oCtrl:aControls[i]:SetTab(pos)
            RETURN oCtrl:aControls[i]
         ENDIF
      ENDIF
      IF Len(oCtrl:aControls[i]:aControls) > 0
         RETURN FindAccelerator(oCtrl:aControls[i], lParam)
      ENDIF
      IF __ObjHasMsg(oCtrl:aControls[i], "TITLE") .AND. hb_IsChar(oCtrl:aControls[i]:title) .AND. ;
         !oCtrl:aControls[i]:lHide .AND. hwg_IsWindowEnabled(oCtrl:aControls[i]:handle)
         IF (pos := At("&", oCtrl:aControls[i]:title)) > 0 .AND. ;
            Upper(Chr(lParam)) == Upper(SubStr(oCtrl:aControls[i]:title, ++pos, 1))
            RETURN oCtrl:aControls[i]
         ENDIF
      ENDIF
   NEXT

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION GetBackColorParent(oCtrl, lSelf, lTransparent)

   LOCAL bColor := GetSysColor(COLOR_BTNFACE)
   LOCAL hTheme
   LOCAL brush := NIL

   DEFAULT lTransparent TO .F.
   IF lSelf == NIL .OR. !lSelf
      oCtrl := oCtrl:oParent
   ENDIF
   IF oCtrl != NIL .AND. oCtrl:Classname = "HTAB"
      //-brush := HBrush():Add(bColor)
      IF Len(oCtrl:aPages) > 0 .AND. oCtrl:Pages[oCtrl:GETACTIVEPAGE()]:bColor != NIL
         //-brush := oCtrl:Pages[oCtrl:GetActivePage()]:brush
         bColor := oCtrl:Pages[oCtrl:GetActivePage()]:bColor
      ELSEIF ISTHEMEACTIVE() .AND. oCtrl:WindowsManifest
         hTheme := hb_OpenThemeData(oCtrl:handle, "TAB") //oCtrl:oParent:WinClass)
         IF !Empty(hTheme)
            bColor := HWG_GETTHEMESYSCOLOR(hTheme, COLOR_WINDOW)
            HB_CLOSETHEMEDATA(hTheme)
            //-brush := HBrush():Add(bColor)
         ENDIF
      ENDIF
   ELSEIF oCtrl:bColor != NIL
      //-brush := oCtrl:brush
      bColor := oCtrl:bColor
   //-ELSEIF oCtrl:brush == NIL .AND. lTransparent
   //-   brush := HBrush():Add(bColor)
   ENDIF
   brush := HBrush():Add(bColor)

RETURN brush

//-------------------------------------------------------------------------------------------------------------------//
