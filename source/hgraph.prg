/*
 * $Id: hgraph.prg 1615 2011-02-18 13:53:35Z mlacecilia $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HGraph class
 *
 * Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

CLASS HGraph INHERIT HControl

CLASS VAR winclass   INIT "STATIC"
   DATA aValues
   DATA nGraphs INIT 1
   DATA nType
   DATA lGrid   INIT .F.
   DATA scaleX, scaleY
   DATA ymaxSet
   DATA tbrush
   DATA colorCoor INIT 16777215
   DATA oPen, oPenCoor
   DATA xmax, ymax, xmin, ymin PROTECTED

   METHOD New( oWndParent, nId, aValues, nLeft, nTop, nWidth, nHeight, oFont, ;
               bSize, ctooltip, tcolor, bcolor )
   METHOD Activate()
   METHOD Redefine(oWndParent, nId, aValues, oFont, ;
                    bSize, ctooltip, tcolor, bcolor)
   METHOD Init()
   METHOD CalcMinMax()
   METHOD Paint( lpDis )
   METHOD Rebuild(aValues, nType)

ENDCLASS

METHOD New( oWndParent, nId, aValues, nLeft, nTop, nWidth, nHeight, oFont, ;
            bSize, ctooltip, tcolor, bcolor ) CLASS HGraph

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, nLeft, nTop, nWidth, nHeight, oFont,, ;
              bSize, { | o, lpdis | o:Paint( lpdis ) }, ctooltip, ;
              IIf( tcolor == Nil, Vcolor("FFFFFF"), tcolor ), IIf( bcolor == Nil, 0, bcolor ) )

   ::aValues := aValues
   ::nType   := 1
   ::nGraphs := 1

   ::Activate()

   RETURN Self

METHOD Redefine(oWndParent, nId, aValues, oFont, ;
                 bSize, ctooltip, tcolor, bcolor) CLASS HGraph

   ::Super:New( oWndParent, nId, SS_OWNERDRAW, 0, 0, 0, 0, oFont,, ;
              bSize, { | o, lpdis | o:Paint( lpdis ) }, ctooltip, ;
              IIf( tcolor == Nil, Vcolor("FFFFFF"), tcolor ), IIf( bcolor == Nil, 0, bcolor ) )

   ::aValues := aValues

   RETURN Self

METHOD Activate() CLASS HGraph
   IF !Empty( ::oParent:handle )
      ::handle := CreateStatic(::oParent:handle, ::id, ;
                                ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight)
      ::Init()
   ENDIF
   RETURN Nil

METHOD Init() CLASS HGraph
   IF !::lInit
      ::Super:Init()
      ::CalcMinMax()
   ENDIF
   RETURN Nil

METHOD CalcMinMax() CLASS HGraph
   LOCAL i, j, nLen
   ::xmax := ::xmin := ::ymax := ::ymin := 0
   IF ::ymaxSet != Nil .AND. ::ymaxSet != 0
      ::ymax := ::ymaxSet
   ENDIF
   FOR i := 1 TO ::nGraphs
      nLen := Len( ::aValues[i] )
      IF ::nType == 1
         FOR j := 1 TO nLen
            ::xmax := Max( ::xmax, ::aValues[ i, j, 1 ] )
            ::xmin := Min( ::xmin, ::aValues[ i, j, 1 ] )
            ::ymax := Max( ::ymax, ::aValues[ i, j, 2 ] )
            ::ymin := Min( ::ymin, ::aValues[ i, j, 2 ] )
         NEXT
      ELSEIF ::nType == 2
         FOR j := 1 TO nLen
            ::ymax := Max( ::ymax, ::aValues[ i, j, 2 ]   )
            ::ymin := Min( ::ymin, ::aValues[ i, j, 2 ]   )
         NEXT
         ::xmax := nLen
      ELSEIF ::nType == 3
         FOR j := 1 TO nLen
            ::ymax += ::aValues[ i, j, 2 ]
         NEXT
      ENDIF
   NEXT

   RETURN Nil

METHOD Paint( lpdis ) CLASS HGraph
   LOCAL drawInfo := GetDrawItemInfo( lpdis )
   LOCAL hDC := drawInfo[3], x1 := drawInfo[4], y1 := drawInfo[5], x2 := drawInfo[6], y2 := drawInfo[7]
   LOCAL i, j, nLen
   LOCAL px1, px2, py1, py2, nWidth

   i := Round(( x2 - x1 ) / 10, 0)
   x1 += i
   x2 -= i
   i := Round(( y2 - y1 ) / 10, 0)
   y1 += i
   y2 -= i

   IF ::nType < 3
      ::scaleX := ( ::xmax - ::xmin ) / ( x2 - x1 )
      ::scaleY := ( ::ymax - ::ymin ) / ( y2 - y1 )
   ENDIF

   IF ::oPenCoor == Nil
      ::oPenCoor := HPen():Add(PS_SOLID, 1, ::colorCoor)
   ENDIF
   IF ::oPen == Nil
      ::oPen := HPen():Add(PS_SOLID, 2, ::tcolor)
   ENDIF

   FillRect( hDC, drawInfo[4], drawInfo[5], drawInfo[6], drawInfo[7], ::brush:handle )
   IF ::nType != 3
      SelectObject(hDC, ::oPenCoor:handle)
      Drawline(hDC, x1 + ( 0 - ::xmin ) / ::scaleX, drawInfo[5] + 3, x1 + ( 0 - ::xmin ) / ::scaleX, drawInfo[7] - 3)
      Drawline(hDC, drawInfo[4] + 3, y2 - ( 0 - ::ymin ) / ::scaleY, drawInfo[6] - 3, y2 - ( 0 - ::ymin ) / ::scaleY)
   ENDIF

   IF ::ymax == ::ymin .AND. ::ymax == 0
      RETURN Nil
   ENDIF

   SelectObject(hDC, ::oPen:handle)
   FOR i := 1 TO ::nGraphs
      nLen := Len( ::aValues[i] )
      IF ::nType == 1
         FOR j := 2 TO nLen
            px1 := Round(x1 + ( ::aValues[ i, j - 1, 1 ] - ::xmin ) / ::scaleX, 0)
            py1 := Round(y2 - ( ::aValues[ i, j - 1, 2 ] - ::ymin ) / ::scaleY, 0)
            px2 := Round(x1 + ( ::aValues[ i, j, 1 ] - ::xmin ) / ::scaleX, 0)
            py2 := Round(y2 - ( ::aValues[ i, j, 2 ] - ::ymin ) / ::scaleY, 0)
            IF px2 != px1 .OR. py2 != py1
               Drawline(hDC, px1, py1, px2, py2)
            ENDIF
         NEXT
      ELSEIF ::nType == 2
         IF ::tbrush == Nil
            ::tbrush := HBrush():Add(::tcolor)
         ENDIF
         nWidth := Round(( x2 - x1 ) / ( nLen * 2 + 1 ), 0)
         FOR j := 1 TO nLen
            px1 := Round(x1 + nWidth * ( j * 2 - 1 ), 0)
            py1 := Round(y2 - ( ::aValues[ i, j, 2 ] - ::ymin ) / ::scaleY, 0)
            FillRect( hDC, px1, y2 - 2, px1 + nWidth, py1, ::tbrush:handle )
         NEXT
      ELSEIF ::nType == 3
         IF ::tbrush == Nil
            ::tbrush := HBrush():Add(::tcolor)
         ENDIF
         SelectObject(hDC, ::oPenCoor:handle)
         SelectObject(hDC, ::tbrush:handle)
         pie(hDC, x1 + 10, y1 + 10, x2 - 10, y2 - 10, x1, Round(y1 + ( y2 - y1 ) / 2, 0), Round(x1 + ( x2 - x1 ) / 2, 0), y1)
      ENDIF
   NEXT

   RETURN Nil

METHOD Rebuild(aValues, nType) CLASS HGraph

   ::aValues := aValues
   IF nType != Nil
      ::nType := nType
   ENDIF
   ::CalcMinMax()
   RedrawWindow( ::handle, RDW_ERASE + RDW_INVALIDATE + RDW_INTERNALPAINT + RDW_UPDATENOW )

   RETURN Nil
