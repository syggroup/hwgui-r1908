//
// $Id: hedit.prg 1906 2012-09-25 22:23:08Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HEdit class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

STATIC s_lColorinFocus := .F.
STATIC s_lFixedColor := .T.
STATIC s_tColorSelect := 0
STATIC s_bColorSelect := 13434879 //hwg_VColor("CCFFFF")
STATIC s_lPersistColorSelect := .F.
STATIC s_bDisablecolor := NIL  // GetSysColor(COLOR_BTNHIGHLIGHT)

#include "windows.ch"
#include "hbclass.ch"
#include "hblang.ch"
#include "guilib.ch"

#define VK_C  67
#define VK_V  86
#define VK_X  87

//-------------------------------------------------------------------------------------------------------------------//

CLASS HEdit INHERIT HControl

   CLASS VAR winclass INIT "EDIT"

   DATA tColorOld
   DATA bColorOld
   DATA lMultiLine INIT .F.
   DATA lWantReturn INIT .F. HIDDEN
   DATA cType INIT "C"
   DATA bSetGet
   DATA bValid
   DATA bkeydown
   DATA bkeyup
   DATA bchange
   DATA cPicture
   DATA cPicFunc
   DATA cPicMask
   DATA lPicComplex INIT .F.
   DATA lFirst INIT .T.
   DATA lChanged INIT .F.
   DATA nMaxLength INIT NIL
   //DATA nColorinFocus INIT hwg_VColor("CCFFFF")
   DATA lFocu INIT .F.
   DATA lReadOnly INIT .F.
   DATA lNoPaste INIT .F.
   DATA oUpDown
   DATA lCopy INIT .F. HIDDEN
   DATA nSelStart INIT 0 HIDDEN
   DATA cSelText INIT "" HIDDEN
   DATA nSelLength INIT 0 HIDDEN

   METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ;
      bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, lNoBorder, nMaxLength, lPassword, bKeyDown, bChange, ;
      bOther)
   METHOD Activate()
   METHOD onEvent(msg, wParam, lParam)
   METHOD Redefine(oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, ;
      bcolor, cPicture, nMaxLength, lMultiLine, bKeyDown, bChange)
   METHOD Init()
   METHOD SetGet(value) INLINE Eval(::bSetGet, value, Self)
   METHOD Refresh()
   METHOD SetText(c)
   METHOD ParsePict(cPicture, vari)

   METHOD VarPut(value) INLINE ::SetGet(value)
   METHOD VarGet() INLINE ::SetGet()

   METHOD IsEditable(nPos, lDel) PROTECTED
   METHOD KeyRight(nPos) PROTECTED
   METHOD KeyLeft(nPos) PROTECTED
   METHOD DeleteChar(lBack) PROTECTED
   METHOD Input(cChar, nPos) PROTECTED
   METHOD GetApplyKey(cKey) PROTECTED
   METHOD Valid() //PROTECTED BECAUSE IS CALL IN HDIALOG
   METHOD When() //PROTECTED
   METHOD onChange(lForce) //PROTECTED
   METHOD IsBadDate(cBuffer) PROTECTED
   METHOD Untransform(cBuffer) PROTECTED
   METHOD FirstEditable() PROTECTED
   METHOD FirstNotEditable(nPos) PROTECTED
   METHOD LastEditable() PROTECTED
   METHOD SetGetUpdated() PROTECTED
   METHOD ReadOnly(lreadOnly) SETGET
   METHOD SelLength(Length) SETGET
   METHOD SelStart(Start) SETGET
   METHOD SelText(cText) SETGET
   METHOD Value (Value) SETGET
   METHOD SetCueBanner (cText, lshowFoco)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, vari, bSetGet, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ;
   bGfocus, bLfocus, ctooltip, tcolor, bcolor, cPicture, lNoBorder, nMaxLength, lPassword, bKeyDown, bChange, ;
   bOther) CLASS HEdit

   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), ;
                        WS_TABSTOP + IIf(lNoBorder == NIL .OR. !lNoBorder, WS_BORDER, 0) + ;
                        IIf(lPassword == NIL .OR. !lPassword, 0, ES_PASSWORD))

   //IF owndParent:oParent != NIL
   //   bPaint := {|o, p|o:paint(p)}
   //ENDIF
   bcolor := IIf(bcolor == NIL .AND. hwg_BitAnd(nStyle, WS_DISABLED) == 0, GetSysColor(COLOR_BTNHIGHLIGHT), bcolor)
   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, bcolor)
//              bSize, bPaint, ctooltip, tcolor, IIf(bcolor == NIL, GetSysColor(COLOR_BTNHIGHLIGHT), bcolor))

   IF vari != NIL
      ::cType := ValType(vari)
   ENDIF
   ::SetText(vari)
   /*
   IF bSetGet == NIL
      ::title := vari
   ENDIF
   */
   ::lReadOnly := hwg_BitAnd(nStyle, ES_READONLY) != 0
   ::bSetGet := bSetGet
   ::bKeyDown := bKeyDown
   ::bChange := bChange
   ::bOther := bOther
   IF hwg_BitAnd(nStyle, ES_MULTILINE) != 0
      //IF hwg_BitAnd(nStyle, ES_WANTRETURN) != 0
       ::lMultiLine := .T.
       ::lWantReturn := hwg_BitAnd(nStyle, ES_WANTRETURN) != 0
      //ENDIF
   ENDIF
   IF (nMaxLength != NIL .AND. !Empty(nMaxLength)) //.AND. (Empty(cPicture) .OR. cPicture == NIL)
      ::nMaxLength := nMaxLength
   ENDIF
   IF ::cType == "N" .AND. hwg_BitAnd(nStyle, ES_LEFT + ES_CENTER) == 0
      ::style := hwg_BitOr(::style, ES_RIGHT + ES_NUMBER)
      cPicture := IIf(cPicture == NIL .AND. ::nMaxLength != NIL, Replicate("9", ::nMaxLength), cPicture)
   ENDIF
   IF ::cType == "D" .AND. bSetGet != NIL
      ::nMaxLength := Len(DTOC(vari)) //IIf(SET(_SET_CENTURY), 10, 8)
   ENDIF
   //IF !Empty(cPicture) .OR. cPicture == NIL .AND. nMaxLength != NIL .OR. !Empty(nMaxLength)
   //   ::nMaxLength := nMaxLength
   //ENDIF
   ::ParsePict(cPicture, vari)
  // ::SetText(vari)

   ::Activate()

   ::DisableBackColor := s_bDisablecolor
   // defines the number of characters based on the size of control
   IF Empty(::nMaxLength) .AND. ::cType == "C" .AND. Empty(cPicture) .AND. hwg_BitAnd(nStyle, ES_AUTOHSCROLL) == 0
       nWidth := (TxtRect(" ", Self))[1]
       ::nMaxLength := INT((::nWidth - nWidth) / nWidth) - 1
       ::nMaxLength := IIf(::nMaxLength < 10, 10, ::nMaxLength)
   ENDIF

   IF ::bSetGet != NIL
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::lnoValid := IIf(bGfocus != NIL, .T., .F.)
      ::oParent:AddEvent(EN_SETFOCUS, Self, {||::When()},, "onGotFocus")
      ::oParent:AddEvent(EN_KILLFOCUS, Self, {||::Valid()},, "onLostFocus")
      ::bValid := {||::Valid()}
   ELSE
      IF bGfocus != NIL
         ::oParent:AddEvent(EN_SETFOCUS, Self, {||::When()},, "onGotFocus")
      ENDIF
      //IF bLfocus != NIL
         ::oParent:AddEvent(EN_KILLFOCUS, Self, {||::Valid()},, "onLostFocus")
         ::bValid := {||::Valid()}
      //ENDIF
   ENDIF

   ::bColorOld := ::bcolor
   ::tColorOld := IIf(tcolor == NIL, 0, ::tcolor)

   IF ::cType != "D"
      SET(_SET_INSERT, !::lPicComplex)
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HEdit

   IF !Empty(::oParent:handle)
      ::handle := CreateEdit(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title)
      ::Init()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Init() CLASS HEdit

   IF !::lInit
      ::Super:Init()
      ::nHolder := 1
      hwg_SetWindowObject(::handle, Self)
      hwg_InitEditProc(::handle)
      ::Refresh()
      //IF ::bChange != NIL .OR. ::lMultiLine
         ::oParent:AddEvent(EN_CHANGE, Self, {||::onChange()},, "onChange")
      //ENDIF

   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD onEvent(msg, wParam, lParam) CLASS HEdit

   LOCAL oParent := ::oParent
   LOCAL nPos
   LOCAL nextHandle
   LOCAL nShiftAltCtrl
   LOCAL lRes
   LOCAL cClipboardText

   IF hb_IsBlock(::bOther)
      IF Eval(::bOther, Self, msg, wParam, lParam) != -1
         RETURN 0
      ENDIF
   ENDIF

   // hwg_WriteLog(Str(MSG) + ::TITLE + Chr(13))

   IF !::lMultiLine

      IF ::bSetGet != NIL
         IF msg == WM_COPY .OR. msg == WM_CUT
            ::lcopy := .T.
            RETURN -1
         ELSEIF ::lCopy .AND. (msg == WM_MOUSELEAVE .OR. (msg == WM_KEYUP .AND. (wParam == VK_C .OR. wParam == VK_X)))
            ::lcopy := .F.
            COPYSTRINGTOCLIPBOARD(::UnTransform(GETCLIPBOARDTEXT()))
            RETURN -1
         ELSEIF msg == WM_PASTE .AND. !::lNoPaste
              ::lFirst := IIf(::cType == "N" .AND. "E" $ ::cPicFunc, .T., .F.)
            cClipboardText := GETCLIPBOARDTEXT()
            IF !Empty(cClipboardText)
               nPos := hwg_HIWORD(hwg_SendMessage(::handle, EM_GETSEL, 0, 0)) + 1
               hwg_SendMessage(::handle, EM_SETSEL, nPos - 1, nPos - 1)
               FOR nPos := 1 to Len(cClipboardText)
                  ::GetApplyKey(SubStr(cClipboardText, nPos, 1))
               NEXT
               nPos := hwg_HIWORD(hwg_SendMessage(::handle, EM_GETSEL, 0, 0)) + 1
               ::title := ::UnTransform(hwg_GetEditText(::oParent:handle, ::id))
               hwg_SendMessage(::handle, EM_SETSEL, nPos - 1, nPos - 1)
              ENDIF
            RETURN 0
         ELSEIF msg == WM_CHAR
            IF !CheckBit(lParam, 32) .AND. hb_IsBlock(::bKeyDown)
               nShiftAltCtrl := IIf(IsCtrlShift(.F., .T.), 1, 0)
               nShiftAltCtrl += IIf(IsCtrlShift(.T., .F.), 2, nShiftAltCtrl)
               nShiftAltCtrl += IIf(Checkbit(lParam, 28), 4, nShiftAltCtrl)
               ::oparent:lSuspendMsgsHandling := .T.
               lRes := Eval(::bKeyDown, Self, wParam, nShiftAltCtrl)
               ::oparent:lSuspendMsgsHandling := .F.
               IF Empty(lRes)
                  RETURN 0
               ENDIF
            ENDIF
            IF wParam == VK_BACK
               ::lFirst := .F.
               ::lFocu := .F.
               ::SetGetUpdated()
               ::DeleteChar(.T.)
               RETURN 0
            ELSEIF wParam == VK_RETURN
               IF !ProcOkCancel(Self, wParam, ::GetParentForm():Type >= WND_DLG_RESOURCE) .AND. ;
                       (::GetParentForm():Type < WND_DLG_RESOURCE .OR. ;
                   !::GetParentForm():lModal)
                   GetSkip(oParent, ::handle, , 1)
                  RETURN 0
               ELSEIF ::GetParentForm():Type < WND_DLG_RESOURCE
                  RETURN 0
               ENDIF
               RETURN -1
            ELSEIF wParam == VK_TAB
               IF (::GetParentForm(Self):Type < WND_DLG_RESOURCE .OR. ;
                   !::GetParentForm(Self):lModal)
                  //- GetSkip(oParent, ::handle, , iif(IsCtrlShift(.F., .T.), -1, 1))
               ENDIF
               RETURN 0
            ELSEIF wParam == VK_ESCAPE
               oParent := ::GetParentForm()
               IF oParent:handle == ::oParent:handle .AND. oParent:lExitOnEsc .AND. ;
                                  oParent:FindControl(IDCANCEL) != NIL .AND. ;
                                !oParent:FindControl(IDCANCEL):IsEnabled()
                   hwg_SendMessage(oParent:handle, WM_COMMAND, hwg_MAKEWPARAM(IDCANCEL, 0), ::handle)
               ENDIF
                         IF (oParent:Type < WND_DLG_RESOURCE .OR. !oParent:lModal)
                   hwg_SetFocus(0)
                   ProcOkCancel(Self, VK_ESCAPE)
                   RETURN 0
               ENDIF
               RETURN 0 //-1
            ENDIF
            //
            IF ::lFocu
               IF ::cType == "N" .AND. SET(_SET_INSERT)
                  ::lFirst := .T.
               ENDIF
               IF !s_lFixedColor
                  ::SetColor(::tcolorOld, ::bColorOld)
                  ::bColor := ::bColorOld
                  ::brush := IIf(::bColorOld == NIL, NIL, ::brush)
                  hwg_SendMessage(::handle, WM_MOUSEMOVE, 0, hwg_MAKELPARAM(1, 1))
               ENDIF
               ::lFocu := .F.
            ENDIF
            //
            IF !IsCtrlShift(, .F.)
               RETURN ::GetApplyKey(Chr(wParam))
            ENDIF
         ELSEIF msg == WM_KEYDOWN
            //IF (CheckBit(lParam, 25) .OR. wParam > 111) .AND. hb_IsBlock(::bKeyDown)
            IF ((CheckBit(lParam, 25) .AND. wParam != 111) .OR. (wParam > 111 .AND. wParam < 124)) .AND. ;
               hb_IsBlock(::bKeyDown)
               nShiftAltCtrl := IIf(IsCtrlShift(.F., .T.), 1, 0)
               nShiftAltCtrl += IIf(IsCtrlShift(.T., .F.), 2, nShiftAltCtrl)
               nShiftAltCtrl += IIf(wParam > 111, 4, nShiftAltCtrl)
               ::oparent:lSuspendMsgsHandling := .T.
               lRes := Eval(::bKeyDown, Self, wParam, nShiftAltCtrl)
               ::oparent:lSuspendMsgsHandling := .F.
               IF Empty(lRes)
                  RETURN 0
               ENDIF
            ENDIF
            IF wParam == 40 .AND. ::oUpDown != NIL // KeyDown
               RETURN -1
            ELSEIF wParam == 40 //.OR. (wParam == 399 .AND. ::oUpDown != NIL)   // KeyDown
               IF !IsCtrlShift()
                  GetSkip(oParent, ::handle, , 1)
                  RETURN 0
               ENDIF
            ELSEIF wParam == 38 .AND. ::oUpDown != NIL   // KeyUp
               RETURN -1
            ELSEIF wParam == 38 //.OR. (wParam == 377 .AND. ::oUpDown != NIL)   // KeyUp
               IF !IsCtrlShift()
                  GetSkip(oParent, ::handle, , -1)
                  RETURN 0
               ENDIF
            ELSEIF wParam == 39     // KeyRight
               ::lFocu := .F.
               IF !IsCtrlShift()
                  ::lFirst := .F.
                  RETURN ::KeyRight()
               ENDIF
            ELSEIF wParam == 37     // KeyLeft
               ::lFocu := .F.
               IF !IsCtrlShift()
                  ::lFirst := .F.
                  RETURN ::KeyLeft()
               ENDIF
            ELSEIF wParam == 35     // End
               ::lFocu := .F.
               IF !IsCtrlShift()
                  ::lFirst := .F.
                  IF ::cType == "C"
                     //nPos := Len(Trim(::title))
                     nPos := Len(Trim(hwg_GetEditText(::oParent:handle, ::id)))
                     hwg_SendMessage(::handle, EM_SETSEL, nPos, nPos)
                     RETURN 0
                  ENDIF
               ENDIF
            ELSEIF wParam == 36     // HOME
               ::lFocu := .F.
               IF !IsCtrlShift()
                  hwg_SendMessage(::handle, EM_SETSEL, ::FirstEditable() - 1, ::FirstEditable() - 1)
                  RETURN 0
               ENDIF
            ELSEIF wParam == 45     // Insert
               IF !IsCtrlShift()
                  SET(_SET_INSERT, !SET(_SET_INSERT))
               ENDIF
            ELSEIF wParam == 46     // Del
               ::lFirst := .F.
               ::SetGetUpdated()
               ::DeleteChar(.F.)
               RETURN 0
            ELSEIF wParam == VK_TAB     // Tab
               GetSkip(oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
               RETURN 0
            ELSEIF wParam == VK_RETURN  // Enter
               //GetSkip(oParent, ::handle, .T., 1)
               RETURN 0
            ENDIF
            IF "K" $ ::cPicFunc .AND. ::lFocu .AND. !Empty(::Title)
                //- ::value := IIf(::cType == "D", CTOD(""), IIf(::cType == "N", 0, ""))
                //- hwg_SendMessage(::handle, EM_SETSEL, ::FirstEditable() - 1, ::FirstEditable() - 1)
                ::Title := IIf(::cType == "D", CTOD(""), IIf(::cType == "N", 0, ""))
            ENDIF
         ELSEIF msg == WM_LBUTTONDOWN
            IF hwg_GetFocus() != ::handle
               //hwg_SetFocus(::handle)
               //RETURN 0
            ENDIF
         ELSEIF msg == WM_LBUTTONUP
            IF Empty(hwg_GetEditText(oParent:handle, ::id))
               hwg_SendMessage(::handle, EM_SETSEL, 0, 0)
            ENDIF
         ENDIF
      ELSE
         // no bsetget
         IF msg == WM_CHAR
            IF wParam == VK_TAB .OR. wParam == VK_ESCAPE .OR. wParam == VK_RETURN
               RETURN 0
            ENDIF
            RETURN -1
         ELSEIF msg == WM_KEYDOWN
            IF wParam == VK_TAB .AND. ::GetParentForm():Type >= WND_DLG_RESOURCE    // Tab
               nexthandle := GetNextDlgTabItem (hwg_GetActiveWindow(), hwg_GetFocus(), ;
                                                 IsCtrlShift(.F., .T.))
               //hwg_SetFocus(nexthandle)
               hwg_PostMessage(hwg_GetActiveWindow(), WM_NEXTDLGCTL, nextHandle, 1)
               RETURN 0
            ELSEIF (wParam == VK_RETURN .OR. wParam == VK_ESCAPE) .AND. ProcOkCancel(Self, wParam, ::GetParentForm():Type >= WND_DLG_RESOURCE)
               RETURN -1
            ELSEIF (wParam == VK_RETURN .OR. wParam == VK_TAB) .AND. ::GetParentForm():Type < WND_DLG_RESOURCE
               GetSkip(oParent, ::handle, , 1)

               RETURN 0
            ENDIF
         ENDIF
      ENDIF
      IF s_lColorinFocus
         IF msg == WM_SETFOCUS
//            ::bColorOld := ::bcolor
            ::nSelStart := IIf(Empty(::title), 0, ::nSelStart)
            ::SetColor(s_tColorSelect, s_bColorSelect)
            hwg_SendMessage(::handle, EM_SETSEL, ::selStart, ::selStart) // era -1
            //-::SetColor(s_tcolorselect, s_bcolorselect, .T.)
         ELSEIF msg == WM_KILLFOCUS .AND. !s_lPersistColorSelect
            ::SetColor(::tcolorOld, ::bColorOld, .T.)
            ::bColor := ::bColorOld
            ::brush := IIf(::bColorOld == NIL, NIL, ::brush)
            hwg_SendMessage(::handle, WM_MOUSEMOVE, 0, hwg_MAKELPARAM(1, 1))
         ENDIF
      ENDIF
      IF msg == WM_SETFOCUS //.AND. ::cType == "N"
         ::lFocu := .T.
         ::lnoValid := .F.
         IF "K" $ ::cPicFunc
            hwg_SendMessage(::handle, EM_SETSEL, 0, -1)
         ELSEIF ::selstart == 0 .AND. "R" $ ::cPicFunc  //.AND. ::lPicComplex
            hwg_SendMessage(::handle, EM_SETSEL, ::FirstEditable() - 1, ::FirstEditable() - 1)
         ENDIF
         //IF (::lPicComplex .OR. !Empty(::cPicMask)) .AND. ::cType != "N" .AND. !::lFirst
         IF ::lPicComplex .AND. ::cType != "N" .AND. !::lFirst
            ::Title := Transform(::Title, ::cPicFunc + " " + ::cPicMask)
         ENDIF
      ENDIF

   ELSE

     // multiline
        IF msg == WM_SETFOCUS
         //nPos := hwg_HIWORD(hwg_SendMessage(::handle, EM_GETSEL, 0, 0)) + 1
         hwg_PostMessage(::handle, EM_SETSEL, 0, 0)
      ELSEIF msg == WM_MOUSEWHEEL
         nPos := hwg_HIWORD(wParam)
         nPos := IIf(nPos > 32768, nPos - 65535, nPos)
         hwg_SendMessage(::handle, EM_SCROLL, IIf(nPos > 0, SB_LINEUP, SB_LINEDOWN), 0)
         //hwg_SendMessage(::handle, EM_SCROLL, IIf(nPos > 0, SB_LINEUP, SB_LINEDOWN), 0)
      ELSEIF msg == WM_CHAR
         IF wParam == VK_TAB
               GetSkip(oParent, ::handle, , iif(IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ELSEIF wParam == VK_ESCAPE
            RETURN 0
         ELSEIF wParam == VK_RETURN .AND. !::lWantReturn .AND. ::bSetGet != NIL
                //IF (::GetParentForm():Type < WND_DLG_RESOURCE .OR. ;
            //     !::GetParentForm():lModal)
                 GetSkip(oParent, ::handle, , 1)
                 RETURN 0
            //ENDIF
            //RETURN -1
         ENDIF
      ELSEIF msg == WM_KEYDOWN
         IF wParam == VK_TAB     // Tab
        //    GetSkip(oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
          //  RETURN 0
         ELSEIF wParam == VK_ESCAPE
            RETURN -1
         ENDIF
         IF hb_IsBlock(::bKeyDown)
             IF !Eval(::bKeyDown, Self, wParam)
                RETURN 0
             ENDIF
         ENDIF
      ENDIF
      // END multiline

   ENDIF

   //IF msg == WM_KEYDOWN
   IF (msg == WM_KEYUP .OR. msg == WM_SYSKEYUP) .AND. wParam != VK_ESCAPE     /* BETTER FOR DESIGNER */
      IF !ProcKeyList(Self, wParam)
         IF hb_IsBlock(::bKeyUp)
            IF !Eval(::bKeyUp, Self, wParam)
               RETURN -1
            ENDIF
         ENDIF
      ENDIF
      IF msg != WM_SYSKEYUP
         RETURN 0
      ENDIF
      /*
      IF wParam != 16 .AND. wParam != 17 .AND. wParam != 18
         DO WHILE oParent != NIL .AND. !__ObjHasMsg(oParent, "GETLIST")
            oParent := oParent:oParent
         ENDDO
         IF oParent != NIL .AND. !Empty(oParent:KeyList)
            nctrl := IIf(IsCtrlShift(.T., .F.), FCONTROL, IIf(IsCtrlShift(.F., .T.), FSHIFT, 0))
            IF (nPos := AScan(oParent:KeyList, {|a|a[1] == nctrl .AND. a[2] == wParam})) > 0
               Eval(oParent:KeyList[nPos, 3], Self)
            ENDIF
         ENDIF
      ENDIF
      */
   ELSEIF msg == WM_GETDLGCODE
      IF wParam == VK_ESCAPE .AND. ;          // DIALOG MODAL
              (oParent := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oParent:IsEnabled()
         RETURN DLGC_WANTMESSAGE
      ENDIF
      IF !::lMultiLine .OR. wParam == VK_ESCAPE
         IF ::bSetGet != NIL
             RETURN DLGC_WANTARROWS + DLGC_WANTTAB + DLGC_WANTCHARS
         ENDIF
      ENDIF
   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, vari, bSetGet, oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, tcolor, ;
   bcolor, cPicture, nMaxLength, lMultiLine, bKeyDown, bChange) CLASS HEdit

   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, ctooltip, tcolor, ;
      IIf(bcolor == NIL, GetSysColor(COLOR_BTNHIGHLIGHT), bcolor))
   ::bKeyDown := bKeyDown
   IF hb_IsLogical(lMultiLine)
      ::lMultiLine := lMultiLine
   ENDIF

   IF vari != NIL
      ::cType := ValType(vari)
   ENDIF
   ::bSetGet := bSetGet

   IF !Empty(cPicture) .OR. cPicture == NIL .AND. nMaxLength != NIL .OR. !Empty(nMaxLength)
      ::nMaxLength := nMaxLength
   ENDIF

   ::ParsePict(cPicture, vari)

   IF bSetGet != NIL
      ::bGetFocus := bGfocus
      ::bLostFocus := bLfocus
      ::lnoValid := IIf(bGfocus != NIL, .T., .F.)
      ::oParent:AddEvent(EN_SETFOCUS, Self, {||::When()},, "onGotFocus")
      ::oParent:AddEvent(EN_KILLFOCUS, Self, {||::Valid()},, "onLostFocus")
      ::bValid := {||::Valid()}
   ELSE
      IF bGfocus != NIL
         ::oParent:AddEvent(EN_SETFOCUS, Self, bGfocus,, "onGotFocus")
      ENDIF
      IF bLfocus != NIL
         ::oParent:AddEvent(EN_KILLFOCUS, Self, bLfocus,, "onLostFocus")
      ENDIF
   ENDIF
   IF bChange != NIL
      ::oParent:AddEvent(EN_CHANGE, Self, bChange,, "onChange")
   ENDIF
   ::bColorOld := ::bcolor

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Value(Value) CLASS HEdit

   LOCAL vari

   IF Value != NIL
       ::SetText(Value)
       ::Refresh()
   ENDIF
   //vari := ::UnTransform(::Title)
   vari := ::UnTransform(hwg_GetEditText(::oParent:handle, ::id))

   IF ::cType == "D"
      vari := CToD(vari)
   ELSEIF ::cType == "N"
      vari := Val(LTrim(vari))
   ENDIF

RETURN vari

//-------------------------------------------------------------------------------------------------------------------//

METHOD Refresh() CLASS HEdit
   
   LOCAL vari
   
   IF hb_IsBlock(::bSetGet)
      vari := Eval(::bSetGet, , Self)
      IF !Empty(::cPicFunc) .OR. !Empty(::cPicMask)
         vari := IIf(vari == NIL, "", Vari)
         vari := Transform(vari, ::cPicFunc + IIf(Empty(::cPicFunc), "", " ") + ::cPicMask)
      ELSE
         vari := IIf(::cType == "D", DToC(vari), IIf(::cType == "N", Str(vari), ;
                 IIf(::cType == "C" .AND. hb_IsChar(vari), Trim(vari), "")))
      ENDIF
      ::Title := vari
   ENDIF
   hwg_SetDlgItemText(::oParent:handle, ::id, ::title)
   IF hwg_IsWindowVisible(::handle) .AND. !Empty(GetWindowParent(::handle)) //PtrtouLong(hwg_GetFocus()) == PtrtouLong(::handle)
      hwg_RedrawWindow(::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_UPDATENOW) //+ RDW_NOCHILDREN)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetText(c) CLASS HEdit

   IF c != NIL
      IF hb_IsObject(c)
         //in run time return object
         RETURN NIL
      ENDIF
      IF !Empty(::cPicFunc) .OR. !Empty(::cPicMask)
         ::title := Transform(c, ::cPicFunc + IIf(Empty(::cPicFunc), "", " ") + ::cPicMask)
        // ::Title := Transform(::Title, ::cPicFunc + " " + ::cPicMask)
      ELSE
         ::title := c
      ENDIF
      //Super:SetText(::title)
      //hwg_SetWindowText(::handle, ::Title)
      hwg_SetDlgItemText(::oParent:handle, ::id, ::title)
      IF hb_IsBlock(::bSetGet)
         Eval(::bSetGet, c, Self)
      ENDIF
   ENDIF
   //::REFRESH()

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION IsCtrlShift(lCtrl, lShift)
   
   LOCAL cKeyb := GetKeyboardState()

   IF lCtrl == NIL
      lCtrl := .T.
   ENDIF
   IF lShift == NIL
      lShift := .T.
   ENDIF

RETURN (lCtrl .AND. (Asc(SubStr(cKeyb, VK_CONTROL + 1, 1)) >= 128)) .OR. ;
   (lShift .AND. (Asc(SubStr(cKeyb, VK_SHIFT + 1, 1)) >= 128))

//-------------------------------------------------------------------------------------------------------------------//

METHOD ParsePict(cPicture, vari) CLASS HEdit
   
   LOCAL nAt
   LOCAL i
   LOCAL masklen
   LOCAL cChar

   ::cPicture := cPicture
   ::cPicFunc := ::cPicMask := ""
   IF ::bSetGet == NIL
      RETURN NIL
   ENDIF

   IF cPicture != NIL
      IF Left(cPicture, 1) == "@"
         nAt := At(" ", cPicture)
         IF nAt == 0
            ::cPicFunc := Upper(cPicture)
            ::cPicMask := ""
         ELSE
            ::cPicFunc := Upper(SubStr(cPicture, 1, nAt - 1))
            ::cPicMask := SubStr(cPicture, nAt + 1)
         ENDIF
         IF ::cPicFunc == "@"
            ::cPicFunc := ""
         ENDIF
      ELSE
         ::cPicFunc := ""
         ::cPicMask := cPicture
      ENDIF
   ENDIF

   IF Empty(::cPicMask)
      IF ::cType == "D"
         ::cPicFunc := "@D" + IIf("K" $ ::cPicFunc, "K", "")
         ::cPicMask := StrTran(DToC(CToD(Space(8))), " ", "9")
      ELSEIF ::cType == "N"
         vari := Str(vari)
         IF (nAt := At(".", vari)) > 0
            ::cPicMask := Replicate("9", nAt - 1) + "." + ;
                          Replicate("9", Len(vari) - nAt)
         ELSE
            ::cPicMask := Replicate("9", Len(vari))
         ENDIF
      ENDIF
   ENDIF

   IF !Empty(::cPicMask)
      ::nMaxLength := NIL
      masklen := Len(::cPicMask)
      FOR i := 1 TO masklen
         cChar := SubStr(::cPicMask, i, 1)
         IF !(cChar $ "!ANX9#")
            ::lPicComplex := .T.
            EXIT
         ENDIF
      NEXT
   ENDIF
   IF Eval(::bSetGet, , Self) != NIL
      ::title := Transform(Eval(::bSetGet, , Self), ::cPicFunc + IIf(Empty(::cPicFunc), "", " ") + ::cPicMask)
      hwg_SetDlgItemText(::oParent:handle, ::id, ::title)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD IsEditable(nPos, lDel) CLASS HEdit
   
   LOCAL cChar

   IF Empty(::cPicMask)
      RETURN .T.
   ENDIF
   IF nPos > Len(::cPicMask)
      RETURN .F.
   ENDIF

   cChar := SubStr(::cPicMask, nPos, 1)
   IF ::cType == "C"
      RETURN cChar $ "!ANX9#"
   ELSEIF ::cType == "N"       // nando add
      RETURN cChar $ "9#$*Z" + IIf(!Empty(lDel), IIf("E" $ ::cPicFunc, ",", ""), "")
   ELSEIF ::cType == "D"
      RETURN cChar == "9"
   ELSEIF ::cType == "L"
      RETURN cChar $ "TFYN"
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

METHOD KeyRight(nPos) CLASS HEdit
   
   LOCAL masklen
   LOCAL newpos

   IF nPos == NIL
      nPos := hwg_HIWORD(hwg_SendMessage(::handle, EM_GETSEL, 0, 0)) + 1
   ENDIF
   IF ::cPicMask == NIL .OR. Empty(::cPicMask)
      hwg_SendMessage(::handle, EM_SETSEL, nPos, nPos)
   ELSE
      masklen := Len(::cPicMask)
      DO WHILE nPos <= masklen
         IF ::IsEditable(++nPos)
            hwg_SendMessage(::handle, EM_SETSEL, nPos - 1, nPos - 1)
            EXIT
         ENDIF
      ENDDO
   ENDIF

   //Added By Sandro Freire

   IF !Empty(::cPicMask)
      newpos := Len(::cPicMask)
      // hwg_WriteLog("KeyRight-2 " + Str(nPos) + " " + Str(newPos))
      IF nPos > newpos .AND. !Empty(Trim(::Title))
         hwg_SendMessage(::handle, EM_SETSEL, newpos, newpos)
      ENDIF
   ENDIF
   IF ::oUpDown != NIL .AND. nPos > newPos
      GetSkip(::oParent, ::handle, , 1)
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

METHOD KeyLeft(nPos) CLASS HEdit

   IF nPos == NIL
      nPos := hwg_HIWORD(hwg_SendMessage(::handle, EM_GETSEL, 0, 0)) + 1
   ENDIF
   IF ::cPicMask == NIL .OR. Empty(::cPicMask)
      hwg_SendMessage(::handle, EM_SETSEL, nPos - 2, nPos - 2)
   ELSE
      DO WHILE nPos >= 1
         IF ::IsEditable(--nPos)
            hwg_SendMessage(::handle, EM_SETSEL, nPos - 1, nPos - 1)
            EXIT
         ENDIF
      ENDDO
   ENDIF
   //IF ::oUpDown != NIL .AND. nPos <= 0
   IF nPos <= 1
      GetSkip(::oParent, ::handle, , -1)
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

METHOD DeleteChar(lBack) CLASS HEdit
   
   LOCAL nSel := hwg_SendMessage(::handle, EM_GETSEL, 0, 0)
   LOCAL nPosEnd := hwg_HIWORD(nSel)
   LOCAL nPosStart := hwg_LOWORD(nSel)
   LOCAL nGetLen := Len(::cPicMask)
   LOCAL cBuf
   LOCAL nPosEdit

   IF hwg_BitAnd(GetWindowLong(::handle, GWL_STYLE), ES_READONLY) != 0
      RETURN NIL
   ENDIF
   IF nGetLen == 0
      nGetLen := Len(::title)
   ENDIF
   IF nPosEnd == nPosStart
      nPosEnd += IIf(lBack, 1, 2)
      nPosStart -= IIf(lBack, 1, 0)
   ELSE
      nPosEnd += 1
   ENDIF
  // hwg_MsgInfo(Str(NPOSEND) + Str(NPOSSTART) + ::TITLE)
   /* NEW */
   IF nPosEnd - nPosStart - 1 > 1 .AND. ::lPicComplex .AND. ::cType != "N" //.AND. NPOSEND < nGetLen
      lBack := .T.
   ELSE
      IF lBack .AND. !::IsEditable(nPosStart + 1, .T.) //.AND. ::cType != "N"
          nPosStart -= IIf(::cType != "N", 1, 0)
          IF nPosStart < 0
             hwg_SendMessage(::handle, EM_SETSEL, ::FirstEditable() - 1, ::FirstEditable() - 1)
             RETURN NIL
          ENDIF
      ENDIF
      IF ::lPicComplex .AND. ::cType != "N" .AND. ::FirstNotEditable(nPosStart) > 0 .AND. ;
               (!lBack .OR. (lBack .AND. nPosEnd - nPosStart - 1 < 2))
         nPosEdit := ::FirstNotEditable(nPosStart)
         nGetLen := Len(Trim(Left(::title, nPosEdit - 1)))
         cBuf := ::Title
         IF nGetLen >= nPosStart + 1
            cBuf := Stuff(::title, nPosStart + 1, 1, "")
            cBuf := Stuff(cBuf, nGetLen, 0, " ")
         ENDIF
      ELSE
         IF Empty(hwg_SendMessage(::handle, EM_GETPASSWORDCHAR, 0, 0))
            cBuf := PadR(Left(::title, nPosStart) + SubStr(::title, nPosEnd), nGetLen, IIf(::lPicComplex, , Chr(0)))
         ELSE
            cBuf := Left(::title, nPosStart) + SubStr(::title, nPosEnd)
         ENDIF
      ENDIF
   ENDIF
   /*
   IF Empty(hwg_SendMessage(::handle, EM_GETPASSWORDCHAR, 0, 0))
      cBuf := PadR(Left(::title, nPosStart) + SubStr(::title, nPosEnd), nGetLen)
   ELSE
      cBuf := Left(::title, nPosStart) + SubStr(::title, nPosEnd)
   ENDIF
   IF ::lPicComplex .AND. ::cType != "N" .AND. ;
   */
   IF lBack .AND. ::lPicComplex .AND. ::cType != "N" .AND. (nPosStart + nPosEnd > 0)
      IF lBack .OR. nPosStart != (nPosEnd - 2)
         IF nPosStart != (nPosEnd - 2)
            cBuf := Left(::title, nPosStart) + Space(nPosEnd - nPosStart - 1) + SubStr(::title, nPosEnd)
         ENDIF
      ELSE
         nPosEdit := ::FirstNotEditable(nPosStart + 1)
         IF nPosEdit > 0
            cBuf := Left(::title, nPosStart) + IF(::IsEditable(nPosStart + 2), SubStr(::title, nPosStart + 2, 1) + "  ", "  ") + SubStr(::title, nPosEdit + 1)
         ELSE
            cBuf := Left(::title, nPosStart) + SubStr(::title, nPosStart + 2) + Space(nPosEnd - nPosStart - 1)
         ENDIF
      ENDIF
      cBuf := Transform(cBuf, ::cPicMask)
   ELSEIF ::cType == "N" .AND. Len(AllTrim(cBuf)) == 0
      ::lFirst := .T.
      nPosStart := ::FirstEditable() - 1
   ELSEIF ::cType == "N" .AND. ::lPicComplex .AND. !lBack .AND. ;
        Right(Trim(::title), 1) != "."
      IF "E" $ ::cPicFunc
         cBuf := Trim(Strtran(cBuf, ".", ""))
         cBuf := Strtran(cBuf, ",", ".")
      ELSE
         cBuf := Trim(Strtran(cBuf, ",", ""))
      ENDIF
      cBuf := Val(LTrim(cBuf))
      cBuf := Transform(cBuf, ::cPicFunc + IIf(Empty(::cPicFunc), "", " ") + ::cPicMask)
   ENDIF
   ::title := cBuf
   hwg_SetDlgItemText(::oParent:handle, ::id, ::title)
   hwg_SendMessage(::handle, EM_SETSEL, nPosStart, nPosStart)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD Input(cChar, nPos) CLASS HEdit

   LOCAL cPic

   IF !Empty(::cPicMask) .AND. nPos > Len(::cPicMask)
      RETURN NIL
   ENDIF
   IF ::cType == "N"
      IF cChar == "-"
         IF nPos != 1
            RETURN NIL
         ENDIF
         ::lFirst := .F.
      ELSEIF !(cChar $ "0123456789")
         RETURN NIL
      ENDIF

   ELSEIF ::cType == "D"

      IF !(cChar $ "0123456789")
         RETURN NIL
      ENDIF

   ELSEIF ::cType == "L"

      IF !(Upper(cChar) $ "YNTF")
         RETURN NIL
      ENDIF

   ENDIF

   IF !Empty(::cPicFunc) .AND. !::cType == "N"
      cChar := Transform(cChar, ::cPicFunc)
   ENDIF

   IF !Empty(::cPicMask)
      cPic := SubStr(::cPicMask, nPos, 1)

      cChar := Transform(cChar, cPic)
      IF cPic == "A"
         IF !IsAlpha(cChar)
            cChar := NIL
         ENDIF
      ELSEIF cPic == "N"
         IF !IsAlpha(cChar) .AND. !IsDigit(cChar)
            cChar := NIL
         ENDIF
      ELSEIF cPic == "9"
         IF !IsDigit(cChar) .AND. cChar != "-"
            cChar := NIL
         ENDIF
      ELSEIF cPic == "#"
         IF !IsDigit(cChar) .AND. !(cChar == " ") .AND. !(cChar $ "+-")
            cChar := NIL
         ENDIF
      ELSE
         cChar := Transform(cChar, cPic)
      ENDIF
   ENDIF

RETURN cChar
#else
METHOD Input(cChar, nPos) CLASS HEdit

   LOCAL cPic

   IF !Empty(::cPicMask) .AND. nPos > Len(::cPicMask)
      RETURN NIL
   ENDIF

   SWITCH ::cType
   CASE "N"
      IF cChar == "-"
         IF nPos != 1
            RETURN NIL
         ENDIF
         ::lFirst := .F.
      ELSEIF !(cChar $ "0123456789")
         RETURN NIL
      ENDIF
      EXIT
   CASE "D"
      IF !(cChar $ "0123456789")
         RETURN NIL
      ENDIF
      EXIT
   CASE "L"
      IF !(Upper(cChar) $ "YNTF")
         RETURN NIL
      ENDIF
   ENDSWITCH

   IF !Empty(::cPicFunc) .AND. !::cType == "N"
      cChar := Transform(cChar, ::cPicFunc)
   ENDIF

   IF !Empty(::cPicMask)
      cPic := SubStr(::cPicMask, nPos, 1)
      cChar := Transform(cChar, cPic)
      SWITCH cPic
      CASE "A"
         IF !IsAlpha(cChar)
            cChar := NIL
         ENDIF
         EXIT
      CASE "N"
         IF !IsAlpha(cChar) .AND. !IsDigit(cChar)
            cChar := NIL
         ENDIF
         EXIT
      CASE "9"
         IF !IsDigit(cChar) .AND. cChar != "-"
            cChar := NIL
         ENDIF
         EXIT
      CASE "#"
         IF !IsDigit(cChar) .AND. !(cChar == " ") .AND. !(cChar $ "+-")
            cChar := NIL
         ENDIF
         EXIT
#ifdef __XHARBOUR__
      DEFAULT
#else
      OTHERWISE
#endif
         cChar := Transform(cChar, cPic)
      ENDSWITCH
   ENDIF

RETURN cChar
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetApplyKey(cKey) CLASS HEdit

   LOCAL nPos
   LOCAL nGetLen
   LOCAL nLen
   LOCAL vari
   LOCAL i
   LOCAL x
   LOCAL newPos
   LOCAL nDecimals
   LOCAL lSignal := .F.

   /* AJ: 11-03-2007 */
   IF hwg_BitAnd(GetWindowLong(::handle, GWL_STYLE), ES_READONLY) != 0
      RETURN 0
   ENDIF

   x := hwg_SendMessage(::handle, EM_GETSEL, 0, 0)
   IF hwg_HIWORD(x) != hwg_LOWORD(x)
      ::DeleteChar(.F.)
   ENDIF
   ::title := hwg_GetEditText(::oParent:handle, ::id)
   IF ::cType == "N" .AND. cKey $ ".," .AND. (nPos := At(".", ::cPicMask)) != 0
      IF ::lFirst
         // vari := 0
         vari := StrTran(Trim(::title), " ", IIf("E" $ ::cPicFunc, ",", "."))
         vari := Val(vari)
      ELSE
         vari := Trim(::title)
         lSignal := IIf(Left(vari, 1) = "-", .T., .F.)
         FOR i := 2 TO Len(vari)
            IF !IsDigit(SubStr(vari, i, 1))
               vari := Left(vari, i - 1) + SubStr(vari, i + 1)
            ENDIF
         NEXT
         IF "E" $ ::cPicFunc .AND. "," $ ::title
            vari := Strtran(::title, ".", "")
            vari := Strtran(vari, ",", ".")
            ::title := "."
         ELSE
            // nando -                               remove the .
            vari := StrTran(vari, " ", IIf("E" $ ::cPicFunc, ",", " "))
         ENDIF
         vari := Val(vari)
         lSignal := IIf(lSignal .AND. vari != 0, .F., lSignal)
      ENDIF
      //IF !Empty(::cPicFunc) .OR. !Empty(::cPicMask)
      IF (!Empty(::cPicFunc) .OR. !Empty(::cPicMask)) .AND. (!(cKey $ ",.") .OR. Right(Trim(::title), 1) = ".")
         //-::title := Transform(vari, ::cPicFunc + IIf(Empty(::cPicFunc), "", " ") + ::cPicMask)
         ::title := Transform(vari, StrTran(::cPicFunc, "Z", "") + IIf(Empty(::cPicFunc), "", " ") + ::cPicMask)
         IF lSignal
           ::title := "-" + SubStr(::title, 2)
         ENDIF
      ENDIF
      hwg_SetDlgItemText(::oParent:handle, ::id, ::title)
      ::KeyRight(nPos - 1)
   ELSE

      IF ::cType == "N" .AND. ::lFirst
         nGetLen := Len(::cPicMask)
         IF (nPos := At(".", ::cPicMask)) == 0
            ::title := Space(nGetLen)
         ELSE
            ::title := Space(nPos - 1) + "." + Space(nGetLen - nPos)
         ENDIF
         nPos := 1
      ELSE
         nPos := hwg_HIWORD(hwg_SendMessage(::handle, EM_GETSEL, 0, 0)) + 1
      ENDIF
      cKey := ::Input(cKey, nPos)
      IF cKey != NIL
         ::SetGetUpdated()
         IF SET(_SET_INSERT) .OR. hwg_HIWORD(x) != hwg_LOWORD(x)
            IF ::lPicComplex
               nGetLen := Len(::cPicMask)
               FOR nLen := 0 TO nGetLen
                  IF !::IsEditable(nPos + nLen)
                     EXIT
                  ENDIF
               NEXT
               ::title := Left(::title, nPos - 1) + cKey + SubStr(::title, nPos, nLen - 1) + SubStr(::title, nPos + nLen)
            ELSE
               ::title := Left(::title, nPos - 1) + cKey + SubStr(::title, nPos)
            ENDIF

            //IF !Empty(::cPicMask) .AND. Len(::cPicMask) < Len(::title)
            IF (!Empty(::cPicFunc) .OR. !Empty(::cPicMask)) .AND. ;
                  (!(cKey $ ",.") .OR. Right(Trim(::title), 1) = ".")
               ::title := Left(::title, nPos - 1) + cKey + SubStr(::title, nPos + 1)
            ENDIF
         ELSE
            ::title := Left(::title, nPos - 1) + cKey + SubStr(::title, nPos + 1)
         ENDIF
         IF !Empty(hwg_SendMessage(::handle, EM_GETPASSWORDCHAR, 0, 0))
            ::title := Left(::title, nPos - 1) + cKey + Trim(SubStr(::title, nPos + 1))
            IF !Empty(::nMaxLength) .AND. Len(Trim(::GetText())) = ::nMaxLength
                  ::title := PadR(::title, ::nMaxLength)
            ENDIF
            nLen := Len(Trim(::GetText()))
         ELSEIF !Empty(::nMaxLength)
            nLen := Len(Trim(::GetText()))
            ::title := PadR(::title, ::nMaxLength)
         ELSEIF !Empty(::cPicMask) .AND. !"@" $ ::cPicMask
            ::title := PadR(::title, Len(::cPicMask))
         ENDIF
         hwg_SetDlgItemText(::oParent:handle, ::id, ::title)
         ::KeyRight(nPos)
         //Added By Sandro Freire
         IF ::cType == "N"
            IF !Empty(::cPicMask)
               nDecimals := Len(SubStr(::cPicMask, At(".", ::cPicMask), Len(::cPicMask)))

               IF nDecimals <= 0
                  nDecimals := 3
               ENDIF
               newPos := Len(::cPicMask) - nDecimals

               IF "E" $ ::cPicFunc .AND. nPos == newPos
                  ::GetApplyKey(",")
               ENDIF
            ENDIF
         ELSEIF !SET(_SET_CONFIRM)
             IF (::cType != "D" .AND. !"@"$::cPicFunc .AND. Empty(::cPicMask) .AND. !Empty(::nMaxLength) .AND. nLen >= ::nMaxLength-1) .OR. ;
                    (!Empty(::nMaxLength) .AND. nPos = ::nMaxLength) .OR. nPos == Len(::cPicMask)
                 GetSkip(::oParent, ::handle, , 1)
             ENDIF
         ENDIF
      ENDIF
   ENDIF
   ::lFirst := .F.

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

METHOD ReadOnly(lreadOnly)

   IF lreadOnly != NIL
      IF !Empty(hwg_SendMessage(::handle, EM_SETREADONLY, IIf(lReadOnly, 1, 0), 0))
          ::lReadOnly := lReadOnly
      ENDIF
   ENDIF

RETURN ::lReadOnly

//-------------------------------------------------------------------------------------------------------------------//

METHOD SelStart(Start) CLASS HEdit
   
   LOCAL nPos

   IF Start != NIL
      ::nSelStart := start
      ::nSelLength := 0
      hwg_SendMessage(::handle, EM_SETSEL, start, start)
   ELSEIF ::nSelLength == 0
      nPos := hwg_HIWORD(hwg_SendMessage(::handle, EM_GETSEL, 0, 0))
      ::nSelStart := nPos
   ENDIF

RETURN ::nSelStart

//-------------------------------------------------------------------------------------------------------------------//

METHOD SelLength(Length) CLASS HEdit

   IF Length != NIL
      hwg_SendMessage(::handle, EM_SETSEL, ::nSelStart, ::nSelStart + Length)
      ::nSelLength := Length
   ENDIF

RETURN ::nSelLength

//-------------------------------------------------------------------------------------------------------------------//

METHOD SelText(cText) CLASS HEdit

   IF cText != NIL
      hwg_SendMessage(::handle, EM_SETSEL, ::nSelStart, ::nSelStart + ::nSelLength)
      hwg_SendMessage(::handle, WM_CUT, 0, 0)
      COPYSTRINGTOCLIPBOARD(cText)
      hwg_SendMessage(::handle, EM_SETSEL, ::nSelStart, ::nSelStart)
      hwg_SendMessage(::handle, WM_PASTE, 0, 0)
      ::nSelLength := 0
      ::cSelText := cText
   ELSE
      ::cSelText := SubStr(::title, ::nSelStart + 1, ::nSelLength)
   ENDIF

RETURN ::cSelText

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetCueBanner(cText, lShowFoco) CLASS HEdit
#DEFINE EM_SETCUEBANNER 0x1501

   LOCAL lRet := .F.

   IF !::lMultiLine
      lRet := hwg_SendMessage(::handle, EM_SETCUEBANNER, IIf(Empty(lShowFoco), 0, 1), ANSITOUNICODE(cText))
   ENDIF

RETURN lRet

//-------------------------------------------------------------------------------------------------------------------//

METHOD When() CLASS HEdit

   LOCAL res := .T.
   LOCAL nSkip
   LOCAL vari

   IF !CheckFocus(Self, .F.)
      RETURN .F.
   ENDIF

   ::lFirst := .T.
   nSkip := IIf(GetKeyState(VK_UP) < 0 .OR. (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0), -1, 1)
   IF hb_IsBlock(::bGetFocus)
      ::lnoValid := .T.
      IF ::cType == "D"
         vari := CToD(::title)
      ELSEIF ::cType == "N"
         vari := Val(LTrim(::title))
      ELSE
        vari := ::title
      ENDIF
      ::oParent:lSuspendMsgsHandling := .T.
      res := Eval(::bGetFocus, vari, IIf(::oUpDown == NIL, Self, ::oUpDown))
      res := IIf(hb_IsLogical(res), res, .T.)
      ::lnoValid := !res
      ::oParent:lSuspendMsgsHandling := .F.
      IF !res
         /*
         oParent := ParentGetDialog(Self)
         IF Self == ATail(oParent:GetList)
            nSkip := -1
         ELSEIF Self == oParent:getList[1]
            nSkip := 1
         ENDIF
         */
         WhenSetFocus(Self, nSkip)
      ELSE
         ::SetFocus()
      ENDIF
   ENDIF

RETURN res

//-------------------------------------------------------------------------------------------------------------------//

METHOD Valid() CLASS HEdit

   LOCAL res := .T.
   LOCAL vari
   LOCAL oDlg

   //IF ::bLostFocus != NIL .AND. (::lNoValid .OR. !CheckFocus(Self, .T.))
   IF (!CheckFocus(Self, .T.) .OR. ::lNoValid) .AND. ::bLostFocus != NIL
      RETURN .T.
   ENDIF
   IF hb_IsBlock(::bSetGet)
      IF (oDlg := ParentGetDialog(Self)) == NIL .OR. oDlg:nLastKey != 27
         vari := ::UnTransform(hwg_GetEditText(::oParent:handle, ::id))
         ::title := vari
         IF ::cType == "D"
            IF ::IsBadDate(vari)
               hwg_SetFocus(0)
               ::SetFocus(.T.)
               hwg_MsgBeep()
               hwg_SendMessage(::handle, EM_SETSEL, 0, 0)
               RETURN .F.
            ENDIF
            vari := CToD(vari)
            IF __SetCentury() .AND. Len(Trim (::title)) < 10
               ::title := DTOC(vari)
               hwg_SetDlgItemText(::oParent:handle, ::id, ::title)
            ENDIF
         ELSEIF ::cType == "N"
            vari := Val(LTrim(vari))
            ::title := Transform(vari, ::cPicFunc + IIf(Empty(::cPicFunc), "", " ") + ::cPicMask)
            hwg_SetDlgItemText(::oParent:handle, ::id, ::title)
         ELSEIF ::lMultiLine
              vari := ::GetText()
              ::title := vari
         ENDIF
         Eval(::bSetGet, vari, Self)
         IF oDlg != NIL
            oDlg:nLastKey := 27
         ENDIF
         IF ::bLostFocus != NIL .OR. ::oUpDown != NIL
            ::oparent:lSuspendMsgsHandling := .T.
            IF ::oUpDown != NIL // updown control
               ::oUpDown:nValue := vari
            ENDIF
            IF hb_IsBlock(::bLostFocus)
               res := Eval(::bLostFocus, vari, IIf(::oUpDown == NIL, Self, ::oUpDown))
               res := IIf(hb_IsLogical(res), res, .T.)
            ENDIF
            IF res .AND. ::oUpDown != NIL // updown control
               //::oUpDown:nValue := vari
               res := ::oUpDown:Valid()
            ENDIF
            IF hb_IsLogical(res) .AND. !res
               IF oDlg != NIL
                  oDlg:nLastKey := 0
               ENDIF
               ::SetFocus(.T.)
               ::oparent:lSuspendMsgsHandling := .F.
               RETURN .F.
            ENDIF
            IF Empty(hwg_GetFocus())
               GetSkip(::oParent, ::handle, , ::nGetSkip)
            ENDIF
         ENDIF
         IF oDlg != NIL
            oDlg:nLastKey := 0
         ENDIF
      ENDIF
   ELSE
     IF ::lMultiLine
        ::title := ::GetText()
     ENDIF
     IF ::bLostFocus != NIL .OR. ::oUpDown != NIL
        ::oparent:lSuspendMsgsHandling := .T.
        IF hb_IsBlock(::bLostFocus)
           res := Eval(::bLostFocus, vari, Self)
           res := IIf(hb_IsLogical(res), res, .T.)
        ENDIF
        IF res .AND. ::oUpDown != NIL // updown control
           res := ::oUpDown:Valid()
        ENDIF
        IF !res
           ::SetFocus()
           ::oparent:lSuspendMsgsHandling := .F.
           RETURN .F.
        ENDIF
        IF Empty(hwg_GetFocus())
           GetSkip(::oParent, ::handle, , ::nGetSkip)
        ENDIF
     ENDIF
   ENDIF
   ::oparent:lSuspendMsgsHandling := .F.

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

METHOD onChange(lForce) CLASS HEdit

   //-LOCAL nPos := hwg_HIWORD(hwg_SendMessage(::handle, EM_GETSEL, 0, 0)) + 1
   LOCAL vari

   IF !hwg_SelfFocus(::handle) .AND. Empty(lForce)
      RETURN NIL
   ENDIF
   IF ::cType == "N"
      vari := ::UnTransform(hwg_GetEditText(::oParent:handle, ::id), "vali")
      vari := Val(LTrim(vari))
   ELSE
      vari := ::UnTransform(hwg_GetEditText(::oParent:handle, ::id), "vali")
      // ::Title := vari  // AQUI DA PROBLEMAS NA MASCARA DO CAMPO
   ENDIF
   IF hb_IsBlock(::bSetGet)
      Eval(::bSetGet, vari, Self)
   ENDIF
   IF hb_IsBlock(::bChange)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bChange, vari, Self)
      ::oparent:lSuspendMsgsHandling := .F.
    ENDIF
   //hwg_SendMessage(::handle, EM_SETSEL, 0, nPos)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Untransform(cBuffer) CLASS HEdit

   LOCAL xValue
   LOCAL cChar
   LOCAL nFor
   LOCAL minus

   IF ::cType == "C"

      IF "R" $ ::cPicFunc
         FOR nFor := 1 TO Len(::cPicMask)
            cChar := SubStr(::cPicMask, nFor, 1)
            IF !(cChar $ "ANX9#!")
               cBuffer := SubStr(cBuffer, 1, nFor - 1) + Chr(1) + SubStr(cBuffer, nFor + 1)
            ENDIF
         NEXT
         cBuffer := StrTran(cBuffer, Chr(1), "")
      ENDIF

      xValue := cBuffer

   ELSEIF ::cType == "N"
      minus := (Left(LTrim(cBuffer), 1) == "-")
      cBuffer := Space(::FirstEditable() - 1) + SubStr(cBuffer, ::FirstEditable(), ::LastEditable() - ::FirstEditable() + 1)

      IF "D" $ ::cPicFunc
         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF !::IsEditable(nFor)
               cBuffer := Left(cBuffer, nFor - 1) + Chr(1) + SubStr(cBuffer, nFor + 1)
            ENDIF
         NEXT
      ELSE
         IF "E" $ ::cPicFunc
            cBuffer := Left(cBuffer, ::FirstEditable() - 1) +           ;
                       StrTran(SubStr(cBuffer, ::FirstEditable(),      ;
                                        ::LastEditable() - ::FirstEditable() + 1), ;
                                ".", " ") + SubStr(cBuffer, ::LastEditable() + 1)
            cBuffer := Left(cBuffer, ::FirstEditable() - 1) +           ;
                       StrTran(SubStr(cBuffer, ::FirstEditable(),      ;
                                        ::LastEditable() - ::FirstEditable() + 1), ;
                                ",", ".") + SubStr(cBuffer, ::LastEditable() + 1)
         ELSE
            cBuffer := Left(cBuffer, ::FirstEditable() - 1) +        ;
                       StrTran(SubStr(cBuffer, ::FirstEditable(),   ;
                                        ::LastEditable() - ::FirstEditable() + 1), ;
                                ",", " ") + SubStr(cBuffer, ::LastEditable() + 1)
         ENDIF

         FOR nFor := ::FirstEditable() TO ::LastEditable()
            IF !::IsEditable(nFor) .AND. SubStr(cBuffer, nFor, 1) != "."
               cBuffer := Left(cBuffer, nFor - 1) + Chr(1) + SubStr(cBuffer, nFor + 1)
            ENDIF
         NEXT
      ENDIF

      cBuffer := StrTran(cBuffer, Chr(1), "")

      cBuffer := StrTran(cBuffer, "$", " ")
      cBuffer := StrTran(cBuffer, "*", " ")
      cBuffer := StrTran(cBuffer, "-", " ")
      cBuffer := StrTran(cBuffer, "(", " ")
      cBuffer := StrTran(cBuffer, ")", " ")

      cBuffer := PadL(StrTran(cBuffer, " ", ""), Len(cBuffer))

      IF minus
         FOR nFor := 1 TO Len(cBuffer)
            IF IsDigit(SubStr(cBuffer, nFor, 1))
               EXIT
            ENDIF
         NEXT
         nFor--
         IF nFor > 0
            cBuffer := Left(cBuffer, nFor - 1) + "-" + SubStr(cBuffer, nFor + 1)
         ELSE
            cBuffer := "-" + cBuffer
         ENDIF
      ENDIF

      xValue := cBuffer

   ELSEIF ::cType == "L"

      cBuffer := Upper(cBuffer)
      xValue := "T" $ cBuffer .OR. "Y" $ cBuffer .OR. hb_langmessage(HB_LANG_ITEM_BASE_TEXT + 1) $ cBuffer

   ELSEIF ::cType == "D"

      IF "E" $ ::cPicFunc
         cBuffer := SubStr(cBuffer, 4, 3) + SubStr(cBuffer, 1, 3) + SubStr(cBuffer, 7)
      ENDIF
      xValue := cBuffer

   ENDIF

RETURN xValue

//-------------------------------------------------------------------------------------------------------------------//

METHOD FirstEditable() CLASS HEdit
   
   LOCAL nFor
   LOCAL nMaxLen := Len(::cPicMask)

   IF ::IsEditable(1)
      RETURN 1
   ENDIF

   FOR nFor := 2 TO nMaxLen
      IF ::IsEditable(nFor)
         RETURN nFor
      ENDIF
   NEXT

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

METHOD FirstNotEditable(nPos) CLASS HEdit
   
   LOCAL nFor
   LOCAL nMaxLen := Len(::cPicMask)

   FOR nFor := ++nPos TO nMaxLen
      IF !::IsEditable(nFor)
         RETURN nFor
      ENDIF
   NEXT

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

METHOD LastEditable() CLASS HEdit
   
   LOCAL nFor
   LOCAL nMaxLen := Len(::cPicMask)

   FOR nFor := nMaxLen TO 1 STEP - 1
      IF ::IsEditable(nFor)
         RETURN nFor
      ENDIF
   NEXT

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

METHOD IsBadDate(cBuffer) CLASS HEdit
   
   LOCAL i
   LOCAL nLen

   IF !Empty(CToD(cBuffer))
      RETURN .F.
   ENDIF
   nLen := Len(cBuffer)
   FOR i := 1 TO nLen
      IF IsDigit(SubStr(cBuffer, i, 1))
         RETURN .T.
      ENDIF
   NEXT

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetGetUpdated() CLASS HEdit

   LOCAL oParent

   ::lChanged := .T.
   IF (oParent := ParentGetDialog(Self)) != NIL
      oParent:lUpdated := .T.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

/*
FUNCTION CreateGetList(oDlg)
   
   LOCAL i
   LOCAL j
   LOCAL aLen1 := Len(oDlg:aControls)
   LOCAL aLen2

   FOR i := 1 TO aLen1
      IF __ObjHasMsg(oDlg:aControls[i], "BSETGET") .AND. oDlg:aControls[i]:bSetGet != NIL
         AAdd(oDlg:GetList, oDlg:aControls[i])
      ELSEIF !Empty(oDlg:aControls[i]:aControls)
         aLen2 := Len(oDlg:aControls[i]:aControls)
         FOR j := 1 TO aLen2
            IF __ObjHasMsg(oDlg:aControls[i]:aControls[j], "BSETGET") .AND. oDlg:aControls[i]:aControls[j]:bSetGet != NIL
               AAdd(oDlg:GetList, oDlg:aControls[i]:aControls[j])
            ENDIF
         NEXT
      ENDIF
   NEXT

RETURN NIL
*/

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION CreateGetList(oDlg, oCnt)
   
   LOCAL i
   LOCAL oCtrl
   LOCAL aLen1

   IF oCnt == NIL
     aLen1 := Len(oDlg:aControls)
     oCtrl := oDlg
   ELSE
     aLen1 := Len(oCnt:aControls)
     oCtrl := oCnt
   ENDIF
   FOR i := 1 TO aLen1
      IF Len(oCtrl:aControls[i]:aControls) > 0
         CreateGetList(oDlg, oCtrl:aControls[i])
      ENDIF
      IF __ObjHasMsg(oCtrl:aControls[i], "BSETGET") .AND. oCtrl:aControls[i]:bSetGet != NIL
         AAdd(oDlg:GetList, oCtrl:aControls[i])
      ENDIF
   NEXT

RETURN oCtrl

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION GetSkip(oParent, hCtrl, lClipper, nSkip)
   
   LOCAL i
   LOCAL nextHandle
   LOCAL oCtrl
   LOCAL oForm := IIf((oForm := oParent:GetParentForm()) == NIL, oParent, oForm)

   DEFAULT nSkip := 1
   IF oParent == NIL .OR. (lClipper != NIL .AND. lClipper .AND. !oForm:lClipper)
      RETURN .F.
   ENDIF
   i := AScan(oParent:acontrols, {|o|PtrtouLong(o:handle) == PtrtouLong(hCtrl)})
   oCtrl := IIf(i > 0, oParent:acontrols[i], oParent)

   IF nSkip != 0
      nextHandle := IIf(oParent:className == "HTAB", NextFocusTab(oParent, hCtrl, nSkip), ;
                 IIf(oParent:className == oForm:ClassName, NextFocus(oParent, hCtrl, nSkip),;
                      NextFocuscontainer(oParent, hCtrl, nSkip)))
   //nextHandle := IIf(oParent:className == "HTAB", NextFocusTab(oParent, hCtrl, nSkip), ;
   //                   NextFocus(oParent, hCtrl, nSkip))
   ELSE
      nextHandle := hCtrl
   ENDIF

   IF i > 0
      oCtrl:nGetSkip := nSkip
      oCtrl:oParent:lGetSkipLostFocus := .T.
   ENDIF
   IF !Empty(nextHandle)
      //i := AScan(oparent:acontrols, {|o|o:handle == nextHandle})
      //oCtrl := IIf(i > 0, oparent:acontrols[i], oParent)
      IF oForm:classname == oParent:classname .OR. oParent:className != "HTAB"
         IF oParent:Type == NIL .OR. oParent:Type < WND_DLG_RESOURCE
             hwg_SetFocus(nextHandle)
         ELSE
            hwg_PostMessage(oParent:handle, WM_NEXTDLGCTL, nextHandle, 1)
         ENDIF
      ELSE
         IF oForm:Type < WND_DLG_RESOURCE .AND. PtrtouLong(oParent:handle) == PtrtouLong(hwg_GetFocus()) //oParent:oParent:Type < WND_DLG_RESOURCE
            hwg_SetFocus(nextHandle)
         ELSEIF PtrtouLong(oParent:handle) == PtrtouLong(hwg_GetFocus())
            hwg_PostMessage(hwg_GetActiveWindow(), WM_NEXTDLGCTL, nextHandle, 1)
         ELSE
            hwg_PostMessage(oParent:handle, WM_NEXTDLGCTL, nextHandle, 1)
         ENDIF
      ENDIF

   ENDIF
   IF nSkip != 0 .AND. hwg_SelfFocus(hctrl, nextHandle) .AND. oCtrl != NIL
     // necessario para executa um codigo do lostfcosu
      IF __ObjHasMsg(oCtrl, "BLOSTFOCUS") .AND. oCtrl:blostfocus != NIL
         hwg_SendMessage(nexthandle, WM_KILLFOCUS, 0, 0)
      ENDIF
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION NextFocusTab(oParent, hCtrl, nSkip)
   
   LOCAL nextHandle := NIL
   LOCAL i
   LOCAL nPage
   LOCAL nFirst
   LOCAL nLast
   LOCAL k := 0

   IF Len(oParent:aPages) > 0
      oParent:SetFocus()
      nPage := oParent:GetActivePage(@nFirst, @nLast)
      IF !oParent:lResourceTab  && TAB without RC
         i := AScan(oParent:acontrols, {|o|o:handle == hCtrl})
         i += IIf(i == 0, nFirst, nSkip) //nLast, nSkip)
         IF i >= nFirst .AND. i <= nLast
            nextHandle := GetNextDlgTabItem (oParent:handle, hCtrl, (nSkip < 0))
            IF i != AScan(oParent:aControls, {|o|o:handle == nextHandle}) .AND. oParent:aControls[i]:CLASSNAME = "HRADIOB"
               nextHandle := GetNextDlgGroupItem(oParent:handle, hCtrl, (nSkip < 0))
            ENDIF
            k := AScan(oParent:acontrols, {|o|o:handle == nextHandle})
            IF Len(oParent:aControls[k]:aControls) > 0 .AND. hCtrl != nextHandle .AND. oParent:aControls[k]:classname != "HTAB"
               nextHandle := NextFocusContainer(oParent:aControls[k], oParent:aControls[k]:handle, nSkip)
               RETURN IIf(!Empty(nextHandle), nextHandle, NextFocusTab(oParent, oParent:aControls[k]:handle, nSkip))
            ENDIF
         ENDIF
      ELSE
         hwg_SetFocus(oParent:aPages[nPage, 1]:aControls[1]:handle)
         RETURN 0
      ENDIF
      IF (nSkip < 0 .AND. (k > i .OR. k == 0)) .OR. (nSkip > 0 .AND. i > k)
         IF oParent:oParent:classname = "HTAB" .AND. oParent:oParent:classname != oParent:classname
                  NextFocusTab(oParent:oParent, nextHandle, nSkip)
         ENDIF
         IF Type("oParent:oParent:Type") = "N" .AND. oParent:oParent:Type < WND_DLG_RESOURCE
             nextHandle := GetNextDlgTabItem (oParent:oParent:handle, hctrl, (nSkip < 0))
         ELSE
             nextHandle := GetNextDlgTabItem (hwg_GetActiveWindow(), hCtrl, (nSkip < 0))
         ENDIF
         IF AScan(oParent:oParent:acontrols, {|o|o:handle == hCtrl}) == 0
             RETURN IIf(nSkip > 0, NextFocus(oParent:oParent, oParent:handle, nSkip), oParent:handle)
             /*
             nexthandle := oParent:handle
             i := AScan(oParent:oparent:acontrols, {|o|o:handle == oParent:handle}) + nSkip
             IF i > 0 .AND. i <= Len(oParent:oParent:acontrols)
                 i := ASCAN(oParent:oParent:acontrols, {|o| hwg_BitaND(HWG_GETWINDOWSTYLE(o:handle), WS_TABSTOP) != 0 }, i)
                 nexthandle := oParent:oParent:acontrols[IIf(i == 0, ASCAN(oParent:oParent:acontrols, ;
                          {|o| hwg_BitaND(HWG_GETWINDOWSTYLE(o:handle), WS_TABSTOP) != 0 }, i), i)]:handle
                  ENDIF
                  */
         ELSE
            hwg_PostMessage(hwg_GetActiveWindow(), WM_NEXTDLGCTL, nextHandle, 1)
         ENDIF
         IF !Empty(nextHandle) .AND. hwg_BitaND(HWG_GETWINDOWSTYLE(nextHandle), WS_TABSTOP) == 0
            NextFocusTab(oParent, nextHandle, nSkip)
         ENDIF
      ENDIF
   ENDIF

RETURN nextHandle

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION NextFocus(oParent, hCtrl, nSkip)

   LOCAL nextHandle := 0
   LOCAL i
   LOCAL nWindow
   LOCAL lGroup := hwg_BitAND(HWG_GETWINDOWSTYLE(hctrl), WS_GROUP) != 0
   LOCAL lHradio
   LOCAL lnoTabStop := .T.

   oParent := IIf(oParent:Type == NIL, oParent:GetParentForm(), oParent)
   nWindow := IIf(oParent:Type <= WND_DLG_RESOURCE, oParent:handle, hwg_GetActiveWindow())

   i := AScan(oparent:acontrols, {|o|hwg_SelfFocus(o:handle, hCtrl)})
   IF i > 0 .AND. Len(oParent:acontrols[i]:aControls) > 0 .AND. ;
      oParent:aControls[i]:className != "HTAB" .AND. (PtrtouLong(hCtrl) != PtrtouLong(nextHandle))
      nextHandle := NextFocusContainer(oParent:aControls[i], hCtrl, nSkip)
      IF !Empty(nextHandle)
         RETURN nextHandle
      ENDIF
   ENDIF
   lHradio := i > 0 .AND. oParent:acontrols[i]:CLASSNAME = "HRADIOB"
      // TABs DO resource
   //IF oParent:Type == WND_DLG_RESOURCE
      nextHandle := GetNextDlgTabItem(nWindow, hctrl,(nSkip < 0))
   //ELSE
      IF lHradio .OR. lGroup
         nexthandle := GetNextDlgGroupItem(nWindow, hctrl,(nSkip < 0))
         i := AScan(oParent:aControls, {|o|PtrtouLong(o:handle) == PtrtouLong(nextHandle)})
         lnoTabStop := !(i > 0 .AND. oParent:aControls[i]:CLASSNAME = "HRADIOB")
      ENDIF

      IF (lGroup .AND. nSkip < 0) .OR. lnoTabStop
         nextHandle := GetNextDlgTabItem (nWindow, hCtrl, (nSkip < 0))
         lnoTabStop := hwg_BitaND(HWG_GETWINDOWSTYLE(nexthandle), WS_TABSTOP) == 0
      ELSE
         lnoTabStop := .F.
       ENDIF
      i := AScan(oParent:aControls, {|o|hwg_SelfFocus(o:handle, nextHandle)})

      IF (lnoTabStop .AND. i > 0 .AND. !hwg_SelfFocus(hCtrl, NextHandle)) .OR. (i > 0 .AND. i <= Len(oParent:aControls) .AND. ;
           oparent:acontrols[i]:classname = "HGROUP") .OR. (i == 0 .AND. !Empty(nextHandle))
          RETURN NextFocus(oParent, nextHandle, nSkip)
      ENDIF
   //ENDIF

RETURN nextHandle

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION NextFocusContainer(oParent, hCtrl, nSkip)
   
   LOCAL nextHandle := NIL
   LOCAL i
   LOCAL i2
   LOCAL nWindow
   LOCAL lGroup := hwg_BitAND(HWG_GETWINDOWSTYLE(hctrl), WS_GROUP) != 0
   LOCAL lHradio
   LOCAL lnoTabStop := .F.

   AEval(oparent:acontrols,{|o| IIf(hwg_BitAND(HWG_GETWINDOWSTYLE(o:handle), WS_TABSTOP) != 0, lnoTabStop := .T., .T.) })
   IF !lnoTabStop .OR. Empty(hCtrl)
      RETURN NIL //nexthandle
   ENDIF
   nWindow := oParent:handle
   i := AScan(oparent:acontrols, {|o|PtrtouLong(o:handle) == PtrtouLong(hCtrl)})
    lHradio := i > 0 .AND. oParent:acontrols[i]:CLASSNAME = "HRADIOB"
      // TABs DO resource
   IF oParent:Type == WND_DLG_RESOURCE
      nexthandle := GetNextDlgGroupItem(oParent:handle, hctrl,(nSkip < 0))
   ELSE
      IF lHradio .OR. lGroup
         nextHandle := GetNextDlgGroupItem(nWindow, hCtrl,(nSkip < 0))
         i := AScan(oParent:aControls, {|o|o:handle == nextHandle})
         lnoTabStop := !(i > 0 .AND. oParent:aControls[i]:CLASSNAME = "HRADIOB")  //hwg_BitAND(HWG_GETWINDOWSTYLE(nexthandle), WS_TABSTOP) == 0
      ENDIF
      IF (lGroup .AND. nSkip < 0) .OR. lnoTabStop
         nextHandle := GetNextDlgTabItem (nWindow, hctrl, (nSkip < 0))
         lnoTabStop := hwg_BitaND(HWG_GETWINDOWSTYLE(nextHandle), WS_TABSTOP) == 0
      ELSE
        lnoTabStop := .F.
      ENDIF
      i2 := AScan(oParent:aControls, {|o|PtrtouLong(o:handle) == PtrtouLong(nextHandle)})
      IF ((i2 < i .AND. nSkip > 0) .OR. (i2 > i .AND. nSkip < 0)) .OR. hCtrl == nextHandle
          RETURN IIf(oParent:oParent:className == "HTAB", NextFocusTab(oParent:oParent, nWindow, nSkip), ;
                       NextFocus(oParent:oparent, hCtrl, nSkip))
      ENDIF
      i := i2
      IF i == 0
         nextHandle := oParent:aControls[Len(oParent:aControls)]:handle
      ELSEIF lnoTabStop .OR. (i > 0 .AND. i <= Len(oParent:acontrols) .AND. oParent:aControls[i]:classname = "HGROUP") .OR. i == 0
         nextHandle := GetNextDlgTabItem (nWindow, nextHandle, (nSkip < 0))
      ENDIF
   ENDIF

RETURN nextHandle

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION ParentGetDialog(o)

   DO WHILE (o := o:oParent) != NIL .AND. !__ObjHasMsg(o, "GETLIST")
   ENDDO

RETURN o

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SetColorinFocus(lDef, tcolor, bcolor, lFixed, lPersist)

   IF !hb_IsLogical(lDef)
      lDef := (hb_IsChar(lDef) .AND. Upper(lDef) = "ON")
   ENDIF
   s_lColorinFocus := lDef
   IF !lDef
      RETURN .F.
   ENDIF
   s_lFixedColor := IIf(lFixed != NIL, !lFixed, s_lFixedColor)
   s_tcolorselect := IIf(tcolor != NIL, tcolor, s_tcolorselect)
   s_bcolorselect := IIf(bcolor != NIL, bcolor, s_bcolorselect)
   s_lPersistColorSelect := IIf(lPersist != NIL, lPersist, s_lPersistColorSelect)

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SetDisableBackColor(lDef, bcolor)

   IF !hb_IsLogical(lDef)
      lDef := (hb_IsChar(lDef) .AND. Upper(lDef) = "ON")
    ENDIF
   //s_lColorinFocus := lDef
     IF !lDef
        s_bDisablecolor := NIL
      RETURN .F.
   ENDIF
   IF Empty(bColor)
      s_bDisablecolor := IIf(Empty(s_bDisablecolor), GetSysColor(COLOR_BTNHIGHLIGHT), s_bDisablecolor)
   ELSE
      s_bDisablecolor := bColor
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

/*
Luis Fernando Basso contribution
*/

/** CheckFocus
* check focus of controls before calling events
*/
FUNCTION CheckFocus(oCtrl, lInside)

   LOCAL oParent := ParentGetDialog(oCtrl)
   LOCAL hGetFocus := PtrtouLong(hwg_GetFocus())
   LOCAL lModal

   IF (!Empty(oParent) .AND. !hwg_IsWindowVisible(oParent:handle)) .OR. Empty(hwg_GetActiveWindow()) // == 0
      IF !lInside .AND. Empty(oParent:nInitFocus) // == 0
         oParent:Show()
         hwg_SetFocus(oParent:handle)
         hwg_SetFocus(hGetFocus)
      ELSEIF !lInside .AND. !Empty(oParent:nInitFocus)
       //  hwg_SetFocus(oParent:handle)
         RETURN .T.
     ENDIF
      RETURN .F.
   ELSEIF !lInside .AND. !oCtrl:lNoWhen
      oCtrl:lNoWhen := .T.
   ELSEIF !lInside
      RETURN .F.
   ENDIF
   IF oParent != NIL .AND. lInside   // valid
      lModal := oParent:lModal .AND. oParent:Type >  WND_DLG_RESOURCE
      IF ((!Empty(hGetFocus) .AND. lModal .AND. !hwg_SelfFocus(GetWindowParent(hGetFocus), oParent:handle)) .OR. ;
         (hwg_SelfFocus(hGetFocus, oCtrl:oParent:handle))) .AND. ;
          hwg_SelfFocus(oParent:handle, oCtrl:oParent:handle)
         RETURN .F.
      ENDIF
      oCtrl:lNoWhen := .F.
   ELSE
      oCtrl:oParent:lGetSkipLostFocus := .F.
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION WhenSetFocus(oCtrl, nSkip)

   IF hwg_SelfFocus(oCtrl:handle) .OR. Empty(hwg_GetFocus())
       GetSkip(oCtrl:oParent, oCtrl:handle, , nSkip)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION GetWindowParent(nHandle)

   DO WHILE !Empty(hwg_GetParent(nHandle)) .AND. !hwg_SelfFocus(nHandle, hwg_GetActiveWindow())
      nHandle := hwg_GetParent(nHandle)
   ENDDO

RETURN PtrtouLong(nHandle)

//-------------------------------------------------------------------------------------------------------------------//
