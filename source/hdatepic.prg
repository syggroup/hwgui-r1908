//
// $Id: hdatepic.prg 1889 2012-09-09 22:28:07Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HDatePicker class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define DTN_DATETIMECHANGE -759
#define DTN_CLOSEUP -753
#define DTM_GETMONTHCAL 4104 // 0x1008
#define DTM_CLOSEMONTHCAL 4109
#define NM_KILLFOCUS -8
#define NM_SETFOCUS -7

//-------------------------------------------------------------------------------------------------------------------//

CLASS HDatePicker INHERIT HControl

   CLASS VAR winclass INIT "SYSDATETIMEPICK32"

   DATA bSetGet
   DATA dValue
   DATA tValue
   DATA bChange
   DATA lnoValid INIT .F.
   DATA lShowTime INIT .T.

   METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bGfocus, bLfocus, ;
      bChange, ctooltip, tcolor, bcolor, lShowTime)
   METHOD Activate()
   METHOD Init()
   METHOD OnEvent(msg, wParam, lParam)
   METHOD Refresh()
   METHOD GetValue()
   METHOD SetValue(xValue)
   METHOD Redefine(oWndParent, nId, vari, bSetGet, oFont, bSize, bInit, bGfocus, bLfocus, bChange, ctooltip, tcolor, ;
      bcolor, lShowTime)
   METHOD onChange(nMess)
   METHOD When()
   METHOD Valid()
   METHOD Value(Value) SETGET

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bGfocus, bLfocus, ;
   bChange, ctooltip, tcolor, bcolor, lShowTime) CLASS HDatePicker

   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), IIf(bSetGet != NIL, WS_TABSTOP, 0) + ;
      IIf(lShowTime == NIL .OR. !lShowTime, 0, DTS_TIMEFORMAT))
   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, , , ctooltip, tcolor, bcolor)

   ::lShowTime := hwg_BitAnd(nStyle, DTS_TIMEFORMAT) > 0
   ::dValue := IIf(vari == NIL .OR. !hb_IsDate(vari), CToD(Space(8)), vari)
   ::tValue := IIf(vari == NIL .OR. !hb_IsChar(vari), Space(6), vari)
   ::title := IIf(!::lShowTime, ::dValue, ::tValue)

   ::bSetGet := bSetGet
   ::bChange := bChange

   HWG_InitCommonControlsEx()
   ::Activate()

   IF bSetGet != NIL
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::oParent:AddEvent(NM_SETFOCUS, Self, {|o, id|::When(o:FindControl(id))}, .T., "onGotFocus")
      ::oParent:AddEvent(NM_KILLFOCUS, Self, {|o, id|::Valid(o:FindControl(id))}, .T., "onLostFocus")
   ELSE
      IF bGfocus != NIL
         ::lnoValid := .T.
         ::oParent:AddEvent(NM_SETFOCUS, Self, bGfocus, .T., "onGotFocus")
      ENDIF
      IF bLfocus != NIL
         ::oParent:AddEvent(NM_KILLFOCUS, Self, bLfocus, .T., "onLostFocus")
      ENDIF
   ENDIF
   ::oParent:AddEvent(DTN_DATETIMECHANGE, Self, {||::onChange(DTN_DATETIMECHANGE)}, .T., "onChange")
   ::oParent:AddEvent(DTN_CLOSEUP, Self, {||::onChange(DTN_CLOSEUP)}, .T., "onClose")

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, vari, bSetGet, oFont, bSize, bInit, bGfocus, bLfocus, bChange, ctooltip, tcolor, ;
   bcolor, lShowTime) CLASS HDatePicker

   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, , ctooltip, tcolor, bcolor)

   HWG_InitCommonControlsEx()
   ::dValue := IIf(vari == NIL .OR. !hb_IsDate(vari), CToD(Space(8)), vari)
   ::tValue := IIf(vari == NIL .OR. !hb_IsChar(vari), Space(6), vari)
   ::bSetGet := bSetGet
   ::bChange := bChange
   ::lShowTime := lShowTime
   IF bGfocus != NIL
      ::oParent:AddEvent(NM_SETFOCUS, Self, bGfocus, .T., "onGotFocus")
   ENDIF
   ::oParent:AddEvent(DTN_DATETIMECHANGE, Self, {||::onChange(DTN_DATETIMECHANGE)}, .T., "onChange")
   ::oParent:AddEvent(DTN_CLOSEUP, Self, {||::onChange(DTN_CLOSEUP)}, .T., "onClose")
   IF bSetGet != NIL
      ::bLostFocus := bLfocus
      ::oParent:AddEvent(NM_KILLFOCUS, Self, {|o, id|::Valid(o:FindControl(id))}, .T., "onLostFocus")
   ELSE
      IF bLfocus != NIL
         ::oParent:AddEvent(NM_KILLFOCUS, Self, bLfocus, .T., "onLostFocus")
      ENDIF
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HDatePicker

   IF !Empty(::oParent:handle)
      ::handle := CreateDatePicker(::oParent:handle, ::id, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::style)
      ::Init()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Init() CLASS HDatePicker

   IF !::lInit
      ::nHolder := 1
      hwg_SetWindowObject(::handle, Self)
      HWG_INITDATEPICKERPROC(::handle)
      ::Super:Init()
      ::Refresh()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD OnEvent(msg, wParam, lParam) CLASS HDatePicker

   IF hb_IsBlock(::bOther)
      IF Eval(::bOther, Self, msg, wParam, lParam) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_CHAR
      IF wParam == VK_TAB
         GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN 0
      ELSEIF wParam == VK_RETURN
         GetSkip(::oParent, ::handle, , 1)
         RETURN 0
      ENDIF
    ELSEIF msg == WM_KEYDOWN
       IF ProcKeyList(Self, wParam)
          RETURN 0
       ENDIF
   ELSEIF msg == WM_GETDLGCODE
      IF wParam == VK_TAB //.AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
         //GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN DLGC_WANTTAB
      ENDIF
   ENDIF

RETURN -1
#else
METHOD OnEvent(msg, wParam, lParam) CLASS HDatePicker

   IF hb_IsBlock(::bOther)
      IF Eval(::bOther, Self, msg, wParam, lParam) != -1
         RETURN 0
      ENDIF
   ENDIF

   SWITCH msg

   CASE WM_CHAR
      IF wParam == VK_TAB
         GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN 0
      ELSEIF wParam == VK_RETURN
         GetSkip(::oParent, ::handle, , 1)
         RETURN 0
      ENDIF
      EXIT
   CASE WM_KEYDOWN
      IF ProcKeyList(Self, wParam)
         RETURN 0
      ENDIF
      EXIT
   CASE WM_GETDLGCODE
      IF wParam == VK_TAB //.AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
         // GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN DLGC_WANTTAB
      ENDIF
   ENDSWITCH

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD Value(Value) CLASS HDatePicker

   IF Value != NIL
      ::SetValue(Value)
   ENDIF

RETURN IIf(::lShowTime, ::tValue, ::dValue)

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetValue() CLASS HDatePicker
RETURN IIf(!::lShowTime, GetDatePicker(::handle), GetTimePicker(::handle))

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetValue(xValue) CLASS HDatePicker

   IF Empty(xValue)
      SetDatePickerNull(::handle)
   ELSEIF ::lShowTime
      SetDatePicker(::handle, Date(), StrTran(xValue, ":", ""))
   ELSE
      SetDatePicker(::handle, xValue, StrTran(::tValue, ":", ""))
   ENDIF
   ::dValue := GetDatePicker(::handle)
   ::tValue := GetTimePicker(::handle)
   ::title := IIf(::lShowTime, ::tValue, ::dValue)
   IF hb_IsBlock(::bSetGet)
      Eval(::bSetGet, IIf(::lShowTime, ::tValue, ::dValue), Self)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Refresh() CLASS HDatePicker

   IF hb_IsBlock(::bSetGet)
      IF !::lShowTime
         ::dValue := Eval(::bSetGet,, Self)
      ELSE
         ::tValue := Eval(::bSetGet,, Self)
      ENDIF
   ENDIF
   IF Empty(::dValue) .AND. !::lShowTime
      //SetDatePickerNull(::handle)
      SetDatePicker(::handle, date(), StrTran(Time(), ":", ""))
   ELSE
      ::SetValue(IIf(!::lShowTime, ::dValue, ::tValue))
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD onChange(nMess) CLASS HDatePicker

   IF (nMess == DTN_DATETIMECHANGE .AND. hwg_SendMessage(::handle, DTM_GETMONTHCAL, 0, 0) == 0) .OR. nMess == DTN_CLOSEUP
      IF nMess == DTN_CLOSEUP
         hwg_PostMessage(::handle, WM_KEYDOWN, VK_RIGHT, 0)
         ::SetFocus()
      ENDIF
      ::dValue := GetDatePicker(::handle)
      ::tValue := GetTimePicker(::handle)
      IF hb_IsBlock(::bSetGet)
         Eval(::bSetGet, IIf(::lShowTime, ::tValue, ::dValue), Self)
      ENDIF
      IF hb_IsBlock(::bChange)
         ::oparent:lSuspendMsgsHandling := .T.
         Eval(::bChange, IIf(::lShowTime, ::tValue, ::dValue), Self)
         ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

METHOD When() CLASS HDatePicker

   LOCAL res := .T.
   LOCAL nSkip

   IF !CheckFocus(Self, .F.)
      RETURN .T.
   ENDIF
   IF hb_IsBlock(::bGetFocus)
      nSkip := IIf(GetKeyState(VK_UP) < 0 .OR. (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0), - 1, 1)
      ::oParent:lSuspendMsgsHandling := .T.
      ::lnoValid := .T.
      res :=  Eval(::bGetFocus, IIf(::lShowTime, ::tValue, ::dValue), Self)
      ::lnoValid := !res
      ::oParent:lSuspendMsgsHandling := .F.
      IF hb_IsLogical(res) .AND. !res
         WhenSetFocus(Self, nSkip)
         hwg_SendMessage(::handle, DTM_CLOSEMONTHCAL, 0, 0)
      ELSE
         ::SetFocus()
      ENDIF
   ENDIF

RETURN res

//-------------------------------------------------------------------------------------------------------------------//

METHOD Valid() CLASS HDatePicker

   LOCAL res := .T.

   //IF !hwg_SelfFocus(GetParent(hwg_GetFocus()), ::GetParentForm():handle)
   //   RETURN .T.
   //ENDIF
   IF !CheckFocus(Self, .T.) .OR. ::lnoValid
      RETURN .T.
   ENDIF
   ::dValue := GetDatePicker(::handle)
   IF hb_IsBlock(::bSetGet)
      Eval(::bSetGet, IIf(::lShowTime, ::tValue, ::dValue), Self)
   ENDIF
   IF hb_IsBlock(::bLostFocus)
      ::oparent:lSuspendMsgsHandling := .T.
      res := Eval(::bLostFocus, IIf(::lShowTime, ::tValue, ::dValue), Self)
      res := IIf(hb_IsLogical(res), res, .T.)
      ::oparent:lSuspendMsgsHandling := .F.
      IF !res
         hwg_PostMessage(::handle, WM_KEYDOWN, VK_RIGHT, 0)
         ::SetFocus(.T.)
      ENDIF
   ENDIF

RETURN res

//-------------------------------------------------------------------------------------------------------------------//
