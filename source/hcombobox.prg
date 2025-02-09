//
// $Id: hcombo.prg 1906 2012-09-25 22:23:08Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HCombo class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

//-------------------------------------------------------------------------------------------------------------------//

CLASS HComboBox INHERIT HControl

   CLASS VAR winclass INIT "COMBOBOX"

   DATA aItems
   DATA aItemsBound
   DATA bSetGet
   DATA value INIT 1
   DATA valueBound INIT 1
   DATA cDisplayValue HIDDEN
   DATA columnBound INIT 1 HIDDEN
   DATA xrowsource INIT {,} HIDDEN

   DATA bChangeSel
   DATA bChangeInt
   DATA bValid
   DATA bSelect

   DATA lText INIT .F.
   DATA lEdit INIT .F.
   DATA SelLeght INIT 0
   DATA SelStart INIT 0
   DATA SelText INIT ""
   DATA nDisplay
   DATA nhItem
   DATA ncWidth
   DATA nHeightBox
   DATA lResource INIT .F.
   DATA ldropshow INIT .F.
   DATA nMaxLength     INIT NIL

   METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, bInit, bSize, ;
      bPaint, bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bLFocus, bIChange, nDisplay, nhItem, ncWidth, ;
      nMaxLength)
   METHOD Activate()
   METHOD Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, bGFocus, ;
      bLFocus, bIChange, nDisplay, nMaxLength, ledit, ltext)
   METHOD INIT()
   METHOD onEvent(msg, wParam, lParam)
   METHOD Requery()
   METHOD Refresh()
   METHOD Setitem(nPos)
   METHOD SetValue(xItem)
   METHOD GetValue()
   METHOD AddItem(cItem, cItemBound, nPos)
   METHOD DeleteItem(xIndex)
   METHOD Valid()
   METHOD When()
   METHOD onSelect()
   METHOD InteractiveChange()
   METHOD onChange(lForce)
   METHOD Populate() HIDDEN
   METHOD GetValueBound(xItem)
   METHOD RowSource(xSource) SETGET
   METHOD DisplayValue(cValue) SETGET
   METHOD onDropDown() INLINE ::ldropshow := .T.
   METHOD SetCueBanner(cText, lShowFoco)
   METHOD MaxLength(nMaxLength) SETGET

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, aItems, oFont, bInit, bSize, bPaint, ;
   bChange, ctooltip, lEdit, lText, bGFocus, tcolor, bcolor, bLFocus, bIChange, nDisplay, nhItem, ncWidth, nMaxLength) CLASS HComboBox

   IF !Empty(nDisplay) .AND. nDisplay > 0
      nStyle := hwg_BitOr(nStyle, CBS_NOINTEGRALHEIGHT  + WS_VSCROLL)
      // CBS_NOINTEGRALHEIGHT. CRIATE VERTICAL SCROOL BAR
   ELSE
      nDisplay := 10
   ENDIF
   nHeight := IIf(Empty(nHeight), 24, nHeight)
   ::nHeightBox := Int(nHeight * 0.75)                    //   Meets A 22'S EDITBOX
   nHeight := nHeight + (IIf(Empty(nhItem), 16.250, (nhItem += 0.10)) * nDisplay)

   IF lEdit == NIL
      lEdit := .F.
   ENDIF

   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), IIf(lEdit, CBS_DROPDOWN, CBS_DROPDOWNLIST) + WS_TABSTOP)
   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ctooltip, tcolor, ;
      bcolor)

   IF lText == NIL
      lText := .F.
   ENDIF

   ::nDisplay := nDisplay
   ::nhItem := nhItem
   ::ncWidth := ncWidth

   ::lEdit := lEdit
   ::lText := lText

   IF lEdit
      ::lText := .T.
      IF nMaxLength != NIL
         ::MaxLength := nMaxLength
      ENDIF
   ENDIF

   IF ::lText
      ::value := IIf(vari == NIL .OR. !hb_IsChar(vari), "", vari)
   ELSE
      ::value := IIf(vari == NIL .OR. !hb_IsNumeric(vari), 1, vari)
   ENDIF

   aItems := IIf(aItems == NIL, {}, aClone(aItems))
   ::RowSource(aItems)
   ::aItemsBound := {}
   ::bSetGet := bSetGet

   ::Activate()

   ::bChangeSel := bChange
   ::bGetFocus := bGFocus
   ::bLostFocus := bLFocus

   IF bSetGet != NIL
      IF bGFocus != NIL
         ::lnoValid := .T.
         ::oParent:AddEvent(CBN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus")
      ENDIF
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 03/06/2006
      ::oParent:AddEvent(CBN_KILLFOCUS, Self, {|o, id|::Valid(o:FindControl(id))}, .F., "onLostFocus")
      //::oParent:AddEvent(CBN_KILLFOCUS, Self, {|o, id|__Valid(o:FindControl(id))}, .F., "onLostFocus")
      //---------------------------------------------------------------------------
   ELSE
      IF bGFocus != NIL
         ::lnoValid := .T.
         ::oParent:AddEvent(CBN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus")
         //::oParent:AddEvent(CBN_SETFOCUS, Self, {|o, id|__When(o:FindControl(id))},, "onGotGocus")
      ENDIF
      ::oParent:AddEvent(CBN_KILLFOCUS, Self, {|o, id|::Valid(o:FindControl(id))}, .F., "onLostFocus")
      //::oParent:AddEvent(CBN_KILLFOCUS, Self, {|o, id|__Valid(o:FindControl(id))},, "onLostFocus")
   ENDIF
   IF bChange != NIL .OR. bSetGet != NIL
      ::oParent:AddEvent(CBN_SELCHANGE, Self, {|o, id|::onChange(o:FindControl(id))},, "onChange")
   ENDIF

   IF bIChange != NIL .AND. ::lEdit
      ::bchangeInt := bIChange
      //::oParent:AddEvent(CBN_EDITUPDATE, Self, {|o, id|__InteractiveChange(o:FindControl(id))}, , "interactiveChange")
      ::oParent:AddEvent(CBN_EDITUPDATE, Self, {|o, id|::InteractiveChange(o:FindControl(id))}, , "interactiveChange")
   ENDIF
   ::oParent:AddEvent(CBN_SELENDOK, Self, {|o, id|::onSelect(o:FindControl(id))}, , "onSelect")
   ::oParent:AddEvent(CBN_DROPDOWN, Self, {|o, id|::onDropDown(o:FindControl(id))}, , "ondropdown")
   ::oParent:AddEvent(CBN_CLOSEUP, Self, {||::ldropshow := .F.}, ,)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HComboBox

   IF !Empty(::oParent:handle)
      ::handle := CreateCombo(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight)
      ::Init()
      ::nHeight := INT(::nHeightBox / 0.75)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, vari, bSetGet, aItems, oFont, bInit, bSize, bPaint, bChange, ctooltip, bGFocus, ;
   bLFocus, bIChange, nDisplay, nMaxLength, ledit, ltext) CLASS HComboBox

   HB_SYMBOL_UNUSED(bLFocus)
   //HB_SYMBOL_UNUSED(bIChange)
   IF lEdit == NIL
      lEdit := .F.
   ENDIF
   IF lText == NIL
      lText := .F.
   ENDIF

   ::lEdit := lEdit
   ::lText := lText

   //::nHeightBox := INT(22 * 0.75) //   Meets A 22'S EDITBOX
   IF !Empty(nDisplay) .AND. nDisplay > 0
      ::Style := hwg_BitOr(::Style, CBS_NOINTEGRALHEIGHT) //+ WS_VSCROLL)
      // CBS_NOINTEGRALHEIGHT. CRIATE VERTICAL SCROOL BAR
   ELSE
      nDisplay := 10
   ENDIF
   //::nHeight := (::nHeight + 16.250) * nDisplay
   ::lResource := .T.
   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, ctooltip)

   ::nDisplay := nDisplay

   IF ::lText
      ::value := IIf(vari == NIL .OR. !hb_IsChar(vari), "", vari)
   ELSE
      ::value := IIf(vari == NIL .OR. !hb_IsNumeric(vari), 1, vari)
   ENDIF
   IF nMaxLength != NIL
       ::MaxLength := nMaxLength
   ENDIF

   aItems := IIf(aItems == NIL, {}, aClone(aItems))
   ::RowSource(aItems)
   ::aItemsBound := {}
   ::bSetGet := bSetGet

   IF bSetGet != NIL
      ::bChangeSel := bChange
      ::bGetFocus := bGFocus
      ::oParent:AddEvent(CBN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus")
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
      IF ::bSetGet != NIL
         ::oParent:AddEvent(CBN_SELCHANGE, Self, {|o, id|::Valid(o:FindControl(id))},, "onChange")
      // ::oParent:AddEvent(CBN_SELCHANGE, Self, {|o, id|__Valid(o:FindControl(id))},, "onChange")
      ELSEIF ::bChangeSel != NIL
         ::oParent:AddEvent(CBN_SELCHANGE, Self, {|o, id|::Valid(o:FindControl(id))},, "onChange")
       //  ::oParent:AddEvent(CBN_SELCHANGE, Self, {|o, id|__Valid(o:FindControl(id))},, "onChange")
      ENDIF
   ELSEIF bChange != NIL .AND. ::lEdit
      ::bChangeSel := bChange
      ::oParent:AddEvent(CBN_SELCHANGE, Self, {|o, id|::onChange(o:FindControl(id))},, "onChange")
    //::oParent:AddEvent(CBN_SELCHANGE, Self, bChange,, "onChange")
   ENDIF

   IF bGFocus != NIL .AND. bSetGet == NIL
      ::oParent:AddEvent(CBN_SETFOCUS, self, {|o, id|::When(o:FindControl(id))},, "onGotFocus")
   ENDIF
   IF bIChange != NIL .AND. ::lEdit
      ::bchangeInt := bIChange
      //::oParent:AddEvent(CBN_EDITUPDATE, Self, {|o, id|__InteractiveChange(o:FindControl(id))}, , "interactiveChange")
      ::oParent:AddEvent(CBN_EDITUPDATE, Self, {|o, id|::InteractiveChange(o:FindControl(id))}, , "interactiveChange")
   ENDIF

   ::oParent:AddEvent(CBN_SELENDOK, Self, {|o, id|::onSelect(o:FindControl(id))}, , "onSelect")
   //::Refresh() // By Luiz Henrique dos Santos
   ::oParent:AddEvent(CBN_DROPDOWN, Self, {|o, id|::onDropDown(o:FindControl(id))}, , "ondropdown")
   ::oParent:AddEvent(CBN_CLOSEUP, Self, {||::ldropshow := .F.}, ,)

   //::Requery()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD INIT() CLASS HComboBox

   LOCAL LongComboWidth
   LOCAL NewLongComboWidth
   LOCAL avgWidth
   LOCAL nHeightBox

   IF !::lInit
      ::nHolder := 1
      hwg_SetWindowObject(::handle, Self)
      HWG_INITCOMBOPROC(::handle)
      IF ::aItems != NIL .AND. !Empty(::aItems)
         /*
         IF ::value == NIL
            IF ::lText
               ::value := ::aItems[1]
            ELSE
               ::value := 1
            ENDIF
         ENDIF
         hwg_SendMessage(::handle, CB_RESETCONTENT, 0, 0)
         FOR i := 1 TO Len(::aItems)
            hwg_ComboAddString(::handle, ::aItems[i])
            numofchars := hwg_SendMessage(::handle, CB_GETLBTEXTLEN, i - 1, 0)
            IF numofchars > LongComboWidth
               LongComboWidth := numofchars
            ENDIF
         NEXT
         */
         ::RowSource(::aItems)
         LongComboWidth := ::Populate()
         //
         IF ::lText
            IF ::lEdit
               hwg_SetDlgItemText(getmodalhandle(), ::id, ::value)
               hwg_SendMessage(::handle, CB_SELECTSTRING, -1, ::value)
               //hwg_SendMessage(::handle, CB_SETEDITSEL, -1, 0)
            ELSE
               #ifdef __XHARBOUR__
               //hwg_ComboSetString(::handle, AScan(::aItems, ::value, , , .T.))
               hwg_ComboSetString(::handle, AScan(::aItems, ALLTRIM(::value)))
               #else
               //hwg_ComboSetString(::handle, hb_AScan(::aItems, ::value, , , .T.))
               hwg_ComboSetString(::handle, hb_AScan(::aItems, ALLTRIM(::value)))
               #endif
            ENDIF
            hwg_SendMessage(::handle, CB_SELECTSTRING, 0, ::value)
            hwg_SetWindowText(::handle, ::value)
         ELSE
            hwg_ComboSetString(::handle, ::value)
         ENDIF
         avgwidth := GetFontDialogUnits(::oParent:handle) //+ 0.75 //, ::oParent:oFont:handle)
         NewLongComboWidth := (LongComboWidth - 2) * avgwidth
         hwg_SendMessage(::handle, CB_SETDROPPEDWIDTH, NewLongComboWidth + 50, 0)
      ENDIF
      ::Super:Init()
      IF !::lResource
         // HEIGHT Items
         IF !Empty(::nhItem)
            hwg_SendMessage(::handle, CB_SETITEMHEIGHT, 0, ::nhItem + 0.10)
         ELSE
            ::nhItem := hwg_SendMessage(::handle, CB_GETITEMHEIGHT, 0, 0) + 0.10
         ENDIF
         nHeightBox := hwg_SendMessage(::handle, CB_GETITEMHEIGHT, -1, 0) //+ 0.750
         //  WIDTH  Items
         IF !Empty(::ncWidth)
            hwg_SendMessage(::handle, CB_SETDROPPEDWIDTH, ::ncWidth, 0)
         ENDIF
         ::nHeight := Int(nHeightBox / 0.75 + (::nhItem * ::nDisplay)) + 3
      ENDIF
   ENDIF
   IF !::lResource
      hwg_MoveWindow(::handle, ::nLeft, ::nTop, ::nWidth, ::nHeight)
      // HEIGHT COMBOBOX
      hwg_SendMessage(::handle, CB_SETITEMHEIGHT, -1, ::nHeightBox)
   ENDIF
   ::Refresh()
   IF ::lEdit
      hwg_SendMessage(::handle, CB_SETEDITSEL, -1, 0)
      hwg_SendMessage(::handle, WM_SETREDRAW, 1, 0)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference
METHOD onEvent(msg, wParam, lParam) CLASS HComboBox

   LOCAL oCtrl

   IF hb_IsBlock(::bOther)
      IF Eval(::bOther, Self, msg, wParam, lParam) != - 1
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_MOUSEWHEEL .AND. ::oParent:nScrollBars != -1 .AND. ::oParent:bScroll == NIL
      ::super:ScrollHV(::oParent, msg, wParam, lParam)
      RETURN 0
   ELSEIF msg == CB_SHOWDROPDOWN
      ::ldropshow := IIf(wParam == 1, .T., ::ldropshow)
   ENDIF

   IF ::bSetGet != NIL .OR. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
      IF msg == WM_CHAR .AND. (::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. ;
          !::GetParentForm(Self):lModal)
         IF wParam == VK_TAB
            GetSkip(::oParent, ::handle,, IIf(IsCtrlShift(.F., .T.), - 1, 1))
            RETURN 0
         ELSEIF wParam == VK_RETURN .AND. ;
            !ProcOkCancel(Self, wParam, ::GetParentForm():Type >= WND_DLG_RESOURCE) .AND.;
                       (::GetParentForm():Type < WND_DLG_RESOURCE .OR. ;
                   !::GetParentForm():lModal)
            GetSkip(::oParent, ::handle, , 1)
            RETURN 0
         ENDIF
      ELSEIF msg == WM_GETDLGCODE
         IF wParam == VK_RETURN
            RETURN DLGC_WANTMESSAGE
         ELSEIF wParam == VK_ESCAPE .AND. ;
                  (oCtrl := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled()
            RETURN DLGC_WANTMESSAGE
         ENDIF
           RETURN  DLGC_WANTCHARS + DLGC_WANTARROWS

      ELSEIF msg == WM_KEYDOWN
         //ProcKeyList(Self, wParam)
         IF wparam == VK_RIGHT .OR. wParam == VK_RETURN //.AND. !::lEdit
             GetSkip(::oParent, ::handle, , 1)
             RETURN 0
         ELSEIF wparam == VK_LEFT //.AND. !::lEdit
               GetSkip(::oParent, ::handle, , -1)
               RETURN 0
         ELSEIF wParam == VK_ESCAPE .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE //.OR.;
            RETURN 0
         ENDIF

      ELSEIF msg == WM_KEYUP
         ProcKeyList(Self, wParam)        //working in MDICHILD AND DIALOG
      ELSEIF msg == WM_COMMAND .AND. ::lEdit .AND. !::ldropshow
         IF GETKEYSTATE(VK_DOWN) + GETKEYSTATE(VK_UP) < 0 .AND. GetKeyState(VK_SHIFT) > 0 .AND. hwg_HIWORD(wParam) == 1
            RETURN 0
        ENDIF
      ELSEIF msg == CB_GETDROPPEDSTATE .AND. !::ldropshow
           IF GETKEYSTATE(VK_RETURN) < 0
            ::GetValue()
          ENDIF
         IF (GETKEYSTATE(VK_RETURN) < 0 .OR. GETKEYSTATE(VK_ESCAPE) < 0) .AND. ;
            (::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. ;
            !::GetParentForm(Self):lModal)
            ProcOkCancel(Self, IIf(GETKEYSTATE(VK_RETURN) < 0, VK_RETURN, VK_ESCAPE))
         ENDIF
           IF GETKEYSTATE(VK_TAB) + GETKEYSTATE(VK_DOWN) < 0 .AND. GetKeyState(VK_SHIFT) > 0
            IF ::oParent:oParent == NIL
             //  GetSkip(::oParent, hwg_GetAncestor(::handle, GA_PARENT), , 1)
            ENDIF
            GetSkip(::oParent, ::handle, , 1)
            RETURN 0
           ELSEIF GETKEYSTATE(VK_UP) < 0 .AND. GetKeyState(VK_SHIFT) > 0
            IF ::oParent:oParent == NIL
             //  GetSkip(::oParent, hwg_GetAncestor(::handle, GA_PARENT), , 1)
            ENDIF
            GetSkip(::oParent, ::handle, , -1)
            RETURN 0
         ENDIF
          IF (::GetParentForm(Self):Type < WND_DLG_RESOURCE.OR. !::GetParentForm(Self):lModal)
             RETURN 1
          ENDIF
      ENDIF
   ENDIF

RETURN -1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HComboBox

   LOCAL oCtrl

   IF hb_IsBlock(::bOther)
      IF Eval(::bOther, Self, msg, wParam, lParam) != -1
         RETURN 0
      ENDIF
   ENDIF
   
   // TODO: unificar switch's

   SWITCH msg

   CASE WM_MOUSEWHEEL
      IF ::oParent:nScrollBars != -1 .AND. ::oParent:bScroll == NIL
         ::super:ScrollHV(::oParent, msg, wParam, lParam)
         RETURN 0
      ENDIF
      EXIT

   CASE CB_SHOWDROPDOWN
      ::ldropshow := IIf(wParam == 1, .T., ::ldropshow)

   ENDSWITCH

   IF hb_IsBlock(::bSetGet) .OR. ::GetParentForm(Self):Type < WND_DLG_RESOURCE

      SWITCH msg

      CASE WM_CHAR
         IF ::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. !::GetParentForm(Self):lModal
            IF wParam == VK_TAB
               GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
               RETURN 0
            ELSEIF wParam == VK_RETURN .AND. ;
               !ProcOkCancel(Self, wParam, ::GetParentForm():Type >= WND_DLG_RESOURCE) .AND. ;
               (::GetParentForm():Type < WND_DLG_RESOURCE .OR. !::GetParentForm():lModal)
               GetSkip(::oParent, ::handle, , 1)
               RETURN 0
            ENDIF
         ENDIF
         EXIT

      CASE WM_GETDLGCODE
         IF wParam == VK_RETURN
            RETURN DLGC_WANTMESSAGE
         ELSEIF wParam == VK_ESCAPE .AND. ;
            (oCtrl := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled()
            RETURN DLGC_WANTMESSAGE
         ENDIF
         RETURN DLGC_WANTCHARS + DLGC_WANTARROWS

      CASE WM_KEYDOWN
         //ProcKeyList(Self, wParam)
         IF wparam == VK_RIGHT .OR. wParam == VK_RETURN //.AND. !::lEdit
            GetSkip(::oParent, ::handle, , 1)
            RETURN 0
         ELSEIF wparam == VK_LEFT //.AND. !::lEdit
            GetSkip(::oParent, ::handle, , -1)
            RETURN 0
         ELSEIF wParam == VK_ESCAPE .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE //.OR. ;
            RETURN 0
         ENDIF
         EXIT

      CASE WM_KEYUP
         ProcKeyList(Self, wParam) //working in MDICHILD AND DIALOG
         EXIT

      CASE WM_COMMAND
         IF ::lEdit .AND. !::ldropshow
            IF GETKEYSTATE(VK_DOWN) + GETKEYSTATE(VK_UP) < 0 .AND. GetKeyState(VK_SHIFT) > 0 .AND. hwg_HIWORD(wParam) == 1
               RETURN 0
            ENDIF
         ENDIF
         EXIT

      CASE CB_GETDROPPEDSTATE
         IF !::ldropshow
            IF GETKEYSTATE(VK_RETURN) < 0
               ::GetValue()
            ENDIF
            IF (GETKEYSTATE(VK_RETURN) < 0 .OR. GETKEYSTATE(VK_ESCAPE) < 0) .AND. ;
               (::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. ;
               !::GetParentForm(Self):lModal)
               ProcOkCancel(Self, IIf(GETKEYSTATE(VK_RETURN) < 0, VK_RETURN, VK_ESCAPE))
            ENDIF
            IF GETKEYSTATE(VK_TAB) + GETKEYSTATE(VK_DOWN) < 0 .AND. GetKeyState(VK_SHIFT) > 0
               IF ::oParent:oParent == NIL
                  //GetSkip(::oParent, hwg_GetAncestor(::handle, GA_PARENT), , 1)
               ENDIF
               GetSkip(::oParent, ::handle, , 1)
               RETURN 0
            ELSEIF GETKEYSTATE(VK_UP) < 0 .AND. GetKeyState(VK_SHIFT) > 0
               IF ::oParent:oParent == NIL
                  //GetSkip(::oParent, hwg_GetAncestor(::handle, GA_PARENT), , 1)
               ENDIF
               GetSkip(::oParent, ::handle, , -1)
               RETURN 0
            ENDIF
            IF ::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. !::GetParentForm(Self):lModal
               RETURN 1
            ENDIF
         ENDIF

      ENDSWITCH

   ENDIF

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD MaxLength(nMaxLength) CLASS HComboBox

   IF nMaxLength != NIL .AND. ::lEdit
       hwg_SendMessage(::handle, CB_LIMITTEXT, nMaxLength, 0)
       ::nMaxLength := nMaxLength
   ENDIF

RETURN ::nMaxLength

//-------------------------------------------------------------------------------------------------------------------//

METHOD Requery() CLASS HComboBox

   hwg_SendMessage(::handle, CB_RESETCONTENT, 0, 0)
   ::Populate()

   /*
   FOR i := 1 TO Len(::aItems)
      hwg_ComboAddString(::handle, ::aItems[i])
   NEXT
   */
   //::Refresh()
   IF Empty(::Value) .AND. Len(::aItems) > 0 .AND. ::bSetGet == NIL .AND. !::lEdit
      ::SetItem(1)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Refresh() CLASS HComboBox

   LOCAL vari

   IF hb_IsBlock(::bSetGet)
      vari := Eval(::bSetGet,, Self)
      IF ::columnBound == 2
          vari := ::GetValueBound(vari)
      ENDIF
      IF ::columnBound == 1
         IF ::lText
         //vari := IIf(::bSetGetField != NIL .AND. hb_IsChar(vari), Trim(vari), vari)
            ::value := IIf(vari == NIL .OR. !hb_IsChar(vari), "", vari)
               //hwg_SendMessage(::handle, CB_SETEDITSEL, 0, Len(::value))
         ELSE
            ::value := IIf(vari == NIL .OR. !hb_IsNumeric(vari), 1, vari)
         ENDIF
      ENDIF
      /*
      IF ::columnBound == 1
         Eval(::bSetGet, ::value, Self)
      ELSE
         Eval(::bSetGet, ::valuebound, Self)
      ENDIF
      */
   ENDIF

   /*
   hwg_SendMessage(::handle, CB_RESETCONTENT, 0, 0)

   FOR i := 1 TO Len(::aItems)
      hwg_ComboAddString(::handle, ::aItems[i])
   NEXT
 */
   IF ::lText
      IF ::lEdit
         hwg_SetDlgItemText(getmodalhandle(), ::id, ::value)
         hwg_SendMessage(::handle, CB_SETEDITSEL, 0, ::SelStart)
      ENDIF
      #ifdef __XHARBOUR__
      hwg_ComboSetString(::handle, AScan(::aItems, ::value))
      #else
      hwg_ComboSetString(::handle, hb_AScan(::aItems, ::value, , , .T.))
      #endif
   ELSE
      hwg_ComboSetString(::handle, ::value)
      //-::SetItem(::value)
   ENDIF
   ::valueBound := ::GetValueBound()

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetItem(nPos) CLASS HComboBox

   /*
 IF hb_IsChar(nPos) .AND. ::lText
    nPos := AScan(::aItems, nPos)
      hwg_ComboSetString(::handle, nPos)
   ENDIF
   */
   IF ::lText
      IF nPos > 0
         ::value := ::aItems[nPos]
         ::ValueBound := ::GetValueBound()
      ELSE
         ::value := ""
         ::valueBound := IIf(::bSetGet != NIL, Eval(::bSetGet,, Self), ::valueBound)
      ENDIF
   ELSE
      ::value := nPos
      ::ValueBound := ::GetValueBound()
   ENDIF

   hwg_ComboSetString(::handle, nPos)

   IF hb_IsBlock(::bSetGet)
      IF ::columnBound == 1
         Eval(::bSetGet, ::value, Self)
      ELSE
         Eval(::bSetGet, ::valuebound, Self)
      ENDIF
   ENDIF

   /*
   IF hb_IsBlock(::bChangeSel)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bChangeSel, nPos, Self)
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF
   */

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetValue(xItem) CLASS HComboBox

   LOCAL nPos

   IF ::lText .AND. hb_IsChar(xItem)
      IF ::columnBound == 2
         nPos := AScan(::aItemsBound, xItem)
      ELSE
         nPos := AScan(::aItems, xItem)
      ENDIF
      hwg_ComboSetString(::handle, nPos)
   ELSE
      nPos := IIf(::columnBound == 2, AScan(::aItemsBound, xItem), xItem)
   ENDIF
   ::setItem(nPos)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetValue() CLASS HComboBox

   LOCAL nPos := hwg_SendMessage(::handle, CB_GETCURSEL, 0, 0) + 1

   //::value := IIf(::lText, ::aItems[nPos], nPos)
   IF ::lText
       IF (::lEdit .OR. !hb_IsChar(::Value)) .AND. nPos <= 1
           ::Value := hwg_GetEditText(::oParent:handle, ::id)
           nPos := hwg_SendMessage(::handle, CB_FINDSTRINGEXACT, -1, ::value) + 1
        ELSEIF nPos > 0
         ::value := ::aItems[nPos]
      ENDIF
      //nPos := IIf(Len(::value) > 0, AScan(::aItems, ::Value), 0)
      ::cDisplayValue := ::Value
      ::value := IIf(nPos > 0, ::aItems[nPos], IIf(::lEdit, "", ::value))
   ELSE
      ::value := nPos
   ENDIF
   ::ValueBound := IIf(nPos > 0, ::GetValueBound(), ::ValueBound) // IIf(::lText, "", 0))
   IF hb_IsBlock(::bSetGet)
      IF ::columnBound == 1
         Eval(::bSetGet, ::value, Self)
      ELSE
         Eval(::bSetGet, ::ValueBound, Self)
      ENDIF
   ENDIF

RETURN ::value

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetValueBound(xItem) CLASS HComboBox

   LOCAL nPos := hwg_SendMessage(::handle, CB_GETCURSEL, 0, 0) + 1

   IF ::columnBound == 1
      RETURN NIL
   ENDIF
   IF xItem == NIL
      IF ::lText
          //nPos := IIf(::Value == NIL, 0, AScan(::aItems, ::Value))
          #ifdef __XHARBOUR__
          nPos := IIf(::Value == NIL, 0, AScan(::aItems, ::value))
          #else
          nPos := IIf(::Value == NIL, 0, hb_AScan(::aItems, ::value, , , .T.))
          #endif
      ENDIF
   ELSE
      //nPos := AScan(::aItemsBound, xItem)
      #ifdef __XHARBOUR__
      nPos := AScan(::aItemsBound, xItem)
      #else
      nPos := hb_AScan(::aItemsBound, xItem, , , .T.)
      #endif
      ::setItem(nPos)
      RETURN IIf(nPos > 0, ::aItems[nPos], xItem)
   ENDIF
   //::ValueBound := IIf(::lText, "", 0)
   IF nPos > 0 .AND. nPos <=  Len(::aItemsBound) // Len(::aItems) == Len(::aItemsBound)
      ::ValueBound := ::aItemsBound[nPos]
   ENDIF

RETURN ::ValueBound

//-------------------------------------------------------------------------------------------------------------------//

METHOD DisplayValue(cValue) CLASS HComboBox

   IF cValue != NIL
       IF ::lEdit .AND. hb_IsChar(cValue)
         hwg_SetDlgItemText(::oParent:handle, ::id, cValue)
         ::cDisplayValue := cValue
      ENDIF
   ENDIF

RETURN IIf(!::lEdit, hwg_GetEditText(::oParent:handle, ::id), ::cDisplayValue)
//RETURN IIf(IsWindow(::oParent:handle), hwg_GetEditText(::oParent:handle, ::id), ::cDisplayValue)

//-------------------------------------------------------------------------------------------------------------------//

METHOD DeleteItem(xIndex) CLASS HComboBox

   LOCAL nIndex

   IF ::lText .AND. hb_IsChar(xIndex)
         nIndex := hwg_SendMessage(::handle, CB_FINDSTRINGEXACT, -1, xIndex) + 1
   ELSE
       nIndex := xIndex
   ENDIF
   IF hwg_SendMessage(::handle, CB_DELETESTRING, nIndex - 1, 0) > 0               //<= Len(ocombo:aitems)
      ADel(::Aitems, nIndex)
      ASize(::Aitems, Len(::aitems) - 1)
      IF Len(::AitemsBound) > 0
         ADel(::AitemsBound, nIndex)
         ASize(::AitemsBound, Len(::aitemsBound) - 1)
      ENDIF
      RETURN .T.
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

METHOD AddItem(cItem, cItemBound, nPos) CLASS HComboBox

   LOCAL nCount

   nCount := hwg_SendMessage(::handle, CB_GETCOUNT, 0, 0) + 1
   IF Len(::Aitems) == Len(::AitemsBound) .AND. cItemBound != NIL
      IF nCount == 1
         ::RowSource({{cItem, cItemBound}})
         ::Aitems := {}
      ENDIF
      IF nPos != NIL .AND. nPos > 0 .AND. nPos < nCount
         aSize(::AitemsBound, nCount + 1)
         aIns(::AitemsBound, nPos, cItemBound)
      ELSE
         AAdd(::AitemsBound, cItemBound)
      ENDIF
      ::columnBound := 2
   ENDIF
   IF nPos != NIL .AND. nPos > 0 .AND. nPos < nCount
       aSize(::Aitems, nCount + 1)
       aIns(::Aitems, nPos, cItem)
    ELSE
       AAdd(::Aitems, cItem)
    ENDIF
    IF nPos != NIL .AND. nPos > 0 .AND. nPos < nCount
       hwg_ComboInsertString(::handle, nPos - 1, cItem) //::aItems[i])
    ELSE
       hwg_ComboAddString(::handle, cItem) //::aItems[i])
    ENDIF

RETURN nCount

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetCueBanner(cText, lShowFoco) CLASS HComboBox

   LOCAL lRet := .F.

   IF ::lEdit
      lRet := hwg_SendMessage(::handle, CB_SETCUEBANNER, IIf(Empty(lShowFoco), 0, 1), ANSITOUNICODE(cText))
   ENDIF

RETURN lRet

//-------------------------------------------------------------------------------------------------------------------//

METHOD InteractiveChange() CLASS HComboBox

   LOCAL npos

   npos := hwg_SendMessage(::handle, CB_GETEDITSEL, 0, 0)
   ::SelStart := nPos
   ::cDisplayValue := hwg_GetWindowText(::handle)
   ::oparent:lSuspendMsgsHandling := .T.
   Eval(::bChangeInt, ::value, Self)
   ::oparent:lSuspendMsgsHandling := .F.
   hwg_SendMessage(::handle, CB_SETEDITSEL, 0, ::SelStart)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD onSelect() CLASS HComboBox

   IF hb_IsBlock(::bSelect)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bSelect, ::value, Self)
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

METHOD onChange(lForce) CLASS HComboBox

   IF !hwg_SelfFocus(::handle) .AND. Empty(lForce)
      RETURN NIL
   ENDIF
   IF !hwg_IsWindowVisible(::handle)
      ::SetItem(::Value)
      RETURN NIL
   ENDIF

   ::SetItem(hwg_SendMessage(::handle, CB_GETCURSEL, 0, 0) + 1)
   IF hb_IsBlock(::bChangeSel)
      //::SetItem(hwg_SendMessage(::handle, CB_GETCURSEL, 0, 0) + 1)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bChangeSel, ::Value, Self)
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD When() CLASS HComboBox

   LOCAL res := .T.
   LOCAL oParent
   LOCAL nSkip

   IF !CheckFocus(Self, .F.)
      RETURN .T.
   ENDIF

   IF !::lText
      //::Refresh()
   ELSE
      //  hwg_SetWindowText(::handle, ::value)
      //  hwg_SendMessage(::handle, CB_SELECTSTRING, 0, ::value)
   ENDIF
   nSkip := IIf(GetKeyState(VK_UP) < 0 .OR. (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0), - 1, 1)
   IF hb_IsBlock(::bGetFocus)
      ::oParent:lSuspendMsgsHandling := .T.
      ::lnoValid := .T.
      IF hb_IsBlock(::bSetGet)
         res := Eval(::bGetFocus, Eval(::bSetGet,, Self), Self)
      ELSE
         res := Eval(::bGetFocus, ::value, Self)
      ENDIF
      ::oParent:lSuspendMsgsHandling := .F.
      ::lnoValid := !res
      IF hb_IsLogical(res) .AND. !res
         oParent := ParentGetDialog(Self)
         IF Self == ATail(oParent:GetList)
            nSkip := - 1
         ELSEIF Self == oParent:getList[1]
            nSkip := 1
         ENDIF
         WhenSetFocus(Self, nSkip)
      ENDIF
   ENDIF

RETURN res

//-------------------------------------------------------------------------------------------------------------------//

METHOD Valid() CLASS HComboBox

   LOCAL oDlg
   LOCAL nSkip
   LOCAL res
   LOCAL hCtrl := hwg_GetFocus()
   LOCAL ltab := GETKEYSTATE(VK_TAB) < 0

   IF ::lNoValid .OR. !CheckFocus(Self, .T.)
      RETURN .T.
   ENDIF

   nSkip := IIf(GetKeyState(VK_SHIFT) < 0, - 1, 1)

   IF (oDlg := ParentGetDialog(Self)) == NIL .OR. oDlg:nLastKey != VK_ESCAPE
      // end by sauli
      // IF lESC // "if" by Luiz Henrique dos Santos (luizhsantos@gmail.com) 04/06/2006
      // By Luiz Henrique dos Santos (luizhsantos@gmail.com.br) 03/06/2006
      ::GetValue()
      IF hb_IsBlock(::bLostFocus)
         ::oparent:lSuspendMsgsHandling := .T.
         res := Eval(::bLostFocus, ::value, Self)
         IF hb_IsLogical(res) .AND. !res
            ::SetFocus(.T.)
            IF oDlg != NIL
               oDlg:nLastKey := 0
            ENDIF
            ::oparent:lSuspendMsgsHandling := .F.
            RETURN .F.
         ENDIF

      ENDIF
      IF oDlg != NIL
         oDlg:nLastKey := 0
      ENDIF
      IF lTab .AND. hwg_SelfFocus(hCtrl) .AND. !hwg_SelfFocus(::oParent:handle, oDlg:handle)
        // IF ::oParent:CLASSNAME = "HTAB"
            ::oParent:SETFOCUS()
            Getskip(::oparent, ::handle, , nSkip)
       //  ENDIF
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
      IF Empty(hwg_GetFocus()) // getfocus return pointer = 0                 //::nValidSetfocus = ::handle
         GetSkip(::oParent, ::handle, , ::nGetSkip)
      ENDIF
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

METHOD RowSource(xSource) CLASS HComboBox

   IF xSource != NIL
      IF hb_IsArray(xSource)
        IF Len(xSource) > 0 .AND. !hb_IsArray(xSource[1]) .AND. Len(xSource) <= 2 .AND. "->" $ xSource[1] // COLUMNS MAX = 2
           ::xrowsource := {xSource[1], IIf(Len(xSource) > 1, xSource[2], NIL)}
        ENDIF
      ELSE
         ::xrowsource := {xSource, NIL}
      ENDIF
      ::aItems := xSource
   ENDIF

RETURN ::xRowSource

//-------------------------------------------------------------------------------------------------------------------//

METHOD Populate() CLASS HComboBox

   LOCAL cAlias
   LOCAL nRecno
   LOCAL value
   LOCAL cValueBound
   LOCAL i
   LOCAL numofchars
   LOCAL LongComboWidth := 0
   LOCAL xRowSource

   IF Empty(::aItems)
      RETURN NIL
   ENDIF
   xRowSource := IIf(hb_IsArray(::xRowSource[1]), ::xRowSource[1, 1], ::xRowSource[1])
   IF xRowSource != NIL .AND. (i := At("->", xRowSource)) > 0
       cAlias := AllTrim(Left(xRowSource, i - 1))
       IF Select(cAlias) == 0 .AND. (i := At("(", cAlias)) > 0
          cAlias := LTrim(SubStr(cAlias, i + 1))
       ENDIF
      value := StrTran(xRowSource, calias + "->", , , 1, 1)
      cAlias := IIf(ValType(xRowSource) == "U", NIL, cAlias)
      cValueBound := IIf(::xrowsource[2] != NIL .AND. cAlias != NIL, StrTran(::xrowsource[2], calias + "->"), NIL)
   ELSE
      cValueBound := IIf(hb_IsArray(::aItems[1]) .AND. Len(::aItems[1]) > 1, ::aItems[1, 2], NIL)
   ENDIF
   ::columnBound := IIf(cValueBound == NIL, 1, 2)
   IF ::value == NIL
      IF ::lText
         ::value := IIf(cAlias == NIL, ::aItems[1], (cAlias)->(&(value)))
       ELSE
         ::value := 1
       ENDIF
   ELSEIF ::lText .AND. !::lEdit .AND. Empty(::value)
      ::value := IIf(cAlias == NIL, ::aItems[1], (cAlias)->(&(value)))
   ENDIF
   hwg_SendMessage(::handle, CB_RESETCONTENT, 0, 0)
   ::AitemsBound := {}
   IF cAlias != NIL .AND. SELECT(cAlias) > 0
      ::aItems := {}
      nRecno := (cAlias)->(Recno())
      (cAlias)->(DBGOTOP())
       i := 1
       DO WHILE !(cAlias)->(EOF())
         AAdd(::Aitems, (cAlias)->(&(value)))
         IF !Empty(cvaluebound)
            AAdd(::AitemsBound, (cAlias)->(&(cValueBound)))
         ENDIF
         hwg_ComboAddString(::handle, ::aItems[i])
         numofchars := hwg_SendMessage(::handle, CB_GETLBTEXTLEN, i - 1, 0)
         IF numofchars > LongComboWidth
             LongComboWidth := numofchars
         ENDIF
         (cAlias)->(DBSKIP())
         i++
       ENDDO
       IF nRecno > 0
          (cAlias)->(DBGOTO(nRecno))
       ENDIF
    ELSE
       FOR i := 1 TO Len(::aItems)
          IF ::columnBound > 1
             IF hb_IsArray(::aItems[i]) .AND. Len(::aItems[i]) > 1
                AAdd(::AitemsBound, ::aItems[i, 2 ])
             ELSE
                AAdd(::AitemsBound, NIL)
             ENDIF
             ::aItems[i] := ::aItems[i, 1]
             hwg_ComboAddString(::handle, ::aItems[i])
          ELSE
             hwg_ComboAddString(::handle, ::aItems[i])
          ENDIF
          numofchars := hwg_SendMessage(::handle, CB_GETLBTEXTLEN, i - 1, 0)
          if numofchars > LongComboWidth
              LongComboWidth := numofchars
          endif
       NEXT
    ENDIF
    ::ValueBound := ::GetValueBound()

RETURN LongComboWidth

//-------------------------------------------------------------------------------------------------------------------//
