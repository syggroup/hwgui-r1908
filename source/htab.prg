//
// $Id: htab.prg 1893 2012-09-10 19:15:47Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HTab class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"
/*
#define TCM_SETCURSEL           4876     // (TCM_FIRST + 12)
#define TCM_SETCURFOCUS         4912     // (TCM_FIRST + 48)
#define TCM_GETCURFOCUS         4911     // (TCM_FIRST + 47)
#define TCM_GETITEMCOUNT        4868     // (TCM_FIRST + 4)

#define TCM_SETIMAGELIST        4867
*/
//- HTab

#define TRANSPARENT 1

//-------------------------------------------------------------------------------------------------------------------//

CLASS HPage INHERIT HObject

   DATA xCaption HIDDEN
   ACCESS Caption INLINE ::xCaption
   ASSIGN Caption(xC) INLINE ::xCaption := xC, ::SetTabText(::xCaption)
   DATA lEnabled INIT .T. // HIDDEN
   DATA PageOrder INIT 1
   DATA oParent
   DATA tcolor, bcolor
   DATA brush
   DATA oFont   // not implemented
   DATA aItemPos INIT {}
   DATA Tooltip

   METHOD New(cCaption, nPage, lEnabled, tcolor, bcolor, cTooltip)
   METHOD Enable() INLINE ::Enabled(.T.)
   METHOD Disable() INLINE ::Enabled(.F.)
   METHOD GetTabText() INLINE GetTabName(::oParent:handle, ::PageOrder - 1)
   METHOD SetTabText(cText)
   METHOD Refresh() INLINE ::oParent:ShowPage(::PageOrder)
   METHOD Enabled(lEnabled) SETGET
   METHOD SetColor(tcolor, bcolor)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(cCaption, nPage, lEnabled, tcolor, bcolor, cTooltip) CLASS HPage

   cCaption := IIf(cCaption == NIL, "New Page", cCaption)
   ::lEnabled := IIf(lEnabled != NIL, lEnabled, .T.)
   ::Pageorder := nPage
   ::Tooltip := cTooltip
   ::SetColor(tColor, bColor)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetColor(tcolor, bColor) CLASS HPage

   IF tcolor != NIL
      ::tcolor := tcolor
   ENDIF
   IF bColor != NIL
      ::bColor := bColor
      IF ::brush != NIL
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add(bColor)
   ENDIF
   IF ::oParent == NIL .OR. (bColor == NIL .AND. tcolor == NIL)
      RETURN NIL
   ENDIF
   ::oParent:SetPaintSizePos(IIf(bColor == NIL, 1, -1))

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetTabText(cText) CLASS HPage

   IF Len(::aItemPos) == 0
      RETURN NIL
   ENDIF

   SetTabName(::oParent:handle, ::PageOrder - 1, cText)
   ::xCaption := cText
   hwg_InvalidateRect(::oParent:handle, 0, ::aItemPos[1], ::aItemPos[2], ::aItemPos[1] + ::aItemPos[3], ::aItemPos[2] + ::aItemPos[4])
   hwg_InvalidateRect(::oParent:handle, 0)
   /*
   FOR i := 1 TO Len(::oParent:Pages)
      ::oParent:Pages[i]:aItemPos := TabItemPos(::oParent:handle, i - 1)
   NEXT
   */
RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Enabled(lEnabled) CLASS HPage

   LOCAL nActive

   IF lEnabled != NIL .AND. ::lEnabled != lEnabled
      ::lEnabled := lEnabled
      IF lEnabled .AND. (::PageOrder != ::oParent:nActive .OR. !hwg_IsWindowEnabled(::oParent:handle))
         IF !hwg_IsWindowEnabled(::oParent:handle)
            ::oParent:Enable()
            ::oParent:setTab(::PageOrder)
         ENDIF
      ENDIF
      ::oParent:ShowDisablePage(::PageOrder)
      IF ::PageOrder == ::oParent:nActive .AND. !::lenabled
         nActive := SetTabFocus(::oParent, ::oParent:nActive, VK_RIGHT)
         IF nActive > 0 .AND. ::oParent:Pages[nActive]:lEnabled
            ::oParent:setTab(nActive)
         ENDIF
      ENDIF
      IF AScan(::oParent:Pages, {|p|p:lEnabled}) == 0
         ::oParent:Disable()
         hwg_SendMessage(::oParent:handle, TCM_SETCURSEL, -1, 0)
      ENDIF
   ENDIF

RETURN ::lEnabled

//-------------------------------------------------------------------------------------------------------------------//

CLASS HTab INHERIT HControl

   CLASS VAR winclass INIT "SysTabControl32"

   DATA aTabs
   DATA aPages INIT {}
   DATA Pages INIT {}
   DATA bChange, bChange2
   DATA hIml, aImages, Image1, Image2
   DATA aBmpSize INIT {0, 0}
   DATA oTemp
   DATA bAction, bRClick
   DATA lResourceTab INIT .F.

   DATA oPaint
   DATA nPaintHeight INIT 0
   DATA TabHeightSize
   DATA internalPaint INIT 0 HIDDEN

   METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, aTabs, bChange, ;
      aImages, lResour, nBC, bClick, bGetFocus, bLostFocus, bRClick)

   METHOD Activate()
   METHOD Init()
   METHOD AddPage(oPage, cCaption)
   METHOD SetTab(n)
   METHOD StartPage(cname, oDlg, lEnabled, tcolor, bcolor, cTooltip)
   METHOD EndPage()
   METHOD ChangePage(nPage)
   METHOD DeletePage(nPage)
   METHOD HidePage(nPage)
   METHOD ShowPage(nPage)
   METHOD GetActivePage(nFirst, nEnd)
   METHOD Notify(lParam)
   METHOD OnEvent(msg, wParam, lParam)
   METHOD Refresh(lAll)
   METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem)
   METHOD ShowDisablePage(nPageEnable, nEvent)
   METHOD DisablePage(nPage) INLINE ::Pages[nPage]:disable()
   METHOD EnablePage(nPage) INLINE ::Pages[nPage]:enable()
   METHOD SetPaintSizePos(nFlag)
   METHOD RedrawControls()
   METHOD ShowToolTips(lParam)
   METHOD onChange()

   HIDDEN:
   DATA nActive INIT 0         // Active Page
   DATA nPrevPage INIT 0
   DATA lClick INIT .F.
   DATA nActivate
   DATA aControlsHide INIT {}

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, aTabs, bChange, ;
   aImages, lResour, nBC, bClick, bGetFocus, bLostFocus, bRClick) CLASS HTab

   LOCAL i

   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), WS_CHILD + WS_CLIPSIBLINGS + WS_TABSTOP + TCS_TOOLTIPS)

   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint)

   ::title := ""
   ::oFont := IIf(oFont == NIL, ::oParent:oFont, oFont)
   ::aTabs := IIf(aTabs == NIL, {}, aTabs)
   ::bChange := bChange
   ::bChange2 := bChange

   ::bGetFocus := bGetFocus
   ::bLostFocus := bLostFocus
   ::bAction := bClick
   ::bRClick := bRClick

   IF aImages != NIL
      ::aImages := {}
      FOR i := 1 TO Len(aImages)
         //AAdd(::aImages, Upper(aImages[i]))
         aImages[i] := IIf(lResour, LoadBitmap(aImages[i]), OpenBitmap(aImages[i]))
         AAdd(::aImages, aImages[i])
      NEXT
      ::aBmpSize := GetBitmapSize(aImages[1])
      ::himl := CreateImageList(aImages, ::aBmpSize[1], ::aBmpSize[2], 12, nBC)
      ::Image1 := 0
      IF Len(aImages) > 1
         ::Image2 := 1
      ENDIF
   ENDIF
   ::oPaint := HPaintTab():New(Self, , 0, 0, 0, 0) //, ::oFont)
   //::brush := GetBackColorParent(Self, .T.)
   HWG_InitCommonControlsEx()
   ::Activate()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HTab

   IF !Empty(::oParent:handle)
      ::handle := CreateTabControl(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight)
      ::Init()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem) CLASS hTab

   HB_SYMBOL_UNUSED(cCaption)
   HB_SYMBOL_UNUSED(lTransp)
   HB_SYMBOL_UNUSED(aItem)

   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor)
   HWG_InitCommonControlsEx()
   ::lResourceTab := .T.
   ::aTabs := {}
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0

   ::brush := GetBackColorParent(Self, .T.)
   ::oPaint := HPaintTab():New(Self, , 0, 0, 0, 0) //, ::oFont)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Init() CLASS HTab

   LOCAL i
   LOCAL x := 0

   IF !::lInit
      InitTabControl(::handle, ::aTabs, IIf(::himl != NIL, ::himl, 0))
      hwg_SendMessage(::handle, TCM_SETMINTABWIDTH, 0, 0)
      IF hwg_BitAnd(::Style, TCS_FIXEDWIDTH) != 0
         ::TabHeightSize := 25 - (::oFont:Height + 12)
         x := ::nWidth / Len(::aPages) - 2
      ELSEIF ::TabHeightSize != NIL
      ELSEIF ::oFont != NIL
         ::TabHeightSize := 25 - (::oFont:Height + 12)
      ELSE
         ::TabHeightSize := 23
      ENDIF
      hwg_SendMessage(::handle, TCM_SETITEMSIZE, 0, MAKELPARAM(x, ::TabHeightSize))
      IF ::himl != NIL
         hwg_SendMessage(::handle, TCM_SETIMAGELIST, 0, ::himl)
      ENDIF
      hwg_AddToolTip(::GetParentForm():handle, ::handle, "")
      ::Super:Init()

      IF Len(::aPages) > 0
         //::Pages[1]:aItemPos := TabItemPos(::handle, 0)
         /*
         IF AScan(::Pages, {|p|p:brush != NIL}) > 0
            ::SetPaintSizePos(-1)
         ELSEIF AScan(::Pages, {|p|p:tcolor != NIL}) > 0
            ::SetPaintSizePos(1)
         ELSE
            ::oPaint:nHeight := ::TabHeightSize
         ENDIF
         */
         ::SetPaintSizePos(IIf(AScan(::Pages, {|p|p:brush != NIL}) > 0, -1, 1))
         ::nActive := 0
         FOR i := 1 TO Len(::aPages)
            ::Pages[i]:aItemPos := TabItemPos(::handle, i - 1)
            ::HidePage(i)
            ::nActive := IIf(::nActive == 0 .AND. ::Pages[i]:Enabled, i, ::nActive)
         NEXT
         hwg_SendMessage(::handle, TCM_SETCURFOCUS, ::nActive - 1, 0)
         IF ::nActive == 0
            ::Disable()
            ::ShowPage(1)
         ELSE
            ::ShowPage(::nActive)
         ENDIF
      ELSE
         Asize(::aPages, hwg_SendMessage(::handle, TCM_GETITEMCOUNT, 0, 0))
         AEval(::aPages, {|a, i|HB_SYMBOL_UNUSED(a), ::AddPage(HPage():New("", i, .T.,), "")})
      ENDIF
      ::nHolder := 1
      hwg_SetWindowObject(::handle, Self)
      hwg_InitTabProc(::handle)

   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetPaintSizePos(nFlag) CLASS HTab
   
   LOCAL aItemPos

   ::Pages[::nActive]:aItemPos := TabItemPos(::handle, ::nActive - 1) //0)
   aItemPos := ::Pages[::nActive]:aItemPos
   IF nFlag == - 1
      ::oPaint:nLeft := 1
      ::oPaint:nWidth := ::nWidth - 3
      IF hwg_BitAnd(::Style, TCS_BOTTOM) != 0
         ::oPaint:nTop := 1
         ::oPaint:nHeight := aItemPos[2] - 3
      ELSE
         ::oPaint:nTop := aItemPos[4]
         ::oPaint:nHeight := ::nHeight - aItemPos[4] - 3
      ENDIF
      ::nPaintHeight := ::oPaint:nHeight
   ELSEIF nFlag == - 2
      hwg_SetWindowPos(::oPaint:handle, HWND_BOTTOM, 0, 0, 0, 0, ;
         SWP_NOSIZE + SWP_NOMOVE + SWP_NOREDRAW + SWP_NOACTIVATE + SWP_NOSENDCHANGING)
      RETURN NIL
   ELSEIF nFlag > 0
      ::npaintheight := nFlag
      ::oPaint:nHeight := nFlag
      IF !hwg_IsWindowEnabled(::handle)
         RETURN NIL
      ENDIF
   ENDIF
   hwg_SetWindowPos(::oPaint:handle, NIL, ::oPaint:nLeft, ::oPaint:nTop, ::oPaint:nWidth, ::oPaint:nHeight, SWP_NOACTIVATE) //+ SWP_SHOWWINDOW)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SetTab(n) CLASS HTab

   IF n > 0 .AND. n <= Len(::aPages)
      IF ::Pages[n]:Enabled
         ::changePage(n)
         hwg_SendMessage(::handle, TCM_SETCURFOCUS, n - 1, 0)
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD StartPage(cname, oDlg, lEnabled, tColor, bColor, cTooltip) CLASS HTab

   ::oTemp := ::oDefaultParent
   ::oDefaultParent := Self

   IF Len(::aTabs) > 0 .AND. Len(::aPages) == 0
      ::aTabs := {}
   ENDIF
   AAdd(::aTabs, cname)
   IF ::lResourceTab
      AAdd(::aPages, {oDlg, 0})
   ELSE
      AAdd(::aPages, {Len(::aControls), 0})
   ENDIF
   ::AddPage(HPage():New(cname, Len(::aPages), lEnabled, tColor, bcolor, cTooltip), cName)
   ::nActive := Len(::aPages)
   ::Pages[::nActive]:aItemPos := {0, 0, 0, 0} //TabItemPos(::handle, ::nActive - 1)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD AddPage(oPage, cCaption) CLASS HTab

   AAdd(::Pages, oPage)
   InitPage(Self, oPage, cCaption, Len(::Pages))

RETURN oPage

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION InitPage(oTab, oPage, cCaption, n)

   LOCAL cname := "Page" + AllTrim(Str(n))

   oPage:oParent := oTab
   __objAddData(oPage:oParent, cname)
   oPage:oParent:&(cname) := oPage
   oPage:Caption := cCaption

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD EndPage() CLASS HTab
   
   LOCAL i
   LOCAL cName
   LOCAL cPage := "Page" + AllTrim(Str(::nActive))

   IF !::lResourceTab
      ::aPages[::nActive, 2] := Len(::aControls) - ::aPages[::nActive, 1]
      IF ::handle != NIL .AND. !Empty(::handle)
         AddTab(::handle, ::nActive, ::aTabs[::nActive])
      ENDIF
      IF ::nActive > 1 .AND. ::handle != NIL .AND. !Empty(::handle)
         ::HidePage(::nActive)
      ENDIF
      // add news objects how property in tab
      FOR i := ::aPages[::nActive, 1] + 1 TO ::aPages[::nActive, 1] + ::aPages[::nActive, 2]
         cName := ::aControls[i]:name
         IF !Empty(cName) .AND. hb_IsChar(cName) .AND. !(":" $ cName) .AND. ;
                                 !("->" $ cName) .AND. !("[" $ cName)
             __objAddData(::&cPage, cName)
               ::&cPage:&(::aControls[i]:name) := ::aControls[i]
           ENDIF
      NEXT
      ::nActive := 1

      ::oDefaultParent := ::oTemp
      ::oTemp := NIL

      ::bChange := {|o, n|o:ChangePage(n)}


   ELSE
      IF ::handle != NIL .AND. !Empty(::handle)

         AddTabDialog(::handle, ::nActive, ::aTabs[::nActive], ::aPages[::nactive, 1]:handle)
      ENDIF
      IF ::nActive > 1 .AND. ::handle != NIL .AND. !Empty(::handle)
         ::HidePage(::nActive)
      ENDIF
      ::nActive := 1

      ::oDefaultParent := ::oTemp
      ::oTemp := NIL

      ::bChange := {|o, n|o:ChangePage(n)}
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD ChangePage(nPage) CLASS HTab
   
   //LOCAL client_rect

   IF nPage == ::nActive //.OR. !::pages[nPage]:enabled
      //SetTabFocus(Self, nPage, .F.)
      RETURN NIL
   ENDIF
   IF !Empty(::aPages) .AND. ::pages[nPage]:enabled
      //-client_rect := TabItemPos(::handle, ::nActive - 1)
      IF ::nActive > 0
         ::HidePage(::nActive)
         IF ::Pages[nPage]:brush != NIL
            ::SetPaintSizePos(-1)
            hwg_RedrawWindow(::oPaint:handle, RDW_INVALIDATE + RDW_INTERNALPAINT)
         ENDIF
      ENDIF
      ::nActive := nPage
      IF ::bChange2 != NIL
        ::onChange()
      ENDIF
      ::ShowPage(nPage)

      IF ::oPaint:nHeight  > ::TabHeightSize + 1
         //- hwg_InvalidateRect(::handle, 1, client_rect[1], client_rect[2], client_rect[3] + 3, client_rect[4] + 0)
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD onChange() CLASS HTab

   IF hb_IsBlock(::bChange2)
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bChange2, Self, ::nActive)
      ::oparent:lSuspendMsgsHandling := .F. //lSuspendMsgsHandling
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD HidePage(nPage) CLASS HTab
   
   LOCAL i
   LOCAL nFirst
   LOCAL nEnd
   LOCAL k

   IF !::lResourceTab
      nFirst := ::aPages[nPage, 1] + 1
      nEnd := ::aPages[nPage, 1] + ::aPages[nPage, 2]
      FOR i := nFirst TO nEnd
         IF (k:= AScan(::aControlsHide, ::aControls[i]:id)) == 0 .AND. ::aControls[i]:lHide
            AAdd(::aControlsHide, ::aControls[i]:id)
         ELSEIF k > 0 .AND. !::aControls[i]:lHide
            ADel(::aControlsHide, k)
            ASize(::aControlsHide, Len(::aControlsHide) - 1)
         ENDIF
         ::aControls[i]:Hide()
      NEXT
   ELSE
      ::aPages[nPage, 1]:Hide()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD ShowPage(nPage) CLASS HTab
   
   LOCAL i
   LOCAL nFirst
   LOCAL nEnd

   IF !::lResourceTab
      nFirst := ::aPages[nPage, 1] + 1
      nEnd := ::aPages[nPage, 1] + ::aPages[nPage, 2]
      IF ::oPaint:nHeight > 1 .AND. ::Pages[nPage]:brush != NIL .AND. ;
         AScan(::aControls, {|o|o:winclass = ::winclass}, nFirst, nEnd - nFirst + 1) > 0
         ::SetPaintSizePos(-2)
      ENDIF
      FOR i := nFirst TO nEnd
         //IF AScan(::aControlsHide, ::aControls[i]:id) == 0 .OR. ::aControls[i]:lHide == .F.
         IF !::aControls[i]:lHide .OR. (Len(::aControlsHide) == 0 .OR. AScan(::aControlsHide, ::aControls[i]:id) == 0)
            ::aControls[i]:Show(SW_SHOWNA)
         ENDIF
      NEXT
      IF ::Pages[nPage]:brush == NIL .AND. ::oPaint:nHeight > 1
         ::SetPaintSizePos(1)
      ENDIF
   /*
   FOR i := nFirst TO nEnd
      IF (__ObjHasMsg(::aControls[i], "BSETGET") .AND. ::aControls[i]:bSetGet != NIL) .OR. hwg_BitAnd(::aControls[i]:style, WS_TABSTOP) != 0
         hwg_SetFocus(::aControls[i]:handle)
         Exit
      ENDIF
   NEXT
   */
   ELSE
      ::aPages[nPage, 1]:show()

      FOR i := 1  TO Len(::aPages[nPage, 1]:aControls)
         IF (__ObjHasMsg(::aPages[nPage, 1]:aControls[i], "BSETGET") .AND. ::aPages[nPage, 1]:aControls[i]:bSetGet != NIL) .OR. hwg_BitAnd(::aPages[nPage, 1]:aControls[i]:style, WS_TABSTOP) != 0
            hwg_SetFocus(::aPages[nPage, 1]:aControls[i]:handle)
            EXIT
         ENDIF
      NEXT

   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Refresh(lAll) CLASS HTab
   
   LOCAL i
   LOCAL nFirst
   LOCAL nEnd
   LOCAL lRefresh
   LOCAL hCtrl := hwg_GetFocus()

   IF ::nActive != 0
      IF !::lResourceTab
         lAll := IIf(lAll == NIL, .F., lAll)
         nFirst := ::aPages[::nActive, 1] + 1
         nEnd := ::aPages[::nActive, 1] + ::aPages[::nActive, 2]
         FOR i := nFirst TO nEnd
            lRefresh := !Empty(__ObjHasMethod(::aControls[i], "REFRESH")) .AND. ;
                  (__ObjHasMsg(::aControls[i], "BSETGET") .OR. lAll) .AND. ::aControls[i]:handle != hCtrl
                IF !Empty(lRefresh)
               ::aControls[i]:Refresh()
               IF hb_IsBlock(::aControls[i]:bRefresh)
                  Eval(::aControls[i]:bRefresh, ::aControls[i])
               ENDIF
            ENDIF
         NEXT
      ENDIF
   ELSE
      ::aPages[::nActive, 1]:Refresh()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD RedrawControls() CLASS HTab
   
   LOCAL i

   IF ::nActive != 0
      IF !::lResourceTab
         ::oParent:lSuspendMsgsHandling := .T.
         FOR i := ::aPages[::nActive, 1] + 1 TO ::aPages[::nActive, 1] + ::aPages[::nActive, 2]
            IF hwg_IsWindowVisible(::aControls[i]:handle) //.AND. ::aControls[i]:bPaint == NIL
               hwg_RedrawWindow(::aControls[i]:handle, IIf(::classname != ::aControls[i]:classname, ;
                  RDW_NOERASE + RDW_FRAME + RDW_INVALIDATE +RDW_NOINTERNALPAINT, RDW_NOERASE +RDW_INVALIDATE))
               /*
               IF ::aControls[i]:winclass = "EDIT" .AND. __ObjHasMsg(::aControls[i], "hUpDown")
                  hwg_InvalidateRect(::aControls[i]:hUpDown, 0)
               ENDIF
                */
            ENDIF
         NEXT
         ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetActivePage(nFirst, nEnd) CLASS HTab
   IF ::nActive > 0
      IF !::lResourceTab
         IF !Empty(::aPages)
            nFirst := ::aPages[::nActive, 1] + 1
            nEnd := ::aPages[::nActive, 1] + ::aPages[::nActive, 2]
         ELSE
            nFirst := 1
            nEnd := Len(::aControls)
         ENDIF
      ELSE
         nFirst := 1
         nEnd := Len(::aPages[::nActive, 1]:aControls)
      ENDIF
   ENDIF

RETURN ::nActive

//-------------------------------------------------------------------------------------------------------------------//

METHOD DeletePage(nPage) CLASS HTab
   IF ::lResourceTab
      ADel(::m_arrayStatusTab, nPage,, .T.)
      DeleteTab(::handle, nPage)
      ::nActive := nPage - 1

   ELSE
      DeleteTab(::handle, nPage - 1)

      ADel(::aPages, nPage)
      ADel(::Pages, nPage)
      ASize(::aPages, Len(::aPages) - 1)
      ASize(::Pages, Len(::Pages) - 1)

      IF nPage > 1
         ::nActive := nPage - 1
         ::SetTab(::nActive)
      ELSEIF Len(::aPages) > 0
         ::nActive := 1
         ::SetTab(1)
      ENDIF
   ENDIF

RETURN ::nActive

//-------------------------------------------------------------------------------------------------------------------//

METHOD Notify(lParam) CLASS HTab
   
   LOCAL nCode := hwg_GetNotifyCode(lParam)
   LOCAL nkeyDown := GetNotifyKeydown(lParam)
   LOCAL nPage := hwg_SendMessage(::handle, TCM_GETCURSEL, 0, 0) + 1

   IF hwg_BitAnd(::Style, TCS_BUTTONS) != 0
      nPage := hwg_SendMessage(::handle, TCM_GETCURFOCUS, 0, 0) + 1
   ENDIF
   IF nPage == 0 .OR. ::handle != hwg_GetFocus()
      IF nCode == TCN_SELCHANGE .AND. ::handle != hwg_GetFocus() .AND. ::lClick
         hwg_SendMessage(::handle, TCM_SETCURSEL, hwg_SendMessage(::handle, ::nPrevPage - 1, 0, 0), 0)
         RETURN 0
      ELSEIF nCode == TCN_SELCHANGE
         hwg_SendMessage(::handle, TCM_SETCURSEL, hwg_SendMessage(::handle, TCM_GETCURFOCUS, 0, 0), 0)
      ENDIF
      ::nPrevPage := nPage
      RETURN 0
   ENDIF

   DO CASE
   CASE nCode == TCN_CLICK
      ::lClick := .T.

   CASE nCode == TCN_KEYDOWN   // -500
      IF (nPage := SetTabFocus(Self, nPage, nKeyDown)) != nPage
         ::nActive := nPage
      ENDIF
   CASE nCode == TCN_FOCUSCHANGE  //-554

   CASE nCode == TCN_SELCHANGE
         // ACTIVATE NEW PAGE
        IF !::pages[nPage]:enabled
           //::SetTab(::nActive)
                   ::lClick := .F.
                   ::nPrevPage := nPage
               RETURN 0
            ENDIF
            IF nPage == ::nPrevPage
            RETURN 0
        ENDIF
              //IF hwg_GetFocus() != ::handle
            //   ::SETFOCUS()
            //ENDIF
        IF hb_IsBlock(::bChange)
           ::oparent:lSuspendMsgsHandling := .T.
           Eval(::bChange, Self, GetCurrentTab(::handle))
           IF hb_IsBlock(::bGetFocus) .AND. nPage != ::nPrevPage .AND. ::Pages[nPage]:Enabled .AND. ::nActivate > 0
              Eval(::bGetFocus, GetCurrentTab(::handle), Self)
              ::nActivate := 0
           ENDIF
           ::oparent:lSuspendMsgsHandling := .F.
        ENDIF
   CASE nCode == TCN_SELCHANGING .AND. ::nPrevPage > 0
        // DEACTIVATE PAGE //ocorre antes de trocar o focu
        ::nPrevPage := ::nActive //npage
        IF hb_IsBlock(::bLostFocus)
           ::oparent:lSuspendMsgsHandling := .T.
           Eval(::bLostFocus, ::nPrevPage, Self)
           ::oparent:lSuspendMsgsHandling := .F.
        ENDIF
   CASE nCode == TCN_SELCHANGING   //-552
      ::nPrevPage := nPage
      RETURN 0
     /*
   CASE nCode == TCN_CLICK
      IF !Empty(::pages) .AND. ::nActive > 0 .AND. ::pages[::nActive]:enabled
         hwg_SetFocus(::handle)
         IF hb_IsBlock(::bAction)
            Eval(::bAction, Self, GetCurrentTab(::handle))
         ENDIF
      ENDIF
   */
   CASE nCode == TCN_RCLICK
      IF !Empty(::pages) .AND. ::nActive > 0 .AND. ::pages[::nActive]:enabled
          IF hb_IsBlock(::bRClick)
              ::oparent:lSuspendMsgsHandling := .T.
              Eval(::bRClick, Self, GetCurrentTab(::handle))
              ::oparent:lSuspendMsgsHandling := .F.
          ENDIF
      ENDIF

   CASE nCode == TCN_SETFOCUS
      IF hb_IsBlock(::bGetFocus) .AND. !::Pages[nPage]:Enabled
         Eval(::bGetFocus, GetCurrentTab(::handle), Self)
      ENDIF
   CASE nCode == TCN_KILLFOCUS
      IF hb_IsBlock(::bLostFocus)
         Eval(::bLostFocus, GetCurrentTab(::handle), Self)
      ENDIF

   ENDCASE
   IF (nCode == TCN_CLICK .AND. ::nPrevPage > 0 .AND. ::pages[::nPrevPage]:enabled) .OR. ;
        (::lClick .AND. nCode == TCN_SELCHANGE)
       ::oparent:lSuspendMsgsHandling := .T.
       IF hb_IsBlock(::bAction) .AND. ::lClick
          Eval(::bAction, Self, GetCurrentTab(::handle))
       ENDIF
       ::oparent:lSuspendMsgsHandling := .F.
       ::lClick := .F.
   ENDIF

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference
METHOD OnEvent(msg, wParam, lParam) CLASS HTab

   LOCAL oCtrl

   IF (msg >= TCM_FIRST .AND. msg < TCM_FIRST + 61)  // optimized only
       RETURN -1
   ENDIF

   IF msg == WM_LBUTTONDOWN
      IF ::ShowDisablePage(lParam, WM_LBUTTONDOWN) == 0
          RETURN 0
      ENDIF
      ::lClick := .T.
      ::SetFocus(0)
      RETURN -1
   ELSEIF msg == WM_MOUSEMOVE //.OR. (::nPaintHeight == 0 .AND. msg == WM_NCHITTEST)
      ::ShowToolTips(lParam)
      RETURN ::ShowDisablePage(lParam)
   ELSEIF msg == WM_PAINT
      RETURN - 1
   ELSEIF msg == WM_ERASEBKGND
      ::ShowDisablePage()
      RETURN - 1
   ELSEIF msg == WM_PRINTCLIENT .OR. msg == WM_NCHITTEST .OR. msg == WM_UPDATEUISTATE
      RETURN -1  // painted objects without METHOD PAINT

   ELSEIF msg == WM_PRINT
      //-AEval(::Pages, {|p, i|p:aItemPos := TabItemPos(::oParent:handle, i - 1)})
      //- ::SetPaintSizePos(-1)
      ::SetPaintSizePos(IIf(::nPaintHeight > 1, -1, 1))
      IF ::nActive > 0
         ::ShowPage(::nActive)
         IF hwg_SendMessage(::handle, TCM_GETROWCOUNT, 0, 0) > 1
            hwg_InvalidateRect(::handle, 0, 1, ::Pages[1]:aItemPos[2], ::nWidth - 1, ::Pages[1]:aItemPos[4] * hwg_SendMessage(::handle, TCM_GETROWCOUNT, 0, 0))
         ENDIF
      ENDIF

   ELSEIF msg == WM_SIZE
      AEval(::Pages, {|p, i|p:aItemPos := TabItemPos(::handle, i - 1)})
      ::oPaint:nHeight := ::nPaintHeight
      ::oPaint:Anchor := IIf(::nPaintHeight > 1, 15, 0)
      IF ::nPaintHeight > 1
         hwg_PostMessage(::handle, WM_PRINT, hwg_GetDC(::handle), PRF_CHECKVISIBLE)
      ENDIF

   ELSEIF msg == WM_SETFONT .AND. ::oFont != NIL .AND. ::lInit
      hwg_SendMessage(::handle, WM_PRINT, hwg_GetDC(::handle), PRF_CHECKVISIBLE) //+ PRF_ERASEBKGND) //PRF_CLIENT + PRF_CHILDREN + PRF_OWNED)

   ELSEIF msg == WM_KEYDOWN .AND. hwg_GetFocus()= ::handle //.OR. (msg == WM_GETDLGCODE .AND. wparam == VK_RETURN))
       IF ProcKeyList(Self, wParam)
          RETURN - 1
       ELSEIF wParam == VK_ESCAPE
         RETURN 0
       ENDIF
       IF wParam == VK_RIGHT .OR. wParam == VK_LEFT
          IF SetTabFocus(Self, ::nActive, wParam) == ::nActive
             RETURN 0
          ENDIF
       ELSEIF (wparam == VK_DOWN .OR. wparam == VK_RETURN) .AND. ::nActive > 0  //
           GetSkip(Self, ::handle, , 1)
           RETURN 0
       ELSEIF wParam == VK_TAB
           GetSkip(::oParent, ::handle, , iif(IsCtrlShift(.F., .T.), -1, 1))
           RETURN 0
       ELSEIF wparam == VK_UP .AND. ::nActive > 0  //
          GetSkip(::oParent, ::handle, , -1)
          RETURN 0
       ENDIF
   ELSEIF msg == WM_HSCROLL .OR. msg == WM_VSCROLL //.AND. ::FINDCONTROL(, hwg_GetFocus()):classname = "HUPDO"
       IF hwg_GetFocus() == ::handle
          hwg_InvalidateRect(::oPaint:handle, 1, 0, 0, ::nwidth, 30) //::TabHeightSize + 2)
       ENDIF
       IF ::GetParentForm(self):Type < WND_DLG_RESOURCE
          RETURN ::oParent:onEvent(msg, wparam, lparam)
       ELSE
          RETURN ::super:onevent(msg, wparam, lparam)
       ENDIF
   ELSEIF msg == WM_GETDLGCODE
      IF wparam == VK_RETURN .OR. wParam == VK_ESCAPE .AND. ;
           ((oCtrl := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled())
         RETURN DLGC_WANTMESSAGE
      ENDIF
   ENDIF
     IF msg == WM_NOTIFY .AND. hwg_IsWindowVisible(::oParent:handle) .AND. ::nActivate == NIL
      IF hb_IsBlock(::bGetFocus)
          ::oParent:lSuspendMsgsHandling := .T.
          Eval(::bGetFocus, Self, GetCurrentTab(::handle))
          ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
   ELSEIF (hwg_IsWindowVisible(::handle) .AND. ::nActivate == NIL) .OR. msg == WM_KILLFOCUS
      ::nActivate := hwg_GetFocus()
   ENDIF

   IF hb_IsBlock(::bOther)
      ::oparent:lSuspendMsgsHandling := .T.
      IF Eval(::bOther, Self, msg, wParam, lParam) != - 1
        //RETURN 0
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF
   IF !((msg == WM_COMMAND .OR. msg == WM_NOTIFY) .AND. ::oParent:lSuspendMsgsHandling .AND. ::lSuspendMsgsHandling)
      IF msg == WM_NCPAINT .AND. ::GetParentForm():nInitFocus > 0 .AND. PtrtouLong(hwg_GetParent(::GetParentForm():nInitFocus)) == PtrtouLong(::handle)
          GetSkip(::oParent, ::GetParentForm():nInitFocus, , 0)
          ::GetParentForm():nInitFocus := 0
      ENDIF
      IF msg == WM_KILLFOCUS .AND. ::GetParentForm() != NIL .AND. ::GetParentForm():Type < WND_DLG_RESOURCE
          hwg_SendMessage(::oParent:handle, WM_COMMAND, makewparam(::id, 0), ::handle)
          ::nPrevPage := 0
      ENDIF
      IF msg == WM_DRAWITEM
         ::ShowDisablePage()
      ENDIF
      RETURN ::Super:onEvent(msg, wparam, lparam)
   ENDIF

RETURN -1
#else
METHOD OnEvent(msg, wParam, lParam) CLASS HTab

   LOCAL oCtrl

   IF msg >= TCM_FIRST .AND. msg < TCM_FIRST + 61 // optimized only
       RETURN -1
   ENDIF

   SWITCH msg

   CASE WM_LBUTTONDOWN
      IF ::ShowDisablePage(lParam, WM_LBUTTONDOWN) == 0
         RETURN 0
      ENDIF
      ::lClick := .T.
      ::SetFocus(0)
      RETURN -1

   CASE WM_MOUSEMOVE
      //.OR. (::nPaintHeight == 0 .AND. msg == WM_NCHITTEST)
      ::ShowToolTips(lParam)
      RETURN ::ShowDisablePage(lParam)

   CASE WM_PAINT
      RETURN -1

   CASE WM_ERASEBKGND
      ::ShowDisablePage()
      RETURN -1

   CASE WM_PRINTCLIENT
   CASE WM_NCHITTEST
   CASE WM_UPDATEUISTATE
      RETURN -1 // painted objects without METHOD PAINT

   CASE WM_PRINT
      //-AEval(::Pages, {|p, i|p:aItemPos := TabItemPos(::oParent:handle, i - 1)})
      //- ::SetPaintSizePos(-1)
      ::SetPaintSizePos(IIf(::nPaintHeight > 1, -1, 1))
      IF ::nActive > 0
         ::ShowPage(::nActive)
         IF hwg_SendMessage(::handle, TCM_GETROWCOUNT, 0, 0) > 1
            hwg_InvalidateRect(::handle, 0, 1, ::Pages[1]:aItemPos[2], ::nWidth - 1, ;
               ::Pages[1]:aItemPos[4] * hwg_SendMessage(::handle, TCM_GETROWCOUNT, 0, 0))
         ENDIF
      ENDIF
      EXIT

   CASE WM_SIZE
      AEval(::Pages, {|p, i|p:aItemPos := TabItemPos(::handle, i - 1)})
      ::oPaint:nHeight := ::nPaintHeight
      ::oPaint:Anchor := IIf(::nPaintHeight > 1, 15, 0)
      IF ::nPaintHeight > 1
         hwg_PostMessage(::handle, WM_PRINT, hwg_GetDC(::handle), PRF_CHECKVISIBLE)
      ENDIF
      EXIT

   CASE WM_SETFONT
      IF ::oFont != NIL .AND. ::lInit
         hwg_SendMessage(::handle, WM_PRINT, hwg_GetDC(::handle), PRF_CHECKVISIBLE) //+ PRF_ERASEBKGND) //PRF_CLIENT + PRF_CHILDREN + PRF_OWNED)
      ENDIF
      EXIT

   CASE WM_KEYDOWN
      IF hwg_GetFocus() == ::handle //.OR. (msg == WM_GETDLGCODE .AND. wparam == VK_RETURN))
         IF ProcKeyList(Self, wParam)
            RETURN -1
         ELSEIF wParam == VK_ESCAPE
            RETURN 0
         ENDIF
         IF wParam == VK_RIGHT .OR. wParam == VK_LEFT
            IF SetTabFocus(Self, ::nActive, wParam) == ::nActive
               RETURN 0
            ENDIF
         ELSEIF (wparam == VK_DOWN .OR. wparam == VK_RETURN) .AND. ::nActive > 0
            GetSkip(Self, ::handle, , 1)
            RETURN 0
         ELSEIF wParam == VK_TAB
            GetSkip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ELSEIF wparam == VK_UP .AND. ::nActive > 0
            GetSkip(::oParent, ::handle, , -1)
            RETURN 0
         ENDIF
      ENDIF
      EXIT

   CASE WM_HSCROLL
   CASE WM_VSCROLL
      //.AND. ::FINDCONTROL(, hwg_GetFocus()):classname = "HUPDO"
      IF hwg_GetFocus() == ::handle
          hwg_InvalidateRect(::oPaint:handle, 1, 0, 0, ::nwidth, 30) //::TabHeightSize + 2)
      ENDIF
      IF ::GetParentForm(self):Type < WND_DLG_RESOURCE
         RETURN ::oParent:OnEvent(msg, wparam, lparam)
      ELSE
          RETURN ::super:OnEvent(msg, wparam, lparam)
      ENDIF
      EXIT

   CASE WM_GETDLGCODE
      IF wparam == VK_RETURN .OR. wParam == VK_ESCAPE .AND. ;
         ((oCtrl := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oCtrl:IsEnabled())
         RETURN DLGC_WANTMESSAGE
      ENDIF

   ENDSWITCH

   IF msg == WM_NOTIFY .AND. hwg_IsWindowVisible(::oParent:handle) .AND. ::nActivate == NIL
      IF hb_IsBlock(::bGetFocus)
         ::oParent:lSuspendMsgsHandling := .T.
         Eval(::bGetFocus, Self, GetCurrentTab(::handle))
         ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
   ELSEIF (hwg_IsWindowVisible(::handle) .AND. ::nActivate == NIL) .OR. msg == WM_KILLFOCUS
      ::nActivate := hwg_GetFocus()
   ENDIF

   IF hb_IsBlock(::bOther)
      ::oparent:lSuspendMsgsHandling := .T.
      IF Eval(::bOther, Self, msg, wParam, lParam) != -1
        //RETURN 0
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
   ENDIF

   IF !((msg == WM_COMMAND .OR. msg == WM_NOTIFY) .AND. ::oParent:lSuspendMsgsHandling .AND. ::lSuspendMsgsHandling)
      IF msg == WM_NCPAINT .AND. ::GetParentForm():nInitFocus > 0 .AND. ;
         PtrtouLong(hwg_GetParent(::GetParentForm():nInitFocus)) == PtrtouLong(::handle)
         GetSkip(::oParent, ::GetParentForm():nInitFocus, , 0)
         ::GetParentForm():nInitFocus := 0
      ENDIF
      IF msg == WM_KILLFOCUS .AND. ::GetParentForm() != NIL .AND. ::GetParentForm():Type < WND_DLG_RESOURCE
         hwg_SendMessage(::oParent:handle, WM_COMMAND, makewparam(::id, 0), ::handle)
         ::nPrevPage := 0
      ENDIF
      IF msg == WM_DRAWITEM
         ::ShowDisablePage()
      ENDIF
      RETURN ::Super:onEvent(msg, wparam, lparam)
   ENDIF

RETURN -1
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD ShowDisablePage(nPageEnable, nEvent) CLASS HTab

   LOCAL client_rect
   LOCAL i
   LOCAL pt := {,}

   DEFAULT nPageEnable := 0
   IF !hwg_IsWindowVisible(::handle) .OR. (AScan(::Pages, {|p|!p:lEnabled}) == 0 .AND. nPageEnable == NIL)
      RETURN - 1
   ENDIF
   nPageEnable := IIf(nPageEnable == NIL, 0, nPageEnable)
   nEvent := IIf(nEvent == NIL, 0, nEvent)
   IF PtrtoUlong(nPageEnable) > 128
      pt[1] := hwg_LOWORD(nPageEnable)
      pt[2] := hwg_HIWORD(nPageEnable)
   ENDIF
   FOR i := 1 TO Len(::Pages)
      IF !::pages[i]:enabled .OR. i == PtrtoUlong(nPageEnable)
         //client_rect := ::Pages[i]:aItemPos
         client_rect := TabItemPos(::handle, i - 1)
         IF (PtInRect(client_rect, pt)) .AND. i != nPageEnable
            RETURN 0
         ENDIF
         ::oPaint:ShowTextTabs(::pages[i], client_rect)
      ENDIF
   NEXT

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

METHOD ShowToolTips(lParam) CLASS HTab
   
   LOCAL i
   LOCAL pt := {,}
   LOCAL client_rect

   IF AScan(::Pages, {|p|p:ToolTip != NIL}) == 0
       RETURN NIL
   ENDIF
   pt[1] := hwg_LOWORD(lParam)
   pt[2] := hwg_HIWORD(lParam)

   FOR i := 1 TO Len(::Pages)
      client_rect := ::Pages[i]:aItemPos
      IF (PtInRect(client_rect, pt))
         ::SetToolTip(IIf(::Pages[i]:Tooltip == NIL, "", ::Pages[i]:Tooltip))
         EXIT
      ENDIF
   NEXT

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

STATIC Function SetTabFocus(oCtrl, nPage, nKeyDown)
   
   LOCAL i
   LOCAL nSkip
   LOCAL nStart
   LOCAL nEnd
   LOCAL nPageAcel

   IF nKeyDown == VK_LEFT .OR. nKeyDown == VK_RIGHT  // 37,39
     nEnd := IIf(nKeyDown == VK_LEFT, 1, Len(oCtrl:aPages))
     nSkip := IIf(nKeyDown == VK_LEFT, -1, 1)
     nStart := nPage + nSkip
     FOR i := nStart TO nEnd STEP nSkip
         IF oCtrl:pages[i]:enabled
            IF (nSkip > 0 .AND. i > nStart) .OR. (nSkip < 0 .AND. i < nStart)
               hwg_SendMessage(oCtrl:handle, TCM_SETCURFOCUS, i - nSkip - 1, 0) // BOTOES
            ENDIF
            RETURN i
         ELSEIF i == nEnd
            IF oCtrl:pages[i - nSkip]:enabled
             hwg_SendMessage(oCtrl:handle, TCM_SETCURFOCUS, i - (nSkip * 2) - 1, 0) // BOTOES
             RETURN (i - nSkip)
          ENDIF
            RETURN nPage
         ENDIF
       NEXT
     ELSE
      nPageAcel := FindTabAccelerator(oCtrl, nKeyDown)
      IF nPageAcel == 0
         hwg_MsgBeep()
      ENDIF
   ENDIF

RETURN nPage

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION FindTabAccelerator(oPage, nKey)
  
   LOCAL i
   LOCAL pos
   LOCAL cKey

  cKey := Upper(Chr(nKey))
  FOR i := 1 TO Len(oPage:aPages)
     IF (pos := At("&", oPage:Pages[i]:caption)) > 0 .AND. cKey == Upper(SubStr(oPage:Pages[i]:caption, ++pos, 1))
        IF oPage:pages[i]:Enabled
            hwg_SendMessage(oPage:handle, TCM_SETCURFOCUS, i - 1, 0)
        ENDIF
        RETURN  i
     ENDIF
  NEXT

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//
// new class to PAINT Pages
//-------------------------------------------------------------------------------------------------------------------//

CLASS HPaintTab INHERIT HControl

   CLASS VAR winclass INIT "STATIC"

   DATA hDC
   METHOD New(oWndParent, nId, nLeft, nTop, nWidth, nHeight, tColor, bColor)
   METHOD Activate()
   METHOD Paint(lpDis)
   METHOD showTextTabs(oPage, aItemPos)
   METHOD Refresh() VIRTUAL

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, nLeft, nTop, nWidth, nHeight, tcolor, bColor) CLASS HPaintTab

   ::bPaint := {|o, p|o:paint(p)}
   ::Super:New(oWndParent, nId, SS_OWNERDRAW + WS_DISABLED, nLeft, nTop, nWidth, nHeight, , ;
              , , ::bPaint, , tcolor, bColor)
   ::anchor := 15
   ::brush := NIL
   ::backstyle := TRANSPARENT
   ::Name := "PaintTab"

   ::Activate()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS HPaintTab

   IF !Empty(::oParent:handle)
      ::handle := CreateStatic(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Paint(lpdis) CLASS HPaintTab

   LOCAL drawInfo := hwg_GetDrawItemInfo(lpdis)
   LOCAL hDC := drawInfo[3]
   LOCAL x1 := drawInfo[4]
   LOCAL y1 := drawInfo[5]
   LOCAL x2 := drawInfo[6]
   LOCAL y2 := drawInfo[7]
   LOCAL i
   LOCAL client_rect
   LOCAL nPage
   LOCAL oPage

   IF Len(::oParent:Pages) == 0
      RETURN 0
   ENDIF

   nPage := hwg_SendMessage(::oParent:handle, TCM_GETCURFOCUS, 0, 0) + 1
   oPage := IIf(nPage > 0, ::oParent:Pages[nPage], ::oParent:Pages[1])

   ::disablebrush := oPage:brush
   IF oPage:brush != NIL
      IF ::oParent:nPaintHeight < ::oParent:TabHeightSize //40
        ::nHeight := 1
        ::move(, , , ::nHeight)
      ELSEIF oPage:brush != NIL
        FillRect(hDC, x1 + 1, y1 + 2, x2 - 1, y2 - 0, oPage:brush:handle) //obrush)
        ::oParent:RedrawControls()
      ENDIF
   ENDIF

   ::hDC := hwg_GetDC(::oParent:handle)
   FOR i := 1 TO Len(::oParent:Pages)
      oPage := ::oParent:Pages[i]
      client_rect := TabItemPos(::oParent:handle, i - 1)
      oPage:aItemPos := client_rect
      IF oPage:brush != NIL //.AND. client_rect[4] - client_rect[2] > 5
         //SetBkMode(hDC, TRANSPARENT)
         IF nPage == oPage:PageOrder
            FillRect(::hDC, client_rect[1], client_rect[2] + 1, client_rect[3], client_rect[4] + 2, oPage:brush:handle)
            IF hwg_GetFocus() == oPage:oParent:handle
               InflateRect(@client_rect, - 2, - 2)
               DrawFocusRect(::hDC, client_rect)
            endif
         ELSE
            FillRect(::hDC, client_rect[1] + IIf(i == nPage + 1, 2, 1), ;
                             client_rect[2] + 1, ;
                             client_rect[3] - IIf(i == nPage - 1, 3, 2) - IIf(i == Len(::oParent:Pages), 1, 0), ;
                             client_rect[4] - 1, oPage:brush:handle)
         ENDIF
      ENDIF
      IF oPage:brush != NIL .OR. oPage:tColor != NIL .OR. !oPage:lenabled
         ::showTextTabs(oPage, client_rect)
      ENDIF
   NEXT

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

METHOD showTextTabs(oPage, aItemPos) CLASS HPaintTab

    LOCAL nStyle
    LOCAL BmpSize := 0
    LOCAL size := 0
    LOCAL aTxtSize
    LOCAL aItemRect
    LOCAL nActive := oPage:oParent:GetActivePage()
    LOCAL hTheme

    //nStyle := SS_CENTER + IIf(hwg_BitAnd(oPage:oParent:Style, TCS_FIXEDWIDTH) != 0, ;
    //                          SS_RIGHTJUST, DT_VCENTER + DT_SINGLELINE)
    AEval(oPage:oParent:Pages, {|p|size += p:aItemPos[3] - p:aItemPos[1]})
    nStyle := SS_CENTER + DT_VCENTER + DT_SINGLELINE + DT_END_ELLIPSIS

    ::hDC := IIf(::hDC == NIL, hwg_GetDC(::oParent:handle), ::hDC)
    IF (ISTHEMEDLOAD())
       hTheme := NIL
       IF ::WindowsManifest
           hTheme := hb_OpenThemeData(::oParent:handle, "TAB")
       ENDIF
       hTheme := IIf(Empty(hTheme), NIL, hTheme)
    ENDIF
    SetBkMode(::hDC, TRANSPARENT)
    IF oPage:oParent:oFont != NIL
       hwg_SelectObject(::hDC, oPage:oParent:oFont:handle)
    ENDIF
    IF oPage:lEnabled
       SetTextColor(::hDC, IIf(Empty(oPage:tColor), GetSysColor(COLOR_WINDOWTEXT), oPage:tColor))
    ELSE
         //SetTextColor(::hDC, GetSysColor(COLOR_GRAYTEXT))
         SetTextColor(::hDC, GetSysColor(COLOR_BTNHIGHLIGHT))
    ENDIF
    aTxtSize := TxtRect(oPage:caption, oPage:oParent)
    IF oPage:oParent:himl != NIL
        BmpSize := ((aItemPos[3] - aItemPos[1]) - (oPage:oParent:aBmpSize[1] + aTxtSize[1])) / 2
        BmpSize += oPage:oParent:aBmpSize[1]
        BmpSize := MAX(BmpSize, oPage:oParent:aBmpSize[1])
    ENDIF
    aItemPos[3] := IIf(size > oPage:oParent:nWidth .AND. aItemPos[1] + BmpSize + aTxtSize[1] > oPage:oParent:nWidth - 44, oPage:oParent:nWidth - 44, aItemPos[3])
    aItemRect := {aItemPos[1] + IIf(oPage:PageOrder == nActive + 1, 1, 0), aItemPos[2], aItemPos[3] - IIf(oPage:PageOrder == Len(oPage:oParent:Pages), 2, IIf(oPage:PageOrder == nActive - 1, 1, 0)), aItemPos[4] - 1}
    IF hwg_BitAnd(oPage:oParent:Style, TCS_BOTTOM) == 0
       IF hTheme != NIL .AND. oPage:brush == NIL
          hb_DrawThemeBackground(hTheme, ::hDC, BP_PUSHBUTTON, 0, aItemRect, NIL)
       ELSE
          FillRect(::hDC, aItemPos[1] + BmpSize + 3, aItemPos[2] + 4, aItemPos[3] - 3, aItemPos[4] - 5, ;
                   IIf(oPage:brush != NIL, oPage:brush:handle, GetStockObject(NULL_BRUSH)))
       ENDIF
       IF nActive == oPage:PageOrder                       // 4
          DrawText(::hDC, oPage:caption, aItemPos[1] + BmpSize - 1, aItemPos[2] - 1, aItemPos[3], aItemPos[4] - 1, nstyle)
       ELSE
          IF oPage:lEnabled == .F.
             DrawText(::hDC, oPage:caption, aItemPos[1] + BmpSize - 1, aItemPos[2] + 1, aItemPos[3] + 1, aItemPos[4] + 1, nstyle)
             SetTextColor(::hDC, GetSysColor(COLOR_GRAYTEXT))
          ENDIF
          DrawText(::hDC, oPage:caption, aItemPos[1] + BmpSize - 1, aItemPos[2] + 1, aItemPos[3] + 1, aItemPos[4] + 1, nstyle)
       ENDIF
    ELSE
       IF hTheme != NIL .AND. oPage:brush == NIL
          hb_DrawThemeBackground(hTheme, ::hDC, BP_PUSHBUTTON, 0, aItemRect, NIL)
       ELSE
          FillRect(::hDC, aItemPos[1] + 3, aItemPos[2] + 3, aItemPos[3] - 4, aItemPos[4] - 5, IIf(oPage:brush != NIL, oPage:brush:handle, GetStockObject(NULL_BRUSH))) // oPage:oParent:brush:handle))
       ENDIF
       IF nActive == oPage:PageOrder                       // 4
          DrawText(::hDC, oPage:caption, aItemPos[1], aItemPos[2] + 2, aItemPos[3], aItemPos[4] + 2, nstyle)
       ELSE
          IF oPage:lEnabled == .F.
             DrawText(::hDC, oPage:caption, aItemPos[1] + 1, aItemPos[2] + 1, aItemPos[3] + 1, aItemPos[4] + 1, nstyle)
             SetTextColor(::hDC, GetSysColor(COLOR_GRAYTEXT))
          ENDIF
          DrawText(::hDC, oPage:caption, aItemPos[1], aItemPos[2], aItemPos[3], aItemPos[4], nstyle)
       ENDIF
    ENDIF
    IF oPage:lEnabled .AND. oPage:brush == NIL
        hwg_InvalidateRect(::oParent:handle, 0, aItemPos[1], aItemPos[2], aItemPos[1] + aItemPos[3], aItemPos[2] + aItemPos[4])
    ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//
