/*
 * $Id: drawwidg.prg 1740 2011-09-23 12:06:53Z LFBASSO $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Brushes handling
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

CLASS HBrush INHERIT HObject

CLASS VAR aBrushes   INIT {}
   DATA handle
   DATA color
   DATA nHatch   INIT 99
   DATA nCounter INIT 1

   METHOD Add(nColor, nHatch)
   METHOD Release()

ENDCLASS

METHOD Add(nColor, nHatch) CLASS HBrush
   LOCAL i

   IF nHatch == Nil
      nHatch := 99
   ENDIF
   IF hb_IsPointer(nColor)
      nColor := PTRTOULONG(nColor)
   ENDIF
   #ifdef __XHARBOUR__
      FOR EACH i IN ::aBrushes

         IF i:color == nColor .AND. i:nHatch == nHatch
            i:nCounter ++
            RETURN i
         ENDIF
      NEXT
   #else
      FOR i := 1 TO Len(::aBrushes)
         IF ::aBrushes[i]:color == nColor .AND. ::aBrushes[i]:nHatch == nHatch
            ::aBrushes[i]:nCounter++
            RETURN ::aBrushes[i]
         ENDIF
      NEXT
   #endif
   IF nHatch != 99
      ::handle := CreateHatchBrush(nHatch, nColor)
   ELSE
      ::handle := CreateSolidBrush(nColor)
   ENDIF
   ::color  := nColor
   AAdd(::aBrushes, Self)

   RETURN Self

METHOD Release() CLASS HBrush
   LOCAL i, nlen := Len(::aBrushes)

   ::nCounter --
   IF ::nCounter == 0
      #ifdef __XHARBOUR__
         FOR EACH i IN ::aBrushes
            IF i:handle == ::handle
               DeleteObject(::handle)
               ADel(::aBrushes, hb_enumindex())
               ASize(::aBrushes, nlen - 1)
               EXIT
            ENDIF
         NEXT
      #else
         FOR i := 1 TO nlen
            IF ::aBrushes[i]:handle == ::handle
               DeleteObject(::handle)
               ADel(::aBrushes, i)
               ASize(::aBrushes, nlen - 1)
               EXIT
            ENDIF
         NEXT
      #endif
   ENDIF
   RETURN Nil

EXIT PROCEDURE CleanDrawWidgHBrush

   LOCAL item

   FOR EACH item IN HBrush():aBrushes
      DeleteObject(item:handle)
   NEXT

RETURN
