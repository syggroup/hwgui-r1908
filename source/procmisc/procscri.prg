//
// $Id: procscri.prg 1783 2011-10-20 11:24:27Z omm $
//
// Common procedures
// Scripts
//
// Author: Alexander S.Kresin <alex@belacy.belgorod.su>
//         www - http://kresin.belgorod.su
//

#pragma -w1

#include "fileio.ch"
#ifndef __WINDOWS__
#define __WINDOWS__
#endif

Memvar iscr

STATIC s_nLastError, s_numlin, s_scr_RetValue
STATIC s_lDebugInfo := .F.
STATIC s_lDebugger := .F.
STATIC s_lDebugRun := .F.

#ifndef __WINDOWS__
STATIC s_y__size := 0, s_x__size := 0
#endif
#define STR_BUFLEN  1024

REQUEST __PP_STDRULES

FUNCTION OpenScript(fname, scrkod)
LOCAL han, stroka, scom, aScr, rejim := 0, i
LOCAL strbuf := Space(STR_BUFLEN), poz := STR_BUFLEN+1
LOCAL aFormCode, aFormName

   scrkod := IIf(scrkod == NIL, "000", Upper(scrkod))
   han := FOpen(fname, FO_READ + FO_SHARED)
   IF han != - 1
      DO WHILE .T.
         stroka := RDSTR(han, @strbuf, @poz, STR_BUFLEN)
         IF Len(stroka) == 0
            EXIT
         ELSEIF rejim == 0 .AND. Left(stroka, 1) == "#"
            IF Upper(Left(stroka, 7)) == "#SCRIPT"
               scom := Upper(Ltrim(SubStr(stroka, 9)))
               IF scom == scrkod
                  aScr := RdScript(han, @strbuf, @poz, , fname + "," + scrkod)
                  EXIT
               ENDIF
            ELSEIF Left(stroka, 6) == "#BLOCK"
               scom := Upper(Ltrim(SubStr(stroka, 8)))
               IF scom == scrkod
                  rejim     := - 1
                  aFormCode := {}
                  aFormName := {}
               ENDIF
            ENDIF
         ELSEIF rejim == -1 .AND. Left(stroka, 1) == "@"
            i := At(" ", stroka)
            AAdd(aFormCode, SubStr(stroka, 2, i - 2))
            AAdd(aFormName, SubStr(stroka, i + 1))
         ELSEIF rejim == -1 .AND. Left(stroka, 9) == "#ENDBLOCK"
#ifdef __WINDOWS__
            i := WCHOICE(aFormName)
#else
            i := FCHOICE(aFormName)
#endif
            IF i == 0
               FClose(han)
               RETURN NIL
            ENDIF
            rejim  := 0
            scrkod := aFormCode[i]
         ENDIF
      ENDDO
      FClose(han)
   ELSE
#ifdef __WINDOWS__
      hwg_MsgStop(fname + " can't be opened ")
#else
      Alert(fname + " can't be opened ")
#endif
      RETURN NIL
   ENDIF
RETURN aScr

FUNCTION RdScript(scrSource, strbuf, poz, lppNoInit, cTitle)
STATIC s_pp
LOCAL han
LOCAL rezArray := IIf(s_lDebugInfo, {"", {}, {}}, {"", {}})

   IF lppNoInit == NIL
      lppNoInit := .F.
   ENDIF
   IF poz == NIL
      poz := 1
   ENDIF
   IF cTitle != NIL
      rezArray[1] := cTitle
   ENDIF
   s_nLastError := 0
   IF scrSource == NIL
      han := NIL
      poz := 0
   ELSEIF hb_IsChar(scrSource)
      strbuf := Space(STR_BUFLEN)
      poz    := STR_BUFLEN+1
      han    := FOPEN(scrSource, FO_READ + FO_SHARED)
   ELSE
      han := scrSource
   ENDIF
   IF han == NIL .OR. han != - 1
      IF !lppNoInit .OR. s_pp == NIL
         s_pp := __pp_init()
      ENDIF
      IF hb_IsChar(scrSource)
         WndOut("Compiling ...")
         WndOut("")
      ENDIF
      s_numlin := 0
      IF !CompileScr(s_pp, han, @strbuf, @poz, rezArray, scrSource)
         rezArray := NIL
      ENDIF
      IF scrSource != NIL .AND. hb_IsChar(scrSource)
         WndOut()
         FCLOSE(han)
      ENDIF
      IF !lppNoInit
         s_pp := NIL
      ENDIF
   ELSE
#ifdef __WINDOWS__
      hwg_MsgStop("Can't open " + scrSource)
#else
      WndOut("Can't open " + scrSource)
      WAIT ""
      WndOut()
#endif
      s_nLastError := -1
      RETURN NIL
   ENDIF
RETURN rezArray

STATIC FUNCTION COMPILESCR(pp, han, strbuf, poz, rezArray, scrSource)
LOCAL scom, poz1, stroka, strfull := "", bOldError, i, tmpArray := {}
Local cLine, lDebug := (Len(rezArray) >= 3)

   DO WHILE .T.
      cLine := RDSTR(han, @strbuf, @poz, STR_BUFLEN)
      IF Len(cLine) == 0
         EXIT
      ENDIF
      s_numlin++
      IF Right(cLine, 1) == ";"
         strfull += Left(cLine, Len(cLine) - 1)
         LOOP
      ELSE
         IF !Empty(strfull)
            cLine := strfull + cLine
         ENDIF
         strfull := ""
      ENDIF
      stroka := RTrim(LTrim(cLine))
      IF Right(stroka, 1) == Chr(26)
         stroka := Left(stroka, Len(stroka) - 1)
      ENDIF
      IF !Empty(stroka) .AND. Left(stroka, 2) != "//"

         IF Left(stroka, 1) == "#"
            IF Upper(Left(stroka, 7)) == "#ENDSCR"
               RETURN .T.
            ELSEIF Upper(Left(stroka, 6)) == "#DEBUG"
               IF !lDebug .AND. Len(rezArray[2]) == 0
                  lDebug := .T.
                  AAdd(rezArray, {})
                  IF SubStr(stroka, 7, 3) == "GER"
                     AAdd(rezArray[2], stroka)
                     AAdd(tmpArray, "")
                     AAdd(rezArray[3], Str(s_numlin, 4) + ":" + cLine)
                  ENDIF
               ENDIF
               LOOP
#ifdef __HARBOUR__
            ELSE
               __pp_process(pp, stroka)
               LOOP
#endif
            ENDIF
#ifdef __HARBOUR__
         ELSE
            stroka := __pp_process(pp, stroka)
#endif
         ENDIF

         poz1 := At(" ", stroka)
         scom := Upper(SubStr(stroka, 1, IIf(poz1 != 0, poz1 - 1, 999)))
         DO CASE
         CASE scom == "PRIVATE" .OR. scom == "PARAMETERS" .OR. scom == "LOCAL"
            IF Len(rezArray[2]) == 0 .OR. (i := ValType(ATail(rezArray[2]))) == "C" .OR. i == "A"
               IF Left(scom, 2) == "LO"
                  AAdd(rezArray[2], " " + AllTrim(SubStr(stroka, 7)))
               ELSEIF Left(scom, 2) == "PR"
                  AAdd(rezArray[2], " " + AllTrim(SubStr(stroka, 9)))
               ELSE
                  AAdd(rezArray[2], "/" + AllTrim(SubStr(stroka, 12)))
               ENDIF
               AAdd(tmpArray, "")
            ELSE
               s_nLastError := 1
               RETURN .F.
            ENDIF
         CASE (scom == "DO" .AND. Upper(SubStr(stroka, 4, 5)) == "WHILE") .OR. scom == "WHILE"
            AAdd(tmpArray, stroka)
            AAdd(rezArray[2], .F.)
         CASE scom == "ENDDO"
            IF !Fou_Do(rezArray[2], tmpArray)
               s_nLastError := 2
               RETURN .F.
            ENDIF
         CASE scom == "EXIT"
            AAdd(tmpArray, "EXIT")
            AAdd(rezArray[2], .F.)
         CASE scom == "LOOP"
            AAdd(tmpArray, "LOOP")
            AAdd(rezArray[2], .F.)
         CASE scom == "IF"
            AAdd(tmpArray, stroka)
            AAdd(rezArray[2], .F.)
         CASE scom == "ELSEIF"
            IF !Fou_If(rezArray, tmpArray, .T.)
               s_nLastError := 3
               RETURN .F.
            ENDIF
            AAdd(tmpArray, SubStr(stroka, 5))
            AAdd(rezArray[2], .F.)
         CASE scom == "ELSE"
            IF !Fou_If(rezArray, tmpArray, .T.)
               s_nLastError := 1
               RETURN .F.
            ENDIF
            AAdd(tmpArray, "IF .T.")
            AAdd(rezArray[2], .F.)
         CASE scom == "ENDIF"
            IF !Fou_If(rezArray, tmpArray, .F.)
               s_nLastError := 1
               RETURN .F.
            ENDIF
         CASE scom == "RETURN"
            bOldError := ErrorBlock({|e|MacroError(1, e, stroka)})
            BEGIN SEQUENCE
               AAdd(rezArray[2], &("{||EndScript(" + LTrim(SubStr(stroka, 7)) + ")}"))
            RECOVER
               IF scrSource != NIL .AND. hb_IsChar(scrSource)
                  WndOut()
                  FCLOSE(han)
               ENDIF
               ErrorBlock(bOldError)
               RETURN .F.
            END SEQUENCE
            ErrorBlock(bOldError)
            AAdd(tmpArray, "")
         CASE scom == "FUNCTION"
            stroka := LTrim(SubStr(stroka, poz1 + 1))
            poz1 := At("(", stroka)
            scom := Upper(Left(stroka, IIf(poz1 != 0, poz1 - 1, 999)))
            AAdd(rezArray[2], IIf(lDebug, {scom, {}, {}}, {scom, {}}))
            AAdd(tmpArray, "")
            IF !CompileScr(pp, han, @strbuf, @poz, rezArray[2, Len(rezArray[2])])
               RETURN .F.
            ENDIF
         CASE scom == "#ENDSCRIPT" .OR. Left(scom, 7) == "ENDFUNC"
            RETURN .T.
         OTHERWISE
            bOldError := ErrorBlock({|e|MacroError(1, e, stroka)})
            BEGIN SEQUENCE
               AAdd(rezArray[2], &("{||" + AllTrim(stroka) + "}"))
            RECOVER
               IF scrSource != NIL .AND. hb_IsChar(scrSource)
                  WndOut()
                  FCLOSE(han)
               ENDIF
               ErrorBlock(bOldError)
               RETURN .F.
            END SEQUENCE
            ErrorBlock(bOldError)
            AAdd(tmpArray, "")
         ENDCASE
         IF lDebug .AND. Len(rezArray[3]) < Len(rezArray[2])
            AAdd(rezArray[3], Str(s_numlin, 4) + ":" + cLine)
         ENDIF
      ENDIF
   ENDDO
RETURN .T.

STATIC FUNCTION MacroError(nm, e, stroka)
Local n, cTitle

#ifdef __WINDOWS__
   IF nm == 1
      stroka := ErrorMessage(e) + Chr(10)+Chr(13) + "in" + Chr(10)+Chr(13) + ;
                      AllTrim(stroka)
      cTitle := "Script compiling error"
   ELSEIF nm == 2
      stroka := ErrorMessage(e)
      cTitle := "Script variables error"
   ELSEIF nm == 3
      n := 2
      DO WHILE !Empty(ProcName(n))
        stroka += Chr(13)+Chr(10) + "Called from " + ProcName(n) + "(" + AllTrim(Str(ProcLine(n++))) + ")"
      ENDDO
      stroka := ErrorMessage(e)+ Chr(10)+Chr(13) + stroka
      cTitle := "Script execution error"
   ENDIF
   stroka += Chr(13)+Chr(10) + Chr(13)+Chr(10) + "Continue ?"
   IF !hwg_MsgYesNo(stroka, cTitle)
      hwg_EndWindow()
      QUIT
   ENDIF
#else
   IF nm == 1
      Alert("Error in;" + AllTrim(stroka))
   ELSEIF nm == 2
      Alert("Script variables error")
   ELSEIF nm == 3
      stroka += ";" + ErrorMessage(e)
      n := 2
      DO WHILE !Empty(ProcName(n))
        stroka += ";Called from " + ProcName(n) + "(" + AllTrim(Str(ProcLine(n++))) + ")"
      ENDDO
      Alert("Script execution error:;" + stroka)
   ENDIF
#endif
   BREAK
RETURN .T. // Warning W0028  Unreachable code

STATIC FUNCTION Fou_If(rezArray, tmpArray, prju)
LOCAL i, j, bOldError

   IF prju
      AAdd(tmpArray, "JUMP")
      AAdd(rezArray[2], .F.)
      IF Len(rezArray) >= 3
         AAdd(rezArray[3], Str(s_numlin, 4) + ":JUMP")
      ENDIF
   ENDIF
   j := Len(rezArray[2])
   FOR i := j TO 1 STEP - 1
      IF Upper(Left(tmpArray[i], 2)) == "IF"
         bOldError := ErrorBlock({|e|MacroError(1, e, tmpArray[i])})
         BEGIN SEQUENCE
            rezArray[2, i] := &("{||IIF(" + AllTrim(SubStr(tmpArray[i], 4)) + ;
                 ",.T.,iscr:=" + LTrim(Str(j, 5)) + ")}")
         RECOVER
            ErrorBlock(bOldError)
            RETURN .F.
         END SEQUENCE
         ErrorBlock(bOldError)
         tmpArray[i] := ""
         i--
         IF i > 0 .AND. tmpArray[i] == "JUMP"
            rezArray[2, i] := &("{||iscr:=" + LTrim(Str(IIf(prju, j - 1, j), 5)) + "}")
            tmpArray[i] := ""
         ENDIF
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

STATIC FUNCTION Fou_Do(rezArray, tmpArray)
LOCAL i, j, iloop := 0
//LOCAL iPos (variable not used)
LOCAL bOldError

   j := Len(rezArray)
   FOR i := j TO 1 STEP - 1
      IF !Empty(tmpArray[i]) .AND. Left(tmpArray[i], 4) == "EXIT"
         rezArray[i] = &("{||iscr:=" + LTrim(Str(j + 1, 5)) + "}")
         tmpArray[i] = ""
      ENDIF
      IF !Empty(tmpArray[i]) .AND. Left(tmpArray[i], 4) == "LOOP"
         iloop := i
      ENDIF
      IF !Empty(tmpArray[i]) .AND. (Upper(Left(tmpArray[i], 8)) = "DO WHILE" .OR. ;
         Upper(Left(tmpArray[i], 5)) = "WHILE")
         bOldError := ErrorBlock({|e|MacroError(1, e, tmpArray[i])})
         BEGIN SEQUENCE
            rezArray[i] = &("{||IIF(" + AllTrim(SubStr(tmpArray[i], ;
                 IIf(Upper(Left(tmpArray[i], 1)) == "D", 10, 7))) + ;
                 ",.T.,iscr:=" + LTrim(Str(j + 1, 5)) + ")}")
         RECOVER
            ErrorBlock(bOldError)
            RETURN .F.
         END SEQUENCE
         ErrorBlock(bOldError)
         tmpArray[i] = ""
         AAdd(rezArray, &("{||iscr:=" + LTrim(Str(i - 1, 5)) + "}"))
         AAdd(tmpArray, "")
         IF iloop > 0
            rezArray[iloop] = &("{||iscr:=" + LTrim(Str(i - 1, 5)) + "}")
            tmpArray[iloop] = ""
         ENDIF
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

FUNCTION DoScript(aScript, aParams)
LOCAL arlen, stroka, varName, varValue, lDebug, lParam, j, RetValue, lSetDebugger := .F.
MEMVAR iscr, bOldError, aScriptt
PRIVATE iscr := 1, bOldError

   s_scr_RetValue := NIL
   IF Type("aScriptt") != "A"
      Private aScriptt := aScript
   ENDIF
   IF aScript == NIL .OR. (arlen := Len(aScript[2])) == 0
      RETURN .T.
   ENDIF
   lDebug := (Len(aScript) >= 3)
   DO WHILE !hb_IsBlock(aScript[2, iscr])
      IF hb_IsChar(aScript[2, iscr])
         IF Left(aScript[2, iscr], 1) == "#"
            IF !s_lDebugger
               lSetDebugger := .T.
               SetDebugger()
            ENDIF
         ELSE
            stroka := SubStr(aScript[2, iscr], 2)
            lParam := (Left(aScript[2, iscr], 1) == "/")
            bOldError := ErrorBlock({|e|MacroError(2, e)})
            BEGIN SEQUENCE
            j := 1
            DO WHILE !Empty(varName := getNextVar(@stroka, @varValue))
               PRIVATE &varName
               IF varvalue != NIL
                  &varName := &varValue
               ENDIF
               IF lParam .AND. aParams != NIL .AND. Len(aParams) >= j
                  &varname := aParams[j]
               ENDIF
               j++
            ENDDO
            RECOVER
               WndOut()
               ErrorBlock(bOldError)
               RETURN .F.
            END SEQUENCE
            ErrorBlock(bOldError)
         ENDIF
      ENDIF
      iscr++
   ENDDO
   IF lDebug
      bOldError := ErrorBlock({|e|MacroError(3, e, aScript[3, iscr])})
   ELSE
      bOldError := ErrorBlock({|e|MacroError(3, e, LTrim(Str(iscr)))})
   ENDIF
   BEGIN SEQUENCE
      IF lDebug .AND. s_lDebugger
         DO WHILE iscr > 0 .AND. iscr <= arlen
#ifdef __WINDOWS__
            IF s_lDebugger
               s_lDebugRun := .F.
               hwg_scrDebug(aScript, iscr)
               DO WHILE !s_lDebugRun
                  hwg_ProcessMessage()
               ENDDO
            ENDIF
#endif
            Eval(aScript[2, iscr])
            iscr++
         ENDDO
#ifdef __WINDOWS__
         hwg_scrDebug(aScript, 0)
         IF lSetDebugger
            SetDebugger(.F.)
         ENDIF
#endif
      ELSE
         DO WHILE iscr > 0 .AND. iscr <= arlen
            Eval(aScript[2, iscr])
            iscr++
         ENDDO
      ENDIF
   RECOVER
      WndOut()
      ErrorBlock(bOldError)
#ifdef __WINDOWS__
      IF lDebug .AND. s_lDebugger
         hwg_scrDebug(aScript, 0)
      ENDIF
#endif
      RETURN .F.
   END SEQUENCE
   ErrorBlock(bOldError)
   WndOut()

   RetValue := s_scr_RetValue
/*   s_scr_RetValue := NIL */
RETURN RetValue

FUNCTION CallFunc(cProc, aParams, aScript)
Local i := 1
MEMVAR aScriptt

   IF aScript == NIL
      aScript := aScriptt
   ENDIF
   s_scr_RetValue := NIL
   cProc := Upper(cProc)
   DO WHILE i <= Len(aScript[2]) .AND. hb_IsArray(aScript[2, i])
      IF aScript[2, i, 1] == cProc
         DoScript(aScript[2, i], aParams)
         EXIT
      ENDIF
      i++
   ENDDO

RETURN s_scr_RetValue

FUNCTION EndScript(xRetValue)
   s_scr_RetValue := xRetValue
   iscr := -99
RETURN NIL

FUNCTION CompileErr(nLine)
   nLine := s_numlin
RETURN s_nLastError

FUNCTION Codeblock(string)
   IF Left(string, 2) == "{|"
      RETURN &(string)
   ENDIF
RETURN &("{||" + string + "}")

FUNCTION SetDebugInfo(lDebug)

   s_lDebugInfo := IIf(lDebug == NIL, .T., lDebug)
RETURN .T.

FUNCTION SetDebugger(lDebug)

   s_lDebugger := IIf(lDebug == NIL, .T., lDebug)
RETURN .T.

FUNCTION SetDebugRun()

   s_lDebugRun := .T.
RETURN .T.


#ifdef __WINDOWS__

STATIC FUNCTION WndOut()
RETURN NIL

#else

FUNCTION WndOut(sout, noscroll, prnew)
LOCAL y1, x1, y2, x2, oldc, ly__size := (s_y__size != 0)
STATIC w__buf
   IF sout == NIL .AND. !ly__size
      RETURN NIL
   ENDIF
   IF s_y__size == 0
      s_y__size := 5
      s_x__size := 30
      prnew   := .T.
   ELSEIF prnew == NIL
      prnew := .F.
   ENDIF
   y1 := 13 - INT(s_y__size / 2)
   x1 := 41 - INT(s_x__size / 2)
   y2 := y1 + s_y__size
   x2 := x1 + s_x__size
   IF sout == NIL
      RESTSCREEN(y1, x1, y2, x2, w__buf)
      s_y__size := 0
   ELSE
      oldc := SETCOLOR("N/W")
      IF prnew
         w__buf := SAVESCREEN(y1, x1, y2, x2)
         @ y1, x1, y2, x2 BOX "谀砍倌莱 "
      ELSEIF noscroll == NIL
         SCROLL(y1 + 1, x1 + 1, y2 - 1, x2 - 1, 1)
      ENDIF
      @ y2 - 1, x1 + 2 SAY sout
      SETCOLOR(oldc)
   ENDIF
RETURN NIL

*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
*+    Function WndGet()
*+
*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
FUNCTION WndGet(sout, varget, spict)

LOCAL y1, x1, y2, x2, oldc
LOCAL GetList := {}
   WndOut(sout)
   y1   := 13 - INT(s_y__size / 2)
   x1   := 41 - INT(s_x__size / 2)
   y2   := y1 + s_y__size
   x2   := x1 + s_x__size
   oldc := SETCOLOR("N/W")
   IF Len(sout) + IIf(spict = "@D", 8, Len(spict)) > s_x__size - 3
      SCROLL(y1 + 1, x1 + 1, y2 - 1, x2 - 1, 1)
   ELSE
      x1 += Len(sout) + 1
   ENDIF
   @ y2 - 1, x1 + 2 GET varget PICTURE spict
   READ
   SETCOLOR(oldc)
RETURN IIf(LASTKEY() == 27, NIL, varget)

*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
*+    Function WndOpen()
*+
*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
FUNCTION WndOpen(ysize, xsize)

   s_y__size := ysize
   s_x__size := xsize
   WndOut("",, .T.)
RETURN NIL
#endif
