/*
 * $Id: hcontrol.prg 1902 2012-09-20 11:51:37Z lfbasso $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HLine class
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
