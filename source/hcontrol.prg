/*
 * $Id: hcontrol.prg 1902 2012-09-20 11:51:37Z lfbasso $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HControl, HGroup, HLine classes
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#translate :hBitmap       => :m_csbitmaps\[1\]
#translate :dwWidth       => :m_csbitmaps\[2\]
#translate :dwHeight      => :m_csbitmaps\[3\]
#translate :hMask         => :m_csbitmaps\[4\]
#translate :crTransparent => :m_csbitmaps\[5\]

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

#define  CONTROL_FIRST_ID   34000
#define TRANSPARENT 1
#define BTNST_COLOR_BK_IN     1            // Background color when mouse is INside
#define BTNST_COLOR_FG_IN     2            // Text color when mouse is INside
#define BTNST_COLOR_BK_OUT    3             // Background color when mouse is OUTside
#define BTNST_COLOR_FG_OUT    4             // Text color when mouse is OUTside
#define BTNST_COLOR_BK_FOCUS  5           // Background color when the button is focused
#define BTNST_COLOR_FG_FOCUS  6            // Text color when the button is focused
#define BTNST_MAX_COLORS      6
#define WM_SYSCOLORCHANGE               0x0015
#define BS_TYPEMASK SS_TYPEMASK
#define OFS_X   10 // distance from left/right side to beginning/end of text

//- HControl

CLASS HControl INHERIT HCustomWindow

   DATA   id
   DATA   tooltip
   DATA   lInit           INIT .F.
   DATA   lnoValid        INIT .F.
   DATA   lnoWhen         INIT .F.
   DATA   nGetSkip        INIT 0
   DATA   Anchor          INIT 0
   DATA   BackStyle       INIT OPAQUE
   DATA   lNoThemes       INIT .F.
   DATA   DisablebColor
   DATA   DisableBrush
   DATA   xControlSource
   DATA   xName           HIDDEN
   ACCESS Name INLINE ::xName
   ASSIGN Name(cName) INLINE ::AddName(cName)

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bSize, bPaint, cTooltip, tcolor, bColor )
   METHOD Init()
   METHOD AddName(cName) HIDDEN
 //  METHOD SetColor(tcolor, bColor, lRepaint)
   METHOD NewId()
   METHOD Show( nShow ) INLINE ::Super:Show( nShow ), IIF( ::oParent:lGetSkipLostFocus,;
                        PostMessage(GetActiveWindow(), WM_NEXTDLGCTL, IIF( ::oParent:FindControl(, GetFocus() ) != NIL, 0, ::handle ), 1), .T. )
   METHOD Hide() INLINE ( ::oParent:lGetSkipLostFocus := .F., ::Super:Hide() )
   //METHOD Disable() INLINE EnableWindow( ::handle, .F. )
   METHOD Disable() INLINE ( IIF( SELFFOCUS(::Handle), SendMessage(GetActiveWindow(), WM_NEXTDLGCTL, 0, 0), ), EnableWindow( ::handle, .F. ) )
   METHOD Enable()      
   METHOD IsEnabled() INLINE IsWindowEnabled(::Handle)
   METHOD Enabled(lEnabled) SETGET
   METHOD SetFont( oFont )
   METHOD SetFocus( lValid )    
                         
   METHOD GetText() INLINE GetWindowText(::handle)
   METHOD SetText( c ) INLINE SetWindowText( ::Handle, c ), ::title := c, ::Refresh()
   METHOD Refresh()     VIRTUAL
   METHOD onAnchor( x, y, w, h )
   METHOD SetToolTip(ctooltip)
   METHOD ControlSource(cControlSource) SETGET
   METHOD DisableBackColor(DisableBColor) SETGET
   METHOD FontBold(lTrue) SETGET
   METHOD FontItalic(lTrue) SETGET
   METHOD FontUnderline(lTrue) SETGET

   METHOD END()

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, ;
            bInit, bSize, bPaint, cTooltip, tcolor, bColor ) CLASS HControl

   ::oParent := IIf( oWndParent == NIL, ::oDefaultParent, oWndParent )
   ::id      := IIf( nId == NIL, ::NewId(), nId )
   ::style   := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), ;
                           WS_VISIBLE + WS_CHILD )

   ::nLeft   := IIF( nLeft = Nil, 0, nLeft )
   ::nTop    := IIF( nTop = Nil, 0, nTop )
   ::nWidth  := IIF( nWidth = Nil, 0, nWidth )
   ::nHeight := IIF( nHeight = Nil, 0, nHeight )

   ::oFont   := oFont
   ::bInit   := bInit
   ::bSize   := bSize
   ::bPaint  := bPaint
   ::tooltip := cTooltip
   ::SetColor(tcolor, bColor)

   ::oParent:AddControl( Self )

   RETURN Self

METHOD NewId() CLASS HControl

   LOCAL oParent := ::oParent, i := 0, nId

   DO WHILE oParent != Nil
      nId := CONTROL_FIRST_ID + 1000 * i + Len( ::oParent:aControls )
      oParent := oParent:oParent
      i ++
   ENDDO
   IF AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
      nId --
      DO WHILE nId >= CONTROL_FIRST_ID .AND. ;
               AScan( ::oParent:aControls, { | o | o:id == nId } ) != 0
         nId --
      ENDDO
   ENDIF
   RETURN nId

METHOD AddName(cName) CLASS HControl

   IF !Empty(cName) .AND. hb_IsChar(cName) .AND. !(":" $ cName) .AND. !("[" $ cName) .AND. !("->" $ cName)
      ::xName := cName
         __objAddData(::oParent, cName)
       ::oParent: & ( cName ) := Self
   ENDIF

RETURN Nil


METHOD INIT() CLASS HControl
   LOCAL oForm := ::GetParentForm()
   
   IF !::lInit
      //IF ::tooltip != Nil
      //   AddToolTip(::oParent:handle, ::handle, ::tooltip)
      //ENDIF
      ::oparent:lSuspendMsgsHandling := .T.
      IF Len( ::aControls) = 0 .AND. ::winclass != "SysTabControl32"  .AND. !hb_IsNumeric(oForm) 
         AddToolTip(oForm:handle, ::handle, ::tooltip)
      ENDIF
      ::oparent:lSuspendMsgsHandling := .F.
      IF ::oFont != NIL .AND. !hb_IsNumeric(::oFont) .AND. ::oParent != Nil 
         SetCtrlFont( ::oParent:handle, ::id, ::oFont:handle )
      ELSEIF oForm != NIL  .AND. !hb_IsNumeric(oForm) .AND. oForm:oFont != Nil         
         SetCtrlFont( ::oParent:handle, ::id, oForm:oFont:handle )
      ELSEIF ::oParent != Nil .AND. ::oParent:oFont != NIL
         SetCtrlFont( ::handle, ::id, ::oParent:oFont:handle )
      ENDIF
      IF oForm != Nil .AND. oForm:Type != WND_DLG_RESOURCE  .AND. ( ::nLeft + ::nTop + ::nWidth + ::nHeight  != 0 )
         // fix init position in FORM reduce  flickering
         SetWindowPos( ::Handle, Nil, ::nLeft, ::nTop, ::nWidth, ::nHeight, SWP_NOACTIVATE + SWP_NOSIZE + SWP_NOZORDER + SWP_NOOWNERZORDER + SWP_NOSENDCHANGING ) //+ SWP_DRAWFRAME )
      ENDIF   

      IF hb_IsBlock(::bInit)
        ::oparent:lSuspendMsgsHandling := .T.
        Eval( ::bInit, Self )
        ::oparent:lSuspendMsgsHandling := .F.
      ENDIF
      IF ::lnoThemes      
          HWG_SETWINDOWTHEME(::handle, 0)
      ENDIF   

      ::lInit := .T.
   ENDIF
   RETURN NIL

   /* moved to HCWINDOW
METHOD SetColor(tcolor, bColor, lRepaint) CLASS HControl

   IF tcolor != NIL
      ::tcolor := tcolor
      IF bColor == NIL .AND. ::bColor == NIL
         bColor := GetSysColor(COLOR_3DFACE)
      ENDIF
   ENDIF

   IF bColor != NIL
      ::bColor := bColor
      IF ::brush != NIL
         ::brush:Release()
      ENDIF
      ::brush := HBrush():Add(bColor)
   ENDIF

   IF lRepaint != NIL .AND. lRepaint
      RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE )
   ENDIF

   RETURN NIL
   */

METHOD SetFocus( lValid ) CLASS HControl
   LOCAL lSuspend := ::oParent:lSuspendMsgsHandling  
   
   IF !IsWindowEnabled(::Handle)
       ::oParent:lSuspendMsgsHandling  := .T.
      // GetSkip(::oParent, ::handle, , 1)
       SendMessage(GetActiveWindow(), WM_NEXTDLGCTL, 0, 0)
       ::oParent:lSuspendMsgsHandling  := lSuspend
   ELSE
      ::oParent:lSuspendMsgsHandling  := !Empty(lValid)
      IF ::GetParentForm():Type < WND_DLG_RESOURCE
         SetFocus(::handle)
      ELSE
         SendMessage(GetActiveWindow(), WM_NEXTDLGCTL, ::handle, 1)
      ENDIF
      ::oParent:lSuspendMsgsHandling  := lSuspend
   ENDIF
   IF ::GetParentForm():Type < WND_DLG_RESOURCE
      ::GetParentForm():nFocus := ::Handle
   ENDIF   
   
   RETURN Nil

METHOD Enable() CLASS HControl
   Local lEnable := IsWindowEnabled(::Handle), nPos, nNext
     
   EnableWindow( ::handle, .T. )
   IF ::oParent:lGetSkipLostFocus .AND. !lEnable .AND. Hwg_BitaND(HWG_GETWINDOWSTYLE(::Handle), WS_TABSTOP) > 0
      nNext := Ascan( ::oParent:aControls, { | o | PtrtouLong( o:Handle ) = PtrtouLong( GetFocus() ) } )
      nPos  := Ascan( ::oParent:acontrols, { | o | PtrtouLong( o:Handle ) = PtrtouLong(::handle) } )
      IF nPos < nNext
         SendMessage(GetActiveWindow(), WM_NEXTDLGCTL, ::handle, 1)
      ENDIF    
   ENDIF   
   RETURN NIL

METHOD DisableBackColor(DisableBColor)

   IF DisableBColor != NIL
      ::DisableBColor := DisableBColor
      IF ::Disablebrush != NIL
         ::Disablebrush:Release()
      ENDIF
      ::Disablebrush := HBrush():Add(::DisableBColor)
      IF !::IsEnabled() .AND. IsWindowVisible(::Handle)
         InvalidateRect( ::Handle, 0 )
      ENDIF
   ENDIF
   RETURN ::DisableBColor

METHOD SetFont( oFont ) CLASS HControl
     
   IF oFont != NIL
      IF hb_IsObject(oFont)
         ::oFont := oFont:SetFontStyle()
         SetWindowFont( ::Handle, ::oFont:Handle, .T. )
      ENDIF
   ELSEIF ::oParent:oFont != NIL
      SetWindowFont( ::handle, ::oParent:oFont:handle, .T. )
   ENDIF
   RETURN ::oFont

METHOD FontBold(lTrue) CLASS HControl
   Local oFont

   IF ::oFont = NIL
      IF ::GetParentForm() != Nil .AND. ::GetParentForm():oFont != Nil
         oFont := ::GetParentForm():oFont
      ELSEIF ::oParent:oFont != NIL
         oFont := ::oParent:oFont
      ENDIF
      IF oFont = Nil .AND. lTrue = Nil
          RETURN .T.
      ENDIF
      ::oFont := IIF( oFont != Nil, HFont():Add(oFont:name, oFont:Width, , , , ,), HFont():Add("", 0, , IIF( !Empty(lTrue), FW_BOLD, FW_REGULAR ), , ,) )
   ENDIF
   IF lTrue != NIL
      ::oFont := ::oFont:SetFontStyle(lTrue)
      SendMessage(::handle, WM_SETFONT, ::oFont:handle, MAKELPARAM( 0, 1 ))
      RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT )
   ENDIF
   RETURN ::oFont:weight == FW_BOLD

METHOD FontItalic(lTrue) CLASS HControl
   Local oFont

   IF ::oFont = NIL
      IF ::GetParentForm() != Nil .AND. ::GetParentForm():oFont != Nil
         oFont := ::GetParentForm():oFont
      ELSEIF ::oParent:oFont != NIL
         oFont := ::oParent:oFont
      ENDIF
      IF oFont = Nil .AND. lTrue = Nil
          RETURN .F.
      ENDIF
      ::oFont := IIF( oFont != Nil, HFont():Add(oFont:name, oFont:width, , , , IIF( lTrue, 1, 0 )), HFont():Add("", 0, , , , IIF( lTrue, 1, 0 )) )
   ENDIF
   IF lTrue != NIL
      ::oFont := ::oFont:SetFontStyle(, , lTrue)
      SendMessage(::handle, WM_SETFONT, ::oFont:handle, MAKELPARAM( 0, 1 ))
      RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT )
   ENDIF
   RETURN ::oFont:Italic = 1

METHOD FontUnderline(lTrue) CLASS HControl
   Local oFont

   IF ::oFont = NIL
      IF ::GetParentForm() != Nil .AND. ::GetParentForm():oFont != Nil
         oFont := ::GetParentForm():oFont
      ELSEIF ::oParent:oFont != NIL
         oFont := ::oParent:oFont
      ENDIF
      IF oFont = Nil .AND. lTrue = Nil
          RETURN .F.
      ENDIF
      ::oFont := IIF( oFont != Nil, HFont():Add(oFont:name, oFont:width, , , , , IIF( lTrue, 1, 0 )), HFont():Add("", 0, , , , , IIF( lTrue, 1, 0)) )
   ENDIF
   IF lTrue != NIL
      ::oFont := ::oFont:SetFontStyle(, , , lTrue)
      SendMessage(::handle, WM_SETFONT, ::oFont:handle, MAKELPARAM( 0, 1 ))
      RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_FRAME + RDW_INTERNALPAINT )
   ENDIF
   RETURN ::oFont:Underline = 1

METHOD SetToolTip ( cToolTip ) CLASS HControl

   IF hb_IsChar(cToolTip) .AND. cToolTip != ::ToolTip
      SETTOOLTIPTITLE(::GetparentForm():handle, ::handle, ctooltip)
      ::Tooltip := cToolTip
   ENDIF
   RETURN ::tooltip

METHOD Enabled(lEnabled) CLASS HControl

  IF lEnabled != Nil
     IF lEnabled
        ::enable()
     ELSE
        ::disable()
     ENDIF
  ENDIF
  RETURN ::isEnabled()

METHOD ControlSource(cControlSource) CLASS HControl
  Local temp

  IF cControlSource != Nil .AND. !Empty(cControlSource) .AND. __objHasData(Self, "BSETGETFIELD")
     ::xControlSource := cControlSource
     temp := SUBSTR( cControlSource, AT( "->", cControlSource ) + 2 )
     ::bSetGetField := IIF( "->" $ cControlSource, FieldWBlock( temp, SELECT( SUBSTR( cControlSource, 1, AT( "->", cControlSource ) - 1 ))),FieldBlock( cControlSource ) )
  ENDIF
  RETURN ::xControlSource

METHOD END() CLASS HControl

   ::Super:END()

   IF ::tooltip != NIL
      DelToolTip(::oParent:handle, ::handle)
      ::tooltip := NIL

   ENDIF
   RETURN NIL

METHOD onAnchor( x, y, w, h ) CLASS HControl
   LOCAL nAnchor, nXincRelative, nYincRelative, nXincAbsolute, nYincAbsolute
   LOCAL x1, y1, w1, h1, x9, y9, w9, h9
   LOCAL nCxv := IIF( HWG_BITAND(::style, WS_VSCROLL) != 0, GetSystemMetrics( SM_CXVSCROLL ) + 1, 3 )
   LOCAL nCyh := IIF( HWG_BITAND(::style, WS_HSCROLL) != 0, GetSystemMetrics( SM_CYHSCROLL ) + 1, 3 )


   nAnchor := ::anchor
   x9 := ::nLeft
   y9 := ::nTop
   w9 := ::nWidth  //- IIF( ::winclass = "EDIT" .AND. __ObjHasMsg( Self,"hwndUpDown" ), GetClientRect( ::hwndUpDown)[3], 0 )
   h9 := ::nHeight

   x1 := ::nLeft
   y1 := ::nTop
   w1 := ::nWidth  //- IIF( ::winclass = "EDIT" .AND. __ObjHasMsg( Self,"hwndUpDown" ), GetClientRect( ::hwndUpDown)[3], 0 )
   h1 := ::nHeight
  //- calculo relativo
   IF x > 0
      nXincRelative :=  w / x
   ENDIF
   IF y > 0
      nYincRelative :=  h / y
   ENDIF
    //- calculo ABSOLUTE
   nXincAbsolute := ( w - x )
   nYincAbsolute := ( h - y )

   IF nAnchor >= ANCHOR_VERTFIX
    //- vertical fixed center
      nAnchor := nAnchor - ANCHOR_VERTFIX
      y1 := y9 + Round(( h - y ) * ( ( y9 + h9 / 2 ) / y ), 2)
   ENDIF
   IF nAnchor >= ANCHOR_HORFIX
    //- horizontal fixed center                                                    
      nAnchor := nAnchor - ANCHOR_HORFIX
      x1 := x9 + Round(( w - x ) * ( ( x9 + w9 / 2 ) / x ), 2)
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTREL
      && relative - RIGHT RELATIVE
      nAnchor := nAnchor - ANCHOR_RIGHTREL
      x1 := w - Round(( x - x9 - w9 ) * nXincRelative, 2) - w9
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMREL
      && relative - BOTTOM RELATIVE
      nAnchor := nAnchor - ANCHOR_BOTTOMREL
      y1 := h - Round(( y - y9 - h9) * nYincRelative, 2 ) - h9
   ENDIF
   IF nAnchor >= ANCHOR_LEFTREL
      && relative - LEFT RELATIVE
      nAnchor := nAnchor - ANCHOR_LEFTREL
      IF x1 != x9
         w1 := x1 - ( Round(x9 * nXincRelative, 2) ) + w9
      ENDIF
      x1 := Round(x9 * nXincRelative, 2)
   ENDIF
   IF nAnchor >= ANCHOR_TOPREL
      && relative  - TOP RELATIVE
      nAnchor := nAnchor - ANCHOR_TOPREL
      IF y1 != y9
         h1 := y1 - ( Round(y9 * nYincRelative, 2) ) + h9
      ENDIF
      y1 := Round(y9 * nYincRelative, 2)
   ENDIF
   IF nAnchor >= ANCHOR_RIGHTABS
      && Absolute - RIGHT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_RIGHTABS
      IF HWG_BITAND(::Anchor, ANCHOR_LEFTREL) != 0
         w1 := INT( nxIncAbsolute ) - ( x1 - x9 ) + w9 
      ELSE
         IF x1 != x9
            w1 := x1 - ( x9 +  INT( nXincAbsolute ) ) + w9
         ENDIF
         x1 := x9 +  INT( nXincAbsolute )
      ENDIF   
   ENDIF
   IF nAnchor >= ANCHOR_BOTTOMABS
      && Absolute - BOTTOM ABSOLUTE
      nAnchor := nAnchor - ANCHOR_BOTTOMABS
      IF HWG_BITAND(::Anchor, ANCHOR_TOPREL) != 0
         h1 := INT( nyIncAbsolute ) - ( y1 - y9 ) + h9 
      ELSE
         IF y1 != y9
            h1 := y1 - ( y9 +  Int( nYincAbsolute ) ) + h9
         ENDIF
         y1 := y9 +  Int( nYincAbsolute )
      ENDIF   
   ENDIF
   IF nAnchor >= ANCHOR_LEFTABS
      && Absolute - LEFT ABSOLUTE
      nAnchor := nAnchor - ANCHOR_LEFTABS
      IF x1 != x9
         w1 := x1 - x9 + w9
      ENDIF
      x1 := x9
   ENDIF
   IF nAnchor >= ANCHOR_TOPABS
      && Absolute - TOP ABSOLUTE
      //nAnchor := nAnchor - 1
      IF y1 != y9
         h1 := y1 - y9 + h9
      ENDIF
      y1 := y9
   ENDIF
   // REDRAW AND INVALIDATE SCREEN
   IF ( x1 != X9 .OR. y1 != y9 .OR. w1 != w9 .OR. h1 != h9 )
      IF isWindowVisible(::handle)
         IF ( x1 != x9 .or. y1 != y9 ) .AND. x9 < ::oParent:nWidth
                   InvalidateRect( ::oParent:handle, 1, MAX( x9 - 1, 0 ), MAX( y9 - 1, 0 ), ;
                                                     x9 + w9 + nCxv, y9 + h9 + nCyh )
         ELSE
             IF w1 < w9
                InvalidateRect( ::oParent:handle, 1, x1 + w1 - nCxv - 1, MAX( y1 - 2, 0 ), ;
                                                    x1 + w9 + 2, y9 + h9 + nCxv + 1)

             ENDIF
             IF h1 < h9
                InvalidateRect( ::oParent:handle, 1, MAX( x1 - 5, 0 ), y1 + h1 - nCyh - 1, ;
                                                        x1 + w9 + 2, y1 + h9 + nCYh )
             ENDIF
         ENDIF
*         ::Move(x1, y1, w1, h1, HWG_BITAND(::Style, WS_CLIPSIBLINGS + WS_CLIPCHILDREN) = 0)

         IF ( ( x1 != x9 .OR. y1 != y9 ) .AND. ( hb_IsBlock(::bPaint) .OR. ;
                      x9 + w9 > ::oParent:nWidth ) ) .OR. ( ::backstyle = TRANSPARENT .AND. ;
                    ( ::Title != Nil .AND. !Empty(::Title) ) ) .OR. __ObjHasMsg( Self,"oImage" )
             IF __ObjHasMsg( Self, "oImage" ) .OR.  ::backstyle = TRANSPARENT //.OR. w9 != w1
                InvalidateRect( ::oParent:handle, 1, MAX( x1 - 1, 0 ), MAX( y1 - 1, 0 ), x1 + w1 + 1, y1 + h1 + 1 )
             ELSE
                RedrawWindow( ::handle, RDW_NOERASE + RDW_INVALIDATE + RDW_INTERNALPAINT )
             ENDIF
         ELSE
             IF LEN( ::aControls ) = 0 .AND. ::Title != Nil
               InvalidateRect( ::handle, 0 )
             ENDIF
             IF w1 > w9
                InvalidateRect( ::oParent:handle, 1, MAX( x1 + w9 - nCxv - 1, 0 ), ;
                                                     MAX( y1, 0 ), x1 + w1 + nCxv, y1 + h1 + 2  )
             ENDIF
             IF h1 > h9
                InvalidateRect( ::oParent:handle, 1, MAX( x1, 0 ), ;
                               MAX( y1 + h9 - nCyh - 1, 1 ), x1 + w1 + 2, y1 + h1 + nCyh )
             ENDIF
         ENDIF
         // redefine new position e new size
         ::Move(x1, y1, w1, h1, HWG_BITAND(::Style, WS_CLIPSIBLINGS + WS_CLIPCHILDREN) = 0)
         
         IF ( ::winClass == "ToolbarWindow32" .OR. ::winClass == "msctls_statusbar32" )
            ::Resize(nXincRelative, w1 != w9, h1 != h9)
         ENDIF
      ELSE
         ::Move(x1, y1, w1, h1, 0)
         IF ( ::winClass == "ToolbarWindow32" .OR. ::winClass == "msctls_statusbar32" )
            ::Resize(nXincRelative, w1 != w9, h1 != h9)
         ENDIF
      ENDIF
   ENDIF
   RETURN Nil

//- HGroup

CLASS HGroup INHERIT HControl

CLASS VAR winclass   INIT "BUTTON"

   DATA oRGroup
   DATA oBrush
   DATA lTransparent  HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp, oRGroup )
   METHOD Activate()
   METHOD Init()
   METHOD Paint( lpDis )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, cCaption, ;
            oFont, bInit, bSize, bPaint, tcolor, bColor, lTransp, oRGroup ) CLASS HGroup

   nStyle := Hwg_BitOr( IIf( nStyle == NIL, 0, nStyle ), BS_GROUPBOX )
   
   ::title   := cCaption
   ::oRGroup := oRGroup

   ::Super:New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
              oFont, bInit, bSize, bPaint,, tcolor, bColor )

   ::oBrush := IIF( bColor != Nil, ::brush,Nil )
   ::lTransparent := IIF( lTransp != NIL, lTransp, .F. )
   ::backStyle := IIF( ( lTransp != NIL .AND. lTransp ) .OR. ::bColor != Nil, TRANSPARENT, OPAQUE )

   ::Activate()
   //::setcolor(tcolor, bcolor)

   RETURN Self

METHOD Activate() CLASS HGroup
   IF !Empty(::oParent:handle)
      ::handle := CreateButton( ::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::title )
      ::Init()
   ENDIF
   RETURN NIL

METHOD Init() CLASS HGroup
   LOCAL nbs

   IF !::lInit
      ::Super:Init()

      //-IF ::backStyle = TRANSPARENT .OR. ::bColor != Nil
      IF ::oBrush != Nil .OR. ::backStyle = TRANSPARENT 
         nbs := HWG_GETWINDOWSTYLE(::handle)
         nbs := modstyle(nbs, BS_TYPEMASK, BS_OWNERDRAW + WS_DISABLED)
         HWG_SETWINDOWSTYLE ( ::handle, nbs )
         ::bPaint   := { | o, p | o:paint( p ) }
      ENDIF
      IF ::oRGroup != Nil
         ::oRGroup:Handle := ::handle
         ::oRGroup:id := ::id
         ::oFont := ::oRGroup:oFont
         ::oRGroup:lInit := .F.
         ::oRGroup:Init()
      ELSE
         IF ::oBrush != Nil
            /*
            nbs :=  AScan( ::oparent:acontrols, { | o | o:handle == ::handle } )
            FOR i = LEN( ::oparent:acontrols ) TO 1 STEP - 1    
               IF nbs != i .AND.;
                   PtInRect( { ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight }, { ::oparent:acontrols[i]:nLeft, ::oparent:acontrols[i]:nTop } ) //.AND. NOUTOBJS = 0
                   SetWindowPos( ::oparent:acontrols[i]:handle, ::Handle, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE + SWP_FRAMECHANGED )
               ENDIF
            NEXT
            */
            SetWindowPos( ::Handle, Nil, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE )
         ELSE
            SetWindowPos( ::Handle, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOSIZE + SWP_NOMOVE + SWP_NOACTIVATE + SWP_NOSENDCHANGING )
         ENDIF
      ENDIF
   ENDIF
   RETURN NIL


METHOD PAINT( lpdis ) CLASS HGroup
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL DC := drawInfo[3]
   LOCAL ppnOldPen, pnFrmDark, pnFrmLight, iUpDist
   LOCAL szText, aSize, dwStyle
   LOCAL rc  := copyrect( { drawInfo[4], drawInfo[5], drawInfo[6] - 1, drawInfo[7] - 1 } )
   LOCAL rcText 

    // determine text length
    szText :=  ::Title
   aSize :=  TxtRect( IIF( Empty(szText), "A", szText ), Self )
   // distance from window top to group rect
    iUpDist := ( aSize[2] / 2 )
   dwStyle := ::Style //HWG_GETWINDOWSTYLE(::handle) //GetStyle();
   rcText := { 0, rc[2] + iUpDist, 0, rc[2] + iUpDist  }
   IF Empty(szText)
    ELSEIF hb_BitAnd(dwStyle, BS_CENTER) == BS_RIGHT // right aligned
      rcText[3] := rc[3] + 2 - OFS_X  
      rcText[1] := rcText[3] - aSize[1]
    ELSEIF hb_BitAnd(dwStyle, BS_CENTER) == BS_CENTER  // text centered
      rcText[1] := ( rc[3] - rc[1]  - aSize[1]  ) / 2
      rcText[3] := rcText[1] + aSize[1] 
    ELSE //((!(dwStyle & BS_CENTER)) || ((dwStyle & BS_CENTER) == BS_LEFT))// left aligned   / default
      rcText[1] := rc[1] + OFS_X
      rcText[3] := rcText[1] + aSize[1] 
    ENDIF
   SetBkMode(dc, TRANSPARENT)       

    IF Hwg_BitAND(dwStyle, BS_FLAT) != 0  // "flat" frame
        //pnFrmDark  := CreatePen( PS_SOLID, 1, RGB(0, 0, 0) ) )
        pnFrmDark  := HPen():Add(PS_SOLID, 1, RGB(64, 64, 64))
        pnFrmLight := HPen():Add(PS_SOLID, 1, GetSysColor(COLOR_3DHILIGHT))

        ppnOldPen := SelectObject(dc, pnFrmDark:Handle)
      MoveTo( dc, rcText[1] - 2, rcText[2]  )
      LineTo( dc, rc[1], rcText[2] )
      LineTo( dc, rc[1], rc[4] )
      LineTo( dc, rc[3], rc[4] )
      LineTo( dc, rc[3], rcText[4] )
      LineTo( dc, rcText[3], rcText[4] )

        SelectObject(dc, pnFrmLight:handle)
      MoveTo( dc, rcText[1] - 2, rcText[2] + 1 )
      LineTo( dc, rc[1] + 1, rcText[2] + 1)
        LineTo( dc, rc[1] + 1, rc[4] - 1 )
        LineTo( dc, rc[3] - 1, rc[4] - 1 )
        LineTo( dc, rc[3] - 1, rcText[4] + 1 )
        LineTo( dc, rcText[3], rcText[4] + 1 )
    ELSE // 3D frame

      pnFrmDark  := HPen():Add(PS_SOLID, 1, GetSysColor(COLOR_3DSHADOW))
      pnFrmLight := HPen():Add(PS_SOLID, 1, GetSysColor(COLOR_3DHILIGHT))

      ppnOldPen := SelectObject(dc, pnFrmDark:handle)
      MoveTo( dc, rcText[1] - 2, rcText[2] )
      LineTo( dc, rc[1], rcText[2] )
      LineTo( dc, rc[1], rc[4] - 1 )
      LineTo( dc, rc[3] - 1, rc[4] - 1 )
      LineTo( dc, rc[3] - 1, rcText[4] )
      LineTo( dc, rcText[3], rcText[4] )

       SelectObject(dc, pnFrmLight:handle)
      MoveTo( dc, rcText[1] - 2, rcText[2] + 1 )
      LineTo( dc, rc[1] + 1, rcText[2] + 1 )
      LineTo( dc, rc[1] + 1, rc[4] - 1 )
      MoveTo( dc, rc[1], rc[4] )
      LineTo( dc, rc[3], rc[4] )
      LineTo( dc, rc[3], rcText[4] - 1)
      MoveTo( dc, rc[3] - 2, rcText[4] + 1 )
      LineTo( dc, rcText[3], rcText[4] + 1 )   
   ENDIF

   // draw text (if any)
   IF !Empty(szText) && !(dwExStyle & (BS_ICON|BS_BITMAP)))
     SetBkMode(dc, TRANSPARENT)       
     IF ::oBrush != Nil
        FillRect( DC, rc[1] + 2, rc[2] + iUpDist + 2, rc[3] - 2, rc[4] - 2, ::brush:handle )
        IF !::lTransparent
           FillRect( DC, rcText[1] - 2, rc[2] + 1, rcText[3] + 1, rc[2] + iUpDist + 2, ::brush:handle )
        ENDIF
     ENDIF
      DrawText( dc, szText, rcText, DT_VCENTER + DT_LEFT + DT_SINGLELINE + DT_NOCLIP )
   ENDIF
     // cleanup
     DeleteObject(pnFrmLight)
     DeleteObject(pnFrmDark)
    SelectObject(dc, ppnOldPen)
   RETURN Nil



// HLine

CLASS HLine INHERIT HControl

CLASS VAR winclass   INIT "STATIC"

   DATA lVert
   DATA LineSlant
   DATA nBorder
   DATA oPenLight, oPenGray

   METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize, bInit, tcolor, nHeight, cSlant, nBorder )
   METHOD Activate()
   METHOD Paint( lpDis )

ENDCLASS


METHOD New( oWndParent, nId, lVert, nLeft, nTop, nLength, bSize, bInit, tcolor, nHeight, cSlant, nBorder ) CLASS HLine

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop,,,,bInit, ;
              bSize, { | o, lp | o:Paint( lp ) }, , tcolor )

   ::title := ""
   ::lVert := IIf( lVert == NIL, .F., lVert )
   ::LineSlant := IIF( Empty(cSlant) .OR. !cSlant $ "/\", "", cSlant )
   ::nBorder := IIF( Empty(nBorder), 1, nBorder )

   IF Empty(::LineSlant)
      IF ::lVert
         ::nWidth  := ::nBorder + 1 //10
         ::nHeight := IIf( nLength == NIL, 20, nLength )
      ELSE
         ::nWidth  := IIf( nLength == NIL, 20, nLength )
         ::nHeight := ::nBorder + 1 //10
      ENDIF
      ::oPenLight := HPen():Add(BS_SOLID, 1, GetSysColor(COLOR_3DHILIGHT))
      ::oPenGray  := HPen():Add(BS_SOLID, 1, GetSysColor(COLOR_3DSHADOW))
   ELSE
      ::nWidth  := nLength
      ::nHeight := nHeight
      ::oPenLight := HPen():Add(BS_SOLID, ::nBorder, tColor)
   ENDIF

   ::Activate()

   RETURN Self

METHOD Activate() CLASS HLine
   IF !Empty(::oParent:handle)
      ::handle := CreateStatic(::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight)
      ::Init()
   ENDIF
   RETURN NIL

METHOD Paint( lpdis ) CLASS HLine
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL hDC := drawInfo[3]
   LOCAL x1  := drawInfo[4], y1 := drawInfo[5]
   LOCAL x2  := drawInfo[6], y2 := drawInfo[7]

   SelectObject(hDC, ::oPenLight:handle)

   IF Empty(::LineSlant)
      IF ::lVert
         // DrawEdge(hDC,x1,y1,x1+2,y2,EDGE_SUNKEN,BF_RIGHT)
         DrawLine(hDC, x1 + 1, y1, x1 + 1, y2)
      ELSE
         // DrawEdge(hDC,x1,y1,x2,y1+2,EDGE_SUNKEN,BF_RIGHT)
         DrawLine(hDC, x1, y1 + 1, x2, y1 + 1)
      ENDIF
      SelectObject(hDC, ::oPenGray:handle)
      IF ::lVert
         DrawLine(hDC, x1, y1, x1, y2)
      ELSE
         DrawLine(hDC, x1, y1, x2, y1)
      ENDIF
   ELSE
      IF ( x2 - x1 ) <= ::nBorder //.OR. ::nWidth <= ::nBorder
         DrawLine(hDC, x1, y1, x1, y2)
      ELSEIF ( y2 - y1 ) <= ::nBorder //.OR. ::nHeight <= ::nBorder
         DrawLine(hDC, x1, y1, x2, y1)
      ELSEIF ::LineSlant == "/"
          DrawLine(hDC, x1, y1 + y2, x1 + x2, y1)
      ELSEIF ::LineSlant == "\"
          DrawLine(hDC, x1, y1, x1 + x2, y1 + y2)
      ENDIF
    ENDIF

   RETURN NIL



   init PROCEDURE starttheme()
   INITTHEMELIB()

   EXIT PROCEDURE endtheme()
   ENDTHEMELIB()
