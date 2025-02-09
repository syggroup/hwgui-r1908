//
// $Id: hcontrol.prg 1902 2012-09-20 11:51:37Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HStatic class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define TRANSPARENT 1

//-------------------------------------------------------------------------------------------------------------------//

CLASS HStatic INHERIT HControl

   CLASS VAR winclass INIT "STATIC"

   DATA AutoSize INIT .T.
   //DATA lTransparent INIT .F. HIDDEN
   DATA nStyleHS
   DATA bClick
   DATA bDblClick
   DATA hBrushDefault HIDDEN

   METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, bSize, bPaint, cTooltip, ;
      tcolor, bColor, lTransp, bClick, bDblClick, bOther)
   METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, ;
      bDblClick, bOther)
   METHOD Activate()
   //METHOD SetValue(value) INLINE hwg_SetDlgItemText(::oParent:handle, ::id, ;
   //
   METHOD SetText(value) INLINE ::SetValue(value)
   METHOD SetValue(cValue)
   METHOD Auto_Size(cValue) HIDDEN
   METHOD Init()
   METHOD PAINT(lpDis)
   METHOD onClick()
   METHOD onDblClick()
   METHOD OnEvent(msg, wParam, lParam)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, bSize, bPaint, cTooltip, ;
   tcolor, bColor, lTransp, bClick, bDblClick, bOther) CLASS HStatic

   LOCAL nStyles

   // Enabling style for tooltips
   //IF hb_IsChar(cTooltip)
   //   IF nStyle == NIL
   //      nStyle := SS_NOTIFY
   //   ELSE
   nStyles := IIf(hwg_BitAND(nStyle, WS_BORDER) != 0, WS_BORDER, 0)
   nStyles += IIf(hwg_BitAND(nStyle, WS_DLGFRAME) != 0, WS_DLGFRAME, 0)
   nStyles += IIf(hwg_BitAND(nStyle, WS_DISABLED) != 0, WS_DISABLED, 0)
   nStyle  := hwg_BitOr(nStyle, SS_NOTIFY) - nStyles
   //    ENDIF
   // ENDIF
   //
   ::nStyleHS := IIf(nStyle == NIL, 0, nStyle)
   ::BackStyle := OPAQUE
   IF (lTransp != NIL .AND. lTransp) //.OR. ::lOwnerDraw
      ::BackStyle := TRANSPARENT
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := {|o, p|o:paint(p)}
      nStyle := SS_OWNERDRAW + hwg_Bitand(nStyle, SS_NOTIFY)
   ELSEIF nStyle - SS_NOTIFY > 32 .OR. ::nStyleHS - SS_NOTIFY == 2
      bPaint := {|o, p|o:paint(p)}
      nStyle := SS_OWNERDRAW + hwg_Bitand(nStyle, SS_NOTIFY)
   ENDIF
   ::hBrushDefault := HBrush():Add(GetSysColor(COLOR_BTNFACE))

   ::Super:New(oWndParent, nId, nStyle + nStyles, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ;
      cTooltip, tcolor, bColor)

   IF ::oParent:oParent != NIL
   //   bPaint := {|o, p|o:paint(p)}
   ENDIF
   ::bOther := bOther
   ::title := cCaption

   ::Activate()

   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent(STN_CLICKED, Self, {||::onClick()})
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent(STN_DBLCLK, Self, {||::onDblClick()})

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, ;
   bDblClick, bOther) CLASS HStatic

   IF (lTransp != NIL .AND. lTransp)  //.OR. ::lOwnerDraw
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := {|o, p|o:paint(p)}
      ::BackStyle := TRANSPARENT
   ENDIF

   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor)

   ::title := cCaption
   ::style := 0
   ::nLeft := 0
   ::nTop := 0
   ::nWidth := 0
   ::nHeight := 0
   // Enabling style for tooltips
   //IF hb_IsChar(cTooltip)
   ::Style := SS_NOTIFY
   //ENDIF
   ::bOther := bOther
   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent(STN_CLICKED, Self, {||::onClick()})
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent(STN_DBLCLK, Self, {||::onDblClick()})

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HStatic

   IF !Empty(::oParent:handle)
      ::handle := CreateStatic(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle)
      ::Init()
      //::Style := ::nStyleHS
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Init() CLASS HStatic

   IF !::lInit
      ::Super:init()
      IF ::nHolder != 1
         ::nHolder := 1
         hwg_SetWindowObject(::handle, Self)
         hwg_InitStaticProc(::handle)
      ENDIF
      IF ::classname == "HSTATIC"
         ::Auto_Size(::Title)
      ENDIF
      IF ::title != NIL
         hwg_SetWindowText(::handle, ::title)
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD OnEvent(msg, wParam, lParam) CLASS  HStatic

   LOCAL nEval
   LOCAL pos

   IF hb_IsBlock(::bOther)
      IF (nEval := Eval(::bOther, Self, msg, wParam, lParam)) != -1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF

   IF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg == WM_KEYUP
      IF wParam == VK_DOWN
         getskip(::oparent, ::handle, , 1)
      ELSEIF wParam == VK_UP
         getskip(::oparent, ::handle, , -1)
      ELSEIF wParam == VK_TAB
         GetSkip(::oParent, ::handle, , iif(IsCtrlShift(.F., .T.), -1, 1))
      ENDIF
      RETURN 0
   ELSEIF msg == WM_SYSKEYUP
      IF (pos := At("&", ::title)) > 0 .AND. wParam == Asc(Upper(SubStr(::title, ++pos, 1)))
         getskip(::oparent, ::handle, , 1)
         RETURN  0
      ENDIF
   ELSEIF msg == WM_GETDLGCODE
      RETURN DLGC_WANTARROWS + DLGC_WANTTAB // +DLGC_STATIC   //DLGC_WANTALLKEYS //DLGC_WANTARROWS  + DLGC_WANTCHARS
   ENDIF

RETURN -1
#else
METHOD OnEvent(msg, wParam, lParam) CLASS  HStatic

   LOCAL nEval
   LOCAL pos

   IF hb_IsBlock(::bOther)
      IF (nEval := Eval(::bOther, Self, msg, wParam, lParam)) != -1 .AND. nEval != NIL
         RETURN 0
      ENDIF
   ENDIF

   SWITCH msg

   CASE WM_ERASEBKGND
      RETURN 0

   CASE WM_KEYUP
      SWITCH wParam
      CASE VK_DOWN
         getskip(::oparent, ::handle, , 1)
      CASE VK_UP
         getskip(::oparent, ::handle, , -1)
      CASE VK_TAB
         GetSkip(::oParent, ::handle, , iif(IsCtrlShift(.F., .T.), -1, 1))
      ENDSWITCH
      RETURN 0

   CASE WM_SYSKEYUP
      IF (pos := At("&", ::title)) > 0 .AND. wParam == Asc(Upper(SubStr(::title, ++pos, 1)))
         getskip(::oparent, ::handle, , 1)
         RETURN  0
      ENDIF
      EXIT

   CASE WM_GETDLGCODE
      RETURN DLGC_WANTARROWS + DLGC_WANTTAB // + DLGC_STATIC //DLGC_WANTALLKEYS //DLGC_WANTARROWS + DLGC_WANTCHARS

   ENDSWITCH

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetValue(cValue) CLASS HStatic

   ::Auto_Size(cValue)
   IF ::Title != cValue
      IF ::backstyle == TRANSPARENT .AND. ::Title != cValue .AND. hwg_IsWindowVisible(::handle)
         hwg_RedrawWindow(::oParent:handle, RDW_NOERASE + RDW_INVALIDATE + RDW_ERASENOW, ;
            ::nLeft, ::nTop, ::nWidth, ::nHeight)
         hwg_InvalidateRect(::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight)
      ENDIF
      hwg_SetDlgItemText(::oParent:handle, ::id, cValue)
   ELSEIF ::backstyle != TRANSPARENT
      hwg_SetDlgItemText(::oParent:handle, ::id, cValue)
   ENDIF
   ::Title := cValue

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Paint(lpDis) CLASS HStatic

   LOCAL drawInfo := hwg_GetDrawItemInfo(lpDis)
   LOCAL client_rect
   LOCAL szText
   LOCAL dwtext
   LOCAL nstyle
   LOCAL brBackground
   LOCAL dc := drawInfo[3]

   client_rect := CopyRect({drawInfo[4], drawInfo[5], drawInfo[6], drawInfo[7]})
   //client_rect := hwg_GetClientRect(::handle)
   szText := hwg_GetWindowText(::handle)

   // Map "Static Styles" to "Text Styles"
   nstyle := ::nStyleHS // ::style
   IF nStyle - SS_NOTIFY < DT_SINGLELINE
      SetAStyle(@nstyle, @dwtext)
   ELSE
      dwtext := nStyle - DT_NOCLIP
   ENDIF

   // Set transparent background
   SetBkMode(dc, ::backstyle)
   IF ::BackStyle == OPAQUE
      brBackground := IIf(!Empty(::brush), ::brush, ::hBrushDefault)
      FillRect(dc, client_rect[1], client_rect[2], client_rect[3], client_rect[4], brBackground:handle)
   ENDIF

   IF ::tcolor != NIL .AND. ::isEnabled()
      SetTextColor(dc, ::tcolor)
   ELSEIF !::isEnabled()
      SetTextColor(dc, 16777215) //GetSysColor(COLOR_WINDOW))
      DrawText(dc, szText, {client_rect[1] + 1, client_rect[2] + 1, client_rect[3] + 1, client_rect[4] + 1}, dwtext)
      SetBkMode(dc, TRANSPARENT)
      SetTextColor(dc, 10526880) //GetSysColor(COLOR_GRAYTEXT))
   ENDIF
   // Draw the text
   DrawText(dc, szText, client_rect, dwtext)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD onClick() CLASS HStatic

   IF hb_IsBlock(::bClick)
      //::oParent:lSuspendMsgsHandling := .T.
      Eval(::bClick, Self, ::id)
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD onDblClick() CLASS HStatic

   IF hb_IsBlock(::bDblClick)
      //::oParent:lSuspendMsgsHandling := .T.
      Eval(::bDblClick, Self, ::id)
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Auto_Size(cValue) CLASS HStatic

   LOCAL ASize
   LOCAL nLeft
   LOCAL nAlign

   IF ::autosize  //.OR. ::lOwnerDraw
      nAlign := ::nStyleHS - SS_NOTIFY
      ASize := TxtRect(cValue, Self)
      // ajust VCENTER
      // ::nTop := ::nTop + Int((::nHeight - ASize[2] + 2) / 2)
      SWITCH nAlign
      CASE SS_RIGHT
         nLeft := ::nLeft + (::nWidth - ASize[1] - 2)
         EXIT
      CASE SS_CENTER
         nLeft := ::nLeft + Int((::nWidth - ASize[1] - 2) / 2)
         EXIT
      CASE SS_LEFT
         nLeft := ::nLeft
      ENDSWITCH
      ::nWidth := ASize[1] + 2
      ::nHeight := ASize[2]
      ::nLeft := nLeft
      ::move(::nLeft, ::nTop)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//
