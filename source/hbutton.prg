//
// $Id: hcontrol.prg 1902 2012-09-20 11:51:37Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HButton class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

//-------------------------------------------------------------------------------------------------------------------//

CLASS HButton INHERIT HControl

   CLASS VAR winclass INIT "BUTTON"

   DATA bClick
   DATA cNote HIDDEN
   DATA lFlat INIT .F.

   METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, bSize, bPaint, bClick, ;
      cTooltip, tcolor, bColor, bGFocus)
   METHOD Activate()
   METHOD Redefine(oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, tcolor, bColor, cCaption, bGFocus)
   METHOD Init()
   //METHOD Notify(lParam)
   METHOD onClick()
   METHOD onGetFocus()
   METHOD onLostFocus()
   METHOD onEvent(msg, wParam, lParam)
   METHOD NoteCaption(cNote) SETGET

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, bSize, bPaint, bClick, ;
   cTooltip, tcolor, bColor, bGFocus) CLASS HButton

   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), BS_PUSHBUTTON + BS_NOTIFY)

   ::title := cCaption
   ::bClick := bClick
   ::bGetFocus := bGFocus
   ::lFlat := hwg_BitAND(nStyle, BS_FLAT) != 0

   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, IIf(nWidth == NIL, 90, nWidth), ;
      IIf(nHeight == NIL, 30, nHeight), oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor)

   ::Activate()
   //IF bGFocus != NIL
   ::bGetFocus := bGFocus
   ::oParent:AddEvent(BN_SETFOCUS, Self, {||::onGetFocus()})
   ::oParent:AddEvent(BN_KILLFOCUS, self, {|| ::onLostFocus()})
   //ENDIF
   /*
   IF ::oParent:oParent != NIL .AND. ::oParent:ClassName == "HTAB"
      //::oParent:AddEvent(BN_KILLFOCUS, Self, {||::Notify(WM_KEYDOWN)})
      IF bClick != NIL
         ::oParent:oParent:AddEvent(0, Self, {||::onClick()})
      ENDIF
   ENDIF
   */
   IF ::id > 2 .OR. ::bClick != NIL
      IF ::id < 3
         ::GetParentForm():AddEvent(BN_CLICKED, Self, {||::onClick()})
      ENDIF
      ::oParent:AddEvent(BN_CLICKED, Self, {||::onClick()})
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HButton

   IF !Empty(::oParent:handle)
      ::handle := CreateButton(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title)
      ::Init()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, cTooltip, tcolor, bColor, cCaption, bGFocus) ;
   CLASS HButton

   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor)

   ::title := cCaption
   //IF bGFocus != NIL
   ::bGetFocus := bGFocus
   ::oParent:AddEvent(BN_SETFOCUS, Self, {||::onGetFocus()})
   //ENDIF
   ::oParent:AddEvent(BN_KILLFOCUS, self, {|| ::onLostFocus()})
   ::bClick := bClick
   IF bClick != NIL
      ::oParent:AddEvent(BN_CLICKED, Self, {||::onClick()})
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Init() CLASS HButton

   IF !::lInit
      IF !(::GetParentForm():classname == ::oParent:classname .AND. ::GetParentForm():Type >= WND_DLG_RESOURCE) .OR. ;
         !::GetParentForm():lModal .OR. ::nHolder == 1
         ::nHolder := 1
         hwg_SetWindowObject(::handle, Self)
         HWG_INITBUTTONPROC(::handle)
      ENDIF
      ::Super:init()
      /*
      IF ::Title != NIL
         hwg_SetWindowText(::handle, ::title)
      ENDIF
      */
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD onevent(msg, wParam, lParam) CLASS HButton

   IF msg == WM_SETFOCUS .AND. ::oParent:oParent == NIL
      //- hwg_SendMessage(::handle, BM_SETSTYLE, BS_PUSHBUTTON, 1)
   ELSEIF msg == WM_KILLFOCUS
      IF ::GetParentForm():handle != ::oParent:handle
      //- IF ::oParent:oParent != NIL
         hwg_InvalidateRect(::handle, 0)
         hwg_SendMessage(::handle, BM_SETSTYLE, BS_PUSHBUTTON, 1)
      ENDIF
   ELSEIF msg == WM_KEYDOWN
      IF (wParam == VK_RETURN .OR. wParam == VK_SPACE)
         hwg_SendMessage(::handle, WM_LBUTTONDOWN, 0, MAKELPARAM(1, 1))
         RETURN 0
      ENDIF
      IF !ProcKeyList(Self, wParam)
         IF wParam == VK_TAB
            GetSkip(::oparent, ::handle, , iif(IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ELSEIF wParam == VK_LEFT .OR. wParam == VK_UP
            GetSkip(::oparent, ::handle, , -1)
            RETURN 0
         ELSEIF wParam == VK_RIGHT .OR. wParam == VK_DOWN
            GetSkip(::oparent, ::handle, , 1)
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF msg == WM_KEYUP
      IF (wParam == VK_RETURN .OR. wParam == VK_SPACE)
         hwg_SendMessage(::handle, WM_LBUTTONUP, 0, MAKELPARAM(1, 1))
         RETURN 0
      ENDIF
   ELSEIF msg == WM_GETDLGCODE .AND. !Empty(lParam)
      IF wParam == VK_RETURN .OR. wParam == VK_TAB
      ELSEIF GETDLGMESSAGE(lParam) == WM_KEYDOWN .AND. wParam != VK_ESCAPE
      ELSEIF GETDLGMESSAGE(lParam) == WM_CHAR .OR.wParam == VK_ESCAPE
         RETURN -1
      ENDIF
      RETURN DLGC_WANTMESSAGE
   ENDIF

RETURN -1
#else
METHOD onevent(msg, wParam, lParam) CLASS HButton

   SWITCH msg

   //CASE WM_SETFOCUS
   //   IF ::oParent:oParent == NIL
   //      //- hwg_SendMessage(::handle, BM_SETSTYLE, BS_PUSHBUTTON, 1)
   //   ENDIF

   CASE WM_KILLFOCUS
      IF ::GetParentForm():handle != ::oParent:handle
      //- IF ::oParent:oParent != NIL
          hwg_InvalidateRect(::handle, 0)
          hwg_SendMessage(::handle, BM_SETSTYLE, BS_PUSHBUTTON, 1)
      ENDIF
      EXIT

   CASE WM_KEYDOWN
      IF (wParam == VK_RETURN .OR. wParam == VK_SPACE)
         hwg_SendMessage(::handle, WM_LBUTTONDOWN, 0, MAKELPARAM(1, 1))
         RETURN 0
      ENDIF
      IF !ProcKeyList(Self, wParam)
         SWITCH wParam
         CASE VK_TAB
            GetSkip(::oparent, ::handle, , iif(IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         CASE VK_LEFT
         CASE VK_UP
            GetSkip(::oparent, ::handle, , -1)
            RETURN 0
         CASE VK_RIGHT
         CASE VK_DOWN
            GetSkip(::oparent, ::handle, , 1)
            RETURN 0
         ENDSWITCH
      ENDIF
      EXIT

   CASE WM_KEYUP
      IF (wParam == VK_RETURN .OR. wParam == VK_SPACE)
         hwg_SendMessage(::handle, WM_LBUTTONUP, 0, MAKELPARAM(1, 1))
         RETURN 0
      ENDIF
      EXIT

   CASE WM_GETDLGCODE
      IF !Empty(lParam)
         IF wParam == VK_RETURN .OR. wParam == VK_TAB
         ELSEIF GETDLGMESSAGE(lParam) == WM_KEYDOWN .AND. wParam != VK_ESCAPE
         ELSEIF GETDLGMESSAGE(lParam) == WM_CHAR .OR. wParam == VK_ESCAPE
            RETURN -1
         ENDIF
         RETURN DLGC_WANTMESSAGE
      ENDIF

   ENDSWITCH

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD onClick() CLASS HButton

   IF hb_IsBlock(::bClick)
      //::oParent:lSuspendMsgsHandling := .T.
      Eval(::bClick, Self, ::id)
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

/*
METHOD Notify(lParam) CLASS HButton

   LOCAL ndown := getkeystate(VK_RIGHT) + getkeystate(VK_DOWN) + GetKeyState(VK_TAB)
   LOCAL nSkip := 0
   //
   IF PtrtoUlong(lParam) == WM_KEYDOWN
      IF ::oParent:Classname == "HTAB"
         IF hwg_GetFocus() != ::handle
            hwg_InvalidateRect(::handle, 0)
            hwg_SendMessage(::handle, BM_SETSTYLE, BS_PUSHBUTTON, 1)
         ENDIF
         IF getkeystate(VK_LEFT) + getkeystate(VK_UP) < 0 .OR. ;
            (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0)
            nSkip := -1
         ELSEIF ndown < 0
            nSkip := 1
         ENDIF
         IF nSkip != 0
            ::oParent:Setfocus()
            GetSkip(::oparent, ::handle, , nSkip)
            RETURN 0
         ENDIF
      ENDIF
   ENDIF

RETURN -1
*/

//-------------------------------------------------------------------------------------------------------------------//

METHOD NoteCaption(cNote) CLASS HButton         //*

//#DEFINE BCM_SETNOTE  0x00001609

   IF cNote != NIL
      IF hwg_BitOr(::Style, BS_COMMANDLINK) > 0
         hwg_SendMessage(::handle, BCM_SETNOTE, 0, ANSITOUNICODE(cNote))
      ENDIF
      ::cNote := cNote
   ENDIF

RETURN ::cNote

//-------------------------------------------------------------------------------------------------------------------//

METHOD onGetFocus() CLASS HButton

   LOCAL res := .T.
   LOCAL nSkip

   IF !CheckFocus(Self, .F.) .OR. ::bGetFocus == NIL
      RETURN .T.
   ENDIF
   IF hb_IsBlock(::bGetFocus)
      nSkip := IIf(GetKeyState(VK_UP) < 0 .OR. (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0), -1, 1)
      ::oParent:lSuspendMsgsHandling := .T.
      res := Eval(::bGetFocus, ::title, Self)
      ::oParent:lSuspendMsgsHandling := .F.
      IF res != NIL .AND. Empty(res)
         WhenSetFocus(Self, nSkip)
         IF ::lflat
            hwg_InvalidateRect(::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight)
         ENDIF
      ENDIF
   ENDIF

RETURN res

//-------------------------------------------------------------------------------------------------------------------//

METHOD onLostFocus() CLASS HButton

   IF ::lflat
      hwg_InvalidateRect(::oParent:handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight)
   ENDIF
   ::lnoWhen := .F.
   IF hb_IsBlock(::bLostFocus).AND. hwg_SelfFocus(hwg_GetParent(hwg_GetFocus()), ::getparentform():handle)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bLostFocus, ::title, Self)
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//
