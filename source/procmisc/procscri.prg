/*
 * $Id: procscri.prg 1783 2011-10-20 11:24:27Z omm $
 *
 * Common procedures
 * Scripts
 *
 * Author: Alexander S.Kresin <alex@belacy.belgorod.su>
 *         www - http://kresin.belgorod.su
*/

#pragma -w1

#include "fileio.ch"
#define __WINDOWS__

Memvar iscr

STATIC nLastError, numlin, scr_RetValue
STATIC lDebugInfo := .F.
STATIC lDebugger := .F.
STATIC lDebugRun := .F.

#ifndef __WINDOWS__
STATIC y__size := 0, x__size := 0
#endif
#define STR_BUFLEN  1024

REQUEST __PP_STDRULES

FUNCTION OpenScript( fname, scrkod )
LOCAL han, stroka, scom, aScr, rejim := 0, i
LOCAL strbuf := Space(STR_BUFLEN), poz := STR_BUFLEN+1
LOCAL aFormCode, aFormName

   scrkod := IIF( scrkod==Nil, "000", Upper(scrkod) )
   han := FOPEN( fname, FO_READ + FO_SHARED )
   IF han != - 1
      DO WHILE .T.
         stroka := RDSTR( han,@strbuf,@poz,STR_BUFLEN )
         IF LEN( stroka ) = 0
            EXIT
         ELSEIF rejim == 0 .AND. Left( stroka,1 ) == "#"
            IF Upper(LEFT(stroka, 7)) == "#SCRIPT"
               scom := Upper(Ltrim(Substr(stroka, 9)))
               IF scom == scrkod
                  aScr := RdScript( han, @strbuf, @poz,,fname+","+scrkod )
                  EXIT
               ENDIF
            ELSEIF LEFT( stroka, 6 ) == "#BLOCK"
               scom := Upper(Ltrim(Substr(stroka, 8)))
               IF scom == scrkod
                  rejim     := - 1
                  aFormCode := {}
                  aFormName := {}
               ENDIF
            ENDIF
         ELSEIF rejim == -1 .AND. LEFT( stroka, 1 ) == "@"
            i := AT( " ", stroka )
            Aadd(aFormCode, SUBSTR( stroka, 2, i-2 ))
            Aadd(aFormName, SUBSTR( stroka, i+1 ))
         ELSEIF rejim == -1 .AND. LEFT( stroka, 9 ) == "#ENDBLOCK"
#ifdef __WINDOWS__
            i := WCHOICE(aFormName)
#else
            i := FCHOICE(aFormName)
#endif
            IF i == 0
               FCLOSE(han)
               RETURN Nil
            ENDIF
            rejim  := 0
            scrkod := aFormCode[i]
         ENDIF
      ENDDO
      FCLOSE(han)
   ELSE
#ifdef __WINDOWS__
      HWG_MsgStop(fname + " can't be opened ")
#else
      ALERT( fname + " can't be opened " )
#endif
      RETURN Nil
   ENDIF
RETURN aScr

FUNCTION RdScript( scrSource, strbuf, poz, lppNoInit, cTitle )
STATIC s_pp
LOCAL han
LOCAL rezArray := Iif( lDebugInfo, { "", {}, {} }, { "", {} } )

   IF lppNoInit == Nil
      lppNoInit := .F.
   ENDIF
   IF poz == Nil
      poz := 1
   ENDIF
   IF cTitle != Nil
      rezArray[1] := cTitle
   ENDIF
   nLastError := 0
   IF scrSource == Nil
      han := Nil
      poz := 0
   ELSEIF hb_IsChar(scrSource)
      strbuf := SPACE(STR_BUFLEN)
      poz    := STR_BUFLEN+1
      han    := FOPEN( scrSource, FO_READ + FO_SHARED )
   ELSE
      han := scrSource
   ENDIF
   IF han == Nil .OR. han != - 1
      IF !lppNoInit .or. s_pp == NIL
         s_pp := __pp_init()
      ENDIF
      IF hb_IsChar(scrSource)
         WndOut( "Compiling ..." )
         WndOut( "" )
      ENDIF
      numlin := 0
      IF !CompileScr( s_pp, han, @strbuf, @poz, rezArray, scrSource )
         rezArray := Nil
      ENDIF
      IF scrSource != Nil .AND. hb_IsChar(scrSource)
         WndOut()
         FCLOSE(han)
      ENDIF
      IF !lppNoInit
         s_pp := NIL
      ENDIF
   ELSE
#ifdef __WINDOWS__
      HWG_MsgStop("Can't open " + scrSource)
#else
      WndOut( "Can't open " + scrSource )
      WAIT ""
      WndOut()
#endif
      nLastError := -1
      RETURN Nil
   ENDIF
RETURN rezArray

STATIC FUNCTION COMPILESCR( pp, han, strbuf, poz, rezArray, scrSource )
LOCAL scom, poz1, stroka, strfull := "", bOldError, i, tmpArray := {}
Local cLine, lDebug := ( Len( rezArray ) >= 3 )

   DO WHILE .T.
      cLine := RDSTR( han, @strbuf, @poz, STR_BUFLEN )
      IF LEN( cLine ) = 0
         EXIT
      ENDIF
      numlin ++
      IF Right( cLine,1 ) == ';'
         strfull += Left( cLine,Len(cLine)-1 )
         LOOP
      ELSE
         IF !Empty(strfull)
            cLine := strfull + cLine
         ENDIF
         strfull := ""
      ENDIF
      stroka := RTRIM( LTRIM( cLine ) )
      IF RIGHT( stroka, 1 ) == CHR(26)
         stroka := LEFT( stroka, LEN( stroka ) - 1 )
      ENDIF
      IF !Empty(stroka) .AND. LEFT( stroka, 2 ) != "//"

         IF Left( stroka,1 ) == "#"
            IF UPPER(Left(stroka, 7)) == "#ENDSCR"
               Return .T.
            ELSEIF UPPER(Left(stroka, 6)) == "#DEBUG"
               IF !lDebug .AND. Len( rezArray[2] ) == 0
                  lDebug := .T.
                  Aadd(rezArray, {})
                  IF SUBSTR( stroka,7,3 ) == "GER"
                     AADD(rezArray[2], stroka)
                     AADD(tmpArray, "")
                     Aadd(rezArray[3], Str( numlin,4 ) + ":" + cLine)
                  ENDIF
               ENDIF
               LOOP
#ifdef __HARBOUR__
            ELSE
               __pp_process( pp, stroka )
               LOOP
#endif
            ENDIF
#ifdef __HARBOUR__
         ELSE
            stroka := __pp_process( pp, stroka )
#endif
         ENDIF

         poz1 := AT( " ", stroka )
         scom := UPPER(SUBSTR(stroka, 1, IIF(poz1 != 0, poz1 - 1, 999)))
         DO CASE
         CASE scom == "PRIVATE" .OR. scom == "PARAMETERS" .OR. scom == "LOCAL"
            IF LEN( rezArray[2] ) == 0 .OR. ( i := VALTYPE(ATAIL( rezArray[2] )) ) == "C" ;
                    .OR. i == "A"
               IF Left( scom,2 ) == "LO"
                  AADD(rezArray[2], " "+ALLTRIM( SUBSTR( stroka, 7 ) ))
               ELSEIF Left( scom,2 ) == "PR"
                  AADD(rezArray[2], " "+ALLTRIM( SUBSTR( stroka, 9 ) ))
               ELSE
                  AADD(rezArray[2], "/"+ALLTRIM( SUBSTR( stroka, 12 ) ))
               ENDIF
               AADD(tmpArray, "")
            ELSE
               nLastError := 1
               RETURN .F.
            ENDIF
         CASE (scom == "DO" .AND. UPPER(SUBSTR(stroka, 4, 5)) == "WHILE") .OR. scom == "WHILE"
            AADD(tmpArray, stroka)
            AADD(rezArray[2], .F.)
         CASE scom == "ENDDO"
            IF !Fou_Do( rezArray[2], tmpArray )
               nLastError := 2
               RETURN .F.
            ENDIF
         CASE scom == "EXIT"
            AADD(tmpArray, "EXIT")
            AADD(rezArray[2], .F.)
         CASE scom == "LOOP"
            AADD(tmpArray, "LOOP")
            AADD(rezArray[2], .F.)
         CASE scom == "IF"
            AADD(tmpArray, stroka)
            AADD(rezArray[2], .F.)
         CASE scom == "ELSEIF"
            IF !Fou_If( rezArray, tmpArray, .T. )
               nLastError := 3
               RETURN .F.
            ENDIF
            AADD(tmpArray, SUBSTR( stroka, 5 ))
            AADD(rezArray[2], .F.)
         CASE scom == "ELSE"
            IF !Fou_If( rezArray, tmpArray, .T. )
               nLastError := 1
               RETURN .F.
            ENDIF
            AADD(tmpArray, "IF .T.")
            AADD(rezArray[2], .F.)
         CASE scom == "ENDIF"
            IF !Fou_If( rezArray, tmpArray, .F. )
               nLastError := 1
               RETURN .F.
            ENDIF
         CASE scom == "RETURN"
            bOldError := ERRORBLOCK( { | e | MacroError(1,e,stroka) } )
            BEGIN SEQUENCE
               AADD(rezArray[2], &( "{||EndScript("+Ltrim( Substr( stroka,7 ) )+")}" ))
            RECOVER
               IF scrSource != Nil .AND. hb_IsChar(scrSource)
                  WndOut()
                  FCLOSE(han)
               ENDIF
               ERRORBLOCK( bOldError )
               RETURN .F.
            END SEQUENCE
            ERRORBLOCK( bOldError )
            AADD(tmpArray, "")
         CASE scom == "FUNCTION"
            stroka := Ltrim( Substr( stroka,poz1+1 ) )
            poz1 := At( "(",stroka )
            scom := UPPER(LEFT(stroka, IIF(poz1 != 0, poz1 - 1, 999)))
            AADD(rezArray[2], Iif( lDebug,{ scom,{},{} },{ scom,{} } ))
            AADD(tmpArray, "")
            IF !CompileScr( pp, han, @strbuf, @poz, rezArray[2,Len(rezArray[2])] )
               RETURN .F.
            ENDIF
         CASE scom == "#ENDSCRIPT" .OR. Left( scom,7 ) == "ENDFUNC"
            RETURN .T.
         OTHERWISE
            bOldError := ERRORBLOCK( { | e | MacroError(1,e,stroka) } )
            BEGIN SEQUENCE
               AADD(rezArray[2], &( "{||" + ALLTRIM( stroka ) + "}" ))
            RECOVER
               IF scrSource != Nil .AND. hb_IsChar(scrSource)
                  WndOut()
                  FCLOSE(han)
               ENDIF
               ERRORBLOCK( bOldError )
               RETURN .F.
            END SEQUENCE
            ERRORBLOCK( bOldError )
            AADD(tmpArray, "")
         ENDCASE
         IF lDebug .AND. Len( rezArray[3] ) < Len( rezArray[2] )
            Aadd(rezArray[3], Str( numlin,4 ) + ":" + cLine)
         ENDIF
      ENDIF
   ENDDO
RETURN .T.

STATIC FUNCTION MacroError( nm, e, stroka )
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
        stroka += Chr(13)+Chr(10) + "Called from " + ProcName(n) + "(" + AllTrim( Str( ProcLine(n++) ) ) + ")"
      ENDDO
      stroka := ErrorMessage(e)+ Chr(10)+Chr(13) + stroka
      cTitle := "Script execution error"
   ENDIF
   stroka += Chr(13)+Chr(10) + Chr(13)+Chr(10) + "Continue ?"
   IF !msgYesNo( stroka, cTitle )
      EndWindow()
      QUIT
   ENDIF
#else
   IF nm == 1
      ALERT( "Error in;" + AllTrim(stroka) )
   ELSEIF nm == 2
      Alert( "Script variables error" )
   ELSEIF nm == 3
      stroka += ";" + ErrorMessage(e)
      n := 2
      DO WHILE !Empty(ProcName(n))
        stroka += ";Called from " + ProcName(n) + "(" + AllTrim( Str( ProcLine(n++) ) ) + ")"
      ENDDO
      Alert( "Script execution error:;"+stroka )
   ENDIF
#endif
   BREAK
RETURN .T. // Warning W0028  Unreachable code

STATIC FUNCTION Fou_If( rezArray, tmpArray, prju )
LOCAL i, j, bOldError

   IF prju
      AADD(tmpArray, "JUMP")
      AADD(rezArray[2], .F.)
      IF Len( rezArray ) >= 3
         Aadd(rezArray[3], Str( numlin,4 ) + ":JUMP")
      ENDIF
   ENDIF
   j := LEN( rezArray[2] )
   FOR i := j TO 1 STEP - 1
      IF UPPER(LEFT(tmpArray[i], 2)) == "IF"
         bOldError := ERRORBLOCK( { | e | MacroError(1,e,tmpArray[i]) } )
         BEGIN SEQUENCE
            rezArray[2, i] := &( "{||IIF(" + ALLTRIM( SUBSTR( tmpArray[i], 4 ) ) + ;
                 ",.T.,iscr:=" + LTRIM( STR( j, 5 ) ) + ")}" )
         RECOVER
            ERRORBLOCK( bOldError )
            RETURN .F.
         END SEQUENCE
         ERRORBLOCK( bOldError )
         tmpArray[i] := ""
         i --
         IF i > 0 .AND. tmpArray[i] == "JUMP"
            rezArray[2, i] := &( "{||iscr:=" + LTRIM( STR( IIF( prju, j - 1, j ), 5 ) ) + "}" )
            tmpArray[i] := ""
         ENDIF
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

STATIC FUNCTION Fou_Do( rezArray, tmpArray )
LOCAL i, j, iloop := 0
//LOCAL iPos (variable not used)
LOCAL bOldError

   j := LEN( rezArray )
   FOR i := j TO 1 STEP - 1
      IF !Empty(tmpArray[i]) .AND. LEFT( tmpArray[i], 4 ) == "EXIT"
         rezArray[i] = &( "{||iscr:=" + LTRIM( STR( j + 1, 5 ) ) + "}" )
         tmpArray[i] = ""
      ENDIF
      IF !Empty(tmpArray[i]) .AND. LEFT( tmpArray[i], 4 ) == "LOOP"
         iloop := i
      ENDIF
      IF !Empty(tmpArray[i]) .AND. (UPPER(LEFT(tmpArray[i], 8)) = "DO WHILE" .OR. ;
         UPPER(LEFT(tmpArray[i], 5)) = "WHILE")
         bOldError := ERRORBLOCK( { | e | MacroError(1,e,tmpArray[i] ) } )
         BEGIN SEQUENCE
            rezArray[i] = &( "{||IIF(" + ALLTRIM( SUBSTR( tmpArray[i], ;
                 IIF(UPPER(LEFT(tmpArray[i], 1)) == "D", 10, 7))) + ;
                 ",.T.,iscr:=" + LTRIM( STR( j + 1, 5 ) ) + ")}" )
         RECOVER
            ERRORBLOCK( bOldError )
            RETURN .F.
         END SEQUENCE
         ERRORBLOCK( bOldError )
         tmpArray[i] = ""
         AADD(rezArray, &( "{||iscr:=" + LTRIM( STR( i - 1, 5 ) ) + "}" ))
         AADD(tmpArray, "")
         IF iloop > 0
            rezArray[iloop] = &( "{||iscr:=" + LTRIM( STR( i - 1, 5 ) ) + "}" )
            tmpArray[iloop] = ""
         ENDIF
         RETURN .T.
      ENDIF
   NEXT
RETURN .F.

FUNCTION DoScript( aScript, aParams )
LOCAL arlen, stroka, varName, varValue, lDebug, lParam, j, RetValue, lSetDebugger := .F.
MEMVAR iscr, bOldError, aScriptt
PRIVATE iscr := 1, bOldError

   scr_RetValue := Nil
   IF Type("aScriptt") != "A"
      Private aScriptt := aScript
   ENDIF
   IF aScript == Nil .OR. ( arlen := Len( aScript[2] ) ) == 0
      Return .T.
   ENDIF
   lDebug := ( Len( aScript ) >= 3 )
   DO WHILE !hb_IsBlock(aScript[2, iscr])
      IF hb_IsChar(aScript[2, iscr])
         IF Left( aScript[2, iscr],1 ) == "#"
            IF !lDebugger
               lSetDebugger := .T.
               SetDebugger()
            ENDIF
         ELSE
            stroka := Substr( aScript[2, iscr],2 )
            lParam := ( Left( aScript[2, iscr],1 ) == "/" )
            bOldError := ERRORBLOCK( { | e | MacroError(2,e) } )
            BEGIN SEQUENCE
            j := 1
            DO WHILE !Empty(varName := getNextVar( @stroka, @varValue ))
               PRIVATE &varName
               IF varvalue != Nil
                  &varName := &varValue
               ENDIF
               IF lParam .AND. aParams != Nil .AND. Len(aParams) >= j
                  &varname = aParams[j]
               ENDIF
               j ++
            ENDDO
            RECOVER
               WndOut()
               ERRORBLOCK( bOldError )
               Return .F.
            END SEQUENCE
            ERRORBLOCK( bOldError )
         ENDIF
      ENDIF
      iscr ++
   ENDDO
   IF lDebug
      bOldError := ERRORBLOCK( { | e | MacroError(3,e,aScript[3,iscr]) } )
   ELSE
      bOldError := ERRORBLOCK( { | e | MacroError(3,e,LTrim(Str(iscr))) } )
   ENDIF
   BEGIN SEQUENCE
      IF lDebug .AND. lDebugger
         DO WHILE iscr > 0 .AND. iscr <= arlen
#ifdef __WINDOWS__
            IF lDebugger
               lDebugRun := .F.
               hwg_scrDebug( aScript,iscr )
               DO WHILE !lDebugRun
                  hwg_ProcessMessage()
               ENDDO
            ENDIF
#endif
            EVAL( aScript[2, iscr] )
            iscr ++
         ENDDO
#ifdef __WINDOWS__
         hwg_scrDebug( aScript,0 )
         IF lSetDebugger
            SetDebugger( .F. )
         ENDIF
#endif
      ELSE
         DO WHILE iscr > 0 .AND. iscr <= arlen
            EVAL( aScript[2, iscr] )
            iscr ++
         ENDDO
      ENDIF
   RECOVER
      WndOut()
      ERRORBLOCK( bOldError )
#ifdef __WINDOWS__
      IF lDebug .AND. lDebugger
         hwg_scrDebug( aScript,0 )
      ENDIF
#endif
      Return .F.
   END SEQUENCE
   ERRORBLOCK( bOldError )
   WndOut()

   RetValue := scr_RetValue
/*   scr_RetValue := Nil */
RETURN RetValue

FUNCTION CallFunc(cProc, aParams, aScript)
Local i := 1
MEMVAR aScriptt

   IF aScript == Nil
      aScript := aScriptt
   ENDIF
   scr_RetValue := Nil
   cProc := Upper(cProc)
   DO WHILE i <= Len(aScript[2]) .AND. hb_IsArray(aScript[2, i])
      IF aScript[2,i,1] == cProc
         DoScript( aScript[2,i],aParams )
         EXIT
      ENDIF
      i ++
   ENDDO

RETURN scr_RetValue

FUNCTION EndScript( xRetValue )
   scr_RetValue := xRetValue
   iscr := -99
RETURN Nil

FUNCTION CompileErr( nLine )
   nLine := numlin
RETURN nLastError

FUNCTION Codeblock( string )
   IF Left( string,2 ) == "{|"
      Return &( string )
   ENDIF
RETURN &("{||"+string+"}")

FUNCTION SetDebugInfo( lDebug )

   lDebugInfo := Iif( lDebug==Nil, .T., lDebug )
RETURN .T.

FUNCTION SetDebugger( lDebug )

   lDebugger := Iif( lDebug==Nil, .T., lDebug )
RETURN .T.

FUNCTION SetDebugRun()

   lDebugRun := .T.
RETURN .T.


#ifdef __WINDOWS__

STATIC FUNCTION WndOut()
RETURN Nil

#else

FUNCTION WndOut( sout, noscroll, prnew )
LOCAL y1, x1, y2, x2, oldc, ly__size := (y__size != 0)
STATIC w__buf
   IF sout == Nil .AND. !ly__size
      Return Nil
   ENDIF
   IF y__size == 0
      y__size := 5
      x__size := 30
      prnew   := .T.
   ELSEIF prnew == Nil
      prnew := .F.
   ENDIF
   y1 := 13 - INT( y__size / 2 )
   x1 := 41 - INT( x__size / 2 )
   y2 := y1 + y__size
   x2 := x1 + x__size
   IF sout == Nil
      RESTSCREEN( y1, x1, y2, x2, w__buf )
      y__size := 0
   ELSE
      oldc := SETCOLOR("N/W")
      IF prnew
         w__buf := SAVESCREEN( y1, x1, y2, x2 )
         @ y1, x1, y2, x2 BOX "谀砍倌莱 "
      ELSEIF noscroll = Nil
         SCROLL( y1 + 1, x1 + 1, y2 - 1, x2 - 1, 1 )
      ENDIF
      @ y2 - 1, x1 + 2 SAY sout
      SETCOLOR(oldc)
   ENDIF
RETURN Nil

*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
*+    Function WndGet()
*+
*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
FUNCTION WndGet( sout, varget, spict )

LOCAL y1, x1, y2, x2, oldc
LOCAL GetList := {}
   WndOut( sout )
   y1   := 13 - INT( y__size / 2 )
   x1   := 41 - INT( x__size / 2 )
   y2   := y1 + y__size
   x2   := x1 + x__size
   oldc := SETCOLOR("N/W")
   IF LEN( sout ) + IIF( spict = "@D", 8, LEN( spict ) ) > x__size - 3
      SCROLL( y1 + 1, x1 + 1, y2 - 1, x2 - 1, 1 )
   ELSE
      x1 += LEN( sout ) + 1
   ENDIF
   @ y2 - 1, x1 + 2 GET varget PICTURE spict
   READ
   SETCOLOR(oldc)
RETURN IIF( LASTKEY() = 27, Nil, varget )

*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
*+    Function WndOpen()
*+
*+北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北北
*+
FUNCTION WndOpen( ysize, xsize )

   y__size := ysize
   x__size := xsize
   WndOut( "",, .T. )
RETURN Nil
#endif
