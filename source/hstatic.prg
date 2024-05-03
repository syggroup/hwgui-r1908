/*
 * $Id: hcontrol.prg 1902 2012-09-20 11:51:37Z lfbasso $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HStatic class
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

CLASS HStatic INHERIT HControl

CLASS VAR winclass   INIT "STATIC"

   DATA AutoSize    INIT .F.
   //DATA lTransparent  INIT .F. HIDDEN
   DATA nStyleHS
   DATA bClick, bDblClick
   DATA hBrushDefault  HIDDEN

   METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
               cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
               bColor, lTransp, bClick, bDblClick, bOther )
   METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, ;
                    bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther)
   METHOD Activate()
   // METHOD SetValue(value) INLINE SetDlgItemText( ::oParent:handle, ::id, ;
   //
   METHOD SetText( value ) INLINE ::SetValue(value)
   METHOD SetValue(cValue)
   METHOD Auto_Size(cValue)  HIDDEN
   METHOD Init()
   METHOD PAINT( lpDis )
   METHOD onClick()
   METHOD onDblClick()
   METHOD OnEvent( msg, wParam, lParam )

ENDCLASS

METHOD New( oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, ;
            cCaption, oFont, bInit, bSize, bPaint, cTooltip, tcolor, ;
            bColor, lTransp, bClick, bDblClick, bOther ) CLASS HStatic

   Local nStyles
   // Enabling style for tooltips
   //IF hb_IsChar(cTooltip)
   //   IF nStyle == NIL
   //      nStyle := SS_NOTIFY
   //   ELSE
   nStyles := IIF(Hwg_BitAND(nStyle, WS_BORDER) != 0, WS_BORDER, 0 )
   nStyles += IIF(Hwg_BitAND(nStyle, WS_DLGFRAME) != 0, WS_DLGFRAME, 0 )
   nStyles += IIF(Hwg_BitAND(nStyle, WS_DISABLED) != 0, WS_DISABLED, 0 )
   nStyle  := Hwg_BitOr( nStyle, SS_NOTIFY ) - nStyles
   //    ENDIF
   // ENDIF
   //
   ::nStyleHS := IIf( nStyle == Nil, 0, nStyle )
   ::BackStyle := OPAQUE
   IF ( lTransp != NIL .AND. lTransp ) //.OR. ::lOwnerDraw
      ::BackStyle := TRANSPARENT
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      nStyle := SS_OWNERDRAW + Hwg_Bitand(nStyle, SS_NOTIFY)
   ELSEIF nStyle - SS_NOTIFY > 32 .OR. ::nStyleHS - SS_NOTIFY = 2
      bPaint := { | o, p | o:paint( p ) }
      nStyle := SS_OWNERDRAW + Hwg_Bitand(nStyle, SS_NOTIFY)
   ENDIF
   ::hBrushDefault := HBrush():Add(GetSysColor(COLOR_BTNFACE))

   ::Super:New( oWndParent, nId, nStyle + nStyles, nLeft, nTop, nWidth, nHeight, oFont, ;
              bInit, bSize, bPaint, cTooltip, tcolor, bColor )

   IF ::oParent:oParent != Nil
   //   bPaint := { | o, p | o:paint( p ) }
   ENDIF
   ::bOther := bOther
   ::title := cCaption

   ::Activate()

   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent( STN_CLICKED, Self, { || ::onClick() } )
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, Self, { || ::onDblClick() } )

   RETURN Self

METHOD Redefine(oWndParent, nId, cCaption, oFont, bInit, ;
                 bSize, bPaint, cTooltip, tcolor, bColor, lTransp, bClick, bDblClick, bOther) CLASS HStatic

   IF ( lTransp != NIL .AND. lTransp )  //.OR. ::lOwnerDraw
      ::extStyle += WS_EX_TRANSPARENT
      bPaint := { | o, p | o:paint( p ) }
      ::BackStyle := TRANSPARENT
   ENDIF

   ::Super:New( oWndParent, nId, 0, 0, 0, 0, 0, oFont, bInit, ;
              bSize, bPaint, cTooltip, tcolor, bColor )

   ::title := cCaption
   ::style := ::nLeft := ::nTop := ::nWidth := ::nHeight := 0
   // Enabling style for tooltips
   //IF hb_IsChar(cTooltip)
   ::Style := SS_NOTIFY
   //ENDIF
   ::bOther := bOther
   ::bClick := bClick
   IF ::id > 2
      ::oParent:AddEvent( STN_CLICKED, Self, { || ::onClick() } )
   ENDIF
   ::bDblClick := bDblClick
   ::oParent:AddEvent( STN_DBLCLK, Self, { || ::onDblClick() } )

   RETURN Self

METHOD Activate() CLASS HStatic
   IF !Empty(::oParent:handle)
      ::handle := CreateStatic(::oParent:handle, ::id, ::style, ;
                                ::nLeft, ::nTop, ::nWidth, ::nHeight, ;
                                ::extStyle)
      ::Init()
      //::Style := ::nStyleHS
   ENDIF
   RETURN NIL

METHOD Init() CLASS HStatic
   IF !::lInit
      ::Super:init()
      IF ::nHolder != 1
         ::nHolder := 1
         SetWindowObject(::handle, Self)
         Hwg_InitStaticProc(::handle)
      ENDIF
      IF ::classname == "HSTATIC"
         ::Auto_Size(::Title)
      ENDIF
      IF ::title != NIL
         SetWindowText( ::handle, ::title )
      ENDIF
   ENDIF
   RETURN  NIL

METHOD OnEvent( msg, wParam, lParam ) CLASS  HStatic
   LOCAL nEval, pos

   IF hb_IsBlock(::bOther)
      IF ( nEval := Eval( ::bOther, Self, msg, wParam, lParam ) ) != - 1 .AND. nEval != Nil
         RETURN 0
      ENDIF
   ENDIF
   IF msg == WM_ERASEBKGND
      RETURN 0
   ELSEIF msg = WM_KEYUP
      IF wParam = VK_DOWN
         getskip(::oparent, ::handle, , 1)
      ELSEIF wParam = VK_UP
         getskip(::oparent, ::handle, , -1)
      ELSEIF wParam = VK_TAB
         GetSkip(::oParent, ::handle, , iif( IsCtrlShift(.F., .T.), -1, 1))
      ENDIF
      RETURN 0
   ELSEIF msg == WM_SYSKEYUP
      IF ( pos := At( "&", ::title ) ) > 0 .and. wParam == Asc(Upper(SubStr(::title, ++pos, 1)))
         getskip(::oparent, ::handle, , 1)
         RETURN  0
      ENDIF

   ELSEIF msg = WM_GETDLGCODE
      RETURN DLGC_WANTARROWS + DLGC_WANTTAB // +DLGC_STATIC   //DLGC_WANTALLKEYS //DLGC_WANTARROWS  + DLGC_WANTCHARS
   ENDIF

   RETURN - 1


METHOD SetValue(cValue) CLASS HStatic

    ::Auto_Size(cValue)
    IF ::Title != cValue
       IF ::backstyle = TRANSPARENT .AND. ::Title != cValue .AND. isWindowVisible(::handle)
          RedrawWindow( ::oParent:Handle, RDW_NOERASE + RDW_INVALIDATE + RDW_ERASENOW, ::nLeft, ::nTop, ::nWidth, ::nHeight )
          InvalidateRect( ::oParent:Handle, 1, ::nLeft, ::nTop, ::nLeft + ::nWidth, ::nTop + ::nHeight  )
       ENDIF
       SetDlgItemText( ::oParent:handle, ::id, cValue )
   ELSEIF ::backstyle != TRANSPARENT
      SetDlgItemText( ::oParent:handle, ::id, cValue )
   ENDIF
   ::Title := cValue
   RETURN Nil

METHOD Paint( lpDis ) CLASS HStatic
   LOCAL drawInfo := GetDrawItemInfo( lpDis )
   LOCAL client_rect, szText
   LOCAL dwtext, nstyle, brBackground
   LOCAL dc := drawInfo[3]

   client_rect    := CopyRect( { drawInfo[4], drawInfo[5], drawInfo[6], drawInfo[7] } )
   //client_rect := GetClientRect(::handle)
   szText      := GetWindowText(::handle)

   // Map "Static Styles" to "Text Styles"
   nstyle := ::nStyleHS  // ::style
   IF nStyle - SS_NOTIFY < DT_SINGLELINE
      SetAStyle(@nstyle, @dwtext)
   ELSE
       dwtext := nStyle - DT_NOCLIP
   ENDIF

   // Set transparent background
   SetBkMode(dc, ::backstyle)
   IF ::BackStyle = OPAQUE
      brBackground := IIF( !Empty(::brush), ::brush, ::hBrushDefault )
      FillRect( dc, client_rect[1], client_rect[2], client_rect[3], client_rect[4], brBackground:handle )
   ENDIF

   IF ::tcolor != NIL .AND. ::isEnabled()
      SetTextColor(dc, ::tcolor)
   ELSEIF !::isEnabled()
      SetTextColor(dc, 16777215) //GetSysColor(COLOR_WINDOW) )
      DrawText( dc, szText, { client_rect[1] + 1, client_rect[2] + 1, client_rect[3] + 1, client_rect[4] + 1 }, dwtext )
      SetBkMode(dc, TRANSPARENT)
      SetTextColor(dc, 10526880) //GetSysColor(COLOR_GRAYTEXT) )
   ENDIF
   // Draw the text
   DrawText( dc, szText, client_rect, dwtext )

   RETURN NIL

METHOD onClick() CLASS HStatic
   IF hb_IsBlock(::bClick)
      //::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN Nil

METHOD onDblClick() CLASS HStatic
   IF hb_IsBlock(::bDblClick)
      //::oParent:lSuspendMsgsHandling := .T.
      Eval( ::bDblClick, Self, ::id )
      ::oParent:lSuspendMsgsHandling := .F.
   ENDIF
   RETURN Nil

METHOD Auto_Size(cValue) CLASS HStatic
   LOCAL  ASize, nLeft, nAlign

   IF ::autosize  //.OR. ::lOwnerDraw
      nAlign := ::nStyleHS - SS_NOTIFY
      ASize :=  TxtRect( cValue, Self )
      // ajust VCENTER
      // ::nTop := ::nTop + Int( ( ::nHeight - ASize[2] + 2 ) / 2 )
      IF nAlign == SS_RIGHT
         nLeft := ::nLeft + ( ::nWidth - ASize[1] - 2 )
      ELSEIF nAlign == SS_CENTER
         nLeft := ::nLeft + Int( ( ::nWidth - ASize[1] - 2 ) / 2 )
      ELSEIF nAlign == SS_LEFT
         nLeft := ::nLeft
      ENDIF
      ::nWidth := ASize[1] + 2
      ::nHeight := ASize[2]
      ::nLeft := nLeft
      ::move(::nLeft, ::nTop)
   ENDIF
   RETURN Nil
