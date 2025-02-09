//
// $Id: hcheck.prg 1859 2012-07-16 17:19:49Z LFBASSO $
//
// HWGUI - Harbour Win32 GUI library source code:
// HCheckButton class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define TRANSPARENT 1

//-------------------------------------------------------------------------------------------------------------------//

CLASS HCheckButton INHERIT HControl

   CLASS VAR winclass INIT "BUTTON"

   DATA bSetGet
   DATA lValue
   DATA lEnter
   DATA lFocu INIT .F.
   DATA bClick

   METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, bSize, ;
      bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter, lTransp, bLFocus)
   METHOD Activate()
   METHOD Redefine(oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, ;
      bGFocus, lEnter)
   METHOD Init()
   METHOD onEvent(msg, wParam, lParam)
   METHOD Refresh()
   // METHOD Disable()
   // METHOD Enable()
   METHOD SetValue(lValue)
   METHOD GetValue() INLINE (hwg_SendMessage(::handle, BM_GETCHECK, 0, 0) == 1)
   METHOD onGotFocus()
   METHOD onClick()
   METHOD KillFocus()
   METHOD Valid()
   METHOD When()
   METHOD Value(lValue) SETGET

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, bInit, bSize, ;
   bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lEnter, lTransp, bLFocus) CLASS HCheckButton

   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), BS_NOTIFY + BS_PUSHBUTTON + BS_AUTOCHECKBOX + WS_TABSTOP)

   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ctooltip, tcolor, ;
      bcolor)

   ::title := cCaption
   ::lValue := IIf(vari == NIL .OR. !hb_IsLogical(vari), .F., vari)
   ::bSetGet := bSetGet
   ::backStyle := IIf(lTransp != NIL .AND. lTransp, TRANSPARENT, OPAQUE)

   ::Activate()

   ::lEnter := IIf(lEnter == NIL .OR. !hb_IsLogical(lEnter), .F., lEnter)
   ::bClick := bClick
   ::bLostFocus := bLFocus
   ::bGetFocus := bGFocus

   IF bGFocus != NIL
      //::oParent:AddEvent(BN_SETFOCUS, Self, {|o, id|__When(o:FindControl(id))},, "onGotFocus")
      ::oParent:AddEvent(BN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus")
      ::lnoValid := .T.
   ENDIF
   //::oParent:AddEvent(BN_CLICKED, Self, {|o, id|__Valid(o:FindControl(id),)},, "onClick")
   ::oParent:AddEvent(BN_CLICKED, Self, {|o, id|::Valid(o:FindControl(id))},, "onClick")
   ::oParent:AddEvent(BN_KILLFOCUS, Self, {||::KILLFOCUS()})

   RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HCheckButton

   IF !Empty(::oParent:handle)
      ::handle := CreateButton(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title)
      ::Init()
   ENDIF

   RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, ;
   bGFocus, lEnter) CLASS HCheckButton

   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor)

   ::lValue := IIf(vari == NIL .OR. !hb_IsLogical(vari), .F., vari)
   ::bSetGet := bSetGet
   ::lEnter := IIf(lEnter == NIL .OR. !hb_IsLogical(vari), .F., lEnter)
   ::bClick := bClick
   ::bLostFocus := bClick
   ::bGetFocus := bGFocus
   IF bGFocus != NIL
      ::oParent:AddEvent(BN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus")
   ENDIF
   ::oParent:AddEvent(BN_CLICKED, self, {|o, id|::Valid(o:FindControl(id))},, "onClick")
   ::oParent:AddEvent(BN_KILLFOCUS, Self, {||::KILLFOCUS()})

   RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Init() CLASS HCheckButton

   IF !::lInit
      ::nHolder := 1
      hwg_SetWindowObject(::handle, Self)
      HWG_INITBUTTONPROC(::handle)
      ::Super:Init()
      IF ::lValue
         hwg_SendMessage(::handle, BM_SETCHECK, 1, 0)
      ENDIF
   ENDIF

   RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HCheckButton

   LOCAL oCtrl

   IF hb_IsBlock(::bOther)
      IF Eval(::bOther, Self, msg, wParam, lParam) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_KEYDOWN
      //IF ProcKeyList(Self, wParam)
      IF wParam == VK_TAB
         GetSkip(::oparent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN 0
      ELSEIF wParam == VK_LEFT .OR. wParam == VK_UP
         GetSkip(::oparent, ::handle, , -1)
         RETURN 0
      ELSEIF wParam == VK_RIGHT .OR. wParam == VK_DOWN
         GetSkip(::oparent, ::handle, , 1)
         RETURN 0
      ELSEIF (wParam == VK_RETURN) // .OR. wParam == VK_SPACE)
         IF ::lEnter
            ::SetValue(!::GetValue())
            ::VALID()
            RETURN 0 //-1
         ELSE
            GetSkip(::oparent, ::handle, , 1)
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF msg == WM_KEYUP
      ProcKeyList(Self, wParam) // working in MDICHILD AND DIALOG

    ELSEIF msg == WM_GETDLGCODE .AND. !Empty(lParam)
      IF wParam == VK_RETURN .OR. wParam == VK_TAB
           RETURN -1
      ELSEIF wParam == VK_ESCAPE .AND. (oCtrl := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled()
         RETURN DLGC_WANTMESSAGE
      ELSEIF GETDLGMESSAGE(lParam) == WM_KEYDOWN .AND. wParam != VK_ESCAPE
      ELSEIF GETDLGMESSAGE(lParam) == WM_CHAR .OR. wParam == VK_ESCAPE .OR. ;
         GETDLGMESSAGE(lParam) == WM_SYSCHAR
         RETURN -1
      ENDIF
      RETURN DLGC_WANTMESSAGE //+ DLGC_WANTCHARS
   ENDIF
   RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HCheckButton

   LOCAL oCtrl

   IF hb_IsBlock(::bOther)
      IF Eval(::bOther, Self, msg, wParam, lParam) != -1
         RETURN 0
      ENDIF
   ENDIF

   SWITCH msg

   CASE WM_KEYDOWN
      //IF ProcKeyList(Self, wParam)
      SWITCH wParam
      CASE VK_TAB
         GetSkip(::oparent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN 0
      CASE VK_LEFT
      CASE VK_UP
         GetSkip(::oparent, ::handle, , -1)
         RETURN 0
      CASE VK_RIGHT
      CASE VK_DOWN
         GetSkip(::oparent, ::handle, , 1)
         RETURN 0
      CASE VK_RETURN // .OR. wParam == VK_SPACE)
         IF ::lEnter
            ::SetValue(!::GetValue())
            ::VALID()
            RETURN 0 //-1
         ELSE
            GetSkip(::oparent, ::handle, , 1)
            RETURN 0
         ENDIF
      ENDSWITCH
      EXIT

   CASE WM_KEYUP
      ProcKeyList(Self, wParam) // working in MDICHILD AND DIALOG
      EXIT

   CASE WM_GETDLGCODE
      IF !Empty(lParam)
         IF wParam == VK_RETURN .OR. wParam == VK_TAB
            RETURN -1
         ELSEIF wParam == VK_ESCAPE .AND. ;
            (oCtrl := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled()
            RETURN DLGC_WANTMESSAGE
         ELSEIF GETDLGMESSAGE(lParam) == WM_KEYDOWN .AND. wParam != VK_ESCAPE
         ELSEIF GETDLGMESSAGE(lParam) == WM_CHAR .OR.wParam == VK_ESCAPE .OR. GETDLGMESSAGE(lParam) == WM_SYSCHAR
            RETURN -1
         ENDIF
         RETURN DLGC_WANTMESSAGE //+ DLGC_WANTCHARS
      ENDIF

   ENDSWITCH

   RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetValue(lValue) CLASS HCheckButton

   hwg_SendMessage(::handle, BM_SETCHECK, IIf(Empty(lValue), 0, 1), 0)
   ::lValue := IIf(lValue == NIL .OR. !hb_IsLogical(lValue), .F., lValue)
   IF hb_IsBlock(::bSetGet)
      Eval(::bSetGet, lValue, Self)
   ENDIF
   ::Refresh()

   RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Value(lValue) CLASS HCheckButton

   IF lValue != NIL
      ::SetValue(lValue)
   ENDIF

   RETURN hwg_SendMessage(::handle, BM_GETCHECK, 0, 0) == 1

//-------------------------------------------------------------------------------------------------------------------//

METHOD Refresh() CLASS HCheckButton

   LOCAL var

   IF hb_IsBlock(::bSetGet)
      var := Eval(::bSetGet,, Self)
      IF var == NIL .OR. !hb_IsLogical(var)
        var := hwg_SendMessage(::handle, BM_GETCHECK, 0, 0) == 1
      ENDIF
      ::lValue := IIf(var == NIL .OR. !hb_IsLogical(var), .F., var)
   ENDIF
   hwg_SendMessage(::handle, BM_SETCHECK, IIf(::lValue, 1, 0), 0)

   RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0
METHOD Disable() CLASS HCheckButton

   ::Super:Disable()
   hwg_SendMessage(::handle, BM_SETCHECK, BST_INDETERMINATE, 0)

   RETURN NIL
#endif

//-------------------------------------------------------------------------------------------------------------------//

#if 0
METHOD Enable() CLASS HCheckButton

   ::Super:Enable()
   hwg_SendMessage(::handle, BM_SETCHECK, IIf(::lValue, 1, 0), 0)

   RETURN NIL
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD onGotFocus() CLASS HCheckButton

   RETURN ::When()

//-------------------------------------------------------------------------------------------------------------------//

METHOD onClick() CLASS HCheckButton

   RETURN ::Valid()

//-------------------------------------------------------------------------------------------------------------------//

METHOD killFocus() CLASS HCheckButton

   LOCAL ndown := Getkeystate(VK_RIGHT) + Getkeystate(VK_DOWN) + GetKeyState(VK_TAB)
   LOCAL nSkip := 0

   IF !CheckFocus(Self, .T.)
      RETURN .T.
   ENDIF

   IF ::oParent:classname = "HTAB"
      IF getkeystate(VK_LEFT) + getkeystate(VK_UP) < 0 .OR. (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0)
         nSkip := -1
      ELSEIF ndown < 0
         nSkip := 1
      ENDIF
      IF nSkip != 0
         GetSkip(::oparent, ::handle, , nSkip)
      ENDIF
   ENDIF
   IF getkeystate(VK_RETURN) < 0 .AND. ::lEnter
      ::SetValue(!::GetValue())
      ::VALID()
   ENDIF
   IF hb_IsBlock(::bLostFocus)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bLostFocus, Self, ::lValue)
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

   RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD When() CLASS HCheckButton

   LOCAL res := .T.
   LOCAL nSkip

   IF !CheckFocus(Self, .F.)
      RETURN .T.
   ENDIF

   nSkip := IIf(GetKeyState(VK_UP) < 0 .OR. (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0), -1, 1)

   IF hb_IsBlock(::bGetFocus)
      ::lnoValid := .T.
      ::oParent:lSuspendMsgsHandling := .T.
      IF hb_IsBlock(::bSetGet)
         res := Eval(::bGetFocus, Eval(::bSetGet, , Self), Self)
      ELSE
         res := Eval(::bGetFocus, ::lValue, Self)
      ENDIF
      ::lnoValid := !res
      IF !res
         WhenSetFocus(Self, nSkip)
      ENDIF
   ENDIF

   ::oParent:lSuspendMsgsHandling := .F.

   RETURN res

//-------------------------------------------------------------------------------------------------------------------//

METHOD Valid() CLASS HCheckButton

   LOCAL l := hwg_SendMessage(::handle, BM_GETCHECK, 0, 0)

   IF !CheckFocus(Self, .T.) .OR. ::lnoValid
      RETURN .T.
   ENDIF

   IF l == BST_INDETERMINATE
      hwg_CheckDlgButton(::oParent:handle, ::id, .F.)
      hwg_SendMessage(::handle, BM_SETCHECK, 0, 0)
      ::lValue := .F.
   ELSE
      ::lValue := (l == 1)
   ENDIF

   IF hb_IsBlock(::bSetGet)
      Eval(::bSetGet, ::lValue, Self)
   ENDIF

   IF hb_IsBlock(::bClick)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bClick, Self, ::lValue)
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

   IF Empty(hwg_GetFocus())
      GetSkip(::oParent, ::handle,, ::nGetSkip)
   ENDIF

   RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//
