//
// $Id: htool.prg 1901 2012-09-19 23:12:50Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HToolBar class
//
// Copyright 2004 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
// www - http://sites.uol.com.br/culikr/
//

#include "windows.ch"
#include "inkey.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#DEFINE IDTOOLBAR 700
#DEFINE IDMAXBUTTONTOOLBAR 64

//-------------------------------------------------------------------------------------------------------------------//

CLASS HToolBar INHERIT HControl

   DATA winclass INIT "ToolbarWindow32"
   DATA TEXT
   DATA id
   DATA nTop
   DATA nLeft
   DATA nwidth
   DATA nheight
   CLASSDATA oSelected INIT NIL
   DATA State INIT 0
   DATA ExStyle
   DATA bClick
   DATA cTooltip
   DATA lPress INIT .F.
   DATA lFlat
   DATA lTransp INIT .F.
   DATA lVertical INIT .F.
   DATA lCreate INIT .F. HIDDEN
   DATA lResource INIT .F. HIDDEN
   DATA nOrder
   DATA BtnWidth
   DATA BtnHeight
   DATA nIDB
   DATA aButtons INIT {}
   DATA aSeparators INIT {}
   Data aItem INIT {}
   DATA Line
   DATA nIndent
   DATA nwSize
   DATA nHSize
   DATA nDrop

   METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, btnWidth, oFont, bInit, bSize, bPaint, ctooltip, ;
      tcolor, bcolor, lTransp, lVertical, aItem, nWSize, nHSize, nIndent, nIDB)
   METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem)
   METHOD Activate()
   METHOD INIT()
   METHOD CreateTool()
   METHOD AddButton(nBitIp, nId, bState, bStyle, cText, bClick, c, aMenu, cName, nIndex)
   METHOD Notify(lParam)
   METHOD EnableButton(idButton, lEnable) INLINE hwg_SendMessage(::handle, TB_ENABLEBUTTON, INT(idButton), ;
      MAKELONG(IIf(lEnable, 1, 0), 0))
   METHOD ShowButton(idButton) INLINE hwg_SendMessage(::handle, TB_HIDEBUTTON, INT(idButton), MAKELONG(0, 0))
   METHOD HideButton(idButton) INLINE hwg_SendMessage(::handle, TB_HIDEBUTTON, INT(idButton), MAKELONG(1, 0))
   METHOD REFRESH() VIRTUAL
   METHOD RESIZE(xIncrSize, lWidth, lHeight)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, btnWidth, oFont, bInit, bSize, bPaint, ctooltip, ;
   tcolor, bcolor, lTransp, lVertical, aItem, nWSize, nHSize, nIndent, nIDB) CLASS hToolBar

   //HB_SYMBOL_UNUSED(cCaption)
   //HB_SYMBOL_UNUSED(lTransp)

   DEFAULT aitem TO {}

   //nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), TBSTYLE_FLAT)
   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), IIf(hwg_BitAnd(nStyle, WS_DLGFRAME + WS_BORDER) > 0, ;
      CCS_NODIVIDER, 0))
   nHeight += IIf(hwg_BitAnd(nStyle, WS_DLGFRAME + WS_BORDER) > 0, 1, 0)
   nWidth -= IIf(hwg_BitAnd(nStyle, WS_DLGFRAME + WS_BORDER) > 0, 2, 0)

   ::lTransp := IIf(lTransp != NIL, lTransp, .F.)
   ::lVertical := IIf(lVertical != NIL .AND. hb_IsLogical(lVertical), lVertical, ::lVertical)
   IF ::lTransp .OR. ::lVertical
      nStyle += IIf(::lTransp, TBSTYLE_TRANSPARENT, IIf(::lVertical, CCS_VERT, 0))
   ENDIF

   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, bSize, bPaint, ctooltip, tcolor, ;
      bcolor)

   ::BtnWidth := BtnWidth //!= NIL, BtnWidth, 32)
   ::nIDB := nIDB
   ::aItem := aItem
   ::nIndent := IIf(nIndent != NIL, nIndent, 1)
   ::nwSize := IIf(nwSize != NIL .AND. nwSize > 11, nwSize, 16)
   ::nhSize := IIf(nhSize != NIL .AND. nhSize > 11, nhSize, ::nwSize - 1)
   ::lnoThemes := !ISTHEMEACTIVE() .OR. !::WindowsManifest
   IF hwg_BitAnd(::Style, WS_DLGFRAME + WS_BORDER + CCS_NODIVIDER) == 0
      IF !::lVertical
         ::Line := HLine():New(oWndParent, , , nLeft, nTop + nHeight + ;
            IIf(::lnoThemes .AND. hwg_BitAnd(nStyle, TBSTYLE_FLAT) > 0, 2, 1), nWidth)
      ELSE
         ::Line := HLine():New(oWndParent, , ::lVertical, nLeft + nWidth + 1, nTop, nHeight)
      ENDIF
   ENDIF
   IF __ObjHasMsg(::oParent, "AOFFSET") .AND. ::oParent:type == WND_MDI .AND. ;
      ::oParent:aOffset[2] + ::oParent:aOffset[3] == 0
      IF ::nWidth > ::nHeight .OR. ::nWidth == 0
         ::oParent:aOffset[2] := ::nHeight
      ELSEIF ::nHeight > ::nWidth .OR. ::nHeight == 0
         IF ::nLeft == 0
            ::oParent:aOffset[1] += ::nWidth
         ELSE
            ::oParent:aOffset[3] += ::nWidth
         ENDIF
      ENDIF
   ENDIF

   ::extstyle := TBSTYLE_EX_MIXEDBUTTONS

   HWG_InitCommonControlsEx()

   ::Activate()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor, lTransp, aItem) ;
   CLASS hToolBar

   HB_SYMBOL_UNUSED(cCaption)
   HB_SYMBOL_UNUSED(lTransp)

   DEFAULT aItem TO {}
   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint, ctooltip, tcolor, bcolor)
   HWG_InitCommonControlsEx()
   ::aItem := aItem

   ::style := 0
   ::nLeft := 0
   ::nTop := 0
   ::nWidth := 0
   ::nHeight := 0
   ::nIndent := 1
   ::lResource := .T.

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Activate() CLASS hToolBar

   IF !Empty(::oParent:handle)
      ::lCreate := .T.
      ::handle := CREATETOOLBAR(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight, ::extStyle)
      ::Init()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD INIT() CLASS hToolBar

   IF !::lInit
      IF ::Line != NIL
         ::Line:Anchor := ::Anchor
      ENDIF
      ::Super:Init()
      ::CreateTool()
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD CREATETOOL() CLASS hToolBar

   LOCAL n
   LOCAL n1
   LOCAL aTemp
   LOCAL aButton :={}
   LOCAL aBmpSize
   LOCAL hIm
   LOCAL nPos
   LOCAL nMax := 0
   LOCAL hImage
   LOCAL img
   LOCAL nlistimg
   LOCAL ndrop := 0

   IF !::lResource
      IF Empty(::handle)
         RETURN NIL
      ENDIF
      IF !::lCreate
         hwg_DestroyWindow(::handle)
         ::Activate()
         //IF !Empty(::oFont)
         ::SetFont(::oFont)
         //ENDIF
      ENDIF
   ELSE
      FOR n := 1 TO Len(::aitem)
         ::AddButton(::aitem[n, 1], ::aitem[n, 2], ::aitem[n, 3], ::aitem[n, 4], ::aitem[n, 6], ::aitem[n, 7], ;
            ::aitem[n, 8], ::aitem[n, 9], , n)
         //::aItem[n, 11] := oButton
      NEXT
   ENDIF
   /*
   IF ::lVertical
      nStyle := hwg_SendMessage(::handle, TB_GETSTYLE, 0, 0) + CCS_VERT
      hwg_SendMessage(::handle, TB_SETSTYLE, 0, nStyle)
   ENDIF
   */
   nlistimg := 0
   IF ::nIDB != NIL .AND. ::nIDB >= 0
      nlistimg := TOOLBAR_LOADSTANDARTIMAGE(::handle, ::nIDB)
   ENDIF
   IF hwg_BitAnd(::Style, TBSTYLE_LIST) > 0 .AND. ::nwSize == NIL
      ::nwSize := MAX(16, (::nHeight - 16))
   ENDIF
   IF ::nwSize != NIL
      hwg_SendMessage(::handle, TB_SETBITMAPSIZE, 0, MAKELONG(::nwSize, ::nhSize))
   ENDIF

   FOR n := 1 TO Len(::aItem)
      IF hb_IsBlock(::aItem[n, 7])
         //::oParent:AddEvent(BN_CLICKED, ::aItem[n, 2], ::aItem[n, 7])
      ENDIF
      IF hb_IsArray(::aItem[n, 9])
         ::aItem[n, 10] := hwg__CreatePopupMenu()
         ::aItem[n, 11]:hMenu := ::aItem[n, 10]
         aTemp := ::aItem[n, 9]
         FOR n1 := 1 TO Len(aTemp)
            aTemp[n1, 1] := IIf(aTemp[n1, 1] = "-", NIL, aTemp[n1, 1])
            hwg__AddMenuItem(::aItem[n, 10], aTemp[n1, 1], -1, .F., aTemp[n1, 2], , .F.)
            ::oParent:AddEvent(BN_CLICKED, aTemp[n1, 2], aTemp[n1, 3])
         NEXT
      ENDIF
      IF ::aItem[n, 4] == BTNS_SEP
         LOOP
      ENDIF
      nDrop := Max(nDrop, IIf(hwg_Bitand(::aItem[n, 4], BTNS_WHOLEDROPDOWN) != 0, 0, ;
         IIf(hwg_Bitand(::aItem[n, 4], BTNS_DROPDOWN) != 0, 8, 0)))
      /*
      IF ::nSize != NIL
         hwg_SendMessage(::handle, TB_SETBITMAPSIZE, 0, MAKELONG(::nSize, ::nSize))
      ENDIF
      */
      IF hb_IsChar(::aItem[n, 1]) .OR. ::aItem[n, 1] > 1
         IF hb_IsChar(::aItem[n, 1]) .AND. At(".", ::aitem[n, 1]) != 0
            IF !File(::aitem[n, 1])
               LOOP
            ENDIF
            //AAdd(aButton, LoadImage(, ::aitem[n, 1], IMAGE_BITMAP, 0, 0, LR_DEFAULTSIZE + LR_CREATEDIBSECTION+ LR_LOADFROMFILE))
            hImage := HBITMAP():AddFile(::aitem[n, 1], , .T., ::nwSize, ::nhSize):handle
         ELSE
            // AAdd(aButton, HBitmap():AddResource(::aitem[n, 1]):handle)
            hImage := HBitmap():AddResource(::aitem[n, 1], LR_LOADTRANSPARENT + LR_LOADMAP3DCOLORS, , ::nwSize, ;
               ::nhSize):handle
         ENDIF
         IF (img := AScan(aButton, hImage)) == 0
            AAdd(aButton, hImage)
            img := Len(aButton)
         ENDIF
         ::aItem[n, 1] := img + nlistimg //n
         IF !::lResource
            TOOLBAR_LOADIMAGE(::handle, aButton[img])
         ENDIF
      ELSE
         /*
         IF ::aItem[n, 1] > 1
            hImage := HBitmap():AddResource(::aitem[n, 1], LR_LOADTRANSPARENT + LR_LOADMAP3DCOLORS, , ::nSize, ;
               ::nSize):handle
         ENDIF
         */
         //AAdd(aButton, LoadImage(, ::aitem[n, 1], IMAGE_BITMAP, 0, 0, LR_DEFAULTSIZE + LR_CREATEDIBSECTION))
         //hImage := HBitmap():AddResource(::aitem[n, 1], LR_LOADTRANSPARENT + LR_LOADMAP3DCOLORS + LR_SHARED, , ;
         //   ::nSize, ::nSize):handle
      ENDIF
   NEXT
   IF Len(aButton) > 0 //.AND. ::lResource
      aBmpSize := GetBitmapSize(aButton[1])
      /*
      nmax := aBmpSize[3]

      FOR n := 2 TO Len(aButton)
         aBmpSize := GetBitmapSize(aButton[n])
         nmax := Max(nmax, aBmpSize[3])
      NEXT
      aBmpSize := GetBitmapSize(aButton[1])

      IF nmax == 4
         hIm := CreateImageList({}, aBmpSize[1], aBmpSize[2], 1, ILC_COLOR4 + ILC_MASK)
      ELSEIF nmax == 8
         hIm := CreateImageList({}, aBmpSize[1], aBmpSize[2], 1, ILC_COLOR8 + ILC_MASK)
      ELSEIF nMax == 16
         hIm := CreateImageList({}, aBmpSize[1], aBmpSize[2], 1, ILC_COLORDDB + ILC_MASK)
      ELSEIF nmax == 24
         hIm := CreateImageList({}, aBmpSize[1], aBmpSize[2], 1, ILC_COLORDDB + ILC_MASK)
      ENDIF
      */
      hIm := CreateImageList({}, aBmpSize[1], aBmpSize[2], 1, ILC_COLORDDB + ILC_MASK)
      FOR nPos := 1 TO Len(aButton)
         //aBmpSize := GetBitmapSize(aButton[nPos])
         /*
         IF aBmpSize[3] == 24
            //Imagelist_AddMasked(hIm, aButton[nPos], RGB(236, 223, 216))
            Imagelist_Add(hIm, aButton[nPos])
         ELSE
            Imagelist_Add(hIm, aButton[nPos])
         ENDIF
         */
         Imagelist_Add(hIm, aButton[nPos])
      NEXT
      hwg_SendMessage(::handle, TB_SETIMAGELIST, 0, hIm)
   ELSEIF Len(aButton) == 0
      hwg_SendMessage(::handle, TB_SETBITMAPSIZE, 0, MAKELONG(0, 0))
      //hwg_SendMessage(::handle, TB_SETDRAWTEXTFLAGS, DT_CENTER + DT_VCENTER, DT_CENTER + DT_VCENTER)
   ENDIF
   hwg_SendMessage(::handle, TB_SETINDENT, ::nIndent, 0)
   IF !Empty(::BtnWidth)
      hwg_SendMessage(::handle, TB_SETBUTTONWIDTH, 0, MAKELPARAM(::BtnWidth - 1, ::BtnWidth + 1))
      //hwg_SendMessage(::handle, TB_SETBUTTONWIDTH, MAKELPARAM(::BtnWidth, ::BtnWidth))
   ENDIF
   IF Len(::aItem) > 0
      TOOLBARADDBUTTONS(::handle, ::aItem, Len(::aItem))
      hwg_SendMessage(::handle, TB_SETEXTENDEDSTYLE, 0, TBSTYLE_EX_DRAWDDARROWS)
   ENDIF
   IF ::BtnWidth != NIL
      IF hwg_BitAnd(::Style, CCS_NODIVIDER) > 0
         nMax := IIf(hwg_BitAnd(::Style, WS_DLGFRAME + WS_BORDER) > 0, 4, 2)
      ELSEIF hwg_BitAnd(::Style, TBSTYLE_FLAT) > 0
         nMax := 2
      ENDIF
      ::ndrop := nMax + IIf(!::WindowsManifest, 0, nDrop)
      ::BtnHeight := MAX(hwg_HIWORD(hwg_SendMessage(::handle, TB_GETBUTTONSIZE, 0, 0)), ;
         ::nHeight - ::nDrop - IIf(!::lnoThemes .AND. hwg_BitAnd(::Style, TBSTYLE_FLAT) > 0, 0, 2))
      IF !::lVertical
         hwg_SendMessage(::handle, TB_SETBUTTONSIZE, 0, MAKELPARAM(::BtnWidth, ::BtnHeight))
      ELSE
         hwg_SendMessage(::handle, TB_SETBUTTONSIZE, 0, MAKELPARAM(::nWidth - ::nDrop - 1, ::BtnWidth))
      ENDIF
   ENDIF
   ::BtnWidth := hwg_LOWORD(hwg_SendMessage(::handle, TB_GETBUTTONSIZE, 0, 0))
   /*
   IF ::lTransp
      nStyle := hwg_SendMessage(::handle, TB_GETSTYLE, 0, 0) + TBSTYLE_TRANSPARENT
      hwg_SendMessage(::handle, TB_SETSTYLE, 0, nStyle)
   ENDIF
   */

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD Notify(lParam) CLASS hToolBar

   LOCAL nCode := hwg_GetNotifyCode(lParam)
   LOCAL nId
   LOCAL nButton
   LOCAL nPos

   IF nCode == TTN_GETDISPINFO

      nButton := TOOLBAR_GETDISPINFOID(lParam)
      nPos := AScan(::aItem, {|x|x[2] == nButton})
      TOOLBAR_SETDISPINFO(lParam, ::aItem[nPos, 8])

   ELSEIF nCode == TBN_GETINFOTIP

      nId := TOOLBAR_GETINFOTIPID(lParam)
      nPos := AScan(::aItem, {|x|x[2] == nId})
      TOOLBAR_GETINFOTIP(lParam, ::aItem[nPos, 8])

   ELSEIF nCode == TBN_DROPDOWN

      nId := TOOLBAR_SUBMENUEXGETID(lParam)
      IF nId > 0 //hb_IsArray(::aItem[1, 9])
         //nid := TOOLBAR_SUBMENUEXGETID(lParam)
         nPos := AScan(::aItem, {|x|x[2] == nId})
         TOOLBAR_SUBMENUEx(lParam, ::aItem[nPos, 10], ::oParent:handle)
      ELSE
         TOOLBAR_SUBMENU(lParam, 1, ::oParent:handle)
      ENDIF

   ELSEIF nCode == NM_CLICK //.AND. ::GetParentForm():Type <= WND_MAIN

      nId := TOOLBAR_IDCLICK(lParam)
      nPos := AScan(::aItem, {|x|x[2] == nId})
      IF nPos > 0 .AND. ::aItem[nPos, 7] != NIL
         Eval(::aItem[nPos, 7], ::aItem[nPos, 11], nId)
      ENDIF

   ENDIF

RETURN 0
#else
METHOD Notify(lParam) CLASS hToolBar

   LOCAL nCode := hwg_GetNotifyCode(lParam)
   LOCAL nId
   LOCAL nButton
   LOCAL nPos

   SWITCH nCode

   CASE TTN_GETDISPINFO
      nButton := TOOLBAR_GETDISPINFOID(lParam)
      nPos := AScan(::aItem, {|x|x[2] == nButton})
      TOOLBAR_SETDISPINFO(lParam, ::aItem[nPos, 8])
      EXIT

   CASE TBN_GETINFOTIP
      nId := TOOLBAR_GETINFOTIPID(lParam)
      nPos := AScan(::aItem, {|x|x[2] == nId})
      TOOLBAR_GETINFOTIP(lParam, ::aItem[nPos, 8])
      EXIT

   CASE TBN_DROPDOWN
      nId := TOOLBAR_SUBMENUEXGETID(lParam)
      IF nId > 0 //hb_IsArray(::aItem[1, 9])
         //nid := TOOLBAR_SUBMENUEXGETID(lParam)
         nPos := AScan(::aItem, {|x|x[2] == nId})
         TOOLBAR_SUBMENUEx(lParam, ::aItem[nPos, 10], ::oParent:handle)
      ELSE
         TOOLBAR_SUBMENU(lParam, 1, ::oParent:handle)
      ENDIF
      EXIT

   CASE NM_CLICK //.AND. ::GetParentForm():Type <= WND_MAIN
      nId := TOOLBAR_IDCLICK(lParam)
      nPos := AScan(::aItem, {|x|x[2] == nId})
      IF nPos > 0 .AND. ::aItem[nPos, 7] != NIL
         Eval(::aItem[nPos, 7], ::aItem[nPos, 11], nId)
      ENDIF

   ENDSWITCH

RETURN 0
#endif

//-------------------------------------------------------------------------------------------------------------------//

METHOD AddButton(nBitIp, nId, bState, bStyle, cText, bClick, c, aMenu, cName, nIndex) CLASS hToolBar

   LOCAL hMenu := NIL // NOTE: to avoid 'Warning W0033  Variable 'HMENU' is never assigned in function...'
   LOCAL oButton

   DEFAULT nBitIp TO -1
   DEFAULT bstate TO TBSTATE_ENABLED
   DEFAULT bstyle TO 0x0000
   DEFAULT c TO ""
   DEFAULT ctext TO ""

   IF nId == NIL .OR. Empty(nId)
      //IDTOOLBAR
      nId := VAL(Right(Str(::id, 6), 1)) * IDMAXBUTTONTOOLBAR
      nId := nId + ::id + IDTOOLBAR + Len(::aButtons) + Len(::aSeparators) + 1
   ENDIF

   IF bStyle != BTNS_SEP //1
      DEFAULT cName TO "oToolButton" + LTrim(Str(Len(::aButtons) + 1))
      AAdd(::aButtons, {Alltrim(cName), nid})
   ELSE
      bstate := IIf(!(::lVertical .AND. Len(::aButtons) == 0), bState, 8) //TBSTATE_HIDE
      DEFAULT nBitIp TO 0
      DEFAULT cName TO "oSeparator" + LTrim(Str(Len(::aSeparators) + 1))
      AAdd(::aSeparators,{cName, nid})
      //bStyle := TBSTYLE_SEP //TBSTYLE_FLAT
   ENDIF

   oButton := HToolButton():New(Self, cName, nBitIp, nId, bState, bStyle, cText, bClick, c, aMenu)
   IF !::lResource
      AAdd(::aItem, {nBitIp, nId, bState, bStyle, 0, cText, bClick, c, aMenu, hMenu, oButton})
   ELSE
      ::aItem[nIndex] := {nBitIp, nId, bState, bStyle, 0, cText, bClick, c, aMenu, hMenu, oButton}
   ENDIF

RETURN oButton

//-------------------------------------------------------------------------------------------------------------------//

METHOD RESIZE(xIncrSize, lWidth, lHeight) CLASS hToolBar

   LOCAL nSize

   IF ::Anchor == 0 .OR. (!lWidth .AND. !lHeight)
      RETURN NIL
   ENDIF
   nSize := hwg_SendMessage(::handle, TB_GETBUTTONSIZE, 0, 0)
   IF xIncrSize != 1
      ::Move(::nLeft, ::nTop, ::nWidth, ::nHeight, 0)
   ENDIF
   IF xIncrSize < 1 .OR. hwg_LOWORD(nSize) <= ::BtnWidth
      ::BtnWidth := ::BtnWidth * xIncrSize
   ELSE
      ::BtnWidth := hwg_LOWORD(nSize) * xIncrSize
   ENDIF
   hwg_SendMessage(::handle, TB_SETBUTTONWIDTH, MAKELPARAM(::BtnWidth - 1, ::BtnWidth + 1))
   IF ::BtnWidth != NIL
      IF !::lVertical
         hwg_SendMessage(::handle, TB_SETBUTTONSIZE, 0, MAKELPARAM(::BtnWidth, ::BtnHeight))
      ELSE
         hwg_SendMessage(::handle, TB_SETBUTTONSIZE, 0, MAKELPARAM(::nWidth - ::nDrop - 1, ::BtnWidth))
      ENDIF
      hwg_SendMessage(::handle, WM_SIZE, 0, 0)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//
