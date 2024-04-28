/*
 * $Id: drawwidg.prg 1740 2011-09-23 12:06:53Z LFBASSO $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Fonts handling
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

CLASS HFont INHERIT HObject

CLASS VAR aFonts   INIT {}
   DATA handle
   DATA name, width, height, weight
   DATA charset, italic, Underline, StrikeOut
   DATA nCounter   INIT 1

   METHOD Add(fontName, nWidth, nHeight, fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle)
   METHOD Select(oFont, nCharSet)
   METHOD Release()
   METHOD SetFontStyle(lBold, nCharSet, lItalic, lUnder, lStrike, nHeight)

ENDCLASS

METHOD Add(fontName, nWidth, nHeight, fnWeight, ;
            fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut, nHandle) CLASS HFont

   LOCAL i, nlen := Len(::aFonts)

   nHeight  := IIf(nHeight == Nil, - 13, nHeight)
   fnWeight := IIf(fnWeight == Nil, 0, fnWeight)
   fdwCharSet := IIf(fdwCharSet == Nil, 0, fdwCharSet)
   fdwItalic := IIf(fdwItalic == Nil, 0, fdwItalic)
   fdwUnderline := IIf(fdwUnderline == Nil, 0, fdwUnderline)
   fdwStrikeOut := IIf(fdwStrikeOut == Nil, 0, fdwStrikeOut)

   FOR i := 1 TO nlen
      IF ::aFonts[i]:name == fontName .AND.          ;
         ::aFonts[i]:width == nWidth .AND.           ;
         ::aFonts[i]:height == nHeight .AND.         ;
         ::aFonts[i]:weight == fnWeight .AND.        ;
         ::aFonts[i]:CharSet == fdwCharSet .AND.     ;
         ::aFonts[i]:Italic == fdwItalic .AND.       ;
         ::aFonts[i]:Underline == fdwUnderline .AND. ;
         ::aFonts[i]:StrikeOut == fdwStrikeOut

         ::aFonts[i]:nCounter++
         IF nHandle != Nil
            DeleteObject(nHandle)
         ENDIF
         RETURN ::aFonts[i]
      ENDIF
   NEXT

   IF nHandle == Nil
      ::handle := CreateFont(fontName, nWidth, nHeight, fnWeight, fdwCharSet, fdwItalic, fdwUnderline, fdwStrikeOut)
   ELSE
      ::handle := nHandle
   ENDIF

   ::name      := fontName
   ::width     := nWidth
   ::height    := nHeight
   ::weight    := fnWeight
   ::CharSet   := fdwCharSet
   ::Italic    := fdwItalic
   ::Underline := fdwUnderline
   ::StrikeOut := fdwStrikeOut

   AAdd(::aFonts, Self)

   RETURN Self

METHOD Select(oFont, nCharSet) CLASS HFont
   LOCAL af := SelectFont(oFont)

   IF af == Nil
      RETURN Nil
   ENDIF

   RETURN ::Add(af[2], af[3], af[4], af[5], IIF(Empty(nCharSet), af[6], nCharSet ), af[7], af[8], af[9], af[1])

METHOD SetFontStyle(lBold, nCharSet, lItalic, lUnder, lStrike, nHeight) CLASS HFont
   LOCAL  weight, Italic, Underline, StrikeOut

   IF lBold != Nil
      weight = IIF(lBold, FW_BOLD, FW_REGULAR)
   ELSE
      weight := ::weight
   ENDIF
   Italic    := IIF(lItalic = Nil, ::Italic, IIF(lItalic, 1, 0))
   Underline := IIF(lUnder  = Nil, ::Underline, IIF(lUnder, 1, 0))
   StrikeOut := IIF(lStrike = Nil, ::StrikeOut, IIF(lStrike, 1, 0))
   nheight   := IIF(nheight = Nil, ::height, nheight)
   nCharSet  := IIF(nCharSet = Nil, ::CharSet, nCharSet)
   RETURN ::Add(::name, ::width, nheight, weight,;
                 nCharSet, Italic, Underline, StrikeOut) // ::handle)

METHOD Release() CLASS HFont
   LOCAL i, nlen := Len(::aFonts)

   ::nCounter --
   IF ::nCounter == 0
      #ifdef __XHARBOUR__
         FOR EACH i IN ::aFonts
            IF i:handle == ::handle
               DeleteObject(::handle)
               ADel(::aFonts, hb_enumindex())
               ASize(::aFonts, nlen - 1)
               EXIT
            ENDIF
         NEXT
      #else
         FOR i := 1 TO nlen
            IF ::aFonts[i]:handle == ::handle
               DeleteObject(::handle)
               ADel(::aFonts, i)
               ASize(::aFonts, nlen - 1)
               EXIT
            ENDIF
         NEXT
      #endif
   ENDIF
   RETURN Nil

EXIT PROCEDURE CleanDrawWidgHFont

   LOCAL item

   FOR EACH item IN HFont():aFonts
      DeleteObject(item:handle)
   NEXT

RETURN
