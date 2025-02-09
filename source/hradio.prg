//
// $Id: hradio.prg 1868 2012-08-27 17:33:11Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HRadioButton class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#DEFINE TRANSPARENT 1

CLASS HRadioGroup INHERIT HControl //HObject

   CLASS VAR winclass   INIT "STATIC"
   CLASS VAR oGroupCurrent
   DATA aButtons
   DATA nValue  INIT 1
   DATA bSetGet
   DATA oHGroup
   DATA lEnabled  INIT .T.
   DATA bClick


   METHOD New(vari, bSetGet, bInit, bClick, bGFocus, nStyle)
   METHOD Newrg(oWndParent, nId, nStyle, vari, bSetGet, nLeft, nTop, nWidth, nHeight, ;
              cCaption, oFont, bInit, bSize, tcolor, bColor, bClick,;
              bGFocus, lTransp)
   METHOD EndGroup(nSelected)
   METHOD SetValue(nValue)
   METHOD GetValue() INLINE ::nValue
   METHOD Value(nValue) SETGET
   METHOD Refresh()
   //METHOD IsEnabled() INLINE ::lEnabled
   METHOD Enable()
   METHOD Disable()
   //METHOD Enabled(lEnabled) SETGET
   METHOD Init()
   METHOD Activate() VIRTUAL

ENDCLASS

METHOD New(vari, bSetGet, bInit, bClick, bGFocus, nStyle) CLASS HRadioGroup

   ::oGroupCurrent := Self
   ::aButtons := {}
   ::oParent := IIf(HWindow():GetMain() != NIL, HWindow():GetMain():oDefaultParent, NIL)

   ::lEnabled :=  !hwg_BitAnd(nStyle, WS_DISABLED) > 0

   ::Super:New(::oParent, ,, ,,,,, bInit)

   ::bInit := bInit
   ::bClick := bClick
   ::bGetFocus := bGfocus


   IF vari != NIL
      IF hb_IsNumeric(vari)
         ::nValue := vari
      ENDIF
      //::bSetGet := bSetGet
   ENDIF
   ::bSetGet := bSetGet

   RETURN Self

METHOD NewRg(oWndParent, nId, nStyle, vari, bSetGet, nLeft, nTop, nWidth, nHeight, ;
             cCaption, oFont, bInit, bSize, tcolor, bColor, bClick,;
             bGFocus, lTransp) CLASS HRadioGroup

   ::oGroupCurrent := Self
   ::aButtons := {}
   ::lEnabled :=  !hwg_BitAnd(nStyle, WS_DISABLED) > 0

   ::Super:New(::oParent, , , nLeft, nTop, nWidth, nHeight, oFont, bInit)
   ::oHGroup := HGroup():New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
                              oFont, bInit, bSize, , tcolor, bColor, lTransp, Self)
                              
   ::lInit := .T.
   ::bInit := bInit
   ::bClick := bClick
   ::bGetFocus := bGfocus

   IF vari != NIL
      IF hb_IsNumeric(vari)
         ::nValue := vari
      ENDIF
   ENDIF
   ::bSetGet := bSetGet

   RETURN Self


METHOD EndGroup(nSelected) CLASS HRadioGroup
   LOCAL nLen

   IF ::oGroupCurrent != NIL .AND. (nLen := Len(::oGroupCurrent:aButtons)) > 0

      nSelected := IIf(nSelected != NIL .AND. nSelected <= nLen .AND. nSelected > 0, ;
                        nSelected, ::oGroupCurrent:nValue)
      IF nSelected != 0 .AND. nSelected <= nLen
         IF ::oGroupCurrent:aButtons[nLen]:handle > 0
            hwg_CheckRadioButton(::oGroupCurrent:aButtons[nLen]:oParent:handle, ;
                             ::oGroupCurrent:aButtons[1]:id,    ;
                             ::oGroupCurrent:aButtons[nLen]:id, ;
                             ::oGroupCurrent:aButtons[nSelected]:id)
         ELSE
            ::oGroupCurrent:aButtons[nLen]:bInit := ;
               &("{|o|hwg_CheckRadioButton(o:oParent:handle," + ;
               LTrim(Str(::oGroupCurrent:aButtons[1]:id)) + "," + ;
               LTrim(Str(::oGroupCurrent:aButtons[nLen]:id)) + "," + ;
               LTrim(Str(::oGroupCurrent:aButtons[nSelected]:id)) + ")}")
         ENDIF
      ENDIF
      IF Empty(::oParent)
         ::oParent := ::oGroupCurrent:aButtons[nLen]:oParent //hwg_GetParentForm()
      ENDIF
      //::Init()
   ENDIF
   ::oGroupCurrent := NIL
   RETURN NIL

METHOD Init() CLASS HRadioGroup

   IF !::lInit
      /*
      IF ::oHGroup != NIL
        ::id := ::oHGroup:id
        ::handle := ::oHGroup:handle
      ENDIF
      */
      ::super:init()
   ENDIF
   RETURN  NIL

METHOD SetValue(nValue) CLASS HRadioGroup
   LOCAL nLen

   IF (nLen := Len(::aButtons)) > 0 .AND. nValue > 0 .AND. nValue <= nLen
      hwg_CheckRadioButton(::aButtons[nLen]:oParent:handle, ;
                       ::aButtons[1]:id,    ;
                       ::aButtons[nLen]:id, ;
                       ::aButtons[nValue]:id)
      ::nValue := nValue
      IF hb_IsBlock(::bSetGet)
         Eval(::bSetGet, ::nValue)
      ENDIF
   ELSEIF nLen > 0
      hwg_CheckRadioButton(::aButtons[nlen]:oParent:handle, ;
            ::aButtons[1]:id,    ;
            ::aButtons[nLen]:id, ;
            0)
   ENDIF
   RETURN NIL
   
METHOD Value(nValue) CLASS HRadioGroup

   IF nValue != NIL
       ::SetValue(nValue)
   ENDIF
    RETURN ::nValue
   

METHOD Refresh() CLASS HRadioGroup
   LOCAL vari

   IF hb_IsBlock(::bSetGet)
     vari := Eval(::bSetGet,, Self)
     IF vari == NIL .OR. !hb_IsNumeric(vari)
         vari := ::nValue
      ENDIF
      ::SetValue(vari)
   ENDIF
   RETURN NIL

METHOD Enable() CLASS HRadioGroup
   LOCAL i, nLen := Len(::aButtons)

   FOR i := 1 TO nLen
       ::aButtons[i]:Enable()
    NEXT
   RETURN NIL

METHOD Disable() CLASS HRadioGroup
   LOCAL i, nLen := Len(::aButtons)

   FOR i := 1 TO nLen
       ::aButtons[i]:Disable()
    NEXT
   RETURN NIL

 *--------------------------------------------------------------

CLASS HRadioButton INHERIT HControl

CLASS VAR winclass   INIT "BUTTON"
   DATA  oGroup
   DATA lWhen  INIT .F.

   METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
              bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp)
   METHOD Activate()
   METHOD Init()
   METHOD Redefine(oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp)
   METHOD GetValue() INLINE (hwg_SendMessage(::handle, BM_GETCHECK, 0, 0) == 1)
  // METHOD Notify(lParam)
   METHOD onevent(msg, wParam, lParam)
   METHOD onGotFocus()
   METHOD onClick()
   METHOD Valid(nKey)
   METHOD When()


ENDCLASS

METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, oFont, ;
            bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp) CLASS HRadioButton

   ::oParent := IIf(oWndParent == NIL, ::oDefaultParent, oWndParent)

   ::id      := IIf(nId == NIL, ::NewId(), nId)
   ::title   := cCaption
   ::oGroup  := HRadioGroup():oGroupCurrent
   ::Enabled := !hwg_BitAnd(nStyle, WS_DISABLED) > 0
   ::style   := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), BS_RADIOBUTTON + ; // BS_AUTORADIOBUTTON+;
                        BS_NOTIFY + ;  // WS_CHILD + WS_VISIBLE
                       IIf(::oGroup != NIL .AND. Empty(::oGroup:aButtons), WS_GROUP , 0))

   ::Super:New(oWndParent, nId, ::Style, nLeft, nTop, nWidth, nHeight, ;
              oFont, bInit, bSize, bPaint, ctooltip, tcolor, bColor)

   ::backStyle :=  IIf(lTransp != NIL .AND. lTransp, TRANSPARENT, OPAQUE)

   ::Activate()
   //::SetColor(tcolor, bColor, .T.)

   //::oParent:AddControl(Self)

   IF ::oGroup != NIL
      bClick := IIf(bClick != NIL, bClick, ::oGroup:bClick)
      bGFocus := IIf(bGFocus != NIL, bGFocus, ::oGroup:bGetFocus)
   ENDIF
   IF bClick != NIL .AND. (::oGroup == NIL .OR. ::oGroup:bSetGet == NIL)
      ::bLostFocus := bClick
   ENDIF
   ::bGetFocus  := bGFocus
   IF bGFocus != NIL
      ::oParent:AddEvent(BN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus")
      //::oParent:AddEvent(BN_SETFOCUS, Self, {|o, id|__When(o:FindControl(id))},, "onGotFocus")
      ::lnoValid := .T.
   ENDIF

   ::oParent:AddEvent(BN_KILLFOCUS, Self, {||CheckFocus(Self, .T.)})

   IF ::oGroup != NIL
      AAdd(::oGroup:aButtons, Self)
      // IF ::oGroup:bSetGet != NIL
      ::bLostFocus := bClick
      //- ::oParent:AddEvent(BN_CLICKED, self, {|o, id|::Valid(o:FindControl(id))},, "onClick")
      ::oParent:AddEvent(BN_CLICKED, self, {||::onClick()}, , "onClick")
      // ENDIF
   ENDIF

   RETURN Self

METHOD Activate() CLASS HRadioButton
   IF !Empty(::oParent:handle)
      ::handle := CreateButton(::oParent:handle, ::id, ;
                               ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title)
      ::Init()
   ENDIF
   RETURN NIL

METHOD Init() CLASS HRadioButton
   IF !::lInit
      ::nHolder := 1
      hwg_SetWindowObject(::handle, Self)
      HWG_INITBUTTONPROC(::handle)
      ::Enabled :=  ::oGroup:lEnabled .AND. ::Enabled 
      ::Super:Init()
   ENDIF
RETURN NIL

METHOD Redefine(oWndParent, nId, oFont, bInit, bSize, bPaint, bClick, ctooltip, tcolor, bcolor, bGFocus, lTransp) CLASS HRadioButton
   ::oParent := IIf(oWndParent == NIL, ::oDefaultParent, oWndParent)
   ::id      := nId
   ::oGroup  := HRadioGroup():oGroupCurrent
   ::style   := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   ::oFont   := oFont
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := ctooltip
   /*
   ::tcolor  := tcolor
   IF tColor != NIL .AND. bColor == NIL
      bColor := GetSysColor(COLOR_3DFACE)
   ENDIF
   */
   ::backStyle :=  IIf(lTransp != NIL .AND. lTransp, TRANSPARENT, OPAQUE)
   ::setcolor(tColor, bColor, .T.)
   ::oParent:AddControl(Self)

   ::oParent:AddControl(Self)

   IF bClick != NIL .AND. (::oGroup == NIL .OR. ::oGroup:bSetGet == NIL)
      //::oParent:AddEvent(0, self, bClick, , "onClick")
      ::bLostFocus := bClick
      //::oParent:AddEvent(0, self, {|o, id|__Valid(o:FindControl(id))}, , "onClick")
   ENDIF
   ::bGetFocus  := bGFocus
   IF bGFocus != NIL
      ::oParent:AddEvent(BN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus")
      ::lnoValid := .T.
   ENDIF
   //::oParent:AddEvent(BN_KILLFOCUS, Self, {||::Notify(WM_KEYDOWN)})
   ::oParent:AddEvent(BN_KILLFOCUS, Self, {||CheckFocus(Self, .T.)})
   IF ::oGroup != NIL
      AAdd(::oGroup:aButtons, Self)
      // IF ::oGroup:bSetGet != NIL
      ::bLostFocus := bClick
      //::oParent:AddEvent(BN_CLICKED, self, {|o, id|::Valid(o:FindControl(id))},, "onClick")
      ::oParent:AddEvent(BN_CLICKED, self, {||::onClick()}, , "onClick")
      // ENDIF
   ENDIF
   RETURN Self

METHOD onEvent(msg, wParam, lParam) CLASS HRadioButton
    LOCAL oCtrl
     
   IF hb_IsBlock(::bOther)
      IF Eval(::bOther, Self, msg, wParam, lParam) != -1
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_GETDLGCODE //.AND. !Empty(wParam)
       IF wParam == VK_RETURN .AND. ProcOkCancel(Self, wParam, ::GetParentForm():Type >= WND_DLG_RESOURCE)
         RETURN 0
      ELSEIF wParam == VK_ESCAPE .AND. ;
                  (oCtrl := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled()
         RETURN DLGC_WANTMESSAGE  
       ELSEIF (wParam != VK_TAB .AND. GETDLGMESSAGE(lParam) == WM_CHAR) .OR. GETDLGMESSAGE(lParam) == WM_SYSCHAR .OR. ;
               wParam == VK_ESCAPE 
         RETURN -1         
      ELSEIF GETDLGMESSAGE(lParam) == WM_KEYDOWN .AND. wParam == VK_RETURN  // DIALOG 
         ::VALID(VK_RETURN)   // dialog funciona
         RETURN DLGC_WANTARROWS
      ENDIF 
      RETURN DLGC_WANTMESSAGE
   ELSEIF msg == WM_KEYDOWN
      //IF ProcKeyList(Self, wParam)
      IF wParam == VK_LEFT .OR. wParam == VK_UP
         GetSkip(::oparent, ::handle, , -1)
         RETURN 0
      ELSEIF wParam == VK_RIGHT .OR. wParam == VK_DOWN
         GetSkip(::oparent, ::handle, , 1)
         RETURN 0
      ELSEIF wParam == VK_TAB //.AND. nType < WND_DLG_RESOURCE
         GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN 0
      ENDIF
      IF (wParam == VK_RETURN)
         ::VALID(VK_RETURN)
         RETURN 0
      ENDIF
   ELSEIF msg == WM_KEYUP
      ProcKeyList(Self, wParam)   // working in MDICHILD AND DIALOG
      IF (wParam == VK_RETURN)
         RETURN 0
      ENDIF  
   ELSEIF msg == WM_NOTIFY
   ENDIF

   RETURN -1
/*
METHOD Notify(lParam) CLASS HRadioButton
   LOCAL ndown := getkeystate(VK_RIGHT) + getkeystate(VK_DOWN) + GetKeyState(VK_TAB)
   LOCAL nSkip := 0

   IF !CheckFocus(Self, .T.)
      RETURN 0
   ENDIF

   IF PTRTOULONG(lParam) == WM_KEYDOWN
      IF GetKeyState(VK_RETURN) < 0 //.AND. ::oGroup:value < Len(::oGroup:aButtons)
         ::oParent:lSuspendMsgsHandling := .T.
         __VALID(Self)
         ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
      IF ::oParent:classname = "HTAB"
         IF getkeystate(VK_LEFT) + getkeystate(VK_UP) < 0 .OR. ;
            (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0)
            nSkip := -1
         ELSEIF ndown < 0
            nSkip := 1
         ENDIF
         IF nSkip != 0
            //hwg_SetFocus(::oParent:handle)
            ::oParent:SETFOCUS()
            GetSkip(::oparent, ::handle, , nSkip)
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL
*/

METHOD onGotFocus() CLASS HRadioButton
   RETURN ::When()

METHOD onClick() CLASS HRadioButton
   ::lWhen := .F.
   ::lnoValid := .F.
   RETURN ::Valid(0)

METHOD When() CLASS HRadioButton
   LOCAL res := .T., nSkip

   IF !CheckFocus(Self, .F.)
      RETURN .T.
   ENDIF
   nSkip := IIf(GetKeyState(VK_UP) < 0 .OR. (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0), - 1, 1)
   ::lwhen := GetKeyState(VK_UP)  + GetKeyState(VK_DOWN) + GetKeyState(VK_RETURN) + GetKeyState(VK_TAB) < 0
   IF hb_IsBlock(::bGetFocus)
      ::lnoValid := .T.
      ::oParent:lSuspendMsgsHandling := .T.
      res := Eval(::bGetFocus, ::oGroup:nValue, Self)
      ::lnoValid := !res
      ::oparent:lSuspendMsgsHandling := .F.
      IF !res
         WhenSetFocus(Self, nSkip)
      ELSE
         ::SETfOCUS()   
      ENDIF
   ENDIF
   RETURN res


METHOD Valid(nKey) CLASS HRadioButton
   LOCAL nEnter := IIf(nKey == NIL, 1, nkey)
   LOCAL hctrl, iValue

   IF ::lnoValid .OR. getkeystate(VK_LEFT) + getkeystate(VK_RIGHT) + GetKeyState(VK_UP) + ;
       GetKeyState(VK_DOWN) + GetKeyState(VK_TAB) < 0 .OR. ::oGroup == NIL .OR. ::lwhen
      ::lwhen := .F.
      RETURN .T.
   ELSE
      ::oParent:lSuspendMsgsHandling := .T.
       iValue := AScan(::oGroup:aButtons, {|o|o:id == ::id})
      IF nEnter == VK_RETURN //< 0
         //-iValue := AScan(::oGroup:aButtons,{|o|o:id == ::id})
         IF !::GetValue()
            ::oGroup:nValue  := iValue
             ::oGroup:SetValue(::oGroup:nValue)      
            ::SetFocus(.T.)
         ENDIF
      ELSEIF nEnter == 0 .AND. !GetKeyState(VK_RETURN) < 0
         IF !::GetValue()
             ::oGroup:nValue := AScan(::oGroup:aButtons, {|o|o:id == ::id})
             ::oGroup:SetValue(::oGroup:nValue)
         ENDIF 
      ENDIF
   ENDIF
   IF ::oGroup:bSetGet != NIL
      Eval(::oGroup:bSetGet, ::oGroup:nValue)
   ENDIF
   hCtrl := hwg_GetFocus()
   IF hb_IsBlock(::bLostFocus) .AND. (nEnter == 0 .OR. iValue == Len(::oGroup:aButtons))
      Eval(::bLostFocus, Self, ::oGroup:nValue)
   ENDIF
   IF nEnter == VK_RETURN .AND. hwg_SelfFocus(hctrl)
       GetSkip(::oParent, hCtrl, , 1)
   ENDIF
   ::oParent:lSuspendMsgsHandling := .F.  
   
   RETURN .T.
