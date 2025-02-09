//
// $Id: drawwidg.prg 1740 2011-09-23 12:06:53Z LFBASSO $
//
// HWGUI - Harbour Win32 GUI library source code:
// Pens handling
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://www.geocities.com/alkresin/
//

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

//-------------------------------------------------------------------------------------------------------------------//

CLASS HPen INHERIT HObject

   CLASS VAR aPens INIT {}

   DATA handle
   DATA style
   DATA width
   DATA color
   DATA nCounter INIT 1

   METHOD Add(nStyle, nWidth, nColor)
   METHOD Get(nStyle, nWidth, nColor)
   METHOD Release()

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD Add(nStyle, nWidth, nColor) CLASS HPen

   LOCAL item

   nStyle := IIf(nStyle == NIL, BS_SOLID, nStyle)
   nWidth := IIf(nWidth == NIL, 1, nWidth)
   nColor := IIf(nColor == NIL, 0, nColor)

   FOR EACH item IN ::aPens
      IF item:style == nStyle .AND. ;
         item:width == nWidth .AND. ;
         item:color == nColor
         item:nCounter++
         RETURN item
      ENDIF
   NEXT

   ::handle := CreatePen(nStyle, nWidth, nColor)
   ::style := nStyle
   ::width := nWidth
   ::color := nColor
   AAdd(::aPens, Self)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD Get(nStyle, nWidth, nColor) CLASS HPen

   LOCAL item

   nStyle := IIf(nStyle == NIL, PS_SOLID, nStyle)
   nWidth := IIf(nWidth == NIL, 1, nWidth)
   nColor := IIf(nColor == NIL, 0, nColor)

   FOR EACH item IN ::aPens
      IF item:style == nStyle .AND. ;
         item:width == nWidth .AND. ;
         item:color == nColor
         RETURN item
      ENDIF
   NEXT

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD Release() CLASS HPen

   LOCAL item
   LOCAL nlen := Len(::aPens)

   ::nCounter--
   IF ::nCounter == 0
      FOR EACH item IN ::aPens
         IF item:handle == ::handle
            hwg_DeleteObject(::handle)
            #ifdef __XHARBOUR__
            ADel(::aPens, hb_EnumIndex())
            #else
            ADel(::aPens, item:__EnumIndex())
            #endif
            ASize(::aPens, nlen - 1)
            EXIT
         ENDIF
      NEXT
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

EXIT PROCEDURE CleanDrawWidgHPen

   LOCAL item

   FOR EACH item IN HPen():aPens
      hwg_DeleteObject(item:handle)
   NEXT

RETURN

//-------------------------------------------------------------------------------------------------------------------//
