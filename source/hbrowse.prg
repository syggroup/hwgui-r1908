//
// $Id: hbrowse.prg 1885 2012-09-05 19:34:25Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// HBrowse class - browse databases and arrays
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

// Modificaciones y Agregados. 27.07.2002, WHT.de la Argentina ///////////////
// 1) En el metodo HColumn se agregaron las DATA: "nJusHead" y "nJustLin",  //
//    para poder justificar los encabezados de columnas y tambien las       //
//    lineas. Por default es DT_LEFT                                        //
//    0-DT_LEFT, 1-DT_RIGHT y 2-DT_CENTER. 27.07.2002. WHT.                 //
// 2) Ahora la variable "cargo" del metodo Hbrowse si es codeblock          //
//    ejectuta el CB. 27.07.2002. WHT                                       //
// 3) Se agreg� el Metodo "ShowSizes". Para poder ver la "width" de cada    //
//    columna. 27.07.2002. WHT.                                             //
//////////////////////////////////////////////////////////////////////////////

#include "windows.ch"
#include "guilib.ch"
#include "common.ch"

#include "inkey.ch"
#include "dbstruct.ch"
#include "hbclass.ch"

#ifdef __XHARBOUR__
   #xtranslate hb_RAScan([<x,...>]) => RAScan(<x>)
   #xtranslate hb_tokenGet([<x>,<n>,<c>]) => __StrToken(<x>,<n>,<c>)
#endif

REQUEST DBGoTop
REQUEST DBGoTo
REQUEST DBGoBottom
REQUEST DBSkip
REQUEST RecCount
REQUEST RecNo
REQUEST Eof
REQUEST Bof

#define HDM_GETITEMCOUNT    4608

//#define DLGC_WANTALLKEYS    0x0004      /* Control wants all keys */

STATIC s_ColSizeCursor := 0
STATIC s_arrowCursor := 0
STATIC s_downCursor := 0
STATIC s_oCursor := 0
STATIC s_oPen64
STATIC s_xDrag
STATIC s_xDragMove := 0
STATIC s_axPosMouseOver := {0, 0}
STATIC s_xToolTip

//----------------------------------------------------//
CLASS HColumn INHERIT HObject

   DATA oParent
   DATA block, heading, footing, width, Type
   DATA length INIT 0
   DATA dec, cargo
   DATA nJusHead, nJusLin, nJusFoot        // Para poder Justificar los Encabezados
   // de las columnas y lineas.
   DATA tcolor, bcolor, brush
   DATA oFont
   DATA lEditable INIT .F.       // Is the column editable
   DATA aList                    // Array of possible values for a column -
   // combobox will be used while editing the cell
   DATA aBitmaps
   DATA bValid, bWhen, bclick    // When and Valid codeblocks for cell editing
   DATA bEdit                    // Codeblock, which performs cell editing, if defined
   DATA cGrid                    // Specify border for Header (SNWE), can be
   // multiline if separated by ;
   DATA lSpandHead INIT .F.
   DATA lSpandFoot INIT .F.
   DATA Picture
   DATA bHeadClick
   DATA bHeadRClick
   DATA bColorFoot               //   bColorFoot must return an array containing two colors values
   //   oBrowse:aColumns[1]:bColorFoot := {|| IF (nNumber < 0, ;
   //      {textColor, backColor}, ;
   //      {textColor, backColor}) }

   DATA bColorBlock              //   bColorBlock must return an array containing four colors values
   //   oBrowse:aColumns[1]:bColorBlock := {|| IF (nNumber < 0, ;
   //      {textColor, backColor, textColorSel, backColorSel}, ;
   //      {textColor, backColor, textColorSel, backColorSel}) }
   DATA headColor                // Header text color
   DATA FootFont                // Footing font

   DATA lHeadClick   INIT .F.
   DATA lHide INIT .F. // HIDDEN
   DATA Column
   DATA nSortMark INIT 0
   DATA Resizable INIT .T.
   DATA ToolTip
   DATA aHints INIT {}
   DATA Hint INIT .F.

   METHOD New(cHeading, block, Type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock, bHeadClick, tcolor, bColor, bClick)
   METHOD Visible(lVisible) SETGET
   METHOD Hide()
   METHOD Show()
   METHOD SortMark(nSortMark) SETGET
   METHOD Value(xValue) SETGET
   METHOD Editable(lEditable) SETGET

ENDCLASS

//----------------------------------------------------//
METHOD New(cHeading, block, Type, length, dec, lEditable, nJusHead, nJusLin, cPict, bValid, bWhen, aItem, bColorBlock, bHeadClick, tcolor, bcolor, bClick) CLASS HColumn

   ::heading := IIf(cHeading == NIL, "", cHeading)
   ::block := block
   ::Type := IIf(Type != NIL, Upper(Type), Type)
   ::length := length
   ::dec := dec
   ::lEditable := IIf(lEditable != NIL, lEditable, ::lEditable)
   ::nJusHead := IIf(nJusHead == NIL, DT_LEFT, nJusHead) + DT_VCENTER + DT_SINGLELINE // Por default
   ::nJusLin := nJusLin //IIf(nJusLin  == NIL, DT_LEFT, nJusLin) + DT_VCENTER + DT_SINGLELINE // Justif.Izquierda
   ::nJusFoot := IIf(nJusLin == NIL, DT_LEFT, nJusLin)
   ::picture := cPict
   ::bValid := bValid
   ::bWhen := bWhen
   ::aList := aItem
   ::bColorBlock := bColorBlock
   ::bHeadClick := bHeadClick
   ::footing := ""
   ::tcolor := tcolor
   ::bcolor := bcolor
   ::bClick := bClick

RETURN Self

METHOD Visible(lVisible) CLASS HColumn

   IF lVisible != NIL
      IF !lVisible
         ::Hide()
      ELSE
         ::Show()
      ENDIF
      ::lHide := !lVisible
   ENDIF

RETURN !::lHide

METHOD Hide() CLASS HColumn

   ::lHide := .T.
   ::oParent:Refresh()

RETURN ::lHide

METHOD Show() CLASS HColumn

   ::lHide := .F.
   ::oParent:Refresh()

RETURN ::lHide

METHOD Editable(lEditable) CLASS HColumn

   IF lEditable != NIL
      ::lEditable := lEditable
      ::oParent:lEditable := lEditable .OR. AScan(::oParent:aColumns, {|c|c:lEditable}) > 0
      hwg_RedrawWindow(::oParent:handle, RDW_INVALIDATE + RDW_INTERNALPAINT)
   ENDIF

RETURN ::lEditable

METHOD SortMark(nSortMark) CLASS HColumn

    IF nSortMark != NIL
      AEval(::oParent:aColumns,{|c|c:nSortMark := 0})
      ::oParent:lHeadClick := .T.
      hwg_InvalidateRect(::oParent:handle, 0, ::oParent:x1, ::oParent:y1 - ::oParent:nHeadHeight * ::oParent:nHeadRows, ::oParent:x2, ::oParent:y1)
      ::oParent:lHeadClick := .F.
      ::nSortMark := nSortMark
    ENDIF

RETURN ::nSortMark

METHOD Value(xValue) CLASS HColumn

   Local varbuf

   IF xValue != NIL
      varbuf := xValue
      IF ::oParent:Type == BRW_DATABASE
         IF (::oParent:Alias)->(RLock())
            (::oParent:Alias)->(Eval(::block, varbuf, ::oParent, ::Column))
            (::oParent:Alias)->(DBUnlock())
         ELSE
             hwg_MsgStop("Can't lock the record!")
         ENDIF
      ELSEIF ::oParent:nRecords  > 0
         Eval(::block, varbuf, ::oParent, ::Column)
      ENDIF
      /* Execute block after changes are made */
      IF ::oParent:bUpdate != NIL .AND. !::oParent:lSuspendMsgsHandling
         ::oParent:lSuspendMsgsHandling := .T.
         Eval(::oParent:bUpdate, ::oParent, ::Column)
         ::oParent:lSuspendMsgsHandling := .F.
      END
   ELSE
      IF ::oParent:Type == BRW_DATABASE
         varbuf := (::oParent:Alias)->(Eval(::block, , ::oParent, ::Column))
      ELSEIF ::oParent:nRecords  > 0
         varbuf := Eval(::block,, ::oParent, ::Column)
      ENDIF
   ENDIF

RETURN varbuf

//----------------------------------------------------//
CLASS HBrowse INHERIT HControl

   DATA winclass   INIT "BROWSE"
   DATA active     INIT .T.
   DATA lChanged   INIT .F.
   DATA lDispHead  INIT .T.                    // Should I display headers ?
   DATA lDispSep   INIT .T.                    // Should I display separators ?
   DATA aColumns                               // HColumn's array
   DATA aColAlias  INIT {}
   DATA aRelation  INIT .F.
   DATA rowCount   INIT 0                      // Number of visible data rows
   DATA rowPos     INIT 1                      // Current row position
   DATA rowCurrCount INIT 0                    // Current number of rows
   DATA colPos     INIT 1                      // Current column position
   DATA nColumns   INIT 0                      // Number of visible data columns
   DATA nLeftCol                               // Leftmost column
   DATA freeze     INIT 0                      // Number of columns to freeze
   DATA nRecords     INIT 0                    // Number of records in browse
   DATA nCurrent     INIT 1                    // Current record
   DATA aArray                                 // An array browsed if this is BROWSE ARRAY
   DATA recCurr       INIT 0
   DATA headColor                      // Header text color
   DATA sepColor       INIT 12632256             // Separators color
   DATA lSep3d        INIT .F.
   DATA varbuf                                 // Used on Edit()
   DATA tcolorSel, bcolorSel, brushSel, htbColor, httColor // Hilite Text Back Color
   DATA bSkip, bGoTo, bGoTop, bGoBot, bEof, bBof
   DATA bRcou, bRecno, bRecnoLog
   DATA bPosChanged, bLineOut
   DATA bScrollPos                             // Called when user move browse through vertical scroll bar
   DATA bHScrollPos                            // Called when user move browse through horizontal scroll bar
   DATA bEnter, bKeyDown, bUpdate, bRclick
   DATA bChangeRowCol
   DATA internal
   DATA Alias                                  // Alias name of browsed database
   DATA x1, y1, x2, y2, width, height, xAdjRight
   DATA minHeight INIT 0
   DATA forceHeight INIT 0                     // force Row height in pixel, set by SetRowHeight
   DATA lEditable INIT .T.
   DATA lAppable  INIT .F.
   DATA lAppMode  INIT .F.
   DATA lAutoEdit INIT .F.
   DATA lUpdated  INIT .F.
   DATA lAppended INIT .F.
   DATA lESC      INIT .F.
   DATA lAdjRight INIT .T.                     // Adjust last column to right
   DATA nHeadRows INIT 1                       // Rows in header
   DATA nHeadHeight INIT 0                     // Pixel height in header for footer (if present) or std font
   DATA nFootHeight INIT 0                     // Pixel height in footer for standard font
   DATA nFootRows INIT 0                       // Rows in footer
   DATA lResizing INIT .F.                     // .T. while a column resizing is undergoing
   DATA lCtrlPress INIT .F.                    // .T. while Ctrl key is pressed
   DATA lShiftPress INIT .F.                    // .T. while Shift key is pressed
   DATA aSelected                              // An array of selected records numbers
   DATA nWheelPress INIT 0                        // wheel or central button mouse pressed flag
   DATA oHeadFont

   DATA lDescend INIT .F.              // Descend Order?
   DATA lFilter INIT .F.               // Filtered? (atribuition is automatic in method "New()").
   DATA bFirst INIT {||DBGoTop()}     // Block to place pointer in first record of condition filter. (Ex.: DbGoTop(), DbSeek(), etc.).
   DATA bLast  INIT {||DBGoBottom()}  // Block to place pointer in last record of condition filter. (Ex.: DbGoBottom(), DbSeek(), etc.).
   DATA bWhile INIT {||.T.}           // Clausule "while". Return logical.
   DATA bFor INIT {||.T.}             // Clausule "for". Return logical.
   DATA nLastRecordFilter INIT 0       // Save the last record of filter.
   DATA nFirstRecordFilter INIT 0      // Save the first record of filter.
   DATA nPaintRow, nPaintCol                   // Row/Col being painted
   DATA aMargin INIT {0, 0, 0, 0} PROTECTED  // Margin TOP-RIGHT-BOTTOM-LEFT
   DATA lRepaintBackground INIT .F. HIDDEN    // Set to true performs a canvas fill before painting rows

   DATA lHeadClick  INIT  .F.    // .T. while a HEADER column is CLICKED
   DATA nyHeight    INIT  0
   DATA fipos      HIDDEN
   DATA lDeleteMark INIT .F.   HIDDEN
   DATA lShowMark   INIT .T.   HIDDEN
   DATA nDeleteMark INIT 0     HIDDEN
   DATA nShowMark   INIT 12    HIDDEN
   DATA oBmpMark    INIT  HBitmap():AddStandard(OBM_MNARROW) HIDDEN
   DATA ShowSortMark  INIT .T.
   DATA nWidthColRight INIT 0  HIDDEN
   DATA nVisibleColLeft INIT 0 HIDDEN
   // one to many relationships
   DATA LinkMaster             // Specifies the parent table linked to the child table displayed in a Grid control.
   DATA ChildOrder             // Specifies the index tag for the record source of the Grid control or Relation object.
   DATA RelationalExpr         // Specifies the expression based on fields in the parent table that relates to an index in the child table joining the two tables
   DATA aRecnoFilter   INIT {}
   DATA nIndexOrd INIT -1 HIDDEN
   DATA nRecCount INIT 0  HIDDEN

   // ADD THEME IN BROWSE
   DATA m_bFirstTime  INIT .T.
   DATA hTheme
   DATA Themed        INIT .T.
   DATA xPosMouseOver INIT  0
   DATA isMouseOver   INIT .F.
   DATA allMouseOver  INIT .F.
   DATA AutoColumnFit INIT  0   // 0-Enable / 2  Disables capability for columns to fit data automatically.
   DATA nAutoFit
   DATA lNoVScroll   INIT .F.
   DATA lDisableVScrollPos INIT .F.
   DATA oTimer  HIDDEN
   DATA nSetRefresh  INIT 0 HIDDEN
   DATA Highlight        INIT .F. // only editable is Highlight
   DATA HighlightStyle   INIT  1  // 0 No color highlighting for grid row
                                  // 1 Enable highlighting for current row. (Default)
                                  // 2 nopersit highlighting //for current row and current cell
                                  // 3 nopersist when grid is not the current active control.

   METHOD New(lType, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
              bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, ;
              lNoBorder, lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, ;
              lDescend, bWhile, bFirst, bLast, bFor, bOther, tcolor, bcolor, brclick, bChgRowCol, ctooltip)
   METHOD InitBrw(nType, lInit)
   METHOD Rebuild()
   METHOD Activate()
   METHOD Init()
   METHOD onEvent(msg, wParam, lParam)
   METHOD Redefine(lType, oWndParent, nId, oFont, bInit, bSize, bPaint, bEnter, bGfocus, bLfocus)
   METHOD FindBrowse(nId)
   METHOD AddColumn(oColumn)
   METHOD InsColumn(oColumn, nPos)
   METHOD DelColumn(nPos)
   METHOD Paint(lLostFocus)
   METHOD LineOut(nRow, nCol, hDC, lSelected, lClear)
   METHOD Select()
   METHOD HeaderOut(hDC)
   METHOD SeparatorOut(hDC, nRowsFill)
   METHOD FooterOut(hDC)
   METHOD SetColumn(nCol)
   METHOD DoHScroll(wParam)
   METHOD DoVScroll(wParam)
   METHOD LineDown(lMouse)
   METHOD LineUp()
   METHOD PageUp()
   METHOD PageDown()
   METHOD Bottom(lPaint)
   METHOD Top()
   METHOD Home() INLINE ::DoHScroll(SB_LEFT)
   METHOD ButtonDown(lParam, lReturnRowCol)
   METHOD ButtonUp(lParam)
   METHOD ButtonDbl(lParam)
   METHOD MouseMove(wParam, lParam)
   METHOD MouseWheel(nKeys, nDelta, nXPos, nYPos)
   METHOD Edit(wParam, lParam)
   METHOD Append() INLINE (::Bottom(.F.), ::LineDown())
   METHOD onClick() 
   METHOD RefreshLine()
   METHOD Refresh(lFull, lLineUp)
   METHOD ShowSizes()
   METHOD END()
   METHOD SetMargin(nTop, nRight, nBottom, nLeft)
   METHOD SetRowHeight(nPixels)
   METHOD FldStr(oBrw, numf)
   METHOD Filter(lFilter) SETGET
   //
   METHOD WhenColumn(value, oGet)
   METHOD ValidColumn(value, oGet, oBtn)
   METHOD onClickColumn(value, oGet, oBtn)
   METHOD EditEvent(oCtrl, msg, wParam, lParam)
   METHOD ButtonRDown(lParam)
   METHOD ShowMark(lShowMark) SETGET
   METHOD DeleteMark(lDeleteMark) SETGET
//   METHOD BrwScrollVPos()
   // new
   METHOD ShowColToolTips(lParam)
    METHOD SetRefresh(nSeconds) SETGET
   METHOD When()
   METHOD Valid()
   METHOD ChangeRowCol(nRowColChange)
   METHOD EditLogical(wParam, lParam)   HIDDEN
   METHOD AutoFit()


ENDCLASS

//----------------------------------------------------//
METHOD New(lType, oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
           bInit, bSize, bPaint, bEnter, bGfocus, bLfocus, lNoVScroll, ;
           lNoBorder, lAppend, lAutoedit, bUpdate, bKeyDown, bPosChg, lMultiSelect, ;
           lDescend, bWhile, bFirst, bLast, bFor, bOther, tcolor, bcolor, bRclick, bChgRowCol, ctooltip) CLASS HBrowse

   lNoVScroll := IIf(lNoVScroll == NIL, .F., lNoVScroll)
   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), WS_CHILD + WS_VISIBLE + WS_TABSTOP + ;
                          IIf(lNoBorder == NIL .OR. !lNoBorder, WS_BORDER, 0) +            ;
                          IIf(!lNoVScroll, WS_VSCROLL, 0))
   nStyle   -= IIf(hwg_BitAND(nStyle, WS_VSCROLL) > 0 .AND. lNoVScroll, WS_VSCROLL, 0)

   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, IIf(nWidth == NIL, 0, nWidth), ;
              IIf(nHeight == NIL, 0, nHeight), oFont, bInit, bSize, bPaint, ctooltip, tColor, bColor)

   ::lNoVScroll := lNoVScroll
   ::Type := lType
   IF oFont == NIL
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter := bEnter
   ::bRclick := bRclick
   ::bGetFocus := bGfocus
   ::bLostFocus := bLfocus
   ::bOther := bOther

   ::lAppable := IIf(lAppend == NIL, .F., lAppend)
   ::lAutoedit := IIf(lAutoedit == NIL, .F., lAutoedit)
   ::bUpdate := bUpdate
   ::bKeyDown := bKeyDown
   ::bPosChanged := bPosChg
   ::bChangeRowCol := bChgRowCol
   IF lMultiSelect != NIL .AND. lMultiSelect
      ::aSelected := {}
   ENDIF
   ::lDescend := IIf(lDescend == NIL, .F., lDescend)

   IF hb_IsBlock(bFirst) .OR. hb_IsBlock(bFor) .OR. hb_IsBlock(bWhile)
      ::lFilter := .T.
      IF hb_IsBlock(bFirst)
         ::bFirst := bFirst
      ENDIF
      IF hb_IsBlock(bLast)
         ::bLast := bLast
      ENDIF
      IF hb_IsBlock(bWhile)
         ::bWhile := bWhile
      ENDIF
      IF hb_IsBlock(bFor)
         ::bFor := bFor
      ENDIF
   ELSE
      ::lFilter := .F.
   ENDIF
   hwg_RegBrowse()
   ::InitBrw(, .F.)
   ::Activate()

RETURN Self

//----------------------------------------------------//
METHOD Activate() CLASS HBrowse
   IF !Empty(::oParent:handle)
      ::handle := CreateBrowse(::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight)
      ::Init()
   ENDIF

RETURN NIL

//----------------------------------------------------//
METHOD Init() CLASS HBrowse

   IF !::lInit
      ::nHolder := 1
      hwg_SetWindowObject(::handle, Self)
      ::Super:Init()
      ::InitBrw(, .T.)
      //VScrollPos(Self, 0, .F.)
      IF ::GetParentForm():Type < WND_DLG_RESOURCE
         ::GetParentForm():lDisableCtrlTab := .T.
      ENDIF

   ENDIF

RETURN NIL

//----------------------------------------------------//
METHOD SetMargin(nTop, nRight, nBottom, nLeft) CLASS HBrowse

   LOCAL aOldMargin := AClone(::aMargin)

   IF nTop == NIL
      nTop := 0
   ENDIF

   IF nRight == NIL
      nRight := nBottom := nLeft := nTop
   ENDIF

   IF nBottom == NIL
      nBottom := nTop
      nLeft := nRight
   ENDIF

   ::aMargin := {nTop, nRight, nBottom, nLeft}

RETURN aOldMargin

/***
*
*/
METHOD SetRowHeight(nPixels) CLASS HBrowse
   
   LOCAL nOldPixels

   nOldPixels := ::forceHeight

   IF hb_IsNumeric(nPixels)
      IF nPixels > 0
         ::forceHeight := nPixels
         IF nPixels != nOldPixels .AND. ::rowCurrCount > 0  //nando
            ::lRepaintBackground := .T.
            ::Rebuild()
            ::Refresh()
         ENDIF
      ELSE
         ::forceHeight := 0
      ENDIF
   ENDIF

RETURN nOldPixels

//----------------------------------------------------//
#if 0 // old code for reference (to be deleted)
METHOD onEvent(msg, wParam, lParam) CLASS HBrowse
   
   LOCAL oParent
   LOCAL cKeyb
   LOCAL nCtrl
   LOCAL nPos
   LOCAL lBEof
   LOCAL nRecStart
   LOCAL nRecStop
   LOCAL nRet
   LOCAL nShiftAltCtrl

   IF ::active .AND. !Empty(::aColumns)
      // moved to first
      IF msg == WM_MOUSEWHEEL .AND. !::oParent:lSuspendMsgsHandling
            ::isMouseOver := .F.
            ::MouseWheel(hwg_LOWORD(wParam), ;
                    IIf(hwg_HIWORD(wParam) > 32768, ;
                        hwg_HIWORD(wParam) - 65535, hwg_HIWORD(wParam)), ;
                    hwg_LOWORD(lParam), hwg_HIWORD(lParam))
         //RETURN 0 because bother is not run
      ENDIF
      //
      IF hb_IsBlock(::bOther)
         IF !hb_IsNumeric(nRet := Eval(::bOther, Self, msg, wParam, lParam))
            nRet := IIf(hb_IsLogical(nRet) .AND. !nRet, 0, -1)
         ENDIF
         IF nRet >= 0
             RETURN -1
         ENDIF
      ENDIF
      IF msg == WM_THEMECHANGED
         IF ::Themed
            IF hb_IsPointer(::hTheme)
               HB_CLOSETHEMEDATA(::htheme)
               ::hTheme := NIL
            ENDIF
            ::Themed := .F.
         ENDIF
         ::m_bFirstTime := .T.
         hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
         RETURN 0
      ENDIF
      IF msg == WM_PAINT
         ::Paint()
         RETURN 1

      ELSEIF msg == WM_ERASEBKGND
         RETURN 0

      ELSEIF msg == WM_SIZE
         ::oParent:lSuspendMsgsHandling := .F.
         ::lRepaintBackground := .T.
         ::isMouseOver := .F.
         IF ::AutoColumnFit == 1
            IF !hwg_IsWindowVisible(::oParent:handle)
               ::Rebuild()
               ::lRepaintBackground := .F.
            ENDIF
            ::AutoFit()
         ENDIF


      ELSEIF msg == WM_SETFONT .AND. ::oHeadFont == NIL .AND. ::lInit
         ::nHeadHeight := 0
         ::nFootHeight := 0

      ELSEIF msg == WM_SETFOCUS .AND. !::lSuspendMsgsHandling
         ::When()
         /*
         IF hb_IsBlock(::bGetFocus)
            Eval(::bGetFocus, Self)
         ENDIF
         */
      ELSEIF msg == WM_KILLFOCUS .AND. !::lSuspendMsgsHandling
         ::Valid()
         /*
         IF hb_IsBlock(::bLostFocus)
            Eval(::bLostFocus, Self)
         ENDIF

         IF ::GetParentForm(self):Type < WND_DLG_RESOURCE
             hwg_SendMessage(::oParent:handle, WM_COMMAND, makewparam(::id, 0), ::handle)
         ENDIF
         */
         ::internal[1] := 15 //force redraw header, footer and separator

      ELSEIF msg == WM_HSCROLL
         ::DoHScroll(wParam)

      ELSEIF msg == WM_VSCROLL
         ::DoVScroll(wParam)

      ELSEIF msg == WM_CHAR
         IF !CheckBit(lParam, 32) //.AND. hb_IsBlock(::bKeyDown)
             nShiftAltCtrl := IIf(IsCtrlShift(.F., .T.), 1, 0)
             nShiftAltCtrl += IIf(IsCtrlShift(.T., .F.), 2, nShiftAltCtrl)
             //nShiftAltCtrl += IIf(wParam > 111, 4, nShiftAltCtrl)
             IF hb_IsBlock(::bKeyDown) .AND. wParam != VK_TAB .AND. wParam != VK_RETURN
                IF Empty(nRet := Eval(::bKeyDown, Self, wParam, nShiftAltCtrl, msg)) .AND. nRet != NIL
                   RETURN 0
                ENDIF
             ENDIF
             IF wParam == VK_RETURN .OR. wParam == VK_ESCAPE
                RETURN -1
             ENDIF
             IF ::lAutoEdit .OR. ::aColumns[::SetColumn()]:lEditable
                ::Edit(wParam, lParam)
             ENDIF
         ENDIF

      ELSEIF msg == WM_GETDLGCODE
         ::isMouseOver := .F.
         IF wParam == VK_ESCAPE .AND. ;          // DIALOG MODAL
                  (oParent := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oParent:IsEnabled()
              RETURN DLGC_WANTMESSAGE
         ELSEIF (wParam == VK_ESCAPE .AND. ::GetParentForm():handle != ::oParent:handle .AND. ::lEsc) .OR. ; //!::lAutoEdit
                (wParam == VK_RETURN .AND. ::GetParentForm():FindControl(IDOK) != NIL)
            RETURN -1
         ENDIF
         RETURN DLGC_WANTALLKEYS

      ELSEIF msg == WM_COMMAND
         // ::Super:onEvent(WM_COMMAND)
         IF ::GetParentForm(self):Type < WND_DLG_RESOURCE
            ::GetParentForm(self):onEvent(msg, wparam, lparam)
         ELSE
            DlgCommand(Self, wParam, lParam)
         ENDIF

      ELSEIF msg == WM_KEYUP //.AND. !::oParent:lSuspendMsgsHandling
         IF wParam == 17
            ::lCtrlPress := .F.
         ENDIF
         IF wParam == 16
            ::lShiftPress := .F.
         ENDIF
         IF wParam == VK_TAB .AND. ::GetParentForm():Type < WND_DLG_RESOURCE
            IF IsCtrlShift(.T., .F.)
               getskip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
               RETURN 0
            ENDIF
            /*
            ELSE
               ::DoHScroll(IIf(IsCtrlShift(.F., .T.), SB_LINELEFT, SB_LINERIGHT))
            ENDIF
            */
         ENDIF
         IF wParam != VK_SHIFT .AND. wParam != VK_CONTROL .AND. wParam != 18
            oParent := ::oParent
            DO WHILE oParent != NIL .AND. !__ObjHasMsg(oParent, "GETLIST")
               oParent := oParent:oParent
            ENDDO
            IF oParent != NIL .AND. !Empty(oParent:KeyList)
               cKeyb := GetKeyboardState()
               nCtrl := IIf(Asc(SubStr(cKeyb, VK_CONTROL + 1, 1)) >= 128, FCONTROL, IIf(Asc(SubStr(cKeyb, VK_SHIFT + 1, 1)) >= 128, FSHIFT, 0))
               IF (nPos := AScan(oParent:KeyList, {|a|a[1] == nCtrl.AND.a[2] == wParam})) > 0
                  Eval(oParent:KeyList[nPos, 3], Self)
               ENDIF
            ENDIF
         ENDIF

         RETURN 1

      ELSEIF msg == WM_KEYDOWN .AND. !::oParent:lSuspendMsgsHandling
         //::isMouseOver := .F.
         IF ((CheckBit(lParam, 25) .AND. wParam != 111) .OR. (wParam > 111 .AND. wParam < 124) .OR.;
               wParam == VK_TAB .OR. wParam == VK_RETURN) .AND. ;
               hb_IsBlock(::bKeyDown)
             nShiftAltCtrl := IIf(IsCtrlShift(.F., .T.), 1, 0)
             nShiftAltCtrl += IIf(IsCtrlShift(.T., .F.), 2, nShiftAltCtrl)
             nShiftAltCtrl += IIf(wParam > 111, 4, nShiftAltCtrl)
             IF Empty(nRet := Eval(::bKeyDown, Self, wParam, nShiftAltCtrl, msg)) .AND. nRet != NIL
                RETURN 0
             ENDIF
         ENDIF
         ::isMouseOver := .F.
         IF wParam == VK_PRIOR .OR. wParam == VK_NEXT .OR. wParam == VK_UP .OR. wParam == VK_DOWN
            IF !::ChangeRowCol(1)
               RETURN -1
            ENDIF
         ENDIF

         IF wParam == VK_TAB
            IF ::lCtrlPress
               getskip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
               RETURN 0
            ELSE
               ::DoHScroll(IIf(IsCtrlShift(.F., .T.), SB_LINELEFT, SB_LINERIGHT))
            ENDIF
         ELSEIF wParam == VK_DOWN //40        // Down
            IF ::lShiftPress .AND. ::aSelected != NIL
               Eval(::bskip, Self, 1)
               lBEof := Eval(::beof, Self)
               Eval(::bskip, Self, -1)
               IF !(lBEof .AND. AScan(::aSelected, Eval(::bRecno, Self)) > 0)
                  ::Select()
                  IF lBEof
                     ::refreshline()
                  ENDIF
               ENDIF
            ENDIF
            ::LINEDOWN()

         ELSEIF wParam == VK_UP //38    // Up

            IF ::lShiftPress .AND. ::aSelected != NIL
               Eval(::bskip, Self, 1)
               lBEof := Eval(::beof, Self)
               Eval(::bskip, Self, -1)
               IF !(lBEof .AND. AScan(::aSelected, Eval(::bRecno, Self)) > 0)
                  ::LINEUP()
               ENDIF
            ELSE
               ::LINEUP()
            ENDIF

            IF ::lShiftPress .AND. ::aSelected != NIL
               Eval(::bskip, Self, -1)
               IF !(lBEof := Eval(::bBof, Self))
                  Eval(::bskip, Self, 1)
               ENDIF
               IF !(lBEof .AND. AScan(::aSelected, Eval(::bRecno, Self)) > 0)
                  ::Select()
                  ::refresh(.F.)
               ENDIF
            ENDIF

         ELSEIF wParam == VK_RIGHT //39    // Right
            ::DoHScroll(SB_LINERIGHT)
         ELSEIF wParam == VK_LEFT //37    // Left
            ::DoHScroll(SB_LINELEFT)
         ELSEIF wParam == VK_HOME //36    // Home
            IF !::lCtrlPress .AND. (::lAutoEdit .OR. ::aColumns[::SetColumn()]:lEditable)
               ::Edit(wParam)
            ELSE
               ::DoHScroll(SB_LEFT)
            ENDIF
         ELSEIF wParam == VK_END //35    // End
            IF !::lCtrlPress .AND. (::lAutoEdit .OR. ::aColumns[::SetColumn()]:lEditable)
               ::Edit(wParam)
            ELSE
               ::DoHScroll(SB_RIGHT)
            ENDIF
         ELSEIF wParam == 34    // PageDown
            nRecStart := Eval(::brecno, Self)
            IF ::lCtrlPress
               IF (::nRecords > ::rowCount)
                  ::BOTTOM()
               ELSE
                 ::PageDown()
               ENDIF
            ELSE
              ::PageDown()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
               nRecStop := Eval(::brecno, Self)
               Eval(::bskip, Self, 1)
               lBEof := Eval(::beof, Self)
               Eval(::bskip, Self, -1)
               IF !(lBEof .AND. AScan(::aSelected, Eval(::bRecno, Self)) > 0)
                  ::Select()
               ENDIF
               DO WHILE Eval(::bRecno, Self) != nRecStart
                  ::Select()
                  Eval(::bskip, Self, -1)
               ENDDO
               ::Select()
               Eval(::bgoto, Self, nRecStop)
               Eval(::bskip, Self, 1)
               IF Eval(::beof, Self)
                  Eval(::bskip, Self, -1)
                  ::Select()
               ELSE
                  Eval(::bskip, Self, -1)
               ENDIF
               ::Refresh()
            ENDIF
         ELSEIF wParam == 33    // PageUp
            nRecStop := Eval(::brecno, Self)
            IF ::lCtrlPress
               ::TOP()
            ELSE
               ::PageUp()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
                nRecStart := Eval(::bRecno, Self)
                DO WHILE Eval(::bRecno, Self) != nRecStop
                   ::Select()
                   Eval(::bskip, Self, 1)
                ENDDO
                Eval(::bgoto, Self, nRecStart)
                ::Refresh()
            ENDIF

         ELSEIF wParam == VK_RETURN    // Enter
            ::Edit(VK_RETURN)

         ELSEIF wParam == VK_ESCAPE .AND. ::lESC
            IF ::GetParentForm():Type < WND_DLG_RESOURCE
               hwg_SendMessage(hwg_GetParent(::handle), WM_SYSCOMMAND, SC_CLOSE, 0)
            ELSE
               hwg_SendMessage(hwg_GetParent(::handle), WM_CLOSE, 0, 0)
            ENDIF
         ELSEIF wParam == VK_CONTROL  //17
            ::lCtrlPress := .T.
         ELSEIF wParam == VK_SHIFT   //16
            ::lShiftPress := .T.
         //ELSEIF ::lAutoEdit .AND. (wParam >= 48 .AND. wParam <= 90 .OR. wParam >= 96 .AND. wParam <= 111)
         //   ::Edit(wParam, lParam)
         ENDIF
         RETURN 1

      ELSEIF msg == WM_LBUTTONDBLCLK
         ::ButtonDbl(lParam)

      ELSEIF msg == WM_LBUTTONDOWN
         ::ButtonDown(lParam)
      ELSEIF msg == WM_LBUTTONUP
         ::ButtonUp(lParam)
      ELSEIF msg == WM_RBUTTONDOWN
         ::ButtonRDown(lParam)
      ELSEIF msg == WM_MOUSEMOVE .AND.!::oParent:lSuspendMsgsHandling
         IF ::nWheelPress > 0
            ::MouseWheel(hwg_LOWORD(wParam), ::nWheelPress - lParam)
         ELSE
            ::MouseMove(wParam, lParam)
            IF ::lHeadClick
               AEval(::aColumns,{|c|c:lHeadClick := .F.})
               hwg_InvalidateRect(::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1)
               ::lHeadClick := .F.
            ENDIF
            IF (!::allMouseOver) .AND. ::hTheme != NIL
               ::allMouseOver := .T.
               TRACKMOUSEVENT(::handle)
            ELSE
               TRACKMOUSEVENT(::handle, TME_HOVER + TME_LEAVE)
            ENDIF
         ENDIF
      ELSEIF msg == WM_MOUSEHOVER
         ::ShowColToolTips(lParam)

      ELSEIF (msg == WM_MOUSELEAVE .OR. msg == WM_NCMOUSELEAVE) //.AND.!::oParent:lSuspendMsgsHandling
         IF ::allMouseOver
            //::MouseMove(0, 0)
            ::MouseMove(wParam, lParam)
            ::allMouseOver := .F.
            //::isMouseOver := .F.
         ENDIF

      ELSEIF msg == WM_MBUTTONUP
         ::nWheelPress := IIf(::nWheelPress > 0, 0, lParam)
         IF ::nWheelPress > 0
            hwg_SetCursor(hwg_LoadCursor(32652))
         ELSE
            hwg_SetCursor(hwg_LoadCursor(IDC_ARROW))
         ENDIF
      /*
      ELSEIF msg == WM_MOUSEWHEEL
         ::MouseWheel(hwg_LOWORD(wParam), ;
                    IIf(hwg_HIWORD(wParam) > 32768, ;
                        hwg_HIWORD(wParam) - 65535, hwg_HIWORD(wParam)), ;
                    hwg_LOWORD(lParam), hwg_HIWORD(lParam))
      */
      ELSEIF msg == WM_DESTROY
        IF hb_IsPointer(::hTheme)
           HB_CLOSETHEMEDATA(::htheme)
          ::hTheme := NIL
        ENDIF
        ::END()
      ENDIF

   ENDIF

RETURN -1
#else
METHOD OnEvent(msg, wParam, lParam) CLASS HBrowse

   LOCAL oParent
   LOCAL cKeyb
   LOCAL nCtrl
   LOCAL nPos
   LOCAL lBEof
   LOCAL nRecStart
   LOCAL nRecStop
   LOCAL nRet
   LOCAL nShiftAltCtrl

   IF !::active .OR. Empty(::aColumns)
      RETURN -1
   ENDIF

   IF hb_IsBlock(::bOther)
      IF !hb_IsNumeric(nRet := Eval(::bOther, Self, msg, wParam, lParam))
         nRet := IIf(hb_IsLogical(nRet) .AND. !nRet, 0, -1)
      ENDIF
      IF nRet >= 0
         RETURN -1
      ENDIF
   ENDIF

   SWITCH msg

   CASE WM_MOUSEWHEEL
      IF !::oParent:lSuspendMsgsHandling
         ::isMouseOver := .F.
         ::MouseWheel(hwg_LOWORD(wParam), IIf(hwg_HIWORD(wParam) > 32768, hwg_HIWORD(wParam) - 65535, hwg_HIWORD(wParam)), ;
            hwg_LOWORD(lParam), hwg_HIWORD(lParam))
         //RETURN 0 because bother is not run
      ENDIF
      EXIT

   CASE WM_THEMECHANGED
      IF ::Themed
         IF hb_IsPointer(::hTheme)
            HB_CLOSETHEMEDATA(::htheme)
            ::hTheme := NIL
         ENDIF
         ::Themed := .F.
      ENDIF
      ::m_bFirstTime := .T.
      hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
      RETURN 0

   CASE WM_PAINT
      ::Paint()
      RETURN 1

   CASE WM_ERASEBKGND
      RETURN 0

   CASE WM_SIZE
      ::oParent:lSuspendMsgsHandling := .F.
      ::lRepaintBackground := .T.
      ::isMouseOver := .F.
      IF ::AutoColumnFit == 1
         IF !hwg_IsWindowVisible(::oParent:handle)
            ::Rebuild()
            ::lRepaintBackground := .F.
         ENDIF
         ::AutoFit()
      ENDIF
      EXIT

   CASE WM_SETFONT
      IF ::oHeadFont == NIL .AND. ::lInit
         ::nHeadHeight := 0
         ::nFootHeight := 0
      ENDIF
      EXIT

   CASE WM_SETFOCUS
      IF !::lSuspendMsgsHandling
         ::When()
         //IF hb_IsBlock(::bGetFocus)
         //   Eval(::bGetFocus, Self)
         //ENDIF
      ENDIF
      EXIT

   CASE WM_KILLFOCUS
      IF !::lSuspendMsgsHandling
         ::Valid()
         //IF hb_IsBlock(::bLostFocus)
         //   Eval(::bLostFocus, Self)
         //ENDIF
         //IF ::GetParentForm(self):Type < WND_DLG_RESOURCE
         //    hwg_SendMessage(::oParent:handle, WM_COMMAND, makewparam(::id, 0), ::handle)
         //ENDIF
         ::internal[1] := 15 //force redraw header, footer and separator
      ENDIF
      EXIT

   CASE WM_HSCROLL
      ::DoHScroll(wParam)
      EXIT

   CASE WM_VSCROLL
      ::DoVScroll(wParam)
      EXIT

   CASE WM_CHAR
      IF !CheckBit(lParam, 32) //.AND. hb_IsBlock(::bKeyDown)
         nShiftAltCtrl := IIf(IsCtrlShift(.F., .T.), 1, 0)
         nShiftAltCtrl += IIf(IsCtrlShift(.T., .F.), 2, nShiftAltCtrl)
         //nShiftAltCtrl += IIf(wParam > 111, 4, nShiftAltCtrl)
         IF hb_IsBlock(::bKeyDown) .AND. wParam != VK_TAB .AND. wParam != VK_RETURN
            IF Empty(nRet := Eval(::bKeyDown, Self, wParam, nShiftAltCtrl, msg)) .AND. nRet != NIL
               RETURN 0
            ENDIF
         ENDIF
         IF wParam == VK_RETURN .OR. wParam == VK_ESCAPE
            RETURN -1
         ENDIF
         IF ::lAutoEdit .OR. ::aColumns[::SetColumn()]:lEditable
            ::Edit(wParam, lParam)
         ENDIF
      ENDIF
      EXIT

   CASE WM_GETDLGCODE
      ::isMouseOver := .F.
      IF wParam == VK_ESCAPE .AND. ; // DIALOG MODAL
         (oParent := ::GetParentForm:FindControl(IDCANCEL)) != NIL .AND. !oParent:IsEnabled()
         RETURN DLGC_WANTMESSAGE
      ELSEIF (wParam == VK_ESCAPE .AND. ::GetParentForm():handle != ::oParent:handle .AND. ::lEsc) .OR. ; //!::lAutoEdit
         (wParam == VK_RETURN .AND. ::GetParentForm():FindControl(IDOK) != NIL)
         RETURN -1
      ENDIF
      RETURN DLGC_WANTALLKEYS

   CASE WM_COMMAND
      //::Super:onEvent(WM_COMMAND)
      IF ::GetParentForm(self):Type < WND_DLG_RESOURCE
         ::GetParentForm(self):OnEvent(msg, wparam, lparam)
      ELSE
         DlgCommand(Self, wParam, lParam)
      ENDIF
      EXIT

   CASE WM_KEYUP //.AND. !::oParent:lSuspendMsgsHandling
      IF wParam == VK_CONTROL
         ::lCtrlPress := .F.
      ENDIF
      IF wParam == VK_SHIFT
         ::lShiftPress := .F.
      ENDIF
      IF wParam == VK_TAB .AND. ::GetParentForm():Type < WND_DLG_RESOURCE
         IF IsCtrlShift(.T., .F.)
            getskip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
            RETURN 0
         ENDIF
         //ELSE
         //   ::DoHScroll(IIf(IsCtrlShift(.F., .T.), SB_LINELEFT, SB_LINERIGHT))
         //ENDIF
      ENDIF
      IF wParam != VK_SHIFT .AND. wParam != VK_CONTROL .AND. wParam != VK_MENU
         oParent := ::oParent
         DO WHILE oParent != NIL .AND. !__ObjHasMsg(oParent, "GETLIST")
            oParent := oParent:oParent
         ENDDO
         IF oParent != NIL .AND. !Empty(oParent:KeyList)
            cKeyb := GetKeyboardState()
            nCtrl := IIf(Asc(SubStr(cKeyb, VK_CONTROL + 1, 1)) >= 128, FCONTROL, ;
               IIf(Asc(SubStr(cKeyb, VK_SHIFT + 1, 1)) >= 128, FSHIFT, 0))
            IF (nPos := AScan(oParent:KeyList, {|a|a[1] == nCtrl .AND. a[2] == wParam})) > 0
               Eval(oParent:KeyList[nPos, 3], Self)
            ENDIF
         ENDIF
      ENDIF
      RETURN 1

   CASE WM_KEYDOWN
      IF !::oParent:lSuspendMsgsHandling
         //::isMouseOver := .F.
         IF ((CheckBit(lParam, 25) .AND. wParam != 111) .OR. (wParam >= VK_F1 .AND. wParam <= VK_F12) .OR. ;
            wParam == VK_TAB .OR. wParam == VK_RETURN) .AND. hb_IsBlock(::bKeyDown)
            nShiftAltCtrl := IIf(IsCtrlShift(.F., .T.), 1, 0)
            nShiftAltCtrl += IIf(IsCtrlShift(.T., .F.), 2, nShiftAltCtrl)
            nShiftAltCtrl += IIf(wParam > 111, 4, nShiftAltCtrl)
            IF Empty(nRet := Eval(::bKeyDown, Self, wParam, nShiftAltCtrl, msg)) .AND. nRet != NIL
               RETURN 0
            ENDIF
         ENDIF
         ::isMouseOver := .F.
         SWITCH wParam
         CASE VK_TAB
            IF ::lCtrlPress
               getskip(::oParent, ::handle, , IIf(IsCtrlShift(.F., .T.), -1, 1))
               RETURN 0
            ENDIF
            ::DoHScroll(IIf(IsCtrlShift(.F., .T.), SB_LINELEFT, SB_LINERIGHT))
            EXIT
         CASE VK_DOWN
            IF !::ChangeRowCol(1)
               RETURN -1
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
               Eval(::bskip, Self, 1)
               lBEof := Eval(::beof, Self)
               Eval(::bskip, Self, -1)
               IF !(lBEof .AND. AScan(::aSelected, Eval(::bRecno, Self)) > 0)
                  ::Select()
                  IF lBEof
                     ::refreshline()
                  ENDIF
               ENDIF
            ENDIF
            ::LINEDOWN()
            EXIT
         CASE VK_UP
            IF !::ChangeRowCol(1)
               RETURN -1
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
               Eval(::bskip, Self, 1)
               lBEof := Eval(::beof, Self)
               Eval(::bskip, Self, -1)
               IF !(lBEof .AND. AScan(::aSelected, Eval(::bRecno, Self)) > 0)
                  ::LINEUP()
               ENDIF
            ELSE
               ::LINEUP()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
               Eval(::bskip, Self, -1)
               IF !(lBEof := Eval(::bBof, Self))
                  Eval(::bskip, Self, 1)
               ENDIF
               IF !(lBEof .AND. AScan(::aSelected, Eval(::bRecno, Self)) > 0)
                  ::Select()
                  ::refresh(.F.)
               ENDIF
            ENDIF
            EXIT
         CASE VK_RIGHT
            ::DoHScroll(SB_LINERIGHT)
            EXIT
         CASE VK_LEFT
            ::DoHScroll(SB_LINELEFT)
            EXIT
         CASE VK_HOME
            IF !::lCtrlPress .AND. (::lAutoEdit .OR. ::aColumns[::SetColumn()]:lEditable)
               ::Edit(wParam)
            ELSE
               ::DoHScroll(SB_LEFT)
            ENDIF
            EXIT
         CASE VK_END
            IF !::lCtrlPress .AND. (::lAutoEdit .OR. ::aColumns[::SetColumn()]:lEditable)
               ::Edit(wParam)
            ELSE
               ::DoHScroll(SB_RIGHT)
            ENDIF
            EXIT
         CASE VK_NEXT
            IF !::ChangeRowCol(1)
               RETURN -1
            ENDIF
            nRecStart := Eval(::brecno, Self)
            IF ::lCtrlPress
               IF (::nRecords > ::rowCount)
                  ::BOTTOM()
               ELSE
                 ::PageDown()
               ENDIF
            ELSE
              ::PageDown()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
               nRecStop := Eval(::brecno, Self)
               Eval(::bskip, Self, 1)
               lBEof := Eval(::beof, Self)
               Eval(::bskip, Self, -1)
               IF !(lBEof .AND. AScan(::aSelected, Eval(::bRecno, Self)) > 0)
                  ::Select()
               ENDIF
               DO WHILE Eval(::bRecno, Self) != nRecStart
                  ::Select()
                  Eval(::bskip, Self, -1)
               ENDDO
               ::Select()
               Eval(::bgoto, Self, nRecStop)
               Eval(::bskip, Self, 1)
               IF Eval(::beof, Self)
                  Eval(::bskip, Self, -1)
                  ::Select()
               ELSE
                  Eval(::bskip, Self, -1)
               ENDIF
               ::Refresh()
            ENDIF
            EXIT
         CASE VK_PRIOR
            IF !::ChangeRowCol(1)
               RETURN -1
            ENDIF
            nRecStop := Eval(::brecno, Self)
            IF ::lCtrlPress
               ::TOP()
            ELSE
               ::PageUp()
            ENDIF
            IF ::lShiftPress .AND. ::aSelected != NIL
                nRecStart := Eval(::bRecno, Self)
                DO WHILE Eval(::bRecno, Self) != nRecStop
                   ::Select()
                   Eval(::bskip, Self, 1)
                ENDDO
                Eval(::bgoto, Self, nRecStart)
                ::Refresh()
            ENDIF
            EXIT
         CASE VK_RETURN
            ::Edit(VK_RETURN)
            EXIT
         CASE VK_ESCAPE
            IF ::lESC
               IF ::GetParentForm():Type < WND_DLG_RESOURCE
                  hwg_SendMessage(hwg_GetParent(::handle), WM_SYSCOMMAND, SC_CLOSE, 0)
               ELSE
                  hwg_SendMessage(hwg_GetParent(::handle), WM_CLOSE, 0, 0)
               ENDIF
            ENDIF
            EXIT
         CASE VK_CONTROL
            ::lCtrlPress := .T.
            EXIT
         CASE VK_SHIFT
            ::lShiftPress := .T.
         //ELSEIF ::lAutoEdit .AND. (wParam >= 48 .AND. wParam <= 90 .OR. wParam >= 96 .AND. wParam <= 111)
         //   ::Edit(wParam, lParam)
         ENDSWITCH
         RETURN 1
      ENDIF
      EXIT

   CASE WM_LBUTTONDBLCLK
      ::ButtonDbl(lParam)
      EXIT

   CASE WM_LBUTTONDOWN
      ::ButtonDown(lParam)
      EXIT

   CASE WM_LBUTTONUP
      ::ButtonUp(lParam)
      EXIT

   CASE WM_RBUTTONDOWN
      ::ButtonRDown(lParam)
      EXIT

   CASE WM_MOUSEMOVE
      IF !::oParent:lSuspendMsgsHandling
         IF ::nWheelPress > 0
            ::MouseWheel(hwg_LOWORD(wParam), ::nWheelPress - lParam)
         ELSE
            ::MouseMove(wParam, lParam)
            IF ::lHeadClick
               AEval(::aColumns, {|c|c:lHeadClick := .F.})
               hwg_InvalidateRect(::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1)
               ::lHeadClick := .F.
            ENDIF
            IF !::allMouseOver .AND. ::hTheme != NIL
               ::allMouseOver := .T.
               TRACKMOUSEVENT(::handle)
            ELSE
               TRACKMOUSEVENT(::handle, TME_HOVER + TME_LEAVE)
            ENDIF
         ENDIF
      ENDIF
      EXIT

   CASE WM_MOUSEHOVER
      ::ShowColToolTips(lParam)
      EXIT

   CASE WM_MOUSELEAVE
   CASE WM_NCMOUSELEAVE //.AND. !::oParent:lSuspendMsgsHandling
      IF ::allMouseOver
         //::MouseMove(0, 0)
         ::MouseMove(wParam, lParam)
         ::allMouseOver := .F.
         //::isMouseOver := .F.
      ENDIF
      EXIT

   CASE WM_MBUTTONUP
      ::nWheelPress := IIf(::nWheelPress > 0, 0, lParam)
      IF ::nWheelPress > 0
         hwg_SetCursor(hwg_LoadCursor(32652))
      ELSE
         hwg_SetCursor(hwg_LoadCursor(IDC_ARROW))
      ENDIF
      EXIT

   //CASE WM_MOUSEWHEEL
   //   ::MouseWheel(hwg_LOWORD(wParam), IIf(hwg_HIWORD(wParam) > 32768, hwg_HIWORD(wParam) - 65535, hwg_HIWORD(wParam)), ;
   //      hwg_LOWORD(lParam), hwg_HIWORD(lParam))

   CASE WM_DESTROY
     IF hb_IsPointer(::hTheme)
        HB_CLOSETHEMEDATA(::htheme)
       ::hTheme := NIL
     ENDIF
     ::END()

   ENDSWITCH

RETURN -1
#endif

//----------------------------------------------------//
METHOD Redefine(lType, oWndParent, nId, oFont, bInit, bSize, bPaint, bEnter, bGfocus, bLfocus) CLASS HBrowse

   ::Super:New(oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, bSize, bPaint)

   ::Type := lType
   IF oFont == NIL
      ::oFont := ::oParent:oFont
   ENDIF
   ::bEnter := bEnter
   ::bGetFocus := bGfocus
   ::bLostFocus := bLfocus

   hwg_RegBrowse()
   ::InitBrw()

RETURN Self

//----------------------------------------------------//
METHOD FindBrowse(nId) CLASS HBrowse
   
   LOCAL i := AScan(::aItemsList, {|o|o:id == nId}, 1, ::iItems)

RETURN IIf(i > 0, ::aItemsList[i], NIL)

//----------------------------------------------------//
METHOD AddColumn(oColumn) CLASS HBrowse

   AAdd(::aColumns, oColumn)
   ::lChanged := .T.
   InitColumn(Self, oColumn, Len(::aColumns))

RETURN oColumn

//----------------------------------------------------//
METHOD InsColumn(oColumn, nPos) CLASS HBrowse

   AAdd(::aColumns, NIL)
   AIns(::aColumns, nPos)
   ::aColumns[nPos] := oColumn
   ::lChanged := .T.
   InitColumn(Self, oColumn, nPos)

RETURN oColumn

STATIC FUNCTION InitColumn(oBrw, oColumn, n)
   
   LOCAL xres
   LOCAL ctype
   LOCAL cname := "Column" + LTrim(Str(Len(oBrw:aColumns)))

   IF oColumn:Type == NIL
      oColumn:Type := ValType(Eval(oColumn:block,, oBrw, n))
   ENDIF
   oColumn:width := 0
   IF oColumn:dec == NIL
      IF oColumn:Type == "N" .AND. At(".", Str(Eval(oColumn:block,, oBrw, n))) != 0
         oColumn:dec := Len(SubStr(Str(Eval(oColumn:block,, oBrw, n)), ;
                                     At(".", Str(Eval(oColumn:block,, oBrw, n))) + 1))
      ELSE
         oColumn:dec := 0
      ENDIF
   ENDIF
   IF oColumn:length == NIL
      IF oColumn:picture != NIL .AND. !Empty(oBrw:aArray)
         oColumn:length := Len(Transform(Eval(oColumn:block,, oBrw, n), oColumn:picture))
      ELSE
         oColumn:length := 10
         IF !Empty(oBrw:aArray)
            xres := Eval(oColumn:block,, oBrw, n)
            ctype := ValType(xres)
         ELSE
            xRes := Space(10)
            ctype := "C"
         ENDIF
      ENDIF
//      oColumn:length := Max(oColumn:length, Len(oColumn:heading))
      oColumn:length := LenVal(xres, ctype, oColumn:picture)
   ENDIF
   oColumn:nJusLin := IIf(oColumn:nJusLin == NIL, IIf(oColumn:Type == "N", DT_RIGHT, DT_LEFT), oColumn:nJusLin) + DT_VCENTER + DT_SINGLELINE
   oColumn:lEditable := IIf(oColumn:lEditable != NIL, oColumn:lEditable, .F.)
   oColumn:oParent := oBrw
   oColumn:Column := n
   __objAddData(oBrw, cName)
   oBrw:&(cName) := oColumn

RETURN NIL

//----------------------------------------------------//
METHOD DelColumn(nPos) CLASS HBrowse

   ADel(::aColumns, nPos)
   ASize(::aColumns, Len(::aColumns) - 1)
   ::lChanged := .T.

RETURN NIL

//----------------------------------------------------//
METHOD END() CLASS HBrowse

   ::Super:END()
   IF ::brush != NIL
      ::brush:Release()
      ::brush := NIL
   ENDIF
   IF ::brushSel != NIL
      ::brushSel:Release()
      ::brushSel := NIL
   ENDIF
   IF s_oPen64 != NIL
      s_oPen64:Release()
   ENDIF
   IF ::oTimer != NIL
      ::oTimer:End()
   ENDIF

RETURN NIL

METHOD ShowMark(lShowMark) CLASS HBrowse

   IF lShowMark != NIL
      ::nShowMark := IIf(lShowMark, 12, 0)
      ::lShowMark := lShowMark
      ::Refresh()
   ENDIF

RETURN ::lDeleteMark

METHOD DeleteMark(lDeleteMark) CLASS HBrowse

   IF lDeleteMark != NIL
      IF ::Type == BRW_DATABASE
         ::nDeleteMark := IIf(lDeleteMark, 7, 0)
         ::lDeleteMark := lDeleteMark
         ::Refresh()
      ENDIF
   ENDIF

RETURN ::lDeleteMark

METHOD ShowColToolTips(lParam) CLASS HBrowse
   
   LOCAL pt
   LOCAL cTip := ""

   IF AScan(::aColumns, {|c|c:Hint != .F. .AND. c:Tooltip != NIL}) == 0
      RETURN NIL
   ENDIF
   pt := ::ButtonDown(lParam, .T.)
   IF pt == NIL .OR. pt[1] = - 1
      RETURN NIL
   ELSEIF pt[1] != 0 .AND. pt[2] != 0 .AND. ::aColumns[pt[2]]:Hint
      cTip := ::aColumns[pt[2]]:aHints[pt[1]]
   ELSEIF pt[2] != 0 .AND. ::aColumns[pt[2]]:ToolTip != NIL
      cTip := ::aColumns[pt[2]]:ToolTip
   ENDIF
   IF !Empty(cTip) .OR. !Empty(s_xToolTip)
      hwg_SetToolTipTitle(::GetparentForm():handle, ::handle, cTip)
      s_xToolTip := IIf(!Empty(cTip), cTip, IIf(!Empty(s_xToolTip), NIL, s_xToolTip))
   ENDIF

RETURN NIL

METHOD SetRefresh(nSeconds) CLASS HBrowse

   IF nSeconds != NIL //.AND. ::Type == BRW_DATABASE
      IF ::oTimer != NIL
         ::oTimer:Interval := nSeconds * 1000
      ELSEIF nSeconds > 0
         SET TIMER ::oTimer OF ::GetParentForm() VALUE (nSeconds * 1000)  ACTION {||IIf(hwg_IsWindowVisible(::handle),;
            (::internal[1] := 12, hwg_InvalidateRect(::handle, 0, ::x1, ::y1, ::x1 + ::xAdjRight, ;
            ::y1 + ::rowCount * (::height + 1) + 1)), NIL)}
      ENDIF
      ::nSetRefresh := nSeconds
   ENDIF

RETURN ::nSetRefresh

//----------------------------------------------------//
METHOD InitBrw(nType, lInit) CLASS HBrowse
   
   LOCAL cAlias := Alias()

   DEFAULT lInit to .F.
   IF Empty(lInit)
      ::x1 := ::y1 := ::x2 := ::y2 := ::xAdjRight := 0
      ::height := ::width := 0
      ::nyHeight := IIf(::GetParentForm(self):Type < WND_DLG_RESOURCE, 1, 0)
      ::lDeleteMark := .F.
      ::lShowMark := .T.
      IF nType != NIL
         ::Type := nType
      ELSE
         ::aColumns := {}
         ::rowPos := ::nCurrent := ::colpos := 1
         ::nLeftCol := 1
         ::freeze := 0
         ::internal := {15, 1, 0, 0}
         ::aArray := NIL
         ::aMargin := {1, 1, 0, 1}
         IF Empty(s_ColSizeCursor)
            s_ColSizeCursor := hwg_LoadCursor(IDC_SIZEWE)
            s_arrowCursor := hwg_LoadCursor(IDC_ARROW)
            s_downCursor := hwg_LoadCursor(IDC_HAND)
         ENDIF
         s_oPen64 := HPen():Add(PS_SOLID, 1, IIf(::Themed, RGB(128, 128, 128), RGB(64, 64, 64)))
      ENDIF
   ENDIF

   IF !Empty(::RelationalExpr)
      ::lFilter := .T.
   ENDIF

   IF ::Type == BRW_DATABASE
      ::Filter(::lFilter)
      /*
      IF !Empty(::Alias) .AND. SELECT(::Alias) > 0
         SELECT (::Alias)
      ENDIF
      ::Alias := Alias()
      IF Empty(::ALias)
         RETURN NIL
      ENDIF
     IF ::lFilter
         ::nLastRecordFilter := ::nFirstRecordFilter := 0
         IF ::lDescend
            ::bSkip := {|o, n|(::Alias)->(FltSkip(o, n, .T.))}
            ::bGoTop := {|o|(::Alias)->(FltGoBottom(o))}
            ::bGoBot := {|o|(::Alias)->(FltGoTop(o))}
            ::bEof := {|o|(::Alias)->(FltBOF(o))}
            ::bBof := {|o|(::Alias)->(FltEOF(o))}
         ELSE
            ::bSkip := {|o, n|(::Alias)->(FltSkip(o, n, .F.))}
            ::bGoTop := {|o|(::Alias)->(FltGoTop(o))}
            ::bGoBot := {|o|(::Alias)->(FltGoBottom(o))}
            ::bEof := {|o|(::Alias)->(FltEOF(o))}
            ::bBof := {|o|(::Alias)->(FltBOF(o))}
         ENDIF
         ::bRcou := {|o|(::Alias)->(FltRecCount(o))}
         ::bRecnoLog := ::bRecno := {|o|(::Alias)->(FltRecNo(o))}
         ::bGoTo := {|o, n|(::Alias)->(FltGoTo(o, n))}
      ELSE
         ::bSkip := {|o, n|HB_SYMBOL_UNUSED(o), (::Alias)->(DBSkip(n))}
         ::bGoTop := {||(::Alias)->(DBGoTop())}
         ::bGoBot := {||(::Alias)->(DBGoBottom())}
         ::bEof := {||(::Alias)->(Eof())}
         ::bBof := {||(::Alias)->(Bof())}
         ::bRcou := {||(::Alias)->(RecCount())}
         ::bRecnoLog := ::bRecno  := {||(::Alias)->(RecNo())}
         ::bGoTo := {|a, n|HB_SYMBOL_UNUSED(a), (::Alias)->(DBGoTo(n))}
      ENDIF
      */
   ELSEIF ::Type == BRW_ARRAY
      ::bSkip := {|o, n|ARSKIP(o, n)}
      ::bGoTop := {|o|o:nCurrent := 1}
      ::bGoBot := {|o|o:nCurrent := o:nRecords}
      ::bEof := {|o|o:nCurrent > o:nRecords}
      ::bBof := {|o|o:nCurrent == 0}
      ::bRcou := {|o|Len(o:aArray)}
      ::bRecnoLog := ::bRecno  := {|o|o:nCurrent}
      ::bGoTo := {|o, n|o:nCurrent := n}
      ::bScrollPos := {|o, n, lEof, nPos|VScrollPos(o, n, lEof, nPos)}
   ENDIF

   IF lInit
      IF !Empty(::LinkMaster)
         SELECT (::Alias)
         IF !Empty(::ChildOrder)
            (::Alias)->(DBSETORDER(::ChildOrder))
         ENDIF
         IF !Empty(::RelationalExpr)
             ::bFirst := {||(::Alias)->(DBSEEK((::LinkMaster)->(&(::RelationalExpr)), .F.))}
             ::bLast := {||(::Alias)->(DBSEEK((::LinkMaster)->(&(::RelationalExpr)), .F., .T.))}
             ::bWhile := {||(::Alias)->(&(::RelationalExpr)) = (::LinkMaster)->(&(::RelationalExpr))}
             //::bSkip := {|o, n|HB_SYMBOL_UNUSED(o), (::Alias)->(DBSkip(n))}
          ENDIF
      ENDIF
   ENDIF
   IF !Empty(cAlias)
      SELECT (cAlias)
   ENDIF

RETURN NIL

METHOD FILTER(lFilter) CLASS HBrowse

   IF lFilter != NIL .AND. ::Type == BRW_DATABASE
      IF Empty(::Alias)
        ::Alias := Alias()
      ENDIF
      IF !Empty(::Alias) .AND. SELECT(::Alias) > 0
         SELECT (::Alias)
      ENDIF
      IF Empty(::ALias)
         RETURN ::lFilter
      ENDIF
      IF lFilter
         ::nLastRecordFilter := ::nFirstRecordFilter := 0
         ::rowCurrCount := 0
         IF ::lDescend
            ::bSkip := {|o, n|(::Alias)->(FltSkip(o, n, .T.))}
            ::bGoTop := {|o|(::Alias)->(FltGoBottom(o))}
            ::bGoBot := {|o|(::Alias)->(FltGoTop(o))}
            ::bEof := {|o|(::Alias)->(FltBOF(o))}
            ::bBof := {|o|(::Alias)->(FltEOF(o))}
         ELSE
            ::bSkip := {|o, n|(::Alias)->(FltSkip(o, n, .F.))}
            ::bGoTop := {|o|(::Alias)->(FltGoTop(o))}
            ::bGoBot := {|o|(::Alias)->(FltGoBottom(o))}
            ::bEof := {|o|(::Alias)->(FltEOF(o))}
            ::bBof := {|o|(::Alias)->(FltBOF(o))}
         ENDIF
         //::bRcou := {|o|(::Alias)->(FltRecCount(o))}
         ::bRcou := {||(::Alias)->(RecCount())}
         ::bRecnoLog := ::bRecno := {|o|(::Alias)->(FltRecNo(o))}
         ::bGoTo := {|o, n|(::Alias)->(FltGoTo(o, n))}
      ELSE
         ::bSkip := {|o, n|HB_SYMBOL_UNUSED(o), (::Alias)->(DBSkip(n))}
         ::bGoTop := {||(::Alias)->(DBGoTop())}
         ::bGoBot := {||(::Alias)->(DBGoBottom())}
         ::bEof := {||(::Alias)->(Eof())}
         ::bBof := {||(::Alias)->(Bof())}
         ::bRcou := {||(::Alias)->(RecCount())}
         ::bRecnoLog := ::bRecno  := {||(::Alias)->(RecNo())}
         ::bGoTo := {|a, n|HB_SYMBOL_UNUSED(a), (::Alias)->(DBGoTo(n))}
      ENDIF
      ::lFilter := lFilter
   ENDIF

RETURN ::lFilter

//----------------------------------------------------//
METHOD Rebuild() CLASS HBrowse
   
   LOCAL i
   LOCAL j
   LOCAL oColumn
   LOCAL xSize
   LOCAL nColLen
   LOCAL nHdrLen
   LOCAL nCount
   LOCAL fontsize

   IF ::brush != NIL
      ::brush:Release()
   ENDIF
   IF ::brushSel != NIL
      ::brushSel:Release()
   ENDIF
   IF ::bcolor != NIL
      ::brush := HBrush():Add(::bcolor)
//      IF hDC != NIL
//         hwg_SendMessage(::handle, WM_ERASEBKGND, hDC, 0)
//      ENDIF
   ENDIF
   IF ::bcolorSel != NIL
      ::brushSel := HBrush():Add(::bcolorSel)
   ENDIF
   ::nLeftCol := ::freeze + 1
   // ::nCurrent := ::rowPos := ::colPos := 1
   ::lEditable := .F.
   ::minHeight := 0

   FOR i := 1 TO Len(::aColumns)

      oColumn := ::aColumns[i]

      IF oColumn:lEditable
         ::lEditable := .T.
      ENDIF
      //FontSize := TxtRect("a", Self, oColumn:oFont)[1]
      FontSize := IIf(oColumn:type $ "DN", TxtRect("9", Self, oColumn:oFont)[1], TxtRect("N", Self, oColumn:oFont)[1])
      IF oColumn:aBitmaps != NIL
         IF oColumn:heading != NIL
            /*
            IF ::oFont != NIL
               xSize := Round((Len(oColumn:heading) + 2) * ((-::oFont:height) * 0.6), 0)
            ELSE
               xSize := Round((Len(oColumn:heading) + 2) * 6, 0)
            ENDIF
            */
            xSize := Round((Len(oColumn:heading) + 0.6) * FontSize, 0)
         ELSE
            xSize := 0
         ENDIF
         IF ::forceHeight > 0
            ::minHeight := ::forceHeight
         ELSE
            FOR j := 1 TO Len(oColumn:aBitmaps)
               xSize := Max(xSize, oColumn:aBitmaps[j, 2]:nWidth + 2)
               ::minHeight := Max(::minHeight, ::aMargin[1] + oColumn:aBitmaps[j, 2]:nHeight + ::aMargin[3])
            NEXT
         ENDIF
      ELSE
         // xSize := round((max(Len(FldStr(Self, i)), Len(oColumn:heading)) + 2) * 8, 0)
         nColLen := oColumn:length
         IF oColumn:heading != NIL
            HdrToken(oColumn:heading, @nHdrLen, @nCount)
            IF !oColumn:lSpandHead
               nColLen := Max(nColLen, nHdrLen)
            ENDIF
            ::nHeadRows := Max(::nHeadRows, nCount)
         ENDIF
         IF oColumn:footing != NIL .AND. !oColumn:lHide
            HdrToken(oColumn:footing, @nHdrLen, @nCount)
            IF !oColumn:lSpandFoot
               nColLen := Max(nColLen, nHdrLen)
            ENDIF
            ::nFootRows := Max(::nFootRows, nCount)
         ENDIF
         /*
         IF ::oFont != NIL
            //xSize := Round((nColLen + 2) * ((-::oFont:height) * 0.6), 0) // Added by Fernando Athayde
            xSize := Round((nColLen) * ((-::oFont:height) * 0.6), 0) // Added by Fernando Athayde
         ELSE
            //xSize := Round((nColLen + 2) * 6, 0)
            xSize := Round((nColLen) * 6, 0)
         ENDIF
         */
         xSize := Round((nColLen + 0.6) * ((FontSize)), 0)
      ENDIF
      xSize := ::aMargin[4] + xSize + ::aMargin[2]
      IF Empty(oColumn:width)
         oColumn:width := xSize
      ENDIF
   NEXT
   IF HWG_BITAND(::style, WS_HSCROLL) != 0
       SetScrollInfo(::handle, SB_HORZ, 1, 0, 1, Len(::aColumns))
   ENDIF

   ::lChanged := .F.

RETURN NIL

METHOD AutoFit() CLASS HBrowse
   
   LOCAL nlen
   LOCAL i
   LOCAL aCoors
   LOCAL nXincRelative

   IF ::AutoColumnFit == 2
      RETURN .F.
   ENDIF
   ::lAdjRight := .F.
   ::oParent:lSuspendMsgsHandling := .T.
   hwg_RedrawWindow(::handle, RDW_VALIDATE + RDW_UPDATENOW)
   ::oParent:lSuspendMsgsHandling := .F.
   aCoors := hwg_GetWindowRect(::handle)
   IF ::nAutoFit == NIL
      ::nAutoFit := IIf(Max(0, ::x2 - ::xAdjRight - 2) == 0, 0, ::x2 / ::xAdjRight)
      nXincRelative := IIf((aCoors[3] - aCoors[1]) - (::nWidth) > 0, ::nAutoFit, 1 / ::nAutoFit)
   ELSE
      nXincRelative := (aCoors[3] - aCoors[1]) / (::nWidth) - 0.01
   ENDIF
   IF ::nAutoFit == 0 .OR. nXincRelative < 1
      IF nXincRelative < 0.1 .OR. ::nAutoFit == 0
         ::nAutoFit := IIf(nXincRelative < 1, NIL, ::nAutoFit)
         RETURN .F.
      ENDIF
      ::nAutoFit := IIf(nXincRelative < 1, NIL, ::nAutoFit)
   ENDIF
    nlen := Len(::aColumns)
   FOR i := 1 to nLen
      IF ::aColumns[i]:Resizable
         ::aColumns[i]:Width := ::aColumns[i]:Width  * nXincRelative
      ENDIF
   NEXT

RETURN .T.

//----------------------------------------------------//
METHOD Paint(lLostFocus) CLASS HBrowse
   
   LOCAL aCoors
   LOCAL aMetr
   LOCAL cursor_row
   LOCAL tmp
   LOCAL nRows
   LOCAL nRowsFill
   LOCAL pps
   LOCAL hDC
   LOCAL oldfont
   LOCAL aMetrHead
   LOCAL nRecFilter

   IF !::active .OR. Empty(::aColumns) .OR. ::lHeadClick  //.OR. ::isMouseOver //.AND. ::internal[1] == WM_MOUSEMOVE)
      pps := hwg_DefinePaintStru()
      hDC := hwg_BeginPaint(::handle, pps)
      IF ::lHeadClick .OR. ::isMouseOver
          ::oParent:lSuspendMsgsHandling := .T.
          ::HeaderOut(hDC)
          ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
      hwg_EndPaint(::handle, pps)
      ::isMouseOver := .F.

      RETURN NIL
   ENDIF
   IF (::m_bFirstTime) .AND. ::Themed
      ::m_bFirstTime := .F.
      IF (ISTHEMEDLOAD())
         IF hb_IsPointer(::hTheme)
            HB_CLOSETHEMEDATA(::htheme)
         ENDIF
         IF ::WindowsManifest
            ::hTheme := hb_OpenThemeData(::handle, "HEADER")
         ENDIF
         ::hTheme := IIf(Empty(::hTheme), NIL, ::hTheme)
      ENDIF

ENDIF

// Validate some variables

   IF ::tcolor == NIL
      ::tcolor := 0
   ENDIF
   IF ::bcolor == NIL
      ::bcolor := VColor("FFFFFF")
   ENDIF

   //IF ::httcolor == NIL
   //   ::httcolor := VColor("FFFFFF")
   //ENDIF
   //IF ::htbcolor == NIL
   //   ::htbcolor := 2896388
   //ENDIF
   IF ::httcolor == NIL
      ::httcolor := GETSYSCOLOR(COLOR_HIGHLIGHTTEXT)
   ENDIF
   IF ::htbcolor == NIL
      ::htbcolor := GETSYSCOLOR(COLOR_HIGHLIGHT)
   ENDIF

   IF ::tcolorSel == NIL
      ::tcolorSel := VColor("FFFFFF")
   ENDIF
   IF ::bcolorSel == NIL
      ::bcolorSel := VColor("808080")
   ENDIF

// Open Paint procedure

   pps := hwg_DefinePaintStru()
   hDC := hwg_BeginPaint(::handle, pps)

   IF ::ofont != NIL
      hwg_SelectObject(hDC, ::ofont:handle)
   ENDIF
   IF ::brush == NIL .OR. ::lChanged
      ::Rebuild()
   ENDIF

// Get client area coordinate

   aCoors := hwg_GetClientRect(::handle)
   aMetr := GetTextMetric(hDC)
   ::width := Round((aMetr[3] + aMetr[2]) / 2 - 1, 0)
// If forceHeight is set, we should use that value
   IF (::forceHeight > 0)
      ::height := ::forceHeight + 1
   ELSE
      ::height := ::aMargin[1] + Max(aMetr[1], ::minHeight) + 1 + ::aMargin[3]
   ENDIF

   aMetrHead := AClone(aMetr)
   IF ::oHeadFont != NIL
      oldfont := hwg_SelectObject(hDC, ::oHeadFont:handle)
      aMetrHead := GetTextMetric(hDC)
      hwg_SelectObject(hDC, oldfont)
   ENDIF
   // USER DEFINE Height  IF != 0
   IF Empty(::nHeadHeight)
      ::nHeadHeight := ::aMargin[1] + aMetrHead[1] + 1 + ::aMargin[3] + 3
   ENDIF
   IF Empty(::nFootHeight)
      ::nFootHeight := ::aMargin[1] + aMetr[1] + 1 + ::aMargin[3]
   ENDIF

   ::x1 := aCoors[1] +  ::nShowMark + ::nDeleteMark
   ::y1 := aCoors[2] + IIf(::lDispHead, ::nHeadHeight * ::nHeadRows, 0)
   ::x2 := aCoors[3]
   ::y2 := aCoors[4] // - IIf(::nFootRows > 0, ::nFootHeight*::nFootRows, 0)
   //--::xAdjRight := ::x2
   IF ::lRepaintBackground
      //FillRect(hDC, ::x1 - ::nDeleteMark, ::y1, ::x2, ::y2 - (::nFootHeight * ::nFootRows), ::brush:handle)
      FillRect(hDC, ::x1 - ::nDeleteMark, ::y1, ::xAdjRight, ::y2 - (::nFootHeight * ::nFootRows), ::brush:handle)
      ::lRepaintBackground := .F.
   ENDIF

   nRowsFill := ::rowCurrCount

   ::nRecords := Eval(::bRcou, Self)
   IF ::nCurrent > ::nRecords .AND. ::nRecords > 0
      ::nCurrent := ::nRecords
   ENDIF

// Calculate number of columns visible

   ::nColumns := FLDCOUNT(Self, ::x1 + 2, ::x2 - 2, ::nLeftCol)

// Calculate number of rows the canvas can host
   ::rowCount := Int((::y2 - ::y1 - (::nFootRows * ::nFootHeight)) / (::height + 1))

// nRows: if number of data rows are less than video rows available....
   nRows := Min(::nRecords, ::rowCount)

   IF ::internal[1] == 0
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         Eval(::bSkip, Self, ::internal[2] - ::rowPos)
      ENDIF
      ::oParent:lSuspendMsgsHandling := .T.
      IF ::aSelected != NIL .AND. AScan(::aSelected, {|x|x = Eval(::bRecno, Self)}) > 0
         ::LineOut(::internal[2], 0, hDC, !::lResizing)
      ELSE
         ::LineOut(::internal[2], 0, hDC, .F.)
      ENDIF
      IF ::rowPos != ::internal[2] .AND. !::lAppMode
         Eval(::bSkip, Self, ::rowPos - ::internal[2])
      ENDIF
    ELSEIF ::internal[1] == 2
    /*
       tmp := Eval(::bRecno, Self)
       Eval(::bgoto, Self, ::internal[3])
       cursor_row := 1
       DO WHILE .T.
         IF Eval(::bRecno, Self) == ::internal[4]
            EXIT
         ENDIF
         //IF cursor_row > nRows .OR. (Eval(::bEof, Self) .AND. !::lAppMode)
         //   EXIT
         //ENDIF
         ::LineOut(cursor_row, 0, hDC, .F.)
         cursor_row++
         Eval(::bSkip, Self, 1)
       ENDDO
       */
       ::xAdjRight := ::x2
       ::HeaderOut(hDC)
       //Eval(::bGoTo, Self, tmp)

    ELSE
      IF !::lAppMode
         //IF Eval(::bEof, Self) .OR. Eval(::bBof, Self)
         IF Eval(::bEof, Self) .OR. Eval(::bBof, Self) .OR. ::rowPos > ::nRecords
            Eval(::bGoTop, Self)
            ::rowPos := 1
         ENDIF
      ENDIF
// Se riga_cursore_video > numero_record
//    metto il cursore sull'ultima riga
      IF ::rowPos > nRows .AND. nRows > 0
         ::rowPos := nRows
      ENDIF

// Take record number
      tmp := Eval(::bRecno, Self)

// if riga_cursore_video > 1
//   we skip ::rowPos-1 number of records back,
//   actually positioning video cursor on first line
      IF ::rowPos > 1
        // Eval(::bSkip, Self, -(::rowPos - 1))
      ENDIF
      // new
      IF ::lFilter .AND. ::rowPos > 1 .AND. tmp = ::nFirstRecordFilter
        Eval(::bSkip, Self, (::rowPos - 1))
        tmp := Eval(::bRecno, Self)
      ENDIF

// Browse printing is split in two parts
// first part starts from video row 1 and goes to end of data (EOF)
//   or end of video lines

// second part starts from where part 1 stopped -
      // new 01/09/2009 - nando
      //nRecFilter := FltRecNoRelative(Self)
      nRecFilter := 0
      IF ::Type == BRW_DATABASE
         nRecFilter := (::Alias)->(RecNo())
         IF ::lFilter .AND. Empty(::RelationalExpr)
            nRecFilter := AScan(::aRecnoFilter, (::Alias)->(RecNo()))
         ELSEIF !Empty((::Alias)->(DBFILTER())) .AND. (::Alias)->(RecNo()) > ::nRecords
            nRecFilter := ::nRecords
         ENDIF
      ENDIF
      IF ::rowCurrCount == 0 .AND. ::nRecords > 0 // INIT
         Eval(::bSkip, Self, 1)
         ::rowCurrCount := IIf(Eval(::bEof, Self), ::rowCount, IIf(::nRecords < ::rowCount, ::nRecords, 1))
         nRecFilter := - 1
      ELSEIF ::nRecords < ::rowCount
         ::rowCurrCount := ::nRecords
      ELSEIF ::rowCurrCount >= ::RowPos .AND. nRecFilter <= ::nRecords
         ::rowCurrCount -= (::rowCurrCount - ::RowPos + 1)
      ELSEIF ::rowCurrCount > ::rowCount - 1
         ::rowCurrCount := ::rowCount - 1
      ENDIF
      IF ::rowCurrCount > 0
          Eval(::bSkip, Self, - ::rowCurrCount)
          IF Eval(::bBof, Self)
               Eval(::bGoTop, Self)
          ENDIF
      ENDIF

      cursor_row := 1
      ::oParent:lSuspendMsgsHandling := .T.
      ::internal[3] := Eval(::bRecno, Self)
       AEval(::aColumns, {|c|c:aHints := {}})
      DO WHILE .T.
         // if we are on the current record, set current video line
         IF Eval(::bRecno, Self) == tmp
            ::rowPos := cursor_row
         ENDIF

         // exit loop when at last row or eof()
         IF cursor_row > nRows .OR. (Eval(::bEof, Self) .AND. !::lAppMode)
            EXIT
         ENDIF

         // decide how to print the video row
         IF ::aSelected != NIL .AND. AScan(::aSelected, {|x|x = Eval(::bRecno, Self)}) > 0
            ::LineOut(cursor_row, 0, hDC, !::lResizing)
         ELSE
            ::LineOut(cursor_row, 0, hDC, .F.)
         ENDIF
         cursor_row++
         Eval(::bSkip, Self, 1)
      ENDDO
      ::internal[4] := Eval(::bRecno, Self)
      //::rowCurrCount := cursor_row - 1
      ::rowCurrCount := IIf(cursor_row - 1 < ::rowCurrCount, ::rowCurrCount, cursor_row - 1)

      // set current_video_line depending on the situation
      IF ::rowPos >= cursor_row
         ::rowPos := IIf(cursor_row > 1, cursor_row - 1, 1)
      ENDIF

      // print the rest of the browse

      DO WHILE cursor_row <= ::rowCount .AND. (::nRecords > nRows .AND. !Eval(::bEof, Self))
         //IF ::aSelected != NIL .AND. AScan(::aSelected, {|x|x = Eval(::bRecno, Self)}) > 0
         //   ::LineOut(cursor_row, 0, hDC, .T., .T.)
         //ELSE
            ::LineOut(cursor_row, 0, hDC, .F., .T.)
         //ENDIF
         cursor_row++
      ENDDO
      IF ::lDispSep .AND. !Checkbit(::internal[1], 1) .AND. nRowsFill <= ::rowCurrCount
         ::SeparatorOut(hDC, ::rowCurrCount)
      ENDIF
      nRowsFill := cursor_row - 1
      // fill the remaining canvas area with background color if needed
      nRows := cursor_row - 1
      IF nRows < ::rowCount .OR. (nRows * (::height - 1) + ::nHeadHeight + ::nFootHeight) < ::nHeight
       //  FillRect(hDC, ::x1, ::y1 + (::height + 1) * nRows + 1, ::x2, ::y2, ::brush:handle)
      ENDIF
      Eval(::bGoTo, Self, tmp)
   ENDIF
   IF ::lAppMode
      ::LineOut(nRows + 1, 0, hDC, .F., .T.)
   ENDIF

   //::LineOut(::rowPos, IIf(::lEditable, ::colpos, 0), hDC, .T.)

   // Highlights the selected ROW
   // we can have a modality with CELL selection only or ROW selection
   IF !::lHeadClick .AND. (!::lEditable .OR. (::lEditable .AND. ::Highlight)) // .AND.!::lResizing
      ::LineOut(::rowPos, 0, hDC, !::lResizing)
   ENDIF
   // Highligths the selected cell
   // FP: Reenabled the lEditable check as it's not possible
   //     to move the "cursor cell" if lEditable is FALSE
   //     Actually: if lEditable is FALSE we can only have LINE selection
//   if ::lEditable
   IF lLostFocus == NIL .AND. !::lHeadClick .AND. (::lEditable .OR. ::Highlight)  //.AND. !::lResizing
      ::LineOut(::rowPos, ::colpos, hDC, !::lResizing)
   ENDIF
//   endif

   // if bit-1 refresh header and footer
   ::oParent:lSuspendMsgsHandling := .F.

   IF Checkbit(::internal[1], 1) .OR. ::lAppMode
      //IF ::lDispSep
         ::SeparatorOut(hDC, nRowsFill)
      //ENDIF
      IF ::nHeadRows > 0
         ::HeaderOut(hDC)
      ENDIF
      IF ::nFootRows > 0
         ::FooterOut(hDC)
      ENDIF
   ENDIF
   IF ::lAppMode .AND. ::nRecords != 0 .AND. ::rowPos = ::rowCount
       ::LineOut(::rowPos, 0, hDC, .T., .T.)
   ENDIF

   // End paint block
   hwg_EndPaint(::handle, pps)

   ::internal[1] := 15
   ::internal[2] := ::rowPos

   // calculate current bRecno()
   tmp := Eval(::bRecno, Self)
   IF ::recCurr != tmp
      ::recCurr := tmp
      IF ::bPosChanged != NIL
         Eval(::bPosChanged, Self, ::rowpos)
      ENDIF
   ENDIF

   IF ::lAppMode
      ::Edit()
   ENDIF

   ::lAppMode := .F.

   // fixed postion vertical scroll bar in refresh out browse
   IF hwg_GetFocus() != ::handle .OR. nRecFilter = - 1
       Eval(::bSkip, Self, 1)
       Eval(::bSkip, Self, -1)
       IF hb_IsBlock(::bScrollPos) // array
         Eval(::bScrollPos, Self, 1, .F.)
      ELSE
         VScrollPos(Self, 0, .F.)
      ENDIF
   ENDIF

RETURN NIL

//----------------------------------------------------//
// TODO: hb_tokenGet() can create problems.... can't have separator as first char
METHOD HeaderOut(hDC) CLASS HBrowse
   
   LOCAL x
   LOCAL oldc
   LOCAL fif
   LOCAL xSize
   LOCAL lFixed := .F.
   LOCAL xSizeMax
   LOCAL oPen
   LOCAL oldBkColor
   LOCAL oColumn
   LOCAL nLine
   LOCAL cStr
   LOCAL cNWSE
   LOCAL oPenHdr
   LOCAL oPenLight
   LOCAL toldc
   LOCAL oldfont
   LOCAL oBmpSort
   LOCAL nMe
   LOCAL nMd
   LOCAL captionRect := {,,,}
   LOCAL aTxtSize
   LOCAL state
   LOCAL aItemRect

   oldBkColor := SetBkColor(hDC, GetSysColor(COLOR_3DFACE))

   IF ::hTheme == NIL
      hwg_SelectObject(hDC, s_oPen64:handle)
      Rectangle(hDC,;
               ::x1 - ::nShowMark - ::nDeleteMark, ;
               ::y1 - (::nHeadHeight * ::nHeadRows) - ::nyHeight, ;
               ::x2, ;
               ::y1)
   ENDIF
   IF !::lDispSep
      oPen := HPen():Add(PS_SOLID, 1, ::bColor)
      hwg_SelectObject(hDC, oPen:handle)
   ELSEIF ::lDispSep
      oPen := HPen():Add(PS_SOLID, 1, ::sepColor)
      hwg_SelectObject(hDC, oPen:handle)
   ENDIF
   IF ::lSep3d
      oPenLight := HPen():Add(PS_SOLID, 1, GetSysColor(COLOR_3DHILIGHT))
   ENDIF

   x := ::x1
   IF ::oHeadFont != NIL
      oldfont := hwg_SelectObject(hDC, ::oHeadFont:handle)
   ENDIF
   IF ::headColor != NIL
      oldc := SetTextColor(hDC, ::headColor)
   ENDIF
   fif := IIf(::freeze > 0, 1, ::nLeftCol)

   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[fif]
      IF oColumn:headColor != NIL
         toldc := SetTextColor(hDC, oColumn:headColor)
      ENDIF
      xSize := oColumn:width
      IF ::lAdjRight .AND. fif == Len(::aColumns)
         xSize := Max(::x2 - x, xSize)
      ENDIF
      xSizeMax := xSize

      IF (fif == Len(::aColumns)) .OR. lFixed
         xSizeMax := Max(::x2 - x, xSize)
         xSize := IIf(::lAdjRight, xSizeMax, xSize)
      ENDIF
      // NANDO
      IF !oColumn:lHide
       IF ::lDispHead .AND. !::lAppMode
         IF oColumn:cGrid == NIL
          //-  DrawButton(hDC, x - 1, ::y1 - ::nHeadHeight * ::nHeadRows, x + xSize - 1, ::y1 + 1, 1)
            IF xsize != xsizeMax
                DrawButton(hDC, x + xsize, ::y1 - ::nHeadHeight * ::nHeadRows, x + xsizeMax, ::y1 + 1, 0)
            ENDIF
         ELSE
            // Draws a grid to the NWSE coordinate...
          //-  DrawButton(hDC, x - 1, ::y1 - ::nHeadHeight * ::nHeadRows, x + xSize - 1, ::y1 + 1, 0)
            IF xSize != xSizeMax
          //-    DrawButton(hDC, x + xsize - 1, ::y1 - ::nHeadHeight * ::nHeadRows, x + xsizeMax - 1, ::y1 + 1, 0)
            ENDIF
            IF oPenHdr == NIL
               oPenHdr := HPen():Add(BS_SOLID, 1, 0)
            ENDIF
            hwg_SelectObject(hDC, oPenHdr:handle)
            cStr := oColumn:cGrid + ";"
            FOR nLine := 1 TO ::nHeadRows
               cNWSE := hb_tokenGet(@cStr, nLine, ";")
               IF At("S", cNWSE) != 0
                  DrawLine(hDC, x - 1, ::y1 - (::nHeadHeight) * (::nHeadRows - nLine), x + xSize - 1, ::y1 - (::nHeadHeight) * (::nHeadRows - nLine))
               ENDIF
               IF At("N", cNWSE) != 0
                  DrawLine(hDC, x - 1, ::y1 - (::nHeadHeight) * (::nHeadRows - nLine + 1), x + xSize - 1, ::y1 - (::nHeadHeight) * (::nHeadRows - nLine + 1))
               ENDIF
               IF At("E", cNWSE) != 0
                  DrawLine(hDC, x + xSize - 2, ::y1 - (::nHeadHeight) * (::nHeadRows - nLine + 1) + 1, x + xSize - 2, ::y1 - (::nHeadHeight) * (::nHeadRows - nLine))
               ENDIF
               IF At("W", cNWSE) != 0
                  DrawLine(hDC, x - 1, ::y1 - (::nHeadHeight) * (::nHeadRows - nLine + 1) + 1, x - 1, ::y1 - (::nHeadHeight) * (::nHeadRows - nLine))
               ENDIF
            NEXT
            hwg_SelectObject(hDC, oPen:handle)
         ENDIF
         // Prints the column heading - justified
         aItemRect := {x, ::y1 - (::nHeadHeight * ::nHeadRows) - ::nyHeight - 1, x + xSize, ::y1 + 1}
         IF !oColumn:lHeadClick
            state := IIf(::hTheme != NIL, IIf(::xPosMouseOver > x .AND. ::xPosMouseOver < x + xsize - 3,;
                                                PBS_HOT, PBS_NORMAL), PBS_NORMAL)
            s_axPosMouseOver := IIf(::xPosMouseOver > x .AND. ::xPosMouseOver < x + xsize - 3,{x, x + xsize }, s_axPosMouseOver)
         ELSE
            state := IIf(::hTheme != NIL, PBS_PRESSED, 6)
            InflateRect(@aItemRect, -1, -1)
         ENDIF
         IF ::hTheme != NIL
             hb_DrawThemeBackground(::hTheme, hDC, BP_PUSHBUTTON, state, aItemRect, NIL)
             SetBkMode(hDC, 1)
         ELSE
             DrawButton(hDC, x, ;
                 ::y1 - (::nHeadHeight * ::nHeadRows) - ::nyHeight, ;
                 x + xSize, ;
                 ::y1, ;
                 state)
         ENDIF
         nMe := IIf(::ShowSortMark .AND. oColumn:SortMark > 0, IIf(oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE == DT_LEFT, 18, 0), 0)
         nMd := IIf(::ShowSortMark .AND. oColumn:SortMark > 0, IIf(oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE != DT_LEFT, 17, 0), ;
                                                               IIf(oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE == DT_RIGHT, 1, 0))
         cStr := oColumn:heading + ";"
         FOR nLine := 1 TO ::nHeadRows
            aTxtSize := IIf(nLine == 1, TxtRect(cStr, Self), aTxtSize)
            DrawText(hDC, hb_tokenGet(@cStr, nLine, ";"), ;
                      x + ::aMargin[4] + 1 + nMe, ;
                      ::y1 - (::nHeadHeight) * (::nHeadRows - nLine + 1) +  ::aMargin[1] + 1, ;
                      x + xSize - (2 + ::aMargin[2] + nMd), ;
                      ::y1 - (::nHeadHeight) * (::nHeadRows - nLine) - 1, ;
                      oColumn:nJusHead + IIf(oColumn:lSpandHead, DT_NOCLIP, 0) + DT_END_ELLIPSIS, @captionRect)
         NEXT      // Nando DT_VCENTER+DT_SINGLELINE
         IF ::ShowSortMark .AND. oColumn:SortMark > 0
            oBmpSort := IIf(oColumn:SortMark == 1, HBitmap():AddStandard(OBM_UPARROWD), HBitmap():AddStandard(OBM_DNARROWD))
            captionRect[2] := (::nHeadHeight + 17) / 2 - 17
            IF oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  ==  DT_RIGHT .OR. xSize < aTxtSize[1] + nMd
               DrawTransparentBitmap(hDC, oBmpSort:handle, captionRect[1] + (captionRect[3] - captionRect[1]), captionRect[2] + 2, ,)
            ELSEIF oColumn:nJusHead - DT_VCENTER - DT_SINGLELINE  ==  DT_CENTER
               CaptionRect[1] := captionRect[1] + (captionRect[3] - captionRect[1] + aTxtSize[1]) / 2  +  ;
                   MIN((x + xSize - (1 + ::aMargin[2])) - (captionRect[1] + (captionRect[3] - captionRect[1] + aTxtSize[1]) / 2) - 16, 8)
               DrawBitmap(hDC, oBmpSort:handle,, captionRect[1] - 1, captionRect[2], ,)
            ELSE
               DrawTransparentBitmap(hDC, oBmpSort:handle, captionRect[1] - nMe, captionRect[2], ,)
            ENDIF
         ENDIF
       ENDIF
      ELSE
         xSize := 0
         IF fif == Len(::aColumns) .AND. !lFixed
            fif := hb_RAScan(::aColumns, {|c|c:lhide = .F.}) - 1
               //::nPaintCol := nColumn
            x -= ::aColumns[fif + 1]:width
            lFixed := .T.
          ENDIF
      ENDIF
      x += xSize

      IF oColumn:headColor != NIL
         SetTextColor(hDC, toldc)
      ENDIF
      fif := IIf(fif = ::freeze, ::nLeftCol, fif + 1)
      IF fif > Len(::aColumns)
         EXIT
      ENDIF
   ENDDO
   ::xAdjRight := x
   IF ::lShowMark .OR. ::lDeleteMark
      xSize := ::nShowMark + ::nDeleteMark
      IF ::hTheme != NIL
         hb_DrawThemeBackground(::hTheme, hDC, BP_PUSHBUTTON, 1, ;
               {::x1 - xSize - 1, ::y1 - (::nHeadHeight * ::nHeadRows) - ::nyHeight - 1, ;
               ::x1 + 1, ::y1 + 1}, NIL)
      ELSE
         hwg_SelectObject(hDC, s_oPen64:handle)
         Rectangle(hDC, ::x1 - xSize -1, ::y1 - (::nHeadHeight * ::nHeadRows) - ::nyHeight, ;
               ::x1 - 1, ::y1)
         DrawButton(hDC, ::x1 - xSize - 0, ::y1 - (::nHeadHeight * ::nHeadRows) - ::nyHeight, ;
               ::x1 - 1, ::y1, 1)
      ENDIF
   ENDIF

   IF ::hTheme != NIL
      hwg_SelectObject(hDC, s_oPen64:handle)
      Rectangle(hDC, ;
               ::x1 - ::nShowMark - ::nDeleteMark, ;
               ::y1, ;//- (::nHeadHeight * ::nHeadRows) - ::nyHeight, ;
               ::x2, ;
               ::y1)
   ENDIF
   IF !::lAdjRight
      DrawLine(hDC, ::xAdjRight, ::y1 - 1, ::x2, ::y1 - 1)
   ENDIF
   SetBkColor(hDC, oldBkColor)
   IF ::headColor != NIL
      SetTextColor(hDC, oldc)
   ENDIF
   IF ::oHeadFont != NIL
      hwg_SelectObject(hDC, oldfont)
   ENDIF
   IF ::lResizing .AND. s_xDragMove > 0
      hwg_SelectObject(hDC, s_oPen64:handle)
      //Rectangle(hDC, s_xDragMove, 1, s_xDragMove, 1 + (::nheight + 1))
      DrawLine(hDC, s_xDragMove, 1, s_xDragMove, (::nHeadHeight * ::nHeadRows) + ::nyHeight + 1 + (::rowCount * (::height + 1 + ::aMargin[3])))
   ENDIF
   IF ::lDispSep
      hwg_DeleteObject(oPen)
      IF oPenHdr != NIL
         oPenHdr:Release()
      ENDIF
      IF oPenLight != NIL
         oPenLight:Release()
      ENDIF
   ENDIF

RETURN NIL

//----------------------------------------------------//
METHOD SeparatorOut(hDC, nRowsFill) CLASS HBrowse
   
   LOCAL i
   LOCAL x
   LOCAL fif
   LOCAL xSize
   LOCAL lFixed := .F.
   LOCAL xSizeMax
   LOCAL bColor
   LOCAL oColumn
   LOCAL oPen
   LOCAL oPenLight
   LOCAL oPenFree

   DEFAULT nRowsFill TO Min(::nRecords + IIf(::lAppMode, 1, 0), ::rowCount)
   oPen := NIL
   oPenLight := NIL
   oPenFree := NIL

   IF !::lDispSep
     // IF oPen == NIL
         oPen := HPen():Add(PS_SOLID, 1, ::bColor)
     // ENDIF
      hwg_SelectObject(hDC, oPen:handle)
   ELSEIF ::lDispSep
     // IF oPen == NIL
         oPen := HPen():Add(PS_SOLID, 1, ::sepColor)
     // ENDIF
      hwg_SelectObject(hDC, oPen:handle)
   ENDIF
   IF ::lSep3d
      IF oPenLight == NIL
         oPenLight := HPen():Add(PS_SOLID, 1, GetSysColor(COLOR_3DHILIGHT))
      ENDIF
   ENDIF

   x := ::x1 //- IIf(::lShowMark .AND. !::lDeleteMark, 1, 0)
   fif := IIf(::freeze > 0, 1, ::nLeftCol)
   FillRect(hDC, ::x1 - ::nShowMark - ::nDeleteMark - 1, ::y1 + (::height + 1) * nRowsfill + 1, ::x2, ::y2 - (::nFootHeight * ::nFootRows), ::brush:handle)
   // SEPARATOR HORIZONT
   FOR i := 1 TO nRowsFill
      DrawLine(hDC, ::x1 - ::nDeleteMark, ::y1 + (::height + 1) * i, IIf(::lAdjRight, ::x2, ::x2), ::y1 + (::height + 1) * i)
   NEXT
   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      //IF (::lAdjRight .AND. fif == Len(::aColumns)) .OR. lFixed
      IF (fif == Len(::aColumns)) .OR. lFixed
         xSizeMax := Max(::x2 - x, xSize) - 1
         xSize := IIf(::lAdjRight, xSizeMax, xSize)
      ENDIF
      IF !oColumn:lHide
        IF ::lDispSep .AND. x > ::x1
           IF ::lSep3d
              hwg_SelectObject(hDC, oPenLight:handle)
              //DrawLine(hDC, x - 1, ::y1 + 1, x - 1, ::y1 + (::height + 1) * nRows)
              DrawLine(hDC, x - 1, ::y1 + 1, x - 1, ::y1 + (::height + 1) * (nRowsFill))
              hwg_SelectObject(hDC, oPen:handle)
              DrawLine(hDC, x - 2, ::y1 + 1, x - 2, ::y1 + (::height + 1) * (nRowsFill))
              //DrawLine(hDC, x - 2, ::y1 + 1, x - 2, ::y1 + (::height + 1) * nRows)
           ELSE
               hwg_SelectObject(hDC, oPen:handle)
               DrawLine(hDC, x - 1, ::y1 + 1, x - 1, ::y1 + (::height + 1) * (nRowsFill))
               //DrawLine(hDC, x - 0, ::y1 + 1, x - 0, ::y1 + (::height + 1) * nRows)
           ENDIF
        ELSE
           // SEPARATOR VERTICAL
           IF !::lDispSep .AND. (oColumn:bColorBlock != NIL .OR. oColumn:bColor != NIL)
              bColor := IIf(oColumn:bColorBlock != NIL, (Eval(oColumn:bColorBlock, ::FLDSTR(Self, fif), fif, Self))[2], oColumn:bColor)
              IF bColor != NIL
                 // horizontal
                 hwg_SelectObject(hDC, HPen():Add(PS_SOLID, 1, bColor):handle)
                 FOR i := 1 TO nRowsFill
                    DrawLine(hDC, x, ::y1 + (::height + 1) * i, x + xsize, ::y1 + (::height + 1) * i)
                 NEXT
              ENDIF
           ENDIF
           IF x > ::x1 - IIf(::lDeleteMark, 1, 0)
              hwg_SelectObject(hDC, oPen:handle)
              DrawLine(hDC, x - 1, ::y1 + 1, x - 1, ::y1 + (::height + 1) * nRowsFill)
           ENDIF
        ENDIF
      ELSE
         xSize := 0
         IF fif == Len(::aColumns) .AND. !lFixed
            fif := hb_RAScan(::aColumns,{|c| c:lhide = .F.}) - 1
            x -= ::aColumns[fif + 1]:width
            lFixed := .T.
         ENDIF
      ENDIF
      x += xSize //+ IIf(::lShowMark .AND. x < ::x1, 1, 0)

      fif := IIf(fif = ::freeze, ::nLeftCol, fif + 1)
      IF fif > Len(::aColumns)
         EXIT
      ENDIF
   ENDDO
   //  SEPARATOR HORIZONT
    hwg_SelectObject(hDC, oPen:handle)
    IF !::lAdjRight
       IF ::lSep3d
         hwg_SelectObject(hDC, oPenLight:handle)
         DrawLine(hDC, x - 1, ::y1 - (::height * ::nHeadRows), x - 1, ::y1 + (::height + 1) * (nRowsFill))
         hwg_SelectObject(hDC, oPen:handle)
         DrawLine(hDC, x - 2, ::y1 - (::height * ::nHeadRows), x - 2, ::y1 + (::height + 1) * (nRowsFill))
       ELSE
          DrawLine(hDC, x - 1, ::y1 - (::height * ::nHeadRows), x - 1, ::y1 + (::height + 1) * (nRowsFill))
       ENDIF
      // DrawLine(hDC, x - 1, ::y1 - (::height * ::nHeadRows), x - 1, ::y1 + (::height + 1) * (nRowsFill))

    ELSE
       DrawLine(hDC, x, ::y1 - (::height * ::nHeadRows), x, ::y1 + (::height + 1) * (nRowsFill))
    ENDIF
    /*
   //IF ::lDispSep
      FOR i := 1 TO nRows
         DrawLine(hDC, ::x1, ::y1 + (::height + 1) * i, IIf(::lAdjRight, ::x2, x), ::y1 + (::height + 1) * i)
      NEXT
   //ENDIF
   */
   IF ::lDispSep
      hwg_DeleteObject(oPen)
      IF oPenLight != NIL
         oPenLight:Release()
      ENDIF
   ENDIF

RETURN NIL

//----------------------------------------------------//
METHOD FooterOut(hDC) CLASS HBrowse
   
   LOCAL x
   LOCAL fif
   LOCAL xSize
   LOCAL oPen
   LOCAL nLine
   LOCAL cStr
   LOCAL oColumn
   LOCAL aColorFoot
   LOCAL oldBkColor
   LOCAL oldTColor
   LOCAL oBrush
   LOCAL nPixelFooterHeight
   LOCAL nY
   LOCAL lFixed := .F.
   LOCAL lColumnFont := .F.
   LOCAL nMl
   LOCAL aItemRect

   nMl := IIf(::lShowMark, ::nShowMark, 0)+ IIf(::lDeleteMark, ::nDeleteMark, 0)
   IF !::lDispSep
      oPen := HPen():Add(PS_SOLID, 1, ::bColor)
      hwg_SelectObject(hDC, oPen:handle)
   ELSEIF ::lDispSep
      oPen := HPen():Add(PS_SOLID, 1, ::sepColor)
      hwg_SelectObject(hDC, oPen:handle)
   ENDIF

   x := ::x1
   fif := IIf(::freeze > 0, 1, ::nLeftCol)

   DO WHILE x < ::x2 - 2
      oColumn := ::aColumns[fif]
      xSize := oColumn:width
      IF ::lAdjRight .AND. fif == Len(::aColumns) .OR. lFixed
         xSize := Max(::x2 - x, xSize)
      ENDIF
     IF !oColumn:lHide
        cStr := oColumn:footing + ";"
        aColorFoot := NIL
        IF oColumn:bColorFoot != NIL
           aColorFoot := Eval(oColumn:bColorFoot, Self)
           oldBkColor := SetBkColor(hDC, aColorFoot[2])
           oldTColor := SetTextColor(hDC, aColorFoot[1])
           oBrush := HBrush():Add(aColorFoot[2])
        ELSE
           //oBrush := ::brush
           oBrush := NIL
        ENDIF

        IF oColumn:FootFont != NIL
           hwg_SelectObject(hDC, oColumn:FootFont:handle)
           lColumnFont := .T.
        ELSEIF lColumnFont
           hwg_SelectObject(hDC, ::ofont:handle)
           lColumnFont := .F.
        ENDIF

        nPixelFooterHeight := (::nFootRows) * (::nFootHeight + 1)

        IF ::lDispSep
           IF ::hTheme != NIL
              aItemRect := {x, ::y2 - nPixelFooterHeight, x + xsize, ::y2 + 1}
              hb_DrawThemeBackground(::hTheme, hDC, PBS_NORMAL, 0, aItemRect, NIL)
              SetBkMode(hDC, 1)
           ELSE
              DrawButton(hDC, x, ::y2 - nPixelFooterHeight, x + xsize, ::y2, 0)
              DrawLine(hDC, x, ::y2, x + xSize, ::y2)
           ENDIF
        ELSE
           IF ::hTheme != NIL
              aItemRect := {x, ::y2 - nPixelFooterHeight, x + xsize + 1, ::y2 + 1}
              hb_DrawThemeBackground(::hTheme, hDC, PBS_NORMAL, 0, aItemRect, NIL)
              SetBkMode(hDC, 1)
           ELSE
              DrawButton(hDC, x, ::y2 - nPixelFooterHeight, x + xsize + 1, ::y2 + 1, 0)
           ENDIF
        ENDIF

        IF oBrush != NIL
           FillRect(hDC, x, ::y2 - nPixelFooterHeight + 1, ;
                x + xSize - 1, ::y2, oBrush:handle)
        ELSE
           oldBkColor := SetBkColor(hDC, GetSysColor(COLOR_3DFACE))
        ENDIF

        nY := ::y2 - nPixelFooterHeight

        FOR nLine := 1 TO ::nFootRows
            DrawText(hDC, hb_tokenGet(@cStr, nLine, ";"), ;
                   x + ::aMargin[4], ;
                   nY + (nLine - 1) * (::nFootHeight + 1) + 1 + ::aMargin[1], ;
                   x + xSize - (1 + ::aMargin[2]), ;
                   nY + (nLine) * (::nFootHeight + 1), ;
                   oColumn:nJusFoot + IIf(oColumn:lSpandFoot, DT_NOCLIP, 0))
        NEXT   // nando DT_VCENTER + DT_SINGLELINE

        IF aColorFoot != NIL
           SetBkColor(hDC, oldBkColor)
           SetTextColor(hDC, oldTColor)
           oBrush:release()
        ENDIF
// Draw footer separator
        IF ::lDispSep .AND. x >= ::x1
           DrawLine(hDC, x + xSize - 1, nY + 3, x + xSize - 1, ::y2 - 4)
        ENDIF
      ELSE
         xSize := 0
         IF fif == Len(::aColumns) .AND. !lFixed
            fif := hb_RAScan(::aColumns, {|c|c:lhide = .F.}) - 1
            x -= ::aColumns[fif + 1]:width
            lFixed := .T.
         ENDIF
      ENDIF
      x += xSize
      fif := IIf(fif = ::freeze, ::nLeftCol, fif + 1)
      IF fif > Len(::aColumns)
         EXIT
      ENDIF
   ENDDO

   IF ::lDispSep
      //DrawLine(hDC, ::x1, nY, IIf(::lAdjRight, ::x2, x), nY)
      //DrawLine(hDC, ::x1, nY + 1, IIf(::lAdjRight, ::x2, x), nY + 1)
      IF HWG_BITAND(::style, WS_HSCROLL) != 0
          DrawLine(hDC, ::x1, ::y2 - 1, IIf(::lAdjRight, ::x2, x), ::y2 - 1)
      ENDIF
      oPen:Release()
   ENDIF
   IF nMl > 0
      hwg_SelectObject(hDC, s_oPen64:handle)
      xSize := nMl
      IF ::hTheme != NIL
         aItemRect := {::x1 - xSize, nY, ::x1 - 1, ::y2 + 1}
         hb_DrawThemeBackground(::hTheme, hDC, BP_PUSHBUTTON, 0, aItemRect, NIL)
      ELSE
        DrawButton(hDC, ::x1 - xSize, nY, ;
               ::x1 - 1, ::y2, 1)
      ENDIF
   ENDIF
   IF lColumnFont
       hwg_SelectObject(hDC, ::oFont:handle)
   ENDIF

RETURN NIL

//-------------- -Row--  --Col-- ------------------------------//
METHOD LineOut(nRow, nCol, hDC, lSelected, lClear) CLASS HBrowse
   
   LOCAL x
   LOCAL nColumn
   LOCAL sviv
   LOCAL xSize
   LOCAL lFixed := .F.
   LOCAL xSizeMax
   LOCAL j
   LOCAL ob
   LOCAL bw
   LOCAL bh
   LOCAL y1
   LOCAL hBReal
   LOCAL oPen
   LOCAL oldBkColor
   LOCAL oldTColor
   LOCAL oldBk1Color
   LOCAL oldT1Color
   LOCAL lColumnFont := .F.
   LOCAL rcBitmap
   LOCAL ncheck
   LOCAL nstate
   LOCAL nCheckHeight
   LOCAL oLineBrush := IIf(nCol >= 1, HBrush():Add(::htbColor), IIf(lSelected, ::brushSel, ::brush))
   LOCAL aCores

   nColumn := 1
   x := ::x1
   IF lClear == NIL
      lClear := .F.
   ENDIF

   IF hb_IsBlock(::bLineOut)
      Eval(::bLineOut, Self, lSelected)
   ENDIF
   IF ::nRecords > 0 .OR. lClear
  //    oldBkColor := SetBkColor(hDC, IIf(nCol >= 1, ::htbcolor, IIf(lSelected, ::bcolorSel, ::bcolor)))
  //    oldTColor := SetTextColor(hDC, IIf(nCol >= 1, ::httcolor, IIf(lSelected, ::tcolorSel, ::tcolor)))
      ::nPaintCol := IIf(::freeze > 0, 1, ::nLeftCol)
      ::nPaintRow := nRow
      IF ::lDeleteMark
         FillRect(hDC, ::x1 - ::nDeleteMark - 0, ::y1 + (::height + 1) * (::nPaintRow - 1) + 1, ;
                        ::x1 - 1, ::y1 + (::height + 1) * ::nPaintRow, IIf(Deleted(), GetStockObject(7), GetStockObject(0))) //::brush:handle))
      ENDIF
      IF ::lShowMark
         IF ::hTheme != NIL
             hb_DrawThemeBackground(::hTheme, hDC, BP_PUSHBUTTON, IIf(lSelected, PBS_VERTICAL, PBS_VERTICAL), ;
                      {::x1 - ::nShowMark - ::nDeleteMark - 1,;
                       ::y1 + (::height + 1) * (::nPaintRow - 1) + 1, ;
                       ::x1 - ::nDeleteMark, ;
                       ::y1 + (::height + 1) * ::nPaintRow + 1}, NIL)
          ELSE
             DrawButton(hDC, ::x1 - ::nShowMark - ::nDeleteMark - 0,;
                         ::y1 + (::height + 1) * (::nPaintRow - 1) + 1, ;
                         ::x1 - ::nDeleteMark - 1, ; //IIf(::lDeleteMark, -1, -2), ;
                         ::y1 + (::height + 1) * ::nPaintRow + 1, 1)
             hwg_SelectObject(hDC, s_oPen64:handle)
             Rectangle(hDC, ::x1 - ::nShowMark - ::nDeleteMark - 1, ::y1 + (::height + 1) * (::nPaintRow - 1), ;
                        ::x1  - ::nDeleteMark - 1, ::y1 + (::height + 1) * ::nPaintRow - 0) //, IIf(Deleted(), GetStockObject(7), ::brush:handle))
          ENDIF
          IF lSelected
             DrawTransparentBitmap(hDC, ::oBmpMark:handle, ::x1 - ::nShowMark - ::nDeleteMark + 1,;
                          (::y1 + (::height + 1) * (::nPaintRow - 1)) + ;
                          ((::y1 + (::height + 1) * (::nPaintRow)) - (::y1 + (::height + 1) * (::nPaintRow - 1))) / 2 - 6)
             IF ::HighlightStyle == 2 .OR. ((::HighlightStyle == 0 .AND. hwg_SelfFocus(::handle)) .OR. ;
                  (::HighlightStyle == 3 .AND. (::Highlight .OR. ::lEditable .OR. !hwg_SelfFocus(::handle))))
                IF !::lEditable .OR. ::HighlightStyle == 3 .OR. ::HighlightStyle == 0
                   ::internal[1] := 1
                   oPen := HPen():Add(0, 1, ::bcolorSel)
                   hwg_SelectObject(hDC, GetStockObject(NULL_BRUSH))
                   hwg_SelectObject(hDC, oPen:handle)
                   RoundRect(hDC, ::x1, ;
                                 ::y1 + (::height + 1) * (::nPaintRow - 1) + 1, ;
                                 ::xAdjRight - 2,;  //::x2 - 1, ;
                                 ::y1 + (::height + 1) * ::nPaintRow, 0, 0)
                   hwg_DeleteObject(oPen)
                   IF ((::Highlight .OR. !::lEditable) .AND. nCol == 0) .OR. (::HighlightStyle == 3 .AND. !hwg_SelfFocus(::handle))
                      RETURN NIL
                   ENDIF
                ENDIF
             ELSEIF ::HighlightStyle == 0 //.OR. ::HighlightStyle == 3
                RETURN NIL
             ENDIF
          ENDIF
      ENDIF
      oldBkColor := SetBkColor(hDC, IIf(nCol >= 1, ::htbcolor, IIf(lSelected, ::bcolorSel, ::bcolor)))
      oldTColor := SetTextColor(hDC, IIf(nCol >= 1, ::httcolor, IIf(lSelected, ::tcolorSel, ::tcolor)))
      ::nVisibleColLeft := ::nPaintCol
      DO WHILE x < ::x2 - 2
         // if bColorBlock defined get the colors
         //IF ::aColumns[::nPaintCol]:bColorBlock != NIL
         aCores := {}
         IF (nCol == 0 .OR. nCol == nColumn) .AND. ::aColumns[::nPaintCol]:bColorBlock != NIL .AND. !lClear
            // nando
            aCores := Eval(::aColumns[::nPaintCol]:bColorBlock, ::FLDSTR(Self, ::nPaintCol), ::nPaintCol, Self)
            IF lSelected
               ::aColumns[::nPaintCol]:tColor := IIf(aCores[3] != NIL, aCores[3], ::tcolorSel)
               ::aColumns[::nPaintCol]:bColor := IIf(aCores[4] != NIL, aCores[4], ::bcolorSel)
            ELSE
               ::aColumns[::nPaintCol]:tColor := IIf(aCores[1] != NIL, aCores[1], ::tcolor)
               ::aColumns[::nPaintCol]:bColor := IIf(aCores[2] != NIL, aCores[2], ::bcolor)
            ENDIF
            ::aColumns[::nPaintCol]:brush := HBrush():Add(::aColumns[::nPaintCol]:bColor)
         ELSE
            ::aColumns[::nPaintCol]:brush := NIL
         ENDIF
         xSize := ::aColumns[::nPaintCol]:width
         xSizeMax := xSize
         IF (::nPaintCol == Len(::aColumns)) .OR. lFixed
            xSizeMax := Max(::x2 - x, xSize)
            xSize := IIf(::lAdjRight, xSizeMax, xSize)
            ::nWidthColRight := xSize
         ENDIF
         IF !::aColumns[::nPaintCol]:lHide
           IF nCol == 0 .OR. nCol == nColumn
             hBReal := oLineBrush:handle
             IF !lClear
                IF ::aColumns[::nPaintCol]:bColor != NIL .AND. ::aColumns[::nPaintCol]:brush == NIL
                   ::aColumns[::nPaintCol]:brush := HBrush():Add(::aColumns[::nPaintCol]:bColor)
                ENDIF
                 //hBReal := IIf(::aColumns[::nPaintCol]:brush != NIL .AND. (::nPaintCol != ::colPos .OR. !lSelected), ;
                 hBReal := IIf(::aColumns[::nPaintCol]:brush != NIL .AND. !(lSelected .AND. Empty(aCores)),;
                          ::aColumns[::nPaintCol]:brush:handle, oLineBrush:handle)
             ENDIF
             // Fill background color of a cell
             FillRect(hDC, x, ::y1 + (::height + 1) * (::nPaintRow - 1) + 1, ;
                      x + xSize - IIf(::lSep3d, 2, 1), ::y1 + (::height + 1) * ::nPaintRow, hBReal)
             IF xSize != xSizeMax
                // !adjright
                hBReal := HBrush():Add(16448764):handle
                FillRect(hDC, x + xsize, ::y1 + (::height + 1) * (::nPaintRow - 1) + 1, ;
                       x + xSizeMax - IIf(::lSep3d, 2, 1), ::y1 + (::height + 1) * ::nPaintRow, hBReal) //::brush:handle)
             ENDIF
             IF !lClear
               IF ::aColumns[::nPaintCol]:aBitmaps != NIL .AND. !Empty(::aColumns[::nPaintCol]:aBitmaps)
                  FOR j := 1 TO Len(::aColumns[::nPaintCol]:aBitmaps)
                     IF Eval(::aColumns[::nPaintCol]:aBitmaps[j, 1], Eval(::aColumns[::nPaintCol]:block,, Self, ::nPaintCol), lSelected)
                        ob := ::aColumns[::nPaintCol]:aBitmaps[j, 2]
                        IF ob:nHeight > ::height
                           y1 := 0
                           bh := ::height
                           bw := Int(ob:nWidth * (ob:nHeight / ::height))
                           DrawBitmap(hDC, ob:handle,, x + (Int(::aColumns[::nPaintCol]:width - ob:nWidth) / 2), y1 + ::y1 + (::height + 1) * (::nPaintRow - 1) + 1, bw, bh)
                        ELSE
                           y1 := Int((::height - ob:nHeight) / 2)
                           DrawTransparentBitmap(hDC, ob:handle, x + (Int(::aColumns[::nPaintCol]:width - ob:nWidth) / 2), y1 + ::y1 + (::height + 1) * (::nPaintRow - 1) + 1)
                        ENDIF
                        EXIT
                     ENDIF
                  NEXT
               ELSE
                  sviv := ::FLDSTR(Self, ::nPaintCol)
                  // new nando
                  IF ::aColumns[::nPaintCol]:type = "L"
                     ncheck := IIf(sviv = "T", 1, 0) + 1
                     rcBitmap := {x + ::aMargin[4] + 1, ;
                               ::y1 + (::height + 1) * (::nPaintRow - 1) + 1 + ::aMargin[1], ;
                               0, 0}
                     nCheckHeight := (::y1 + (::height + 1) * ::nPaintRow) - (::y1 + (::height + 1) * (::nPaintRow - 1)) - ::aMargin[1] - ::aMargin[3] - 1
                     nCheckHeight := IIf(nCheckHeight > 16, 16, nCheckHeight)
                     IF hwg_BitAND(::aColumns[::nPaintCol]:nJusLin, DT_CENTER) != 0
                        rcBitmap[1] := rcBitmap[1] + (xsize - ::aMargin[2] - ::aMargin[4] - nCheckHeight + 1) / 2
                     ENDIF
                     rcBitmap[4] := ::y1 + (::height + 1) * ::nPaintRow - (1 + ::aMargin[3])
                     rcBitmap[2] := rcBitmap[2] + ((rcBitmap[4] - rcBitmap[2]) - nCheckHeight + 1) / 2
                     rcBitmap[3] := rcBitmap[1] + nCheckHeight
                     rcBitmap[4] := rcBitmap[2] + nCheckHeight
                     IF (nCheck > 0)
                        nState := DFCS_BUTTONCHECK
                        IF (nCheck > 1)
                           nState := hwg_bitor(nstate, DFCS_CHECKED)
                        ENDIF
                        nState += IIf(::lEditable .OR. ::aColumns[::nPaintCol]:lEditable, 0, DFCS_INACTIVE)
                        DrawFrameControl(hDC, rcBitmap, DFC_BUTTON, nState + DFCS_FLAT)
                     ENDIF
                     sviv := ""
                  ENDIF
                  // Ahora lineas Justificadas !!
                  IF ::aColumns[::nPaintCol]:tColor != NIL //.AND. (::nPaintCol != ::colPos .OR. !lSelected)
                     oldT1Color := SetTextColor(hDC, ::aColumns[::nPaintCol]:tColor)
                  ENDIF
                  IF ::aColumns[::nPaintCol]:bColor != NIL //.AND. (::nPaintCol != ::colPos .OR. !lSelected)
                     oldBk1Color := SetBkColor(hDC, ::aColumns[::nPaintCol]:bColor)
                  ENDIF
                  IF ::aColumns[::nPaintCol]:oFont != NIL
                     hwg_SelectObject(hDC, ::aColumns[::nPaintCol]:oFont:handle)
                     lColumnFont := .T.
                  ELSEIF lColumnFont
                     hwg_SelectObject(hDC, ::ofont:handle)
                     lColumnFont := .F.
                  ENDIF
                  IF ::aColumns[::nPaintCol]:Hint
                      AAdd(::aColumns[::nPaintCol]:aHints, sViv)
                  ENDIF
                  DrawText(hDC, sviv, ;
                            x + ::aMargin[4] + 1, ;
                            ::y1 + (::height + 1) * (::nPaintRow - 1) + 1 + ::aMargin[1], ;
                            x + xSize - (2 + ::aMargin[2]), ;
                            ::y1 + (::height + 1) * ::nPaintRow - (1 + ::aMargin[3]), ;
                            ::aColumns[::nPaintCol]:nJusLin + DT_NOPREFIX)

// Clipping rectangle
                  #if 0
                     rectangle(hDC, ;
                               x + ::aMargin[4], ;
                               ::y1 + (::height + 1) * (::nPaintRow - 1) + 1 + ::aMargin[1], ;
                               x + xSize - (2 + ::aMargin[2]), ;
                               ::y1 + (::height + 1) * ::nPaintRow - (1 + ::aMargin[3]) ;
                              )
                  #endif

                  IF ::aColumns[::nPaintCol]:tColor != NIL //.AND. (::nPaintCol != ::colPos .OR. !lSelected)
                     SetTextColor(hDC, oldT1Color)
                  ENDIF

                  IF ::aColumns[::nPaintCol]:bColor != NIL //.AND. (::nPaintCol != ::colPos .OR. !lSelected)
                     SetBkColor(hDC, oldBk1Color)
                  ENDIF
                ENDIF
              ENDIF
           ENDIF
         ELSE
            xSize := 0
            IF nCol > 0 .AND. lSelected .AND. nCol == nColumn
               nCol++
            ENDIF
            IF nColumn == Len(::aColumns) .AND. !lFixed
               nColumn := hb_RAScan(::aColumns, {|c|c:lhide = .F.}) - 1
               ::nPaintCol := nColumn
               x -= ::aColumns[::nPaintCol + 1]:width
               lFixed := .T.
            ENDIF
         ENDIF
         x += xSize
         ::nPaintCol := IIf(::nPaintCol == ::freeze, ::nLeftCol, ::nPaintCol + 1)
         nColumn++
         IF !::lAdjRight .AND. ::nPaintCol > Len(::aColumns)
            EXIT
         ENDIF
      ENDDO

// Fill the browse canvas from x+::width to ::x2-2
// when all columns width less than canvas width (lAdjRight == .F.)
/*
      IF !::lAdjRight .AND. ::nPaintCol == Len(::aColumns) + 1
         xSize := Max(::x2 - x, xSizeMax)

         xSize := Max(::x2 - x, xSize)
         FillRect(hDC, x, 0, ;
                   x + xSize - IIf(::lSep3d, 2, 1), ::y2, oLineBrush)

      ENDIF
*/
      SetTextColor(hDC, oldTColor)
      SetBkColor(hDC, oldBkColor)
      IF lColumnFont
         hwg_SelectObject(hDC, ::ofont:handle)
      ENDIF
   ENDIF

RETURN NIL

//----------------------------------------------------//
METHOD SetColumn(nCol) CLASS HBrowse
   
   LOCAL nColPos
   LOCAL lPaint := .F.
   LOCAL lEditable := ::lEditable .OR. ::Highlight

   IF lEditable .OR. ::lAutoEdit
      IF nCol != NIL .AND. nCol >= 1 .AND. nCol <= Len(::aColumns)
         IF nCol <= ::freeze
            ::colpos := nCol
         ELSEIF nCol >= ::nLeftCol .AND. nCol <= ::nLeftCol + ::nColumns - ::freeze - 1
            ::colpos := nCol - ::nLeftCol + ::freeze + 1
         ELSE
            ::nLeftCol := nCol
            ::colpos := ::freeze + 1
            lPaint := .T.
         ENDIF
         IF !lPaint
            ::RefreshLine()
         ELSE
            hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE)
         ENDIF
      ENDIF

      IF ::colpos <= ::freeze
         nColPos := ::colpos
      ELSE
         nColPos := ::nLeftCol + ::colpos - ::freeze - 1
      ENDIF
      RETURN nColPos

   ENDIF

RETURN 1

//----------------------------------------------------//
STATIC FUNCTION LINERIGHT(oBrw)
   
   LOCAL i
   LOCAL lEditable := oBrw:lEditable .OR. oBrw:Highlight

   IF lEditable .OR. oBrw:lAutoEdit
      IF oBrw:colpos < oBrw:nColumns
         oBrw:colpos++
         RETURN NIL
      ENDIF
   ENDIF
   IF oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < Len(oBrw:aColumns) .AND. ;
       oBrw:nLeftCol < Len(oBrw:aColumns)
      i := oBrw:nLeftCol + oBrw:nColumns
      DO WHILE oBrw:nColumns + oBrw:nLeftCol - oBrw:freeze - 1 < Len(oBrw:aColumns) .AND. oBrw:nLeftCol + oBrw:nColumns == i
         oBrw:nLeftCol++
      ENDDO
      oBrw:colpos := i - oBrw:nLeftCol + 1
   ENDIF

RETURN NIL

//----------------------------------------------------//
// Move the visible browse one step to the left
STATIC FUNCTION LINELEFT(oBrw)
   
   LOCAL lEditable := oBrw:lEditable .OR. oBrw:Highlight

   IF lEditable .OR. oBrw:lAutoEdit
      oBrw:colpos--
   ENDIF
   IF oBrw:nLeftCol > oBrw:freeze + 1 .AND. (!lEditable .OR. oBrw:colpos < oBrw:freeze + 1)
      oBrw:nLeftCol--
      IF !lEditable .OR. oBrw:colpos < oBrw:freeze + 1
         oBrw:colpos := oBrw:freeze + 1
      ENDIF
   ENDIF
   IF oBrw:colpos < 1
      oBrw:colpos := 1
   ENDIF

RETURN NIL

//----------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD DoVScroll(wParam) CLASS HBrowse
   
   LOCAL nScrollCode := hwg_LOWORD(wParam)

   IF nScrollCode == SB_LINEDOWN
      ::LINEDOWN(.T.)
   ELSEIF nScrollCode == SB_LINEUP
      ::LINEUP()
   ELSEIF nScrollCode == SB_BOTTOM
      ::BOTTOM()
   ELSEIF nScrollCode == SB_TOP
      ::TOP()
   ELSEIF nScrollCode == SB_PAGEDOWN
      ::PAGEDOWN()
   ELSEIF nScrollCode == SB_PAGEUP
      ::PAGEUP()

   ELSEIF nScrollCode == SB_THUMBPOSITION .OR. nScrollCode == SB_THUMBTRACK
      ::SetFocus()
      IF hb_IsBlock(::bScrollPos)
         Eval(::bScrollPos, Self, nScrollCode, .F., hwg_HIWORD(wParam))
      ELSE
         IF (::Alias)->(IndexOrd()) == 0              // sk
            (::Alias)->(DBGoTo(hwg_HIWORD(wParam)))   // sk
         ELSE
            (::Alias)->(OrdKeyGoTo(hwg_HIWORD(wParam))) // sk
         ENDIF
         Eval(::bSkip, Self, 1)
         Eval(::bSkip, Self, -1)
         VScrollPos(Self, 0, .F.)
         ::refresh()
      ENDIF
   ENDIF

RETURN 0
#else
METHOD DoVScroll(wParam) CLASS HBrowse

   LOCAL nScrollCode := hwg_LOWORD(wParam)

   SWITCH nScrollCode
   CASE SB_LINEDOWN
      ::LINEDOWN(.T.)
      EXIT
   CASE SB_LINEUP
      ::LINEUP()
      EXIT
   CASE SB_BOTTOM
      ::BOTTOM()
      EXIT
   CASE SB_TOP
      ::TOP()
      EXIT
   CASE SB_PAGEDOWN
      ::PAGEDOWN()
      EXIT
   CASE SB_PAGEUP
      ::PAGEUP()
      EXIT
   CASE SB_THUMBPOSITION
   CASE SB_THUMBTRACK
      ::SetFocus()
      IF hb_IsBlock(::bScrollPos)
         Eval(::bScrollPos, Self, nScrollCode, .F., hwg_HIWORD(wParam))
      ELSE
         IF (::Alias)->(IndexOrd()) == 0            // sk
            (::Alias)->(DBGoTo(hwg_HIWORD(wParam)))     // sk
         ELSE
            (::Alias)->(OrdKeyGoTo(hwg_HIWORD(wParam))) // sk
         ENDIF
         Eval(::bSkip, Self, 1)
         Eval(::bSkip, Self, -1)
         VScrollPos(Self, 0, .F.)
         ::refresh()
      ENDIF
   ENDSWITCH

RETURN 0
#endif

//----------------------------------------------------//

#if 0 // old code for reference (to be deleted)
METHOD DoHScroll(wParam) CLASS HBrowse
   
   LOCAL nScrollCode := hwg_LOWORD(wParam)
   LOCAL nPos
   LOCAL oldLeft := ::nLeftCol
   LOCAL nLeftCol
   LOCAL colpos
   LOCAL oldPos := ::colpos

   IF !::ChangeRowCol(2)
      RETURN .F.
   ENDIF

   IF nScrollCode == SB_LINELEFT .OR. nScrollCode == SB_PAGELEFT
      LineLeft(Self)

   ELSEIF nScrollCode == SB_LINERIGHT .OR. nScrollCode == SB_PAGERIGHT
      LineRight(Self)

   ELSEIF nScrollCode == SB_LEFT
      nLeftCol := colpos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colpos != ::colpos
         nLeftCol := ::nLeftCol
         colpos := ::colpos
         LineLeft(Self)
      ENDDO
   ELSEIF nScrollCode == SB_RIGHT
      nLeftCol := colpos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colpos != ::colpos
         nLeftCol := ::nLeftCol
         colpos := ::colpos
         LineRight(Self)
      ENDDO
   ELSEIF nScrollCode == SB_THUMBTRACK .OR. nScrollCode == SB_THUMBPOSITION
      ::SetFocus()
      IF ::lEditable
         SetScrollRange(::handle, SB_HORZ, 1, Len(::aColumns))
         SetScrollPos(::handle, SB_HORZ, hwg_HIWORD(wParam))
         ::SetColumn(hwg_HIWORD(wParam))
      ELSE
         IF hwg_HIWORD(wParam) > (::colpos + ::nLeftCol - 1)
            LineRight(Self)
         ENDIF
         IF hwg_HIWORD(wParam) < (::colpos + ::nLeftCol - 1)
            LineLeft(Self)
         ENDIF
      ENDIF
   ENDIF

   IF ::nLeftCol != oldLeft .OR. ::colpos != oldPos
      IF HWG_BITAND(::style, WS_HSCROLL) != 0
         SetScrollRange(::handle, SB_HORZ, 1, Len(::aColumns))
         nPos := ::colpos + ::nLeftCol - 1
         SetScrollPos(::handle, SB_HORZ, nPos)
      ENDIF
      // TODO: here I force a full repaint and HSCROLL appears...
      //       but we should do more checks....
      // IF ::nLeftCol == oldLeft
      //   ::RefreshLine()
      //ELSE
      IF ::nLeftCol != ::nVisibleColLeft
         hwg_RedrawWindow(::handle, RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW)  // Force a complete redraw
      ELSE
         ::RefreshLine()
      ENDIF

   ENDIF
   ::SetFocus()

RETURN NIL
#else
METHOD DoHScroll(wParam) CLASS HBrowse

   LOCAL nScrollCode := hwg_LOWORD(wParam)
   LOCAL nPos
   LOCAL oldLeft := ::nLeftCol
   LOCAL nLeftCol
   LOCAL colpos
   LOCAL oldPos := ::colpos

   IF !::ChangeRowCol(2)
      RETURN .F.
   ENDIF

   SWITCH nScrollCode
   CASE SB_LINELEFT
   CASE SB_PAGELEFT
      LineLeft(Self)
      EXIT
   CASE SB_LINERIGHT
   CASE SB_PAGERIGHT
      LineRight(Self)
      EXIT
   CASE SB_LEFT
      nLeftCol := colpos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colpos != ::colpos
         nLeftCol := ::nLeftCol
         colpos := ::colpos
         LineLeft(Self)
      ENDDO
      EXIT
   CASE SB_RIGHT
      nLeftCol := colpos := 0
      DO WHILE nLeftCol != ::nLeftCol .OR. colpos != ::colpos
         nLeftCol := ::nLeftCol
         colpos := ::colpos
         LineRight(Self)
      ENDDO
      EXIT
   CASE SB_THUMBTRACK
   CASE SB_THUMBPOSITION
      ::SetFocus()
      IF ::lEditable
         SetScrollRange(::handle, SB_HORZ, 1, Len(::aColumns))
         SetScrollPos(::handle, SB_HORZ, hwg_HIWORD(wParam))
         ::SetColumn(hwg_HIWORD(wParam))
      ELSE
         IF hwg_HIWORD(wParam) > (::colpos + ::nLeftCol - 1)
            LineRight(Self)
         ENDIF
         IF hwg_HIWORD(wParam) < (::colpos + ::nLeftCol - 1)
            LineLeft(Self)
         ENDIF
      ENDIF
   ENDSWITCH

   IF ::nLeftCol != oldLeft .OR. ::colpos != oldPos
      IF HWG_BITAND(::style, WS_HSCROLL) != 0
         SetScrollRange(::handle, SB_HORZ, 1, Len(::aColumns))
         nPos := ::colpos + ::nLeftCol - 1
         SetScrollPos(::handle, SB_HORZ, nPos)
      ENDIF
      // TODO: here I force a full repaint and HSCROLL appears...
      //       but we should do more checks....
      // IF ::nLeftCol == oldLeft
      //   ::RefreshLine()
      //ELSE
      IF ::nLeftCol != ::nVisibleColLeft
         hwg_RedrawWindow(::handle, RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW) // Force a complete redraw
      ELSE
         ::RefreshLine()
      ENDIF
   ENDIF
   ::SetFocus()

RETURN NIL
#endif

//----------------------------------------------------//
METHOD LINEDOWN(lMouse) CLASS HBrowse

   Eval(::bSkip, Self, 1)
   IF Eval(::bEof, Self)
      //Eval(::bSkip, Self, -1)
      IF ::lAppable .AND. (lMouse == NIL .OR. !lMouse)
         ::lAppMode := .T.
      ELSE
         Eval(::bSkip, Self, -1)
         IF !hwg_SelfFocus(::handle)
           ::SetFocus()
         ENDIF
         RETURN NIL
      ENDIF
   ENDIF
   ::rowPos++
   IF ::rowPos > ::rowCount
      ::rowPos := ::rowCount
      IF ::lAppMode
          //::nLeftCol := ::freeze + 1
          hwg_RedrawWindow(::handle, RDW_INVALIDATE + RDW_UPDATENOW + RDW_NOERASE)
      ELSE
          hwg_RedrawWindow(::handle, RDW_INVALIDATE + RDW_INTERNALPAINT)
      ENDIF
      //::Refresh(.F.)  //::nFootRows > 0)
      ::internal[1] := 14
   ELSE
      ::internal[1] := 0
   ENDIF
   //::internal[1] := 14 //0
   /*
   nUpper := ::y1  +  (::height + 1) * (::rowPos - 2)
   nLower := ::y1 + (::height + 1) * (::rowPos)
   hwg_InvalidateRect(::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, nUpper, ::x2, nLower)
   */
   hwg_InvalidateRect(::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + (::height + 1) * ::internal[2] - ::height, ;
      ::xAdjRight, ::y1 + (::height + 1) * ::internal[2])
   hwg_InvalidateRect(::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + (::height + 1) * ::rowPos - ::height, ;
      ::xAdjRight, ::y1 + (::height + 1) * ::rowPos)

   //ENDIF
   IF ::lAppMode
      IF ::RowCurrCount < ::RowCount
         Eval(::bSkip, Self, -1)
      ENDIF
      IF ::rowPos > 1
         ::rowPos--
      ENDIF
      //::colPos := ::nLeftCol := 1
      ::colPos := Max(1, AScan(::aColumns, {|c|c:lEditable}))
      ::nLeftCol := ::freeze + 1
   ENDIF
   IF !::lAppMode .OR. ::nLeftCol == 1
      ::internal[1] := SetBit(::internal[1], 1, 0)
   ENDIF

   IF hb_IsBlock(::bScrollPos)
      Eval(::bScrollPos, Self, 1, .F.)
   ELSEIF ::nRecords > 1
      VScrollPos(Self, 0, .F.)
   ENDIF

  // ::SetFocus()  ??

RETURN NIL

//----------------------------------------------------//
METHOD LINEUP() CLASS HBrowse

   Eval(::bSkip, Self, -1)
   IF Eval(::bBof, Self)
      Eval(::bGoTop, Self)
   ELSE
      ::rowPos--
      IF ::rowPos == 0  // needs scroll
         ::rowPos := 1
         hwg_RedrawWindow(::handle, RDW_INVALIDATE + RDW_INTERNALPAINT)
         //::Refresh(.F., .T.)
         ::internal[1] := 14
      ELSE
         ::internal[1] := 0
      ENDIF
      //::internal[1] := 14 //0
      hwg_InvalidateRect(::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + (::height + 1) * ;
         ::internal[2] - ::height, ::xAdjRight, ::y1 + (::height + 1) * ::internal[2])
      hwg_InvalidateRect(::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + (::height + 1) * ;
         ::rowPos - ::height, ::xAdjRight, ::y1 + (::height + 1) * ::rowPos)
      //ENDIF
      IF hb_IsBlock(::bScrollPos)
         Eval(::bScrollPos, Self, -1, .F.)
      ELSEIF ::nRecords > 1
         VScrollPos(Self, 0, .F.)
      ENDIF
      ::internal[1] := SetBit(::internal[1], 1, 0)
   ENDIF
  // ::SetFocus() ??

RETURN NIL

//----------------------------------------------------//
METHOD PAGEUP() CLASS HBrowse
   
   LOCAL STEP
   LOCAL lBof := .F.

   IF ::rowPos > 1
      STEP := (::rowPos - 1)
      Eval(::bSKip, Self, -STEP)
      ::rowPos := 1
   ELSE
      STEP := ::rowCurrCount    // Min(::nRecords, ::rowCount)
      Eval(::bSkip, Self, -STEP)
      IF Eval(::bBof, Self)
         Eval(::bGoTop, Self)
         lBof := .T.
      ENDIF
   ENDIF

   IF hb_IsBlock(::bScrollPos)
      Eval(::bScrollPos, Self, -STEP, lBof)
   ELSEIF ::nRecords > 1
      VScrollPos(Self, 0, .F.)
   ENDIF

   ::Refresh(::nFootRows > 0)
  //  ::SetFocus() ??

RETURN NIL

//----------------------------------------------------//
/**
 *
 * If cursor is in the last visible line, skip one page
 * If cursor in not in the last line, go to the last
 *
*/
METHOD PAGEDOWN() CLASS HBrowse
   
   LOCAL nRows := ::rowCurrCount
   LOCAL STEP := IIf(nRows > ::rowPos, nRows - ::rowPos, nRows)

   Eval(::bSkip, Self, STEP)

   IF Eval(::bEof, Self)
      Eval(::bSkip, Self, -1)
   ENDIF
   ::rowPos := Min(::nRecords, nRows)

   IF hb_IsBlock(::bScrollPos)
      Eval(::bScrollPos, Self, STEP, .F.)
   ELSE
      VScrollPos(Self, 0, .F.)
   ENDIF

   ::Refresh(::nFootRows > 0)
   // ::SetFocus() ???

RETURN NIL

//----------------------------------------------------//
METHOD BOTTOM(lPaint) CLASS HBrowse

   IF ::Type == BRW_ARRAY
      ::nCurrent := ::nRecords
      ::rowPos := IIf(::rowCurrCount <= ::rowCount, ::rowCurrCount, ::rowCount + 1)
   ELSE
      //::rowPos := LastRec()
      ::rowPos := IIf(::rowCurrCount <= ::rowCount, ::rowCurrCount, ::rowCount + 1)
      Eval(::bGoBot, Self)
   ENDIF

   VScrollPos(Self, 0, IIf(::Type == BRW_ARRAY, .F., .T.))

   IF lPaint == NIL .OR. lPaint
      ::Refresh(::nFootRows > 0)
      //::SetFocus()
   ELSE
      //hwg_InvalidateRect(::handle, 0)
      ::internal[1] := SetBit(::internal[1], 1, 0)
   ENDIF

RETURN NIL

//----------------------------------------------------//
METHOD TOP() CLASS HBrowse

   ::rowPos := 1
   Eval(::bGoTop, Self)
   VScrollPos(Self, 0, .F.)

   //hwg_InvalidateRect(::handle, 0)
   ::Refresh(::nFootRows > 0)
   ::internal[1] := SetBit(::internal[1], 1, 0)
   ::SetFocus()

RETURN NIL

//----------------------------------------------------//
METHOD ButtonDown(lParam, lReturnRowCol) CLASS HBrowse

   LOCAL nLine
   LOCAL STEP
   LOCAL res
   LOCAL xm
   LOCAL x1
   LOCAL fif
   LOCAL aColumns := {}
   LOCAL nCols := 1
   LOCAL xSize := 0
   LOCAL lEditable := ::lEditable .OR. ::Highlight

   // Calculate the line you clicked on, keeping track of header
   IF (::lDispHead)
      nLine := Int((hwg_HIWORD(lParam) - (::nHeadHeight * ::nHeadRows)) / (::height + 1) + 1)
   ELSE
      nLine := Int(hwg_HIWORD(lParam) / (::height + 1) + 1)
   ENDIF

   STEP := nLine - ::rowPos
   res := .F.
   xm := hwg_LOWORD(lParam)

   x1 := ::x1
   fif := IIf(::freeze > 0, 1, ::nLeftCol)

   DO WHILE nCols <= Len(::aColumns)
      xSize := ::aColumns[nCols]:width
      IF (::lAdjRight .AND. nCols == Len(::aColumns))
         xSize := Max(::x2 - x1, xSize)
      ENDIF
      IF !::aColumns[nCols]:lHide
         AAdd(aColumns, {xSize, ncols})
         x1 += xSize
         xSize := 0
      ENDIF
      nCols++
   ENDDO
   x1 := ::x1
   aColumns[Len(aColumns), 1] += xSize

   DO WHILE fif <= Len(::aColumns)
      IF (!(fif < (::nLeftCol + ::nColumns) .AND. x1 + aColumns[fif, 1] < xm))
         EXIT
      ENDIF
      x1 += aColumns[fif, 1]
      fif := IIf(fif == ::freeze, ::nLeftCol, fif + 1)
   ENDDO
   IF fif > Len(aColumns)
      IF !::lAdjRight     // no column select
         RETURN NIL
      ENDIF
      fif--
   ENDIF
   //nando
   fif := aColumns[fif, 2]
   IF lReturnRowCol != NIL .AND. lReturnRowCol
       RETURN {IIf(nLine <= ::rowCurrCount, nLine, - 1), fif}
   ENDIF

IF nLine > 0 .AND. nLine <= ::rowCurrCount
   // NEW
   IF !::ChangeRowCol(IIf(nLine = ::rowPos .AND. ::colpos == fif, 0, IIf( ;
         nLine != ::rowPos .AND. ::colpos != fif, 3, IIf(nLine != ::rowPos, 1, 2))))
      RETURN .F.
   ENDIF

   IF STEP != 0
      Eval(::bSkip, Self, STEP)
      ::rowPos := nLine
      IF hb_IsBlock(::bScrollPos)
         Eval(::bScrollPos, Self, STEP, .F.)
      ELSEIF ::nRecords > 1
         VScrollPos(Self, 0, .F.)
      ENDIF
      res := .T.

      /*
      IF !Eval(::bEof, Self)
         ::rowPos := nLine
         IF hb_IsBlock(::bScrollPos)
            Eval(::bScrollPos, Self, STEP, .F.)
         ELSEIF ::nRecords > 1
            VScrollPos(Self, 0, .F.)
         ENDIF
         res := .T.
      ELSEIF nRec > 0
         Eval(::bGoto, Self, nRec)
      ENDIF
      */
   ENDIF
   IF lEditable .OR. ::lAutoEdit

      IF ::colpos != fif - ::nLeftCol + 1 + ::freeze
         // Colpos should not go beyond last column or I get bound errors on ::Edit()
         ::colpos := Min(::nColumns + 1, fif - ::nLeftCol + 1 + ::freeze)
         VScrollPos(Self, 0, .F.)
         res := .T.
      ENDIF
   ENDIF
   IF res
      ::internal[1] := 15   // Force FOOTER
      //hwg_RedrawWindow(::handle, RDW_INVALIDATE)
      hwg_InvalidateRect(::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + (::height + 1) * ;
         ::internal[2] - ::height, ::xAdjRight, ::y1 + (::height + 1) * ::internal[2])
      hwg_InvalidateRect(::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + (::height + 1) * ;
         ::rowPos - ::height, ::xAdjRight, ::y1 + (::height + 1) * ::rowPos)
   ENDIF
   ::fipos := Min(::colpos + ::nLeftCol - 1 - ::freeze, Len(::aColumns))
   IF ::aColumns[::fipos]:Type = "L"
      ::EditLogical(WM_LBUTTONDOWN)
   ENDIF

ELSEIF nLine == 0
   IF PtrtouLong(s_oCursor) ==  PtrtouLong(s_ColSizeCursor)
      ::lResizing := .T.
      ::isMouseOver := .F.
      hwg_SetCursor(s_oCursor)
      s_xDrag := hwg_LOWORD(lParam)
      s_xDragMove := s_xDrag
      hwg_InvalidateRect(::handle, 0)
   ELSEIF ::lDispHead .AND. nLine >= - ::nHeadRows .AND. ;
      fif <= Len(::aColumns) //.AND. ;
      //::aColumns[fif]:bHeadClick != NIL
      ::aColumns[fif]:lHeadClick := .T.
      hwg_InvalidateRect(::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1)
     // hwg_MsgInfo("C")
      IF ::aColumns[fif]:bHeadClick != NIL
         ::isMouseOver := .F.
         ::oParent:lSuspendMsgsHandling := .T.
         Eval(::aColumns[fif]:bHeadClick, ::aColumns[fif], fif, Self)
         ::oParent:lSuspendMsgsHandling := .F.
      ENDIF
      ::lHeadClick := .T.
   ENDIF
ENDIF
   IF (PtrtouLong(hwg_GetActiveWindow()) == PtrtouLong(::GetParentForm():handle) .OR. ;
       ::GetParentForm():Type < WND_DLG_RESOURCE)
       ::SetFocus()
       ::RefreshLine()
   ENDIF

RETURN NIL

//----------------------------------------------------//
METHOD ButtonUp(lParam) CLASS HBrowse

   LOCAL xPos := hwg_LOWORD(lParam)
   LOCAL x
   LOCAL x1
   LOCAL i

   IF ::lResizing
      x1 := 0
      x := ::x1
      i := IIf(::freeze > 0, 1, ::nLeftCol)    // ::nLeftCol
      DO WHILE x < s_xDrag
         IF !::aColumns[i]:lHide
            x += ::aColumns[i]:width
            IF Abs(x - s_xDrag) < 10 .AND. ::aColumns[i]:Resizable
               x1 := x - ::aColumns[i]:width
               EXIT
            ENDIF
         ENDIF
         i := IIf(i == ::freeze, ::nLeftCol, i + 1)
      ENDDO
      IF xPos > x1
         ::aColumns[i]:width := xPos - x1
         hwg_SetCursor(s_arrowCursor)
         s_oCursor := 0
         ::isMouseOver := .F.
         //s_xDragMove := 0
         hwg_InvalidateRect(::handle, 0)
         ::lResizing := .F.
      ENDIF

   ELSEIF ::aSelected != NIL
      IF ::lCtrlPress
         ::Select()
         ::refreshline()
      ELSE
         IF Len(::aSelected) > 0
            ::aSelected := {}
            ::Refresh()
         ENDIF
      ENDIF
   ENDIF
   IF ::lHeadClick
      AEval(::aColumns,{|c|c:lHeadClick := .F.})
      hwg_InvalidateRect(::handle, 0, ::x1, ::y1 - ::nHeadHeight * ::nHeadRows, ::x2, ::y1)
      ::lHeadClick := .F.
     hwg_SetCursor(s_downCursor)
   ENDIF
   /*
   IF PtrtouLong(hwg_GetActiveWindow()) == PtrtouLong(::GetParentForm():handle) .OR. ;
       ::GetParentForm():Type < WND_DLG_RESOURCE
       ::SetFocus()
   ENDIF
    */
RETURN NIL

METHOD Select() CLASS HBrowse
   
   LOCAL i

   IF (i := AScan(::aSelected, Eval(::bRecno, Self))) > 0
      ADel(::aSelected, i)
      ASize(::aSelected, Len(::aSelected) - 1)
   ELSE
      AAdd(::aSelected, Eval(::bRecno, Self))
   ENDIF

RETURN NIL

//----------------------------------------------------//
METHOD ButtonRDown(lParam) CLASS HBrowse
   
   LOCAL nLine
   LOCAL xm
   LOCAL x1
   LOCAL fif
   Local acolumns := {}
   LOCAL nCols := 1
   LOCAL xSize := 0

   // Calculate the line you clicked on, keeping track of header
   IF (::lDispHead)
      nLine := Int((hwg_HIWORD(lParam) - (::nHeadHeight * ::nHeadRows)) / (::height + 1) + 1)
   ELSE
      nLine := Int(hwg_HIWORD(lParam) / (::height + 1) + 1)
   ENDIF
   xm := hwg_LOWORD(lParam)

   x1 := ::x1
   fif := IIf(::freeze > 0, 1, ::nLeftCol)
   DO WHILE nCols <= Len(::aColumns)
      xSize := ::aColumns[ncols]:width
      IF (::lAdjRight .AND. nCols == Len(::aColumns))
         xSize := Max(::x2 - x1, xSize)
      ENDIF
      IF !::aColumns[nCols]:lhide
         AAdd(aColumns, {xSize, ncols})
         x1 += xSize
         xSize := 0
      ENDIF
      nCols++
   ENDDO
   x1 := ::x1
   aColumns[Len(aColumns), 1] += xSize
   DO WHILE fif <= Len(aColumns)
      IF (!(fif < (::nLeftCol + ::nColumns) .AND. x1 + aColumns[fif, 1] < xm))
         EXIT
      ENDIF
      x1 += aColumns[fif, 1]
      fif := IIf(fif == ::freeze, ::nLeftCol, fif + 1)
   ENDDO
   IF fif > Len(aColumns)
      IF !::lAdjRight     // no column select
         RETURN NIL
      ENDIF
      fif--
   ENDIF
   fif := aColumns[fif, 2]
   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      //::fipos := Min(::colpos + ::nLeftCol - 1 - ::freeze, Len(::aColumns))
      IF hb_IsBlock(::bRClick)
         Eval(::bRClick, Self, nLine, fif)
      ENDIF
   ELSEIF nLine == 0
      IF ::lDispHead .AND. ;
         nLine >=  - ::nHeadRows .AND. fif <= Len(::aColumns)
         IF ::aColumns[fif]:bHeadRClick != NIL
            Eval(::aColumns[fif]:bHeadRClick, Self, nLine, fif)
         ENDIF
      ENDIF
   ENDIF

RETURN NIL

METHOD ButtonDbl(lParam) CLASS HBrowse
   
   LOCAL nLine := Int(IIf(::lDispHead, ;
                          ((hwg_HIWORD(lParam) - (::nHeadHeight * ::nHeadRows)) / (::height + 1) + 1), ;
                          hwg_HIWORD(lParam) / (::height + 1) + 1))

   IF nLine > 0 .AND. nLine <= ::rowCurrCount
      ::ButtonDown(lParam)
      ::Edit()
   ENDIF

RETURN NIL

//----------------------------------------------------//
METHOD MouseMove(wParam, lParam) CLASS HBrowse
   
   LOCAL xPos := hwg_LOWORD(lParam)
   LOCAL yPos := hwg_HIWORD(lParam)
   LOCAL x := ::x1
   LOCAL i
   LOCAL res := .F.
   LOCAL nLastColumn
   local currxPos := ::xPosMouseOver

   ::xPosMouseOver := 0
   ::isMouseOver := IIf(::lDispHead .AND. ::hTheme != NIL .AND. currxPos != 0, .T., .F.)
   nLastColumn := IIf(::lAdjRight, Len(::aColumns) - 1, Len(::aColumns))

   // DlgMouseMove()
   IF !::active .OR. Empty(::aColumns) .OR. ::x1 == NIL
      RETURN NIL
   ENDIF
   IF ::isMouseOver
      hwg_InvalidateRect(::handle, 0, s_axPosMouseOver[1], ::y1 - ::nHeadHeight * ::nHeadRows, s_axPosMouseOver[2], ::y1)
   ENDIF
   IF ::lDispHead .AND. (yPos <= ::nHeadHeight * ::nHeadRows + 1 .OR.; // ::height*::nHeadRows+1
       (::lResizing .AND. yPos > ::y1)) .AND. ;
      (xPos >= ::x1 .AND. xPos <= Max(s_xDragMove, ::xAdjRight) + 4)
      IF wParam == MK_LBUTTON .AND. ::lResizing
         hwg_SetCursor(s_oCursor)
         res := .T.
         s_xDragMove := xPos
         ::isMouseOver := .T.
         hwg_InvalidateRect(::handle, 0, xPos - 18, ::y1 - (::nHeadHeight * ::nHeadRows), xPos + 18, ;
            ::y2 - (::nFootHeight * ::nFootRows) - 1)
      ELSE
         i := IIf(::freeze > 0, 1, ::nLeftCol)
         DO WHILE x < ::x2 - 2 .AND. i <= nLastColumn     // Len(::aColumns)
            // TraceLog("Colonna " + Str(i) + "    x=" + Str(x))
            IF !::aColumns[i]:lhide
               x += ::aColumns[i]:width
               ::xPosMouseOver := xPos
               IF Abs(x - xPos) < 8
                  IF PtrtouLong(s_oCursor) != PtrtouLong(s_ColSizeCursor)
                     s_oCursor := s_ColSizeCursor
                  ENDIF
                  hwg_SetCursor(s_oCursor)
                  res := .T.
                  EXIT
               ELSE
                  s_oCursor := s_DownCursor
                  hwg_SetCursor(s_oCursor)
                  res := .T.
               ENDIF
            ENDIF
            i := IIf(i == ::freeze, ::nLeftCol, i + 1)
         ENDDO
      ENDIF
      IF !res .AND. !Empty(s_oCursor)
         hwg_SetCursor(s_arrowCursor)
         s_oCursor := 0
         ::lResizing := .F.
      ENDIF
      ::isMouseOver := IIf(::hTheme != NIL .AND. ::xPosMouseOver != 0, .T., .F.)
   ENDIF
   IF ::isMouseOver
      hwg_InvalidateRect(::handle, 0, ::xPosMouseOver - 1, ::y1 - ::nHeadHeight * ::nHeadRows, ::xPosMouseOver + 1, ::y1)
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
METHOD MouseWheel(nKeys, nDelta, nXPos, nYPos) CLASS HBrowse

   HB_SYMBOL_UNUSED(nXPos)
   HB_SYMBOL_UNUSED(nYPos)

   IF hwg_BitAnd(nKeys, MK_MBUTTON) != 0
      IF nDelta > 0
         ::PageUp()
      ELSE
         ::PageDown()
      ENDIF
   ELSE
      IF nDelta > 0
         ::LineUp()
      ELSE
         ::LineDown(.T.)
      ENDIF
      /*
      IF (::rowPos == 1 .OR. ::rowPos = ::rowCount) .AND. ::rowCurrCount >= ::rowCount
         ::Refresh(.F., nDelta > 0)
      ENDIF
      */
   ENDIF

RETURN NIL

METHOD onClick() CLASS HBrowse

   LOCAL lRes := .F.

   IF hb_IsBlock(::bEnter)
      ::oParent:lSuspendMsgsHandling := .T.
      lRes := Eval(::bEnter, Self, ::fipos)
      ::oParent:lSuspendMsgsHandling := .F.
      IF !hb_IsLogical(lRes)
         RETURN .T.
      ENDIF
   ENDIF

RETURN lRes

//----------------------------------------------------//
METHOD Edit(wParam, lParam) CLASS HBrowse
   
   LOCAL fipos
   LOCAL x1
   LOCAL y1
   LOCAL fif
   LOCAL nWidth
   LOCAL lReadExit
   LOCAL rowPos
   LOCAL oModDlg
   LOCAL oColumn
   LOCAL aCoors
   LOCAL nChoic
   LOCAL bInit
   LOCAL oGet
   LOCAL Type
   LOCAL oComboFont
   LOCAL oCombo
   LOCAL oBtn
   LOCAL oGet1
   LOCAL owb1
   LOCAL owb2
   LOCAL nHget

   fipos := Min(::colpos + ::nLeftCol - 1 - ::freeze, Len(::aColumns))
   ::fiPos := fipos

   //IF (!Eval(::bEof, Self) .OR. ::lAppMode) .AND. ;
   //   (::bEnter == NIL .OR. (hb_IsLogical(lRes := Eval(::bEnter, Self, fipos)) .AND. !lRes))
   IF (!Eval(::bEof, Self) .OR. ::lAppMode) .AND. (!::onClick())
      oColumn := ::aColumns[fipos]
      IF ::Type == BRW_DATABASE
         ::varbuf := (::Alias)->(Eval(oColumn:block,, Self, fipos))
      ELSE
         IF ::nRecords == 0 .AND. ::lAppMode
            AAdd(::aArray, Array(Len(::aColumns)))
            FOR fif := 1 TO Len(::aColumns)
                ::aArray[1, fif] := ;
                   IIf(::aColumns[fif]:Type == "D", CToD(Space(8)), ;
                   IIf(::aColumns[fif]:Type == "N", 0, IIf(::aColumns[fif]:Type == "L", .F., "")))
            NEXT
           ::lAppMode := .F.
           ::Refresh(::nFootRows > 0)
         ENDIF
         ::varbuf := Eval(oColumn:block,, Self, fipos)
      ENDIF
      Type := IIf(oColumn:Type == "U".AND.::varbuf != NIL, ValType(::varbuf), oColumn:Type)
      //IF ::lEditable .AND. Type != "O" .AND. Type != "L" // columns logic is handling in BUTTONDOWN()
      IF ::lEditable .AND. Type != "O" .AND. (oColumn:aList != NIL .OR. (oColumn:aList == NIL .AND. wParam != 13))
         IF oColumn:lEditable
            IF ::lAppMode
               IF Type == "D"
                  ::varbuf := CToD("")
               ELSEIF Type == "N"
                  ::varbuf := 0
               ELSEIF Type == "L"
                  ::varbuf := .F.
               ELSE
                  ::varbuf := ""
               ENDIF
            ENDIF
         ELSE
            RETURN NIL
         ENDIF
         x1 := ::x1
         fif := IIf(::freeze > 0, 1, ::nLeftCol)
         DO WHILE fif < fipos
            IF !::aColumns[fif]:lhide
               x1 += ::aColumns[fif]:width
            ENDIF
            fif := IIf(fif = ::freeze, ::nLeftCol, fif + 1)
         ENDDO
         nWidth := Min(::aColumns[fif]:width, ::x2 - x1 - 1)
         IF fif == Len(::aColumns)
            nWidth := Min(::nWidthColRight, ::x2 - x1 - 1)
         ENDIF
         rowPos := ::rowPos - 1
         IF ::lAppMode .AND. ::nRecords != 0 .AND. ::rowPos != ::rowCount
            rowPos++
         ENDIF
         y1 := ::y1 + (::height + 1) * rowPos

         // aCoors := hwg_GetWindowRect(::handle)
         // x1 += aCoors[1]
         // y1 += aCoors[2]

         aCoors := hwg_ClientToScreen(::handle, x1, y1)
         x1 := aCoors[1]
         y1 := aCoors[2] + 1

         lReadExit := SET(_SET_EXIT, .T.)

         ::lNoValid := .T.
         IF Type != "L"
            bInit := IIf(wParam == NIL .OR. wParam == 13 .OR. Empty(lParam), {|o|hwg_MoveWindow(o:handle, x1, y1, nWidth, o:nHeight + 1)}, ;
                       {|o|hwg_MoveWindow(o:handle, x1, y1, nWidth, o:nHeight + 1), ;
                           o:aControls[1]:SetFocus(), hwg_PostMessage(o:aControls[1]:handle, WM_CHAR, wParam, lParam)})
         ELSE
            bInit := {||.F.}
         ENDIF

         IF Type != "M"
            INIT DIALOG oModDlg ;
                 STYLE WS_POPUP + 1 + IIf(oColumn:aList == NIL, WS_BORDER, 0) + DS_CONTROL ;
                 At x1, y1 - IIf(oColumn:aList == NIL, 1, 0) ;
                 SIZE nWidth - 1, ::height + IIf(oColumn:aList == NIL, 1, 0) ;
                 ON INIT bInit ;
                 ON OTHER MESSAGES {|o, m, w, l|::EditEvent(o, m, w, l)}
         ELSE
            INIT DIALOG oModDlg title "memo edit" At 0, 0 SIZE 400, 300 ON INIT {|o|o:center()}
         ENDIF

         IF oColumn:aList != NIL .AND. (oColumn:bWhen == NIL .OR. Eval(oColumn:bWhen))
            oModDlg:brush := - 1
            oModDlg:nHeight := ::height + 1 // * 5

            IF hb_IsNumeric(::varbuf)
               nChoic := ::varbuf
            ELSE
               ::varbuf := AllTrim(::varbuf)
               nChoic := AScan(oColumn:aList, ::varbuf)
            ENDIF

            oComboFont := IIf(ValType(::oFont) == "U", ;
                               HFont():Add("MS Sans Serif", 0, -8), ;
                               HFont():Add(::oFont:name, ::oFont:width, ::oFont:height + 2))

            @ 0, 0 GET COMBOBOX oCombo VAR nChoic ;
               ITEMS oColumn:aList            ;
               SIZE nWidth, ::height + 1      ;
               FONT oComboFont  ;
               DISPLAYCOUNT  IIf(Len(oColumn:aList) > ::rowCount, ::rowCount - 1, Len(oColumn:aList)) ;
               VALID {|oColumn, oGet|::ValidColumn(oColumn, oGet)};
               WHEN {|oColumn, oGet|::WhenColumn(oColumn, oGet)}
            //oCombo:bSelect := {||KEYB_EVENT(VK_RETURN)}

            oModDlg:AddEvent(0, IDOK, {||oModDlg:lResult := .T., oModDlg:close()})

         ELSE
            IF Type == "L"
               oModDlg:lResult := .T.
            ELSEIF Type != "M"
               nHGet := Max((::height - (TxtRect("N", self))[2]) / 2, 0)
               @ 0, nHGet GET oGet VAR ::varbuf       ;
                  SIZE nWidth - IIf(oColumn:bClick != NIL, 16, 1), ::height   ;
                  NOBORDER                       ;
                  STYLE ES_AUTOHSCROLL           ;
                  FONT ::oFont                   ;
                  PICTURE IIf(Empty(oColumn:picture), NIL, oColumn:picture)   ;
                  VALID {|oColumn, oGet|::ValidColumn(oColumn, oGet, oBtn)};
                  WHEN {|oColumn, oGet|::WhenColumn(oColumn, oGet, oBtn)}
                  //VALID oColumn:bValid           ;
                  //WHEN oColumn:bWhen
                 //oModDlg:AddEvent(0, IDOK, {||oModDlg:lResult := .T., oModDlg:close()})
               IF oColumn:bClick != NIL
                  IF Type != "D"
                     @ nWidth - 15, 0  OWNERBUTTON oBtn  SIZE 16, ::height - 0 ;
                        TEXT "..."  FONT HFont():Add("MS Sans Serif", 0, -10, 400) ;
                        COORDINATES 0, 1, 0, 0      ;
                        ON CLICK {|oColumn, oBtn|HB_SYMBOL_UNUSED(oColumn), ::onClickColumn(.T., oGet, oBtn)}
                        oBtn:themed := ::hTheme != NIL
                  ELSE
                     @ nWidth - 16, 0 DATEPICKER oBtn SIZE 16, ::height - 1  ;
                        ON CHANGE {|value, oBtn|::onClickColumn(value, oGet, oBtn)}
                  ENDIF
               ENDIF
               oGet:lNoValid := .T.
               IF !Empty(wParam) .AND. wParam != 13 .AND. !Empty(lParam)
                  hwg_SendMessage(oGet:handle, WM_CHAR, wParam, lParam)
               ENDIF
            ELSE
               oGet1 := ::varbuf
               @ 10, 10 Get oGet1 SIZE oModDlg:nWidth - 20, 240 FONT ::oFont Style WS_VSCROLL + WS_HSCROLL + ES_MULTILINE VALID oColumn:bValid
               @ 010, 252 ownerbutton owb2 text "Save" size 80, 24 ON Click {||::varbuf := oGet1, oModDlg:close(), oModDlg:lResult := .T.}
               @ 100, 252 ownerbutton owb1 text "Close" size 80, 24 ON CLICK {||oModDlg:close()}
            ENDIF
         ENDIF

         IF Type != "L" .AND. ::nSetRefresh > 0
            ::oTimer:Interval := 0
         ENDIF

         ACTIVATE DIALOG oModDlg

         ::lNoValid := .F.
         IF Type = "L" .AND. wParam != VK_RETURN
             hwg_SetCursor(s_arrowCursor)
             IF wParam == VK_SPACE
                oModDlg:lResult := ::EditLogical(wParam)
                RETURN NIL
             ENDIF
         ENDIF

         IF oColumn:aList != NIL
            oComboFont:Release()
         ENDIF

         IF oModDlg:lResult
            IF oColumn:aList != NIL
               IF hb_IsNumeric(::varbuf)
                  ::varbuf := nChoic
               ELSE
                  ::varbuf := oColumn:aList[nChoic]
               ENDIF
            ENDIF
            IF ::lAppMode
               ::lAppMode := .F.
               IF ::Type == BRW_DATABASE
                  (::Alias)->(DBAppend())
                  (::Alias)->(Eval(oColumn:block, ::varbuf, Self, fipos))
                  (::Alias)->(DBUnlock())
               ELSE
                  IF hb_IsArray(::aArray[1])
                     AAdd(::aArray, Array(Len(::aArray[1])))
                     FOR fif := 2 TO Len((::aArray[1]))
                        ::aArray[Len(::aArray), fif] := ;                                                 
                                                            IIf(::aColumns[fif]:Type == "D", CToD(Space(8)), ;
                                                                 IIf(::aColumns[fif]:Type == "N", 0, ""))
                     NEXT
                  ELSE
                     AAdd(::aArray, NIL)
                  ENDIF
                  ::nCurrent := Len(::aArray)
                  Eval(oColumn:block, ::varbuf, Self, fipos)
               ENDIF
               IF ::nRecords > 0
                  ::rowPos++
               ENDIF
               ::lAppended := .T.
               IF !(Getkeystate(VK_UP) < 0 .OR. Getkeystate(VK_DOWN) < 0)
                  ::DoHScroll(SB_LINERIGHT)
               ENDIF
               ::Refresh(::nFootRows > 0)
            ELSE
               IF ::Type == BRW_DATABASE
                  IF (::Alias)->(RLock())
                     (::Alias)->(Eval(oColumn:block, ::varbuf, Self, fipos))
                     (::Alias)->(DBUnlock())
                  ELSE
                     hwg_MsgStop("Can't lock the record!")
                  ENDIF
               ELSE
                  Eval(oColumn:block, ::varbuf, Self, fipos)
               ENDIF
               IF !(Getkeystate(VK_UP) < 0 .OR. Getkeystate(VK_DOWN) < 0 .OR. Getkeystate(VK_SPACE) < 0) .AND. Type != "L"
                  ::DoHScroll(SB_LINERIGHT)
               ENDIF
               ::lUpdated := .T.
               hwg_InvalidateRect(::handle, 0, ::x1, ::y1 + (::height + 1) * (::rowPos - 2), ::x2, ;
                  ::y1 + (::height + 1) * ::rowPos)
               ::RefreshLine()
            ENDIF

            /* Execute block after changes are made */
            IF hb_IsBlock(::bUpdate)
               Eval(::bUpdate, Self, fipos)
            END

         ELSEIF ::lAppMode
            ::lAppMode := .F.
            //hwg_InvalidateRect(::handle, 0, ::x1, ::y1 + (::height + 1) * ::rowPos, ::x2, ::y1 + (::height + 1) * ;
            //   (::rowPos + 2))
            IF ::Type == BRW_DATABASE .AND. Eval(::bEof, Self)
               Eval(::bSkip, Self, -1)
            ENDIF
            IF ::rowPos < ::rowCount
               //::RefreshLine()
               hwg_InvalidateRect(::handle, 0, ::x1 - ::nShowMark - ::nDeleteMark, ::y1 + (::height + 1) * ::rowPos, ;
                  ::x2, ::y1 + (::height + 1) * (::rowPos + 1))
            ELSE
               ::Refresh()
            ENDIF
         ENDIF
         ::SetFocus()
         SET(_SET_EXIT, lReadExit)

         IF ::nSetRefresh > 0
            ::oTimer:Interval := ::nSetRefresh
         ENDIF

      ELSEIF ::lEditable
         ::DoHScroll(SB_LINERIGHT)
      ENDIF
   ENDIF

RETURN NIL

METHOD EditLogical(wParam, lParam) CLASS HBrowse

   HB_SYMBOL_UNUSED(lParam)

      IF !::aColumns[::fipos]:lEditable
          RETURN .F.
      ENDIF

      IF ::aColumns[::fipos]:bWhen != NIL
         ::oparent:lSuspendMsgsHandling := .T.
         ::varbuf := Eval(::aColumns[::fipos]:bWhen, ::aColumns[::fipos], ::varbuf)
         ::oparent:lSuspendMsgsHandling := .F.
         IF !(hb_IsLogical(::varbuf) .AND. ::varbuf)
            RETURN .F.
         ENDIF
      ENDIF

      IF ::Type == BRW_DATABASE
         IF wParam != VK_SPACE
            ::varbuf := (::Alias)->(Eval(::aColumns[::fipos]:block,, Self, ::fipos))
         ENDIF
         IF (::Alias)->(RLock())
            (::Alias)->(Eval(::aColumns[::fipos]:block, !::varbuf, Self, ::fipos))
            (::Alias)->(DBUnlock())
         ELSE
             hwg_MsgStop("Can't lock the record!")
         ENDIF
      ELSEIF ::nRecords  > 0
         IF wParam != VK_SPACE
             ::varbuf := Eval(::aColumns[::fipos]:block,, Self, ::fipos)
         ENDIF
         Eval(::aColumns[::fipos]:block, !::varbuf, Self, ::fipos)
      ENDIF

      ::lUpdated := .T.
      ::RefreshLine()
      IF ::aColumns[::fipos]:bValid != NIL
         ::oparent:lSuspendMsgsHandling := .T.
         Eval(::aColumns[::fipos]:bValid, !::varbuf, ::aColumns[::fipos]) //, ::varbuf)
        ::oparent:lSuspendMsgsHandling := .F.
      ENDIF

RETURN .T.

METHOD EditEvent(oCtrl, msg, wParam, lParam)

   HB_SYMBOL_UNUSED(lParam)

   IF (msg == WM_KEYDOWN .AND. (wParam == VK_RETURN .OR. wParam == VK_TAB))
      RETURN -1
   ELSEIF (msg == WM_KEYDOWN .AND. wParam == VK_ESCAPE)
      oCtrl:oParent:lResult := .F.
      oCtrl:oParent:Close()
      RETURN 0
   ENDIF

RETURN -1

METHOD onClickColumn(value, oGet, oBtn) CLASS HBROWSE
   
   LOCAL oColumn := ::aColumns[::fipos]

   IF hb_IsDate(value)
      ::varbuf := value
      oGet:refresh()
      hwg_PostMessage(oBtn:handle, WM_KEYDOWN, VK_TAB, 0)
   ENDIF
   IF oColumn:bClick != NIL
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(oColumn:bClick, value, oGet, oColumn, Self)
      ::oparent:lSuspendMsgsHandling := .F.
    ENDIF
   oGet:SetFocus()

RETURN NIL

METHOD WhenColumn(value, oGet) CLASS HBROWSE
   
   LOCAL res := .T.
   LOCAL oColumn := ::aColumns[::fipos]

   IF oColumn:bWhen != NIL
      ::oparent:lSuspendMsgsHandling := .T.
      res := Eval(oColumn:bWhen, Value, oGet)
        oGet:lnovalid := res
        IF hb_IsLogical(res) .AND. !res
           ::SetFocus()
           oGet:oParent:close()
        ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
    ENDIF

RETURN res

METHOD ValidColumn(value, oGet, oBtn) CLASS HBROWSE
   
   LOCAL res := .T.
   LOCAL oColumn := ::aColumns[::fipos]

   IF !CheckFocus(oGet, .T.) //.OR. oGet:lNoValid
      RETURN .T.
   ENDIF
   IF oBtn != NIL .AND. hwg_GetFocus() == oBtn:handle
      RETURN .T.
   ENDIF
   IF oColumn:bValid != NIL
       ::oparent:lSuspendMsgsHandling := .T.
       res := Eval(oColumn:bValid, value, oGet)
         oGet:lnovalid := res
         IF hb_IsLogical(res) .AND. !res
            oGet:SetFocus()
         ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
    ENDIF
    IF res
      oGet:oParent:close()
      oGet:oParent:lResult := .T.
    ENDIF

RETURN res

METHOD ChangeRowCol(nRowColChange) CLASS HBrowse
// 0 (default) No change.
// 1 Row change
// 2 Column change
// 3 Row and column change
   
   LOCAL res := .T.
   LOCAL lSuspendMsgsHandling := ::oParent:lSuspendMsgsHandling
   
   IF hb_IsBlock(::bChangeRowCol) .AND. !::oParent:lSuspendMsgsHandling
      ::oParent:lSuspendMsgsHandling := .T.
      res := Eval(::bChangeRowCol, nRowColChange, Self, ::SetColumn())
      ::oParent:lSuspendMsgsHandling := lSuspendMsgsHandling
   ENDIF
   IF nRowColChange > 0
      ::lSuspendMsgsHandling := .F.
   ENDIF

RETURN !Empty(res)

METHOD When() CLASS HBrowse
   
   LOCAL nSkip
   LOCAL res := .T.

   IF !CheckFocus(self, .F.)
      RETURN .F.
   ENDIF
   IF ::HighlightStyle == 0 .OR. ::HighlightStyle == 3
      ::RefreshLine()
   ENDIF

   IF hb_IsBlock(::bGetFocus)
      nSkip := IIf(GetKeyState(VK_UP) < 0 .OR. (GetKeyState(VK_TAB) < 0 .AND. GetKeyState(VK_SHIFT) < 0), -1, 1)
      ::oParent:lSuspendMsgsHandling := .T.
      ::lnoValid := .T.
      //::setfocus()
      res := Eval(::bGetFocus, ::Colpos, Self)
      res := IIf(hb_IsLogical(res), res, .T.)
      ::lnoValid := !res
      IF !res
         WhenSetFocus(Self, nSkip)
      ENDIF
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN res

METHOD Valid() CLASS HBrowse
   
   LOCAL res

   //IF ::bLostFocus != NIL .AND. (!CheckFocus(Self, .T.) .OR.::lNoValid)
   IF !CheckFocus(self, .T.) .OR. ::lNoValid
      RETURN .T.
   ENDIF
   IF ::HighlightStyle == 0 .OR. ::HighlightStyle == 3
      ::RefreshLine()
   ENDIF
   IF hb_IsBlock(::bLostFocus)
      ::oParent:lSuspendMsgsHandling := .T.
      res := Eval(::bLostFocus, ::ColPos, Self)
      res := IIf(hb_IsLogical(res), res, .T.)
      IF hb_IsLogical(res) .AND. !res
         ::setfocus(.T.)
         ::oParent:lSuspendMsgsHandling := .F.
         RETURN .F.
      ENDIF
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF

RETURN .T.

//----------------------------------------------------//
METHOD RefreshLine() CLASS HBrowse
   
   LOCAL nInternal := ::internal[1]

   ::internal[1] := 0
   hwg_InvalidateRect(::handle, 0, ::x1 - ::nDeleteMark, ::y1 + (::height + 1) * ::rowPos - ::height, ::x2, ;
      ::y1 + (::height + 1) * ::rowPos)
   ::internal[1] := nInternal

RETURN NIL

//----------------------------------------------------//
METHOD Refresh(lFull, lLineUp) CLASS HBrowse

   IF lFull == NIL .OR. lFull
      IF ::lFilter
         ::nLastRecordFilter := 0
         ::nFirstRecordFilter := 0
         //SetScrollPos(::handle, SB_VERT, 0)
         //::RowPos := 0
         /*
         (::Alias)->(FltGoTop(Self)) // sk
         */
            // you need this? becausee it will not let scroll you browse? // lfbasso@
      ENDIF
      ::internal[1] := 15
      //hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW)
      IF ::nCurrent < ::rowCount .AND. ::rowPos <= ::nCurrent .AND. Empty(lLineUp)
         ::rowPos := ::nCurrent
      ENDIF
      //hwg_RedrawWindow(::handle, RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW)
   ELSE
      hwg_InvalidateRect(::handle, 0)
      ::internal[1] := SetBit(::internal[1], 1, 0)
      IF ::nCurrent < ::rowCount .AND. ::rowPos <= ::nCurrent .AND. Empty(lLineUp)
         ::rowPos := ::nCurrent
      ENDIF
      //hwg_RedrawWindow(::handle, RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW)
   ENDIF
   //hwg_RedrawWindow(::handle, RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW)
   hwg_RedrawWindow(::handle, RDW_ERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT + RDW_UPDATENOW) // Force a complete redraw

RETURN NIL

/*
METHOD BrwScrollVPos() CLASS HBrowse
   
   LOCAL minPos
   LOCAL maxPos
   Local nRecCount
   LOCAL nRecno
   LOCAL nPosRecno
   LOCAL nIndexOrd := (::Alias)->(IndexOrd())
   LOCAL lDisableVScrollPos := ::lDisableVScrollPos .AND. IndexOrd() != 0

   nPosRecno := IIf(nIndexOrd == 0 .OR. lDisableVScrollPos, (::Alias)->(RecNo()), (::Alias)->(ordkeyno()))

   IF !lDisableVScrollPos .AND. ((!::lFilter .AND. Empty((::Alias)->(DBFILTER()))) .OR. !Empty(::RelationalExpr))
      nRecCount := Eval(::bRcou, Self) //IIf((::Alias)->(IndexOrd()) == 0, , OrdKeyCount())
      IF ::nRecCount != nRecCount .OR. nIndexOrd != ::nIndexOrd .OR. ::Alias != Alias()
         ::nRecCount := nRecCount
         ::nIndexOrd := nIndexOrd
         nrecno := (::Alias)->(RecNo())
         Eval(::bGobot, Self)
         maxPos := IIf(nIndexOrd == 0, (::Alias)->(RecNo()), IIf(Empty(::RelationalExpr), ::nRecCount, (::Alias)->(ordkeyno())))
         Eval(::bGotop, Self)
         minPos := IIf(nIndexOrd == 0, (::Alias)->(RecNo()), (::Alias)->(ordkeyno()))
         (::Alias)->(DBGoTo(nrecno))
         IF minPos != maxPos
            SetScrollRange(::handle, SB_VERT, minPos, maxPos)
         ENDIF
          // (::Alias)->(DBGoTo(nrecno))
      ENDIF
   ELSE
      ::nRecCount := (::Alias)->(Reccount())
      SetScrollRange(::handle, SB_VERT, 1, ::nRecCount)
   ENDIF
   RETURN IIf(lDisableVScrollPos, ::nRecCount / 2, nPosRecno)
    //IIf((::Alias)->(IndexOrd()) == 0 .OR. ::lDisableVScrollPos, (::Alias)->(RecNo()), (::Alias)->(ordkeyno()))
*/
//----------------------------------------------------//
METHOD FldStr(oBrw, numf) CLASS HBrowse
   
   LOCAL cRes
   LOCAL vartmp
   LOCAL Type
   LOCAL pict

   IF numf <= Len(oBrw:aColumns)

      pict := oBrw:aColumns[numf]:picture

      IF pict != NIL
         IF oBrw:Type == BRW_DATABASE
            IF oBrw:aRelation
               cRes := (oBrw:aColAlias[numf])->(Transform(Eval(oBrw:aColumns[numf]:block,, oBrw, numf), pict))
            ELSE
               cRes := (oBrw:Alias)->(Transform(Eval(oBrw:aColumns[numf]:block,, oBrw, numf), pict))
            ENDIF
         ELSE
            oBrw:nCurrent := IIf(oBrw:nCurrent == 0, 1, oBrw:nCurrent)
            vartmp := Eval(oBrw:aColumns[numf]:block,, oBrw, numf)
            cRes := IIf(vartmp != NIL, Transform(vartmp, pict), Space(oBrw:aColumns[numf]:length))
         ENDIF
      ELSE
         IF oBrw:Type == BRW_DATABASE
            IF oBrw:aRelation
               vartmp := (oBrw:aColAlias[numf])->(Eval(oBrw:aColumns[numf]:block,, oBrw, numf))
            ELSE
               vartmp := (oBrw:Alias)->(Eval(oBrw:aColumns[numf]:block,, oBrw, numf))
            ENDIF
         ELSE
            oBrw:nCurrent := IIf(oBrw:nCurrent == 0, 1, oBrw:nCurrent)
            vartmp := Eval(oBrw:aColumns[numf]:block,, oBrw, numf)
         ENDIF

         Type := (oBrw:aColumns[numf]):Type
         IF Type == "U" .AND. vartmp != NIL
            Type := ValType(vartmp)
         ENDIF
         IF Type == "C"
            //cRes := Padr(vartmp, oBrw:aColumns[numf]:length)
            cRes := vartmp
         ELSEIF Type == "N"
            IF oBrw:aColumns[numf]:aList != NIL .AND. (oBrw:aColumns[numf]:bWhen == NIL .OR. Eval(oBrw:aColumns[numf]:bWhen))
               IF vartmp == 0
                  cRes := ""
               ELSE
                  cRes := oBrw:aColumns[numf]:aList[vartmp]
               ENDIF
            ELSE
               cRes := PadL(Str(vartmp, oBrw:aColumns[numf]:length, ;
                                  oBrw:aColumns[numf]:dec), oBrw:aColumns[numf]:length)
            ENDIF
         ELSEIF Type == "D"
            cRes := PadR(DToC(vartmp), oBrw:aColumns[numf]:length)

         ELSEIF Type == "L"
            cRes := PadR(IIf(vartmp, "T", "F"), oBrw:aColumns[numf]:length)

         ELSEIF Type == "M"
            cRes := IIf(Empty(vartmp), "<memo>", "<MEMO>")

         ELSEIF Type == "O"
            cRes := "<" + vartmp:Classname() + ">"

         ELSEIF Type == "A"
            cRes := "<Array>"

         ELSE
            cRes := Space(oBrw:aColumns[numf]:length)
         ENDIF
      ENDIF
   ENDIF

RETURN cRes

//----------------------------------------------------//
STATIC FUNCTION FLDCOUNT(oBrw, xstrt, xend, fld1)
   
   LOCAL klf := 0
   LOCAL i := IIf(oBrw:freeze > 0, 1, fld1)

   DO WHILE .T.
      // xstrt += (MAX(oBrw:aColumns[i]:length, Len(oBrw:aColumns[i]:heading)) - 1) * oBrw:width
      xstrt += oBrw:aColumns[i]:width
      IF xstrt > xend
         EXIT
      ENDIF
      klf++
      i := IIf(i == oBrw:freeze, fld1, i + 1)
      // xstrt += 2 * oBrw:width
      IF i > Len(oBrw:aColumns)
         EXIT
      ENDIF
   ENDDO

RETURN IIf(klf == 0, 1, klf)

//----------------------------------------------------//
FUNCTION HWG_CREATEARLIST(oBrw, arr)
   
   LOCAL i
   
   oBrw:Type := BRW_ARRAY
   oBrw:aArray := arr
   IF Len(oBrw:aColumns) == 0
      // oBrw:aColumns := {}
      IF hb_IsArray(arr[1])
         FOR i := 1 TO Len(arr[1])
            oBrw:AddColumn(HColumn():New(, ColumnArBlock()))
         NEXT
      ELSE
         oBrw:AddColumn(HColumn():New(, {|value, o|HB_SYMBOL_UNUSED(value), o:aArray[o:nCurrent]}))
      ENDIF
   ENDIF
   Eval(oBrw:bGoTop, oBrw)
   oBrw:Refresh()

RETURN NIL

//----------------------------------------------------//
PROCEDURE ARSKIP(oBrw, nSkip)
   
   LOCAL nCurrent1

   IF oBrw:nRecords != 0
      nCurrent1 := oBrw:nCurrent
      oBrw:nCurrent += nSkip + IIf(nCurrent1 == 0, 1, 0)
      IF oBrw:nCurrent < 1
         oBrw:nCurrent := 0
      ELSEIF oBrw:nCurrent > oBrw:nRecords
         oBrw:nCurrent := oBrw:nRecords + 1
      ENDIF
   ENDIF

RETURN

//----------------------------------------------------//
FUNCTION CreateList(oBrw, lEditable)
   
   LOCAL i
   LOCAL nArea := Select()
   LOCAL kolf := FCount()

   oBrw:Alias := Alias()

   oBrw:aColumns := {}
   FOR i := 1 TO kolf
      oBrw:AddColumn(HColumn():New(FieldName(i),                      ;
                                   FieldWBlock(FieldName(i), nArea),  ;
                                   dbFieldInfo(DBS_TYPE, i),         ;
                                   IIf(dbFieldInfo(DBS_TYPE, i) == "D".AND.__SetCentury(), 10, dbFieldInfo(DBS_LEN, i)), ;
                                   dbFieldInfo(DBS_DEC, i),          ;
                                   lEditable))
   NEXT

   oBrw:Refresh()

RETURN NIL

FUNCTION VScrollPos(oBrw, nType, lEof, nPos)
   
   LOCAL minPos
   LOCAL maxPos
   LOCAL oldRecno
   LOCAL newRecno
   LOCAL nrecno

   IF oBrw:lNoVScroll
      RETURN NIL
   ENDIF
   GetScrollRange(oBrw:handle, SB_VERT, @minPos, @maxPos)
   IF nPos == NIL
      IF oBrw:Type != BRW_DATABASE
         IF nType > 0 .AND. lEof
            Eval(oBrw:bSkip, oBrw, -1)
         ENDIF
         nPos := IIf(oBrw:nRecords > 1, Round(((maxPos - minPos + 1) / (oBrw:nRecords - 1)) * ;
                                                (Eval(oBrw:bRecnoLog, oBrw) - 1), 0), minPos)
         SetScrollPos(oBrw:handle, SB_VERT, nPos)
      ELSEIF !Empty(oBrw:Alias)
         nrecno := (oBrw:Alias)->(RecNo())
         Eval(oBrw:bGotop, oBrw)
         minPos := IIf((oBrw:Alias)->(IndexOrd()) == 0, (oBrw:Alias)->(RecNo()), (oBrw:Alias)->(ordkeyno()))
         Eval(oBrw:bGobot, oBrw)
         maxPos := IIf((oBrw:Alias)->(IndexOrd()) == 0, (oBrw:Alias)->(RecNo()), (oBrw:Alias)->(ordkeyno()))
         IF minPos != maxPos
            SetScrollRange(oBrw:handle, SB_VERT, minPos, maxPos)
         ENDIF
         (oBrw:Alias)->(DBGoTo(nrecno))
         SetScrollPos(oBrw:handle, SB_VERT, IIf((oBrw:Alias)->(IndexOrd()) == 0, (oBrw:Alias)->(RecNo()), (oBrw:Alias)->(ordkeyno())))

//         SetScrollPos(oBrw:handle, SB_VERT, oBrw:BrwScrollVPos())
      ENDIF
   ELSE
      oldRecno := Eval(oBrw:bRecnoLog, oBrw)
      newRecno := Round((oBrw:nRecords - 1) * nPos / (maxPos - minPos) + 1, 0)
      IF newRecno <= 0
         newRecno := 1
      ELSEIF newRecno > oBrw:nRecords
         newRecno := oBrw:nRecords
      ENDIF
      IF nType == SB_THUMBPOSITION
         SetScrollPos(oBrw:handle, SB_VERT, nPos)
      ENDIF
      IF newRecno != oldRecno
         Eval(oBrw:bSkip, oBrw, newRecno - oldRecno)
         IF oBrw:rowCount - oBrw:rowPos > oBrw:nRecords - newRecno
            oBrw:rowPos := oBrw:rowCount - (oBrw:nRecords - newRecno)
         ENDIF
         IF oBrw:rowPos > newRecno
            oBrw:rowPos := newRecno
         ENDIF
         oBrw:Refresh(oBrw:nFootRows > 0)
      ENDIF
   ENDIF

RETURN NIL

/*
Function HScrollPos(oBrw, nType, lEof, nPos)

   LOCAL minPos
   LOCAL maxPos
   LOCAL i
   LOCAL nSize := 0
   LOCAL nColPixel
   LOCAL nBWidth := oBrw:nWidth // :width is _not_ browse width

   GetScrollRange(oBrw:handle, SB_HORZ, @minPos, @maxPos)

   IF nType == SB_THUMBPOSITION

      nColPixel := Int((nPos * nBWidth) / ((maxPos - minPos) + 1))
      i := oBrw:nLeftCol - 1

      do while nColPixel > nSize .AND. i < Len(oBrw:aColumns)
         nSize += oBrw:aColumns[++i]:width
      enddo

      // colpos is relative to leftmost column, as it seems, so I subtract leftmost column number
      oBrw:colpos := Max(i, oBrw:nLeftCol) - oBrw:nLeftCol + 1
   ENDIF

   SetScrollPos(oBrw:handle, SB_HORZ, nPos)

RETURN NIL
*/

//----------------------------------------------------//
// Agregado x WHT. 27.07.02
// Locus metodus.
METHOD ShowSizes() CLASS HBrowse
   
   LOCAL cText := ""

   AEval(::aColumns, ;
         {|v, e|HB_SYMBOL_UNUSED(v), cText += ::aColumns[e]:heading + ": " + Str(Round(::aColumns[e]:width / 8, 0) - 2) + Chr(10) + Chr(13)})
   hwg_MsgInfo(cText)

RETURN NIL

FUNCTION ColumnArBlock()
RETURN {|value, o, n|IIf(value == NIL, ;
                         o:aArray[IIf(o:nCurrent < 1, 1, o:nCurrent), n], ;
                         o:aArray[IIf(o:nCurrent < 1, 1, o:nCurrent), n] := value)}


STATIC FUNCTION HdrToken(cStr, nMaxLen, nCount)

   LOCAL nL
   LOCAL nPos := 0

   nMaxLen := nCount := 0
   cStr += ";"
#ifdef __XHARBOUR__
   DO WHILE (nL := Len(__StrTkPtr(@cStr, @nPos, ";"))) != 0
#else
   DO WHILE (nL := Len(hb_tokenPtr(@cStr, @nPos, ";"))) != 0
#endif
      nMaxLen := Max(nMaxLen, nL)
      nCount++
   ENDDO

RETURN NIL

STATIC FUNCTION FltSkip(oBrw, nLines, lDesc)

   LOCAL n

   IF nLines == NIL
      nLines := 1
   ENDIF
   IF lDesc == NIL
      lDesc := .F.
   ENDIF
   IF nLines > 0
      FOR n := 1 TO nLines
         (oBrw:Alias)->(DBSKIP(IIf(lDesc, - 1, + 1)))
         IF Empty(oBrw:RelationalExpr)
            DO WHILE (oBrw:Alias)->(!Eof()) .AND. Eval(oBrw:bWhile, oBrw) .AND. !Eval(oBrw:bFor, oBrw)
              //SKIP IIf(lDesc, - 1, + 1)
               (oBrw:Alias)->(DBSKIP(IIf(lDesc, - 1, + 1)))
            ENDDO
         ENDIF
      NEXT
   ELSEIF nLines < 0
      FOR n := 1 TO (nLines * (-1))
         IF (oBrw:Alias)->(Eof())
            IF lDesc
               FltGoTop(oBrw)
            ELSE
               FltGoBottom(oBrw)
            ENDIF
         ELSE
            //SKIP IIf(lDesc, + 1, - 1)
            (oBrw:Alias)->(DBSKIP(IIf(lDesc, + 1, - 1)))
         ENDIF
         IF Empty(oBrw:RelationalExpr)
         DO WHILE !(oBrw:Alias)->(Bof()) .AND. Eval(oBrw:bWhile, oBrw) .AND. !Eval(oBrw:bFor, oBrw)
            //SKIP IIf(lDesc, + 1, - 1)
            (oBrw:Alias)->(DBSKIP(IIf(lDesc, + 1, - 1)))
         ENDDO
         ENDIF
      NEXT
   ENDIF

RETURN NIL

STATIC FUNCTION FltGoTop(oBrw)

   IF oBrw:nFirstRecordFilter == 0
      Eval(oBrw:bFirst)
      IF (oBrw:Alias)->(!Eof())
         IF Empty(oBrw:RelationalExpr)
            DO WHILE (oBrw:Alias)->(!Eof()) .AND. !(Eval(oBrw:bWhile, oBrw) .AND. Eval(oBrw:bFor, oBrw))
              (oBrw:Alias)->(DBSkip())
            ENDDO
         ENDIF
         oBrw:nFirstRecordFilter := FltRecNo(oBrw)
      ELSE
         oBrw:nFirstRecordFilter := 0
      ENDIF
   ELSE
      FltGoTo(oBrw, oBrw:nFirstRecordFilter)
   ENDIF

RETURN NIL

STATIC FUNCTION FltGoBottom(oBrw)

   IF oBrw:nLastRecordFilter == 0
      Eval(oBrw:bLast)
      IF Empty(oBrw:RelationalExpr)
         IF !Eval(oBrw:bWhile, oBrw) .OR. !Eval(oBrw:bFor, oBrw)
            DO WHILE (oBrw:Alias)->(!Bof()) .AND. !Eval(oBrw:bWhile, oBrw)
              (oBrw:Alias)->(DBSkip(-1))
            ENDDO
            DO WHILE !Bof() .AND. Eval(oBrw:bWhile, oBrw) .AND. !Eval(oBrw:bFor, oBrw)
              (oBrw:Alias)->(DBSkip(-1))
            ENDDO
         ENDIF
      ENDIF
      oBrw:nLastRecordFilter := FltRecNo(oBrw)
   ELSE
      FltGoTo(oBrw, oBrw:nLastRecordFilter)
   ENDIF

RETURN NIL

STATIC FUNCTION FltBOF(oBrw)

   LOCAL lRet := .F.
   LOCAL nRecord
   LOCAL xValue
   LOCAL xFirstValue

   IF (oBrw:Alias)->(Bof())
      lRet := .T.
   ELSE
      nRecord := FltRecNo(oBrw)
      xValue := (oBrw:Alias)->(OrdKeyNo()) //&(cKey)
      FltGoTop(oBrw)
      xFirstValue := (oBrw:Alias)->(OrdKeyNo()) //&(cKey)

      IF xValue < xFirstValue
         lRet := .T.
         FltGoTop(oBrw)
      ELSE
         FltGoTo(oBrw, nRecord)
      ENDIF
   ENDIF

RETURN lRet

STATIC FUNCTION FltEOF(oBrw)

   LOCAL lRet := .F.
   LOCAL nRecord
   LOCAL xValue
   LOCAL xLastValue

   IF (oBrw:Alias)->(Eof())
      lRet := .T.
   ELSE
      nRecord := FltRecNo(oBrw)
      xValue := (oBrw:Alias)->(OrdKeyNo())
      FltGoBottom(oBrw)
      xLastValue := (oBrw:Alias)->(OrdKeyNo())
      IF xValue > xLastValue
         lRet := .T.
         FltGoBottom(oBrw)
         (oBrw:Alias)->(DBSkip())
      ELSE
         FltGoTo(oBrw, nRecord)
      ENDIF
   ENDIF

RETURN lRet

/* no used
STATIC FUNCTION FltRecCount(oBrw)

   LOCAL nRecord
   LOCAL nCount := 0

   nRecord := FltRecNo(oBrw)
   FltGoTop(oBrw)
   oBrw:aRecnoFilter := {}
   DO WHILE !(oBrw:Alias)->(Eof()) .AND. Eval(oBrw:bWhile, oBrw)
      IF Eval(oBrw:bFor, oBrw)
         nCount++
         IF oBrw:lFilter
            AAdd(oBrw:aRecnoFilter, (oBrw:Alias)->(recno()))
         ENDIF
      ENDIF
      (oBrw:Alias)->(DBSkip())
   ENDDO
   FltGoTo(oBrw, nRecord)

RETURN nCount
*/

STATIC FUNCTION FltGoTo(oBrw, nRecord)

   HB_SYMBOL_UNUSED(oBrw)

RETURN (oBrw:Alias)->(DBGoTo(nRecord))

STATIC FUNCTION FltRecNo(oBrw)

   HB_SYMBOL_UNUSED(oBrw)

RETURN (oBrw:Alias)->(RecNo())

//End Implementation by Luiz
/* no used
STATIC FUNCTION FltRecNoRelative(oBrw)

   HB_SYMBOL_UNUSED(oBrw)
   IF oBrw:lFilter .AND. Empty(oBrw:RelationalExpr)
      RETURN AScan(oBrw:aRecnoFilter, (oBrw:Alias)->(RecNo()))
   ENDIF
   IF !Empty(DBFILTER()) .AND. (oBrw:Alias)->(RecNo()) > oBrw:nRecords
      RETURN oBrw:nRecords
   ENDIF

   RETURN (oBrw:Alias)->(RecNo())
*/

STATIC FUNCTION LenVal(xVal, cType, cPict)

   LOCAL nLen

   IF !ISCHARACTER(cType)
      cType := ValType(xVal)
   ENDIF

   SWITCH cType
   CASE "L"
      nLen := 1
      EXIT

   CASE "N"
   CASE "C"
   CASE "D"
      IF !Empty(cPict)
         nLen := Len(Transform(xVal, cPict))
         EXIT
      ENDIF

      SWITCH cType
      CASE "N"
         nLen := Len(Str(xVal))
         EXIT

      CASE "C"
         nLen := Len(xVal)
         EXIT

      CASE "D"
         nLen := Len(DToC(xVal))
         EXIT
      END
      EXIT

#ifdef __XHARBOUR__
   DEFAULT
#else
   OTHERWISE
#endif
      nLen := 0

   ENDSWITCH

RETURN nLen

#pragma BEGINDUMP

#include <hbapi.h>

HB_FUNC_TRANSLATE(CREATEARLIST, HWG_CREATEARLIST);

#pragma ENDDUMP
