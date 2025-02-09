//
// $Id: hwinprn.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// HWinPrn class
//
// Copyright 2005 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "hwgui.ch"
#include "hbclass.ch"


#define   STD_HEIGHT      4

#define   MODE_NORMAL     0
#define   MODE_ELITE      1
#define   MODE_COND       2
#define   MODE_ELITECOND  3
#define   MODE_USER      10

Static s_cPseudoChar := "ÄÍ³ºÚÉÕÖ¿»·¸ÀÈÓÔÙ¼½¾ÂËÑÒÁÊÏÐÃÌÆÇ´¹µ¶ÅÎ×Ø"


CLASS HWinPrn INHERIT HObject

   CLASS VAR nStdHeight SHARED  INIT NIL
   CLASS VAR cPrinterName SHARED  INIT NIL
   DATA   oPrinter
   DATA   oFont
   DATA   nLineHeight, nLined
   DATA   nCharW
   DATA   x, y
   DATA   lElite    INIT .F.
   DATA   lCond     INIT .F.
   DATA   nLineInch INIT 6
   DATA   lBold     INIT .F.
   DATA   lItalic   INIT .F.
   DATA   lUnder    INIT .F.
   DATA   lChanged  INIT .F.

   DATA   cpFrom, cpTo
   DATA   nTop      INIT 5
   DATA   nBottom   INIT 5
   DATA   nLeft     INIT 5
   DATA   nRight    INIT 5


   METHOD New(cPrinter, cpFrom, cpTo, nFormType, nBin, lLandScape, nCopies)
   METHOD InitValues(lElite, lCond, nLineInch, lBold, lItalic, lUnder)
   METHOD SetMode(lElite, lCond, nLineInch, lBold, lItalic, lUnder)
   METHOD StartDoc(lPreview, cMetaName)
   METHOD NextPage()
   METHOD PrintLine(cLine, lNewLine)
   METHOD PrintText(cText)
   METHOD PutCode(cLine)
   METHOD EndDoc()
   METHOD End()

   HIDDEN:
      DATA lDocStart   INIT .F.
      DATA lPageStart  INIT .F.
      DATA lFirstLine

ENDCLASS

METHOD New(cPrinter, cpFrom, cpTo, nFormType, nBin, lLandScape, nCopies) CLASS HWinPrn

   ::oPrinter := HPrinter():New(IIf(cPrinter == NIL, "", cPrinter), .F., nFormType, nBin, lLandScape, nCopies)
   IF ::oPrinter == NIL
      RETURN NIL
   ENDIF
   ::cpFrom := cpFrom
   ::cpTo   := cpTo

RETURN Self

METHOD InitValues(lElite, lCond, nLineInch, lBold, lItalic, lUnder) CLASS HWinPrn

   IF lElite != NIL; ::lElite := lElite;  ENDIF
   IF lCond != NIL; ::lCond := lCond;  ENDIF
   IF nLineInch != NIL; ::nLineInch := nLineInch;  ENDIF
   IF lBold != NIL; ::lBold := lBold;  ENDIF
   IF lItalic != NIL; ::lItalic := lItalic;  ENDIF
   IF lUnder != NIL; ::lUnder := lUnder;  ENDIF
   ::lChanged := .T.

RETURN NIL

METHOD SetMode(lElite, lCond, nLineInch, lBold, lItalic, lUnder) CLASS HWinPrn
#ifdef __PLATFORM__Linux__
Local cFont := "Monospace "
#else
Local cFont := "Lucida Console"
#endif
Local aKoef := {1, 1.22, 1.71, 2}
Local nMode := 0, oFont, nWidth, nPWidth

   ::InitValues(lElite, lCond, nLineInch, lBold, lItalic, lUnder)

   IF ::lPageStart

      IF ::nStdHeight == NIL .OR. ::cPrinterName != ::oPrinter:cPrinterName
         ::nStdHeight := STD_HEIGHT
         ::cPrinterName := ::oPrinter:cPrinterName
         nPWidth := ::oPrinter:nWidth / ::oPrinter:nHRes - 10
         IF nPWidth > 210 .OR. nPWidth < 190
            nPWidth := 200
         ENDIF
#ifdef __PLATFORM__Linux__
         oFont := ::oPrinter:AddFont(cFont + "Regular", ::nStdHeight * ::oPrinter:nVRes)
#else
         oFont := ::oPrinter:AddFont(cFont, ::nStdHeight * ::oPrinter:nVRes)
#endif
         ::oPrinter:SetFont(oFont)
         nWidth := ::oPrinter:GetTextWidth(Replicate("A", 80)) / ::oPrinter:nHRes
         IF nWidth > nPWidth+2 .OR. nWidth < nPWidth-15
            ::nStdHeight := ::nStdHeight * (nPWidth / nWidth)
         ENDIF
         oFont:Release()
      ENDIF

      IF ::lElite
         nMode++
      ENDIF
      IF ::lCond
         nMode += 2
      ENDIF

      ::nLineHeight := (::nStdHeight / aKoef[nMode+1]) * ::oPrinter:nVRes
      ::nLined := (25.4 * ::oPrinter:nVRes) / ::nLineInch - ::nLineHeight

#ifdef __PLATFORM__Linux__
      IF ::lBold
         cFont += "Bold"
      ENDIF
      IF ::lItalic
         cFont += "Italic"
      ENDIF
      IF !::lBold .AND. !::lItalic
         cFont += "Regular"
      ENDIF
      oFont := ::oPrinter:AddFont(cFont, ::nLineHeight)
#else
      oFont := ::oPrinter:AddFont("Lucida Console", ::nLineHeight, ::lBold, ::lItalic, ::lUnder, 204)
#endif

      IF ::oFont != NIL
         ::oFont:Release()
      ENDIF
      ::oFont := oFont

      ::oPrinter:SetFont(::oFont)
      ::nCharW := ::oPrinter:GetTextWidth("ABCDEFGHIJ") / 10
      ::lChanged := .F.

   ENDIF

RETURN NIL

METHOD StartDoc(lPreview, cMetaName) CLASS HWinPrn

   ::lDocStart := .T.
   ::oPrinter:StartDoc(lPreview, cMetaName)
   ::NextPage()

RETURN NIL

METHOD NextPage() CLASS HWinPrn

   IF !::lDocStart
      RETURN NIL
   ENDIF
   IF ::lPageStart
      ::oPrinter:EndPage()
   ENDIF

   ::lPageStart := .T.
   ::oPrinter:StartPage()

   IF ::oFont == NIL
      ::SetMode()
   ELSE
      ::oPrinter:SetFont(::oFont)
   ENDIF

   ::y := ::nTop * ::oPrinter:nVRes - ::nLineHeight - ::nLined
   ::lFirstLine := .T.

RETURN NIL

METHOD PrintLine(cLine, lNewLine) CLASS HWinPrn
Local i, i0, j, slen, c

   IF !::lDocStart
      ::StartDoc()
   ENDIF

   IF ::y + 2 * (::nLineHeight + ::nLined) > ::oPrinter:nHeight
      ::NextPage()
   ENDIF
   ::x := ::nLeft * ::oPrinter:nHRes
   IF ::lFirstLine
      ::lFirstLine := .F.
   ELSEIF lNewLine == NIL .OR. lNewLine
      ::y += ::nLineHeight + ::nLined
   ENDIF

   IF cLine != NIL .AND. !Empty(cLine)
      slen := Len(cLine)
      i := 1
      i0 := 0
      DO WHILE i <= slen
         IF (c := SubStr(cLine, i, 1)) < " "
            IF i0 != 0
               ::PrintText(SubStr(cLine, i0, i - i0))
               i0 := 0
            ENDIF
            i += ::PutCode(SubStr(cLine, i))
            LOOP
         ELSEIF (j := At(c, s_cPseudoChar)) != 0
            IF i0 != 0
               ::PrintText(SubStr(cLine, i0, i - i0))
               i0 := 0
            ENDIF
            IF j < 3            // Horisontal line ÄÍ
               i0 := i
               DO WHILE i <= slen .AND. SubStr(cLine, i, 1) == c
                  i++
               ENDDO
               ::oPrinter:Line(::x, ::y + (::nLineHeight / 2), ::x + (i - i0) * ::nCharW, ::y + (::nLineHeight / 2))
               ::x += (i-i0) * ::nCharW
               i0 := 0
               LOOP
            ELSE
               IF j < 5         // Vertical Line ³º
                  ::oPrinter:Line(::x + (::nCharW / 2), ::y, ::x + (::nCharW / 2), ::y + ::nLineHeight + ::nLined)
               ELSEIF j < 9     // ÚÉÕÖ
                  ::oPrinter:Line(::x + (::nCharW / 2), ::y + (::nLineHeight / 2), ::x + ::nCharW, ::y + (::nLineHeight / 2))
                  ::oPrinter:Line(::x + (::nCharW / 2), ::y + (::nLineHeight / 2), ::x + (::nCharW / 2), ::y+::nLineHeight + ::nLined)
               ELSEIF j < 13    // ¿»·¸
                  ::oPrinter:Line(::x, ::y+(::nLineHeight/2), ::x+(::nCharW/2), ::y+(::nLineHeight/2))
                  ::oPrinter:Line(::x+(::nCharW/2), ::y+(::nLineHeight/2), ::x+(::nCharW/2), ::y+::nLineHeight+::nLined)
               ELSEIF j < 17    // ÀÈÓÔ
                  ::oPrinter:Line(::x+(::nCharW/2), ::y+(::nLineHeight/2), ::x+::nCharW, ::y+(::nLineHeight/2))
                  ::oPrinter:Line(::x+(::nCharW/2), ::y, ::x+(::nCharW/2), ::y+(::nLineHeight/2))
               ELSEIF j < 21    // Ù¼½¾
                  ::oPrinter:Line(::x, ::y+(::nLineHeight/2), ::x+(::nCharW/2), ::y+(::nLineHeight/2))
                  ::oPrinter:Line(::x+(::nCharW/2), ::y, ::x+(::nCharW/2), ::y+(::nLineHeight/2))
               ELSEIF j < 25    // ÂËÑÒ
                  ::oPrinter:Line(::x, ::y+(::nLineHeight/2), ::x+::nCharW, ::y+(::nLineHeight/2))
                  ::oPrinter:Line(::x+(::nCharW/2), ::y+(::nLineHeight/2), ::x+(::nCharW/2), ::y+::nLineHeight+::nLined)
               ELSEIF j < 29    // ÁÊÏÐ
                  ::oPrinter:Line(::x, ::y+(::nLineHeight/2), ::x+::nCharW, ::y+(::nLineHeight/2))
                  ::oPrinter:Line(::x+(::nCharW/2), ::y, ::x+(::nCharW/2), ::y+(::nLineHeight/2))
               ELSEIF j < 33    // ÃÌÆÇ
                  ::oPrinter:Line(::x+(::nCharW/2), ::y+(::nLineHeight/2), ::x+::nCharW, ::y+(::nLineHeight/2))
                  ::oPrinter:Line(::x+(::nCharW/2), ::y, ::x+(::nCharW/2), ::y+::nLineHeight+::nLined)
               ELSEIF j < 37    // ´¹µ¶
                  ::oPrinter:Line(::x, ::y+(::nLineHeight/2), ::x+(::nCharW/2), ::y+(::nLineHeight/2))
                  ::oPrinter:Line(::x+(::nCharW/2), ::y, ::x+(::nCharW/2), ::y+::nLineHeight+::nLined)
               ELSE    // ÅÎ×Ø
                  ::oPrinter:Line(::x, ::y+(::nLineHeight/2), ::x+::nCharW, ::y+(::nLineHeight/2))
                  ::oPrinter:Line(::x+(::nCharW/2), ::y, ::x+(::nCharW/2), ::y+::nLineHeight+::nLined)
               ENDIF
               ::x += ::nCharW
            ENDIF
         ELSE
            IF i0 == 0
               i0 := i
            ENDIF
         ENDIF
         i++
      ENDDO
      IF i0 != 0
         ::PrintText(SubStr(cLine, i0, i - i0))
      ENDIF
   ENDIF

RETURN NIL

METHOD PrintText(cText) CLASS HWinPrn

   IF ::lChanged
      ::SetMode()
   ENDIF
   ::oPrinter:Say(IIf(::cpFrom!=::cpTo, hb_Translate(cText, ::cpFrom, ::cpTo), cText), ;
            ::x, ::y, ::oPrinter:nWidth, ::y+::nLineHeight+::nLined)
   ::x += (::nCharW * Len(cText))

RETURN NIL

METHOD PutCode(cLine) CLASS HWinPrn
Static aCodes := { ;
   {Chr(27) + "@", .F., .F., 6, .F., .F., .F.},  ;     /* Reset */
   {Chr(27) + "M", .T.,,,,,},  ;     /* Elite */
   {Chr(15),, .T.,,,,},      ;     /* Cond */
   {Chr(18),, .F.,,,,},      ;     /* Cancel Cond */
   {Chr(27) + "0",,, 8,,,},    ;     /* 8 lines per inch */
   {Chr(27) + "2",,, 6,,,},    ;     /* 6 lines per inch (standard) */
   {Chr(27) + "-1",,,,,, .T.}, ;     /* underline */
   {Chr(27) + "-0",,,,,, .F.}, ;     /* cancel underline */
   {Chr(27) + "4",,,,, .T.,},  ;     /* italic */
   {Chr(27) + "5",,,,, .F.,},  ;     /* cancel italic */
   {Chr(27) + "G",,,,, .T.,},  ;     /* bold */
   {Chr(27) + "H",,,, .F.,,}   ;     /* cancel bold */
 }
Local i, sLen := Len(aCodes), c := Left(cLine, 1)

   FOR i := 1 TO sLen
      IF Left(aCodes[i, 1], 1) == c .AND. At(aCodes[i, 1], Left(cLine, 3)) == 1
         ::InitValues(aCodes[i, 2], aCodes[i, 3], aCodes[i, 4], aCodes[i, 5], aCodes[i, 6], aCodes[i, 7])
         RETURN Len(aCodes[i, 1])
      ENDIF
   NEXT

RETURN 1

METHOD EndDoc() CLASS HWinPrn

   IF ::lPageStart
      ::oPrinter:EndPage()
      ::lPageStart := .F.
   ENDIF
   IF ::lDocStart
      ::oPrinter:EndDoc()
      ::lDocStart := .F.
      IF __ObjHasMsg(::oPrinter, "PREVIEW") .AND. ::oPrinter:lPreview
         ::oPrinter:Preview()
      ENDIF
   ENDIF

RETURN NIL

METHOD End() CLASS HWinPrn

   ::EndDoc()
   ::oFont:Release()
   ::oPrinter:End()
RETURN NIL

