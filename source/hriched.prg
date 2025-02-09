//
// $Id: hriched.prg 1809 2011-12-19 06:22:05Z omm $
//
// HWGUI - Harbour Win32 GUI library source code:
// HRichEdit class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HRichEdit INHERIT HControl

#ifdef UNICODE
   CLASS VAR winclass INIT "RichEdit20W"
#else
   CLASS VAR winclass INIT "RichEdit20A"
#endif
   DATA lChanged   INIT .F.
   DATA lSetFocus  INIT .T.
   DATA lAllowTabs INIT .F.
   DATA lctrltab   HIDDEN
   DATA lReadOnly  INIT .F.
   DATA Col        INIT 0
   DATA Line       INIT 0
   DATA LinesTotal INIT 0
   DATA SelStart   INIT 0
   DATA SelText    INIT 0
   DATA SelLength  INIT 0

   DATA hdcPrinter

   DATA bChange

   METHOD New(oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip,;
               tcolor, bcolor, bOther, lAllowTabs, bChange, lnoBorder)
   METHOD Activate()
   METHOD onEvent(msg, wParam, lParam)
   METHOD Init()
   METHOD onGotFocus()
   METHOD onLostFocus()
   METHOD When()
   METHOD Valid()
   METHOD UpdatePos()
   METHOD onChange()
   METHOD ReadOnly(lreadOnly) SETGET
   METHOD SetColor(tColor, bColor, lRedraw)
   METHOD SaveFile(cFile)
   METHOD OpenFile(cFile)
   METHOD Print()

ENDCLASS

METHOD New(oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bSize, bPaint, bGfocus, bLfocus, ctooltip, ;
            tcolor, bcolor, bOther, lAllowTabs, bChange, lnoBorder) CLASS HRichEdit

   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), WS_CHILD + WS_VISIBLE + WS_TABSTOP + ; // WS_BORDER)
                        IIf(lNoBorder == NIL .OR. !lNoBorder, WS_BORDER, 0))
   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              bSize, bPaint, ctooltip, tcolor, IIf(bcolor == NIL, GetSysColor(COLOR_BTNHIGHLIGHT), bcolor))

   ::title   := vari
   ::bOther  := bOther
   ::bChange := bChange
   ::lAllowTabs := IIf(Empty(lAllowTabs), ::lAllowTabs, lAllowTabs)
   ::lReadOnly := hwg_BitAnd(nStyle, ES_READONLY) != 0

   hwg_InitRichEdit()

   ::Activate()

   IF bGfocus != NIL
      //::oParent:AddEvent(EN_SETFOCUS, Self, bGfocus,, "onGotFocus")
      ::bGetFocus := bGfocus
      ::oParent:AddEvent(EN_SETFOCUS, Self, {|o|::When(o)}, , "onGotFocus")
   ENDIF
   IF bLfocus != NIL
      //::oParent:AddEvent(EN_KILLFOCUS, Self, bLfocus,, "onLostFocus")
      ::bLostFocus := bLfocus
      ::oParent:AddEvent(EN_KILLFOCUS, Self, {|o|::Valid(o)}, , "onLostFocus")
   ENDIF

   RETURN Self

METHOD Activate() CLASS HRichEdit
   IF !Empty(::oParent:handle)
      ::handle := CreateRichEdit(::oParent:handle, ::id, ;
                                 ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::title)
      ::Init()
   ENDIF
   RETURN NIL

METHOD Init() CLASS HRichEdit
   IF !::lInit
      ::nHolder := 1
      hwg_SetWindowObject(::handle, Self)
      hwg_InitRichProc(::handle)
      ::Super:Init()
      ::SetColor(::tColor, ::bColor)
      IF ::bChange != NIL
         hwg_SendMessage(::handle, EM_SETEVENTMASK, 0, ENM_SELCHANGE + ENM_CHANGE)
         ::oParent:AddEvent(EN_CHANGE, ::id, {||::onChange()})
      ENDIF
   ENDIF
   RETURN NIL

#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HRichEdit
   LOCAL nDelta, nret

   // hwg_WriteLog("rich" + Str(msg) + Str(wParam) + Str(lParam) + Chr(13))
   IF msg == WM_KEYUP .OR. msg == WM_LBUTTONDOWN .OR. msg == WM_LBUTTONUP // msg == WM_NOTIFY .OR.
      ::updatePos()
   ELSEIF msg == WM_MOUSEACTIVATE .AND. ::GetParentForm():Type < WND_DLG_RESOURCE
      ::SetFocus()
   ENDIF
   IF msg == EM_GETSEL .OR. msg == EM_LINEFROMCHAR .OR. msg == EM_LINEINDEX .OR. ;
       msg == EM_GETLINECOUNT .OR. msg == EM_SETSEL .OR. msg == EM_SETCHARFORMAT .OR. ;
       msg == EM_HIDESELECTION .OR. msg == WM_GETTEXTLENGTH .OR. msg == EM_GETFIRSTVISIBLELINE
      RETURN - 1
   ENDIF
   IF msg == WM_SETFOCUS .AND. ::lSetFocus //.AND. hwg_IsWindowVisible(::handle)
      ::lSetFocus := .F.
      hwg_PostMessage(::handle, EM_SETSEL, 0, 0)
   ELSEIF msg == WM_SETFOCUS .AND. ::lAllowTabs .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
        ::lctrltab := ::GetParentForm(Self):lDisableCtrlTab
        ::GetParentForm(Self):lDisableCtrlTab := ::lAllowTabs
   ELSEIF msg == WM_KILLFOCUS .AND. ::lAllowTabs .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
        ::GetParentForm(Self):lDisableCtrlTab := ::lctrltab
   ENDIF
   IF msg == WM_KEYDOWN .AND. (wParam == VK_DELETE .OR. wParam == VK_BACK)  //46Del
      ::lChanged := .T.
   ENDIF
   IF msg == WM_CHAR
      IF wParam == VK_TAB .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
         IF (IsCtrlShift(.T., .F.) .OR. !::lAllowTabs)
            RETURN 0
         ENDIF
      ENDIF
       IF !IsCtrlShift(.T., .F.)
         ::lChanged := .T.
      ENDIF
   ELSEIF hb_IsBlock(::bOther)
      nret := Eval(::bOther, Self, msg, wParam, lParam)
      IF !hb_IsNumeric(nret) .OR. nret > - 1
         RETURN nret
      ENDIF
   ENDIF
   IF msg == WM_KEYUP
     IF wParam == VK_TAB .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
         IF IsCtrlShift(.T., .F.)
            GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ENDIF
      ENDIF
   ELSEIF msg == WM_KEYDOWN
      IF wParam == VK_TAB .AND. (IsCtrlShift(.T., .F.) .OR. !::lAllowTabs)
         GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
         RETURN 0
      ELSEIF wParam == VK_TAB .AND. ::GetParentForm(Self):Type >= WND_DLG_RESOURCE
         RE_INSERTTEXT(::handle, Chr(VK_TAB))
          RETURN 0
      ENDIF
      IF wParam == VK_ESCAPE .AND. ::GetParentForm():handle != ::oParent:handle
         IF hwg_GetParent(::oParent:handle) != NIL
            //hwg_SendMessage(hwg_GetParent(::oParent:handle), WM_CLOSE, 0, 0)
         ENDIF
         RETURN 0
      ENDIF
   ELSEIF msg == WM_MOUSEWHEEL
      nDelta := hwg_HIWORD(wParam)
      IF nDelta > 32768
         nDelta -= 65535
      ENDIF
      hwg_SendMessage(::handle, EM_SCROLL, IIf(nDelta > 0, SB_LINEUP, SB_LINEDOWN), 0)
      //hwg_SendMessage(::handle, EM_SCROLL, IIf(nDelta > 0, SB_LINEUP, SB_LINEDOWN), 0)
   ELSEIF msg == WM_DESTROY
      ::END()
   ENDIF

   RETURN - 1
#else
METHOD onEvent(msg, wParam, lParam) CLASS HRichEdit

   LOCAL nDelta
   LOCAL nret

   SWITCH msg

   CASE WM_KEYDOWN
      SWITCH wParam
      CASE VK_DELETE
      CASE VK_BACK
         ::lChanged := .T.
         EXIT
      CASE VK_TAB
         IF (IsCtrlShift(.T., .F.) .OR. !::lAllowTabs)
            GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ELSEIF ::GetParentForm(Self):Type >= WND_DLG_RESOURCE
            RE_INSERTTEXT(::handle, Chr(VK_TAB))
            RETURN 0
         ENDIF
         EXIT
      CASE VK_ESCAPE
         IF ::GetParentForm():handle != ::oParent:handle
            //IF hwg_GetParent(::oParent:handle) != NIL
               //hwg_SendMessage(hwg_GetParent(::oParent:handle), WM_CLOSE, 0, 0)
            //ENDIF
            RETURN 0
         ENDIF
      ENDSWITCH
      EXIT

   CASE WM_KEYUP
      ::updatePos()
      IF wParam == VK_TAB .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
         IF IsCtrlShift(.T., .F.)
            GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ENDIF
      ENDIF
      EXIT

   CASE WM_LBUTTONDOWN
      ::updatePos()
      EXIT

   CASE WM_LBUTTONUP
      ::updatePos()
      EXIT

   CASE WM_MOUSEACTIVATE
      IF ::GetParentForm():Type < WND_DLG_RESOURCE
         ::SetFocus()
      ENDIF
      EXIT

   CASE EM_GETSEL
   CASE EM_LINEFROMCHAR
   CASE EM_LINEINDEX
   CASE EM_GETLINECOUNT
   CASE EM_SETSEL
   CASE EM_SETCHARFORMAT
   CASE EM_HIDESELECTION
   CASE WM_GETTEXTLENGTH
   CASE EM_GETFIRSTVISIBLELINE
      RETURN -1

   CASE WM_SETFOCUS
      IF ::lSetFocus // .AND. hwg_IsWindowVisible(::handle)
         ::lSetFocus := .F.
         hwg_PostMessage(::handle, EM_SETSEL, 0, 0)
      ELSEIF ::lAllowTabs .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
         ::lctrltab := ::GetParentForm(Self):lDisableCtrlTab
         ::GetParentForm(Self):lDisableCtrlTab := ::lAllowTabs
      ENDIF
      EXIT

   CASE WM_KILLFOCUS
      IF ::lAllowTabs .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
         ::GetParentForm(Self):lDisableCtrlTab := ::lctrltab
      ENDIF
      EXIT

   CASE WM_CHAR
      IF wParam == VK_TAB .AND. ::GetParentForm(Self):Type < WND_DLG_RESOURCE
         IF (IsCtrlShift(.T., .F.) .OR. !::lAllowTabs)
            RETURN 0
         ENDIF
      ENDIF
      IF !IsCtrlShift(.T., .F.)
         ::lChanged := .T.
      ENDIF
      EXIT

   CASE WM_MOUSEWHEEL
      nDelta := hwg_HIWORD(wParam)
      IF nDelta > 32768
         nDelta -= 65535
      ENDIF
      hwg_SendMessage(::handle, EM_SCROLL, IIf(nDelta > 0, SB_LINEUP, SB_LINEDOWN), 0)
      //hwg_SendMessage(::handle, EM_SCROLL, IIf(nDelta > 0, SB_LINEUP, SB_LINEDOWN), 0)
      EXIT

   CASE WM_DESTROY
      ::END()

   ENDSWITCH

   IF hb_IsBlock(::bOther)
      nret := Eval(::bOther, Self, msg, wParam, lParam)
      IF !hb_IsNumeric(nret) .OR. nret > -1
         RETURN nret
      ENDIF
   ENDIF

RETURN -1
#endif

METHOD SetColor(tColor, bColor, lRedraw) CLASS HRichEdit

   IF tcolor != NIL
      re_SetDefault(::handle, tColor) //, ID_FONT ,,) // cor e fonte padrao
   ENDIF
   IF bColor != NIL
      hwg_SendMessage(::handle, EM_SETBKGNDCOLOR, 0, bColor) // cor de fundo
   ENDIF
   ::super:SetColor(tColor, bColor, lRedraw)

   RETURN NIL

METHOD ReadOnly(lreadOnly)

   IF lreadOnly != NIL
      IF !Empty(hwg_SendMessage(::handle, EM_SETREADONLY, IIf(lReadOnly, 1, 0), 0))
          ::lReadOnly := lReadOnly
      ENDIF
   ENDIF
   RETURN ::lReadOnly

METHOD UpdatePos() CLASS HRichEdit
   LOCAL npos := hwg_SendMessage(::handle, EM_GETSEL, 0, 0)
   LOCAL pos1 := hwg_LOWORD(npos) + 1, pos2 := hwg_HIWORD(npos) + 1

   ::Line := hwg_SendMessage(::handle, EM_LINEFROMCHAR, pos1 - 1, 0) + 1
   ::LinesTotal := hwg_SendMessage(::handle, EM_GETLINECOUNT, 0, 0)
   ::SelText := RE_GETTEXTRANGE(::handle, pos1, pos2)
   ::SelStart := pos1
   ::SelLength := pos2 - pos1
   ::Col := pos1 - hwg_SendMessage(::handle, EM_LINEINDEX, -1, 0)

   RETURN nPos

METHOD onChange() CLASS HRichEdit

   IF hb_IsBlock(::bChange)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bChange, ::gettext(), Self)
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN NIL

METHOD onGotFocus() CLASS HRichEdit
  RETURN ::When()

METHOD onLostFocus() CLASS HRichEdit
  RETURN ::Valid()


METHOD When() CLASS HRichEdit

    IF !CheckFocus(Self, .F.)
       RETURN .T.
   ENDIF
   ::title := ::GetText()
   ::oparent:lSuspendMsgsHandling := .T.
   Eval(::bGetFocus, ::title, Self) // TODO: hb_IsBlock ?
   ::oparent:lSuspendMsgsHandling := .F.
 RETURN .T.


METHOD Valid() CLASS HRichEdit

   IF hb_IsBlock(::bLostFocus) .AND. !CheckFocus(Self, .T.)
       RETURN .T.
   ENDIF
   ::title := ::GetText()
   ::oparent:lSuspendMsgsHandling := .T.
   Eval(::bLostFocus, ::title, Self)
   ::oparent:lSuspendMsgsHandling := .F.

  RETURN .T.

METHOD SaveFile(cFile) CLASS HRichEdit

   IF !Empty(cFile)
      IF !Empty(SAVERICHEDIT(::handle, cFile))
          RETURN .T.
      ENDIF
   ENDIF
   RETURN .F.

METHOD OpenFile(cFile) CLASS HRichEdit

   IF !Empty(cFile)
      IF !Empty(LOADRICHEDIT(::handle, cFile))
          RETURN .T.
      ENDIF
   ENDIF
   RETURN .F.

METHOD Print() CLASS HRichEdit

   IF ::hDCPrinter == NIL
    //  ::hDCPrinter := hwg_PrintSetup()
   ENDIF
   IF HWG_STARTDOC(::hDCPrinter) != 0
      IF PrintRTF(::handle, ::hDCPrinter) != 0
          HWG_ENDDOC(::hDCPrinter)
      ELSE
         HWG_ABORTDOC(::hDCPrinter)
      ENDIF
   ENDIF
   RETURN .F.


/*
Function DefRichProc(hEdit, msg, wParam, lParam)
Local oEdit
   // hwg_WriteLog("RichProc: " + Str(hEdit, 10) + "|" + Str(msg, 6) + "|" + Str(wParam, 10) + "|" + Str(lParam, 10))
   oEdit := FindSelf(hEdit)
   IF msg == WM_CHAR
      oEdit:lChanged := .T.
   ELSEIF msg == WM_KEYDOWN
      IF wParam == 46     // Del
         oEdit:lChanged := .T.
      ENDIF
   ELSEIF oEdit:bOther != NIL
      RETURN Eval(oEdit:bOther, oEdit, msg, wParam, lParam)
   ENDIF
RETURN -1
*/
