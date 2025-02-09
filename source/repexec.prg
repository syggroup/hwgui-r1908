//
// $Id: repexec.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// RepExec - Loading and executing of reports, built with RepBuild
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "guilib.ch"
#include "repmain.h"
#include "fileio.ch"
#include "common.ch"

// #define __DEBUG__

STATIC s_aPaintRep := NIL

REQUEST DBUseArea
REQUEST RecNo
REQUEST DBSkip
REQUEST DBGoTop
REQUEST DBCloseArea

FUNCTION ClonePaintRep(ar)
   s_aPaintRep := AClone(ar)
   RETURN NIL

FUNCTION SetPaintRep(ar)
   s_aPaintRep := ar
   RETURN NIL

FUNCTION OpenReport(fname, repName)
   LOCAL strbuf := Space(512), poz := 513, stroka, nMode := 0
   LOCAL han
   LOCAL itemName, aItem, res := .T.
   LOCAL nFormWidth

   IF s_aPaintRep != NIL .AND. fname == s_aPaintRep[FORM_FILENAME] .AND. repName == s_aPaintRep[FORM_REPNAME]
      RETURN res
   ENDIF
   han := FOpen(fname, FO_READ + FO_SHARED)
   IF han != - 1
      DO WHILE .T.
         stroka := RDSTR(han, @strbuf, @poz, 512)
         IF Len(stroka) == 0
            EXIT
         ENDIF
         IF Left(stroka, 1) == ";"
            LOOP
         ENDIF
         IF nMode == 0
            IF Left(stroka, 1) == "#"
               IF Upper(SubStr(stroka, 2, 6)) == "REPORT"
                  stroka := LTrim(SubStr(stroka, 9))
                  IF Upper(stroka) == Upper(repName)
                     nMode := 1
                     s_aPaintRep := {0, 0, 0, 0, 0, {}, fname, repName, .F., 0, NIL}
                  ENDIF
               ENDIF
            ENDIF
         ELSEIF nMode == 1
            IF Left(stroka, 1) == "#"
               IF Upper(SubStr(stroka, 2, 6)) == "ENDREP"
                  EXIT
               ELSEIF Upper(SubStr(stroka, 2, 6)) == "SCRIPT"
                  nMode := 2
                  IF aItem != NIL
                     aItem[ITEM_SCRIPT] := ""
                  ELSE
                     s_aPaintRep[FORM_VARS] := ""
                  ENDIF
               ENDIF
            ELSE
               IF (itemName := NextItem(stroka, .T.)) == "FORM"
                  s_aPaintRep[FORM_WIDTH] := Val(NextItem(stroka))
                  s_aPaintRep[FORM_HEIGHT] := Val(NextItem(stroka))
                  nFormWidth := Val(NextItem(stroka))
                  s_aPaintRep[FORM_XKOEF] := nFormWidth / s_aPaintRep[FORM_WIDTH]
               ELSEIF itemName == "TEXT"
                  AAdd(s_aPaintRep[FORM_ITEMS], {1, NextItem(stroka), Val(NextItem(stroka)), ;
                                                  Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                                                  Val(NextItem(stroka)), Val(NextItem(stroka)), 0, NextItem(stroka), ;
                                                  Val(NextItem(stroka)), 0, NIL, 0})
                  aItem := ATail(s_aPaintRep[FORM_ITEMS])
                  aItem[ITEM_FONT] := HFont():Add(NextItem(aItem[ITEM_FONT], .T., ","), ;
                                                     Val(NextItem(aItem[ITEM_FONT],, ",")), Val(NextItem(aItem[ITEM_FONT],, ",")), ;
                                                     Val(NextItem(aItem[ITEM_FONT],, ",")), Val(NextItem(aItem[ITEM_FONT],, ",")), ;
                                                     Val(NextItem(aItem[ITEM_FONT],, ",")), Val(NextItem(aItem[ITEM_FONT],, ",")), ;
                                                     Val(NextItem(aItem[ITEM_FONT],, ",")))
                  IF aItem[ITEM_X1] == NIL .OR. aItem[ITEM_X1] == 0 .OR. ;
                  aItem[ITEM_Y1] == NIL .OR. aItem[ITEM_Y1] == 0 .OR. ;
                  aItem[ITEM_WIDTH] == NIL .OR. aItem[ITEM_WIDTH] == 0 .OR. ;
                  aItem[ITEM_HEIGHT] == NIL .OR. aItem[ITEM_HEIGHT] == 0
                  hwg_MsgStop("Error: " + stroka)
                  res := .F.
                  EXIT
               ENDIF
            ELSEIF itemName == "HLINE" .OR. itemName == "VLINE" .OR. itemName == "BOX"
               AAdd(s_aPaintRep[FORM_ITEMS], {IIf(itemName == "HLINE", 2, IIf(itemName == "VLINE", 3, 4)), ;
                                                "", Val(NextItem(stroka)), ;
                                                Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                                                Val(NextItem(stroka)), 0, NextItem(stroka), 0, 0, 0, NIL, 0})
               aItem := ATail(s_aPaintRep[FORM_ITEMS])
               aItem[ITEM_PEN] := HPen():Add(Val(NextItem(aItem[ITEM_PEN], .T., ",")), ;
                                                Val(NextItem(aItem[ITEM_PEN],, ",")), Val(NextItem(aItem[ITEM_PEN],, ",")))
               IF aItem[ITEM_X1] == NIL .OR. aItem[ITEM_X1] == 0 .OR. ;
               aItem[ITEM_Y1] == NIL .OR. aItem[ITEM_Y1] == 0 .OR. ;
               aItem[ITEM_WIDTH] == NIL .OR. aItem[ITEM_WIDTH] == 0 .OR. ;
               aItem[ITEM_HEIGHT] == NIL .OR. aItem[ITEM_HEIGHT] == 0
               hwg_MsgStop("Error: " + stroka)
               res := .F.
               EXIT
            ENDIF
         ELSEIF itemName == "BITMAP"
            AAdd(s_aPaintRep[FORM_ITEMS], {5, NextItem(stroka), ;
                                             Val(NextItem(stroka)), ;
                                             Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                                             Val(NextItem(stroka)), 0, 0, 0, 0, 0, NIL, 0})
            aItem := ATail(s_aPaintRep[FORM_ITEMS])
            IF aItem[ITEM_X1] == NIL .OR. aItem[ITEM_X1] == 0 .OR. ;
               aItem[ITEM_Y1] == NIL .OR. aItem[ITEM_Y1] == 0 .OR. ;
               aItem[ITEM_WIDTH] == NIL .OR. aItem[ITEM_WIDTH] == 0 .OR. ;
               aItem[ITEM_HEIGHT] == NIL .OR. aItem[ITEM_HEIGHT] == 0
               hwg_MsgStop("Error: " + stroka)
               res := .F.
               EXIT
            ENDIF
         ELSEIF itemName == "MARKER"
            AAdd(s_aPaintRep[FORM_ITEMS], {6, NextItem(stroka), Val(NextItem(stroka)), ;
                                             Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                                             Val(NextItem(stroka)), Val(NextItem(stroka)), ;
                                             0, 0, 0, 0, NIL, 0})
            aItem := ATail(s_aPaintRep[FORM_ITEMS])
         ENDIF
      ENDIF
   ELSEIF nMode == 2
      IF Left(stroka, 1) == "#" .AND. Upper(SubStr(stroka, 2, 6)) == "ENDSCR"
         nMode := 1
      ELSE
         IF aItem != NIL
            aItem[ITEM_SCRIPT] += stroka + Chr(13) + Chr(10)
         ELSE
            s_aPaintRep[FORM_VARS] += stroka + Chr(13) + Chr(10)
         ENDIF
      ENDIF
   ENDIF
ENDDO
FClose(han)
ELSE
   hwg_MsgStop("Can't open " + fname)
   RETURN .F.
ENDIF
IF Empty(s_aPaintRep[FORM_ITEMS])
   hwg_MsgStop(repName + " not found or empty!")
   res := .F.
ELSE
   s_aPaintRep[FORM_ITEMS] := ASort(s_aPaintRep[FORM_ITEMS], , , {|z, y|z[ITEM_Y1] < y[ITEM_Y1] .OR. (z[ITEM_Y1] == y[ITEM_Y1] .AND. z[ITEM_X1] < y[ITEM_X1]) .OR. (z[ITEM_Y1] == y[ITEM_Y1] .AND. z[ITEM_X1] == y[ITEM_X1] .AND. (z[ITEM_WIDTH] < y[ITEM_WIDTH] .OR. z[ITEM_HEIGHT] < y[ITEM_HEIGHT]))})
ENDIF
RETURN res

FUNCTION RecalcForm(aPaintRep, nFormWidth)
   LOCAL hDC, aMetr, aItem, i
   hDC := hwg_GetDC(hwg_GetActiveWindow())
   aMetr := GetDeviceArea(hDC)
   aPaintRep[FORM_XKOEF] := (aMetr[1] - XINDENT) / aPaintRep[FORM_WIDTH]
   hwg_ReleaseDC(hwg_GetActiveWindow(), hDC)

   IF nFormWidth != aMetr[1] - XINDENT
      FOR i := 1 TO Len(aPaintRep[FORM_ITEMS])
         aItem := aPaintRep[FORM_ITEMS, i]
         aItem[ITEM_X1] := Round(aItem[ITEM_X1] * (aMetr[1] - XINDENT) / nFormWidth, 0)
         aItem[ITEM_Y1] := Round(aItem[ITEM_Y1] * (aMetr[1] - XINDENT) / nFormWidth, 0)
         aItem[ITEM_WIDTH] := Round(aItem[ITEM_WIDTH] * (aMetr[1] - XINDENT) / nFormWidth, 0)
         aItem[ITEM_HEIGHT] := Round(aItem[ITEM_HEIGHT] * (aMetr[1] - XINDENT) / nFormWidth, 0)
      NEXT
   ENDIF
   RETURN NIL

FUNCTION PrintReport(printerName, oPrn, lPreview)
   LOCAL oPrinter := IIf(oPrn != NIL, oPrn, HPrinter():New(printerName))
   LOCAL aPrnCoors, prnXCoef, prnYCoef
   LOCAL iItem, aItem, nLineStartY := 0, nLineHeight := 0, nPHStart := 0
   LOCAL iPH := 0, iSL := 0, iEL := 0, iPF := 0, iEPF := 0, iDF := 0
   LOCAL poz := 0, stroka, varName, varValue, i
   LOCAL oFont
   LOCAL lAddMode := .F., nYadd := 0, nEndList := 0

   MEMVAR lFirst, lFinish, lLastCycle, oFontStandard
   PRIVATE lFirst := .T., lFinish := .T., lLastCycle := .F.

   IF oPrinter:hDCPrn == NIL .OR. oPrinter:hDCPrn == 0
      RETURN .F.
   ENDIF

   aPrnCoors := GetDeviceArea(oPrinter:hDCPrn)
   prnXCoef := (aPrnCoors[1] / s_aPaintRep[FORM_WIDTH]) / s_aPaintRep[FORM_XKOEF]
   prnYCoef := (aPrnCoors[2] / s_aPaintRep[FORM_HEIGHT]) / s_aPaintRep[FORM_XKOEF]
   // hwg_WriteLog(oPrinter:cPrinterName + Str(aPrnCoors[1]) + Str(aPrnCoors[2]) + " / " + Str(s_aPaintRep[FORM_WIDTH]) + " " + Str(s_aPaintRep[FORM_HEIGHT]) + Str(s_aPaintRep[FORM_XKOEF]) + " / " + Str(prnXCoef) + Str(prnYCoef))

   IF Type("oFontStandard") = "U"
      PRIVATE oFontStandard := HFont():Add("Arial", 0, -13, 400, 204)
   ENDIF

   FOR i := 1 TO Len(s_aPaintRep[FORM_ITEMS])
      IF s_aPaintRep[FORM_ITEMS, i, ITEM_TYPE] == TYPE_TEXT
         oFont := s_aPaintRep[FORM_ITEMS, i, ITEM_FONT]
         s_aPaintRep[FORM_ITEMS, i, ITEM_STATE] := HFont():Add(oFont:name, ;
                                                             oFont:width, ;
                                                             Round(oFont:height * prnYCoef, 0), ;
                                                             oFont:weight, ;
                                                             oFont:charset, ;
                                                             oFont:italic)
      ENDIF
   NEXT

   IF hb_IsChar(s_aPaintRep[FORM_VARS])
      DO WHILE .T.
         stroka := RDSTR(, s_aPaintRep[FORM_VARS], @poz)
         IF Len(stroka) == 0
            EXIT
         ENDIF
         DO WHILE !Empty(varName := getNextVar(@stroka, @varValue))
            PRIVATE &varName
            IF varValue != NIL
               &varName := &varValue
            ENDIF
         ENDDO
      ENDDO
   ENDIF

   FOR iItem := 1 TO Len(s_aPaintRep[FORM_ITEMS])
      aItem := s_aPaintRep[FORM_ITEMS, iItem]
      IF aItem[ITEM_TYPE] == TYPE_MARKER
         aItem[ITEM_STATE] := 0
         IF aItem[ITEM_CAPTION] == "SL"
            nLineStartY := aItem[ITEM_Y1]
            aItem[ITEM_STATE] := 0
            iSL := iItem
         ELSEIF aItem[ITEM_CAPTION] == "EL"
            nLineHeight := aItem[ITEM_Y1] - nLineStartY
            iEL := iItem
         ELSEIF aItem[ITEM_CAPTION] == "PF"
            nEndList := aItem[ITEM_Y1]
            iPF := iItem
         ELSEIF aItem[ITEM_CAPTION] == "EPF"
            iEPF := iItem
         ELSEIF aItem[ITEM_CAPTION] == "DF"
            iDF := iItem
            IF iPF == 0
               nEndList := aItem[ITEM_Y1]
            ENDIF
         ELSEIF aItem[ITEM_CAPTION] == "PH"
            iPH := iItem
            nPHStart := aItem[ITEM_Y1]
         ENDIF
      ENDIF
   NEXT
   IF iPH > 0 .AND. iSL == 0
      hwg_MsgStop("'Start Line' marker is absent")
      oPrinter:END()
      RETURN .F.
   ELSEIF iSL > 0 .AND. iEL == 0
      hwg_MsgStop("'End Line' marker is absent")
      oPrinter:END()
      RETURN .F.
   ELSEIF iPF > 0 .AND. iEPF == 0
      hwg_MsgStop("'End of Page Footer' marker is absent")
      oPrinter:END()
      RETURN .F.
   ELSEIF iSL > 0 .AND. iPF == 0 .AND. iDF == 0
      hwg_MsgStop("'Page Footer' and 'Document Footer' markers are absent")
      oPrinter:END()
      RETURN .F.
   ENDIF

   #ifdef __DEBUG__
      oPrinter:END()
      // hwg_WriteLog("Startdoc")
      // hwg_WriteLog("Startpage")
   #else
      oPrinter:StartDoc(lPreview)
      oPrinter:StartPage()
   #endif

   DO WHILE .T.
      iItem := 1
      DO WHILE iItem <= Len(s_aPaintRep[FORM_ITEMS])
         aItem := s_aPaintRep[FORM_ITEMS, iItem]
         // hwg_WriteLog(Str(iItem, 3) + ": " + Str(aItem[ITEM_TYPE]))
         IF aItem[ITEM_TYPE] == TYPE_MARKER
            IF aItem[ITEM_CAPTION] == "PH"
               IF aItem[ITEM_STATE] == 0
                  aItem[ITEM_STATE] := 1
                  FOR i := 1 TO iPH - 1
                     IF s_aPaintRep[FORM_ITEMS, i, ITEM_TYPE] == TYPE_BITMAP
                        PrintItem(oPrinter, s_aPaintRep, s_aPaintRep[FORM_ITEMS, i], prnXCoef, prnYCoef, IIf(lAddMode, nYadd, 0), .T.)
                     ENDIF
                  NEXT
               ENDIF
            ELSEIF aItem[ITEM_CAPTION] == "SL"
               IF aItem[ITEM_STATE] == 0
                  // IF iPH == 0
                  FOR i := 1 TO iSL - 1
                     IF s_aPaintRep[FORM_ITEMS, i, ITEM_TYPE] == TYPE_BITMAP
                        PrintItem(oPrinter, s_aPaintRep, s_aPaintRep[FORM_ITEMS, i], prnXCoef, prnYCoef, IIf(lAddMode, nYadd, 0), .T.)
                     ENDIF
                  NEXT
                  // ENDIF
                  aItem[ITEM_STATE] := 1
                  IF !ScriptExecute(aItem)
                     #ifdef __DEBUG__
                        // hwg_WriteLog("Endpage")
                        // hwg_WriteLog("Enddoc")
                     #else
                        oPrinter:EndPage()
                        oPrinter:EndDoc()
                        oPrinter:END()
                     #endif
                     RETURN .F.
                  ENDIF
                  IF lLastCycle
                     iItem := iEL + 1
                     LOOP
                  ENDIF
               ENDIF
               lAddMode := .T.
            ELSEIF aItem[ITEM_CAPTION] == "EL"
               FOR i := iSL + 1 TO iEL - 1
                  IF s_aPaintRep[FORM_ITEMS, i, ITEM_TYPE] == TYPE_BITMAP
                     PrintItem(oPrinter, s_aPaintRep, s_aPaintRep[FORM_ITEMS, i], prnXCoef, prnYCoef, IIf(lAddMode, nYadd, 0), .T.)
                  ENDIF
               NEXT
               IF !ScriptExecute(aItem)
                  #ifdef __DEBUG__
                     // hwg_WriteLog("Endpage")
                     // hwg_WriteLog("Enddoc")
                  #else
                     oPrinter:EndPage()
                     oPrinter:EndDoc()
                     oPrinter:END()
                  #endif
                  RETURN .F.
               ENDIF
               IF !lLastCycle
                  nYadd += nLineHeight
                  // hwg_WriteLog(Str(nLineStartY) + " " + Str(nYadd) + " " + Str(nEndList))
                  IF nLineStartY + nYadd + nLineHeight >= nEndList
                     // hwg_WriteLog("New Page")
                     IF iPF == 0
                        #ifdef __DEBUG__
                           // hwg_WriteLog("Endpage")
                           // hwg_WriteLog("Startpage")
                        #else
                           oPrinter:EndPage()
                           oPrinter:StartPage()
                        #endif
                        nYadd := 10 - IIf(nPHStart > 0, nPHStart, nLineStartY)
                        lAddMode := .T.
                        IF iPH == 0
                           iItem := iSL
                        ELSE
                           iItem := iPH
                        ENDIF
                     ELSE
                        lAddMode := .F.
                     ENDIF
                  ELSE
                     iItem := iSL
                  ENDIF
               ELSE
                  lAddMode := .F.
               ENDIF
            ELSEIF aItem[ITEM_CAPTION] == "EPF"
               FOR i := iPF + 1 TO iEPF - 1
                  IF s_aPaintRep[FORM_ITEMS, i, ITEM_TYPE] == TYPE_BITMAP
                     PrintItem(oPrinter, s_aPaintRep, s_aPaintRep[FORM_ITEMS, i], prnXCoef, prnYCoef, IIf(lAddMode, nYadd, 0), .T.)
                  ENDIF
               NEXT
               IF !lLastCycle
                  #ifdef __DEBUG__
                     // hwg_WriteLog("Endpage")
                     // hwg_WriteLog("Startpage")
                  #else
                     oPrinter:EndPage()
                     oPrinter:StartPage()
                  #endif
                  nYadd := 10 - IIf(nPHStart > 0, nPHStart, nLineStartY)
                  lAddMode := .T.
                  IF iPH == 0
                     iItem := iSL
                  ELSE
                     iItem := iPH
                  ENDIF
               ENDIF
            ELSEIF aItem[ITEM_CAPTION] == "DF"
               lAddMode := .F.
               IF aItem[ITEM_ALIGN] == 1
               ENDIF
            ENDIF
         ELSE
            IF aItem[ITEM_TYPE] == TYPE_TEXT
               IF !ScriptExecute(aItem)
                  #ifdef __DEBUG__
                     // hwg_WriteLog("Endpage")
                     // hwg_WriteLog("Enddoc")
                  #else
                     oPrinter:EndPage()
                     oPrinter:EndDoc()
                  #endif
                  oPrinter:END()
                  RETURN .F.
               ENDIF
            ENDIF
            IF aItem[ITEM_TYPE] != TYPE_BITMAP
               PrintItem(oPrinter, s_aPaintRep, aItem, prnXCoef, prnYCoef, IIf(lAddMode, nYadd, 0), .T.)
            ENDIF
         ENDIF
         iItem++
      ENDDO
      FOR i := IIf(iSL == 0, 1, IIf(iDF > 0, iDF + 1, IIf(iPF > 0, iEPF + 1, iEL + 1))) TO Len(s_aPaintRep[FORM_ITEMS])
         IF s_aPaintRep[FORM_ITEMS, i, ITEM_TYPE] == TYPE_BITMAP
            PrintItem(oPrinter, s_aPaintRep, s_aPaintRep[FORM_ITEMS, i], prnXCoef, prnYCoef, IIf(lAddMode, nYadd, 0), .T.)
         ENDIF
      NEXT
      IF lFinish
         EXIT
      ENDIF
   ENDDO

   #ifdef __DEBUG__
      // hwg_WriteLog("Endpage")
      // hwg_WriteLog("Enddoc")
   #else
      oPrinter:EndPage()
      oPrinter:EndDoc()
      IF lPreview != NIL .AND. lPreview
         oPrinter:Preview()
      ENDIF
   #endif
   oPrinter:END()

   FOR i := 1 TO Len(s_aPaintRep[FORM_ITEMS])
      IF s_aPaintRep[FORM_ITEMS, i, ITEM_TYPE] == TYPE_TEXT
         s_aPaintRep[FORM_ITEMS, i, ITEM_STATE]:Release()
         s_aPaintRep[FORM_ITEMS, i, ITEM_STATE] := NIL
      ENDIF
   NEXT

   RETURN .T.

FUNCTION PrintItem(oPrinter, aPaintRep, aItem, prnXCoef, prnYCoef, nYadd, lCalc)
   LOCAL x1 := aItem[ITEM_X1], y1 := aItem[ITEM_Y1] + nYadd, x2, y2
   LOCAL hBitmap, stroka

   HB_SYMBOL_UNUSED(aPaintRep)

   x2 := x1 + aItem[ITEM_WIDTH] - 1
   y2 := y1 + aItem[ITEM_HEIGHT] - 1
   // hwg_WriteLog(Str(aItem[ITEM_TYPE]) + ": " + IIf(aItem[ITEM_TYPE] == TYPE_TEXT, aItem[ITEM_CAPTION], "") + Str(x1) + Str(y1) + Str(x2) + Str(y2))
   x1 := Round(x1 * prnXCoef, 0)
   y1 := Round(y1 * prnYCoef, 0)
   x2 := Round(x2 * prnXCoef, 0)
   y2 := Round(y2 * prnYCoef, 0)
   // hwg_WriteLog("PrintItem-2: " + Str(x1) + Str(y1) + Str(x2) + Str(y2))

   #ifdef __DEBUG__
      // hwg_WriteLog(Str(aItem[ITEM_TYPE]) + ": " + Str(x1) + " " + Str(y1) + " " + Str(x2) + " " + Str(y2) + " " + IIf(aItem[ITEM_TYPE] == TYPE_TEXT, aItem[ITEM_CAPTION] + IIf(aItem[ITEM_VAR] > 0, "(" + &(aItem[ITEM_CAPTION]) + ")", ""), ""))
   #else
      // hwg_WriteLog(Str(aItem[ITEM_TYPE]) + ": " + Str(x1) + " " + Str(y1) + " " + Str(x2) + " " + Str(y2) + " " + IIf(aItem[ITEM_TYPE] == TYPE_TEXT, aItem[ITEM_CAPTION] + IIf(aItem[ITEM_VAR] > 0, "(" + &(aItem[ITEM_CAPTION]) + ")", ""), ""))
      IF aItem[ITEM_TYPE] == TYPE_TEXT
         IF aItem[ITEM_VAR] > 0
            stroka := IIf(lCalc, &(aItem[ITEM_CAPTION]), "")
         ELSE
            stroka := aItem[ITEM_CAPTION]
         ENDIF
         IF !Empty(aItem[ITEM_CAPTION])
            oPrinter:Say(stroka, x1, y1, x2, y2, ;
                          IIf(aItem[ITEM_ALIGN] == 0, DT_LEFT, IIf(aItem[ITEM_ALIGN] == 1, DT_RIGHT, DT_CENTER)), ;
                          aItem[ITEM_STATE])
         ENDIF
      ELSEIF aItem[ITEM_TYPE] == TYPE_HLINE
         oPrinter:Line(x1, Round((y1 + y2) / 2, 0), x2, Round((y1 + y2) / 2, 0), aItem[ITEM_PEN])
      ELSEIF aItem[ITEM_TYPE] == TYPE_VLINE
         oPrinter:Line(Round((x1 + x2) / 2, 0), y1, Round((x1 + x2) / 2, 0), y2, aItem[ITEM_PEN])
      ELSEIF aItem[ITEM_TYPE] == TYPE_BOX
         oPrinter:Box(x1, y1, x2, y2, aItem[ITEM_PEN])
      ELSEIF aItem[ITEM_TYPE] == TYPE_BITMAP
         hBitmap := OpenBitmap(aItem[ITEM_CAPTION], oPrinter:hDC)
         // hwg_WriteLog("hBitmap: " + Str(hBitmap))
         oPrinter:Bitmap(x1, y1, x2, y2,, hBitmap)
         hwg_DeleteObject(hBitmap)
         // DrawBitmap(hDC, aItem[ITEM_BITMAP], SRCAND, x1, y1, x2 - x1 + 1, y2 - y1 + 1)
      ENDIF
   #endif
   RETURN NIL

STATIC FUNCTION ScriptExecute(aItem)
   LOCAL nError, nLineEr
   IF aItem[ITEM_SCRIPT] != NIL .AND. !Empty(aItem[ITEM_SCRIPT])
      IF hb_IsChar(aItem[ITEM_SCRIPT])
         IF (aItem[ITEM_SCRIPT] := RdScript(, aItem[ITEM_SCRIPT])) == NIL
            nError := CompileErr(@nLineEr)
            hwg_MsgStop("Script error (" + LTrim(Str(nError)) + "), line " + LTrim(Str(nLineEr)))
            RETURN .F.
         ENDIF
      ENDIF
      DoScript(aItem[ITEM_SCRIPT])
      RETURN .T.
   ENDIF
   RETURN .T.


