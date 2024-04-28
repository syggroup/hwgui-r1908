/*
 * $Id: drawwidg.prg 1740 2011-09-23 12:06:53Z LFBASSO $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Pens handling
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

CLASS HPen INHERIT HObject

CLASS VAR aPens   INIT {}
   DATA handle
   DATA style, width, color
   DATA nCounter   INIT 1

   METHOD Add(nStyle, nWidth, nColor)
   METHOD Get(nStyle, nWidth, nColor)
   METHOD Release()

ENDCLASS

METHOD Add(nStyle, nWidth, nColor) CLASS HPen
   LOCAL i

   nStyle := IIf(nStyle == Nil, BS_SOLID, nStyle)
   nWidth := IIf(nWidth == Nil, 1, nWidth)
   nColor := IIf(nColor == Nil, 0, nColor)

   #ifdef __XHARBOUR__
      FOR EACH i IN ::aPens
         IF i:style == nStyle .AND. ;
            i:width == nWidth .AND. ;
            i:color == nColor

            i:nCounter ++
            RETURN i
         ENDIF
      NEXT
   #else
      FOR i := 1 TO Len(::aPens)
         IF ::aPens[i]:style == nStyle .AND. ;
            ::aPens[i]:width == nWidth .AND. ;
            ::aPens[i]:color == nColor

            ::aPens[i]:nCounter++
            RETURN ::aPens[i]
         ENDIF
      NEXT
   #endif

   ::handle := CreatePen(nStyle, nWidth, nColor)
   ::style  := nStyle
   ::width  := nWidth
   ::color  := nColor
   AAdd(::aPens, Self)

   RETURN Self

METHOD Get(nStyle, nWidth, nColor) CLASS HPen
   LOCAL i

   nStyle := IIf(nStyle == Nil, PS_SOLID, nStyle)
   nWidth := IIf(nWidth == Nil, 1, nWidth)
   nColor := IIf(nColor == Nil, 0, nColor)

   #ifdef __XHARBOUR__
      FOR EACH i IN ::aPens
         IF i:style == nStyle .AND. ;
            i:width == nWidth .AND. ;
            i:color == nColor

            RETURN i
         ENDIF
      NEXT
   #else
      FOR i := 1 TO Len(::aPens)
         IF ::aPens[i]:style == nStyle .AND. ;
            ::aPens[i]:width == nWidth .AND. ;
            ::aPens[i]:color == nColor

            RETURN ::aPens[i]
         ENDIF
      NEXT
   #endif

   RETURN Nil

METHOD Release() CLASS HPen
   LOCAL i, nlen := Len(::aPens)

   ::nCounter --
   IF ::nCounter == 0
      #ifdef __XHARBOUR__
         FOR EACH i  IN ::aPens
            IF i:handle == ::handle
               DeleteObject(::handle)
               ADel(::aPens, hb_EnumIndex())
               ASize(::aPens, nlen - 1)
               EXIT
            ENDIF
         NEXT
      #else
         FOR i := 1 TO nlen
            IF ::aPens[i]:handle == ::handle
               DeleteObject(::handle)
               ADel(::aPens, i)
               ASize(::aPens, nlen - 1)
               EXIT
            ENDIF
         NEXT
      #endif
   ENDIF
   RETURN Nil


EXIT PROCEDURE CleanDrawWidgHPen

   LOCAL i

   FOR i := 1 TO Len(HPen():aPens)
      DeleteObject(HPen():aPens[i]:handle)
   NEXT

RETURN
