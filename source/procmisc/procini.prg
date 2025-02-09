//
// $Id: procini.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// Common procedures
// Ini files reading
//
// Author: Alexander S.Kresin <alex@belacy.belgorod.su>
//         www - http://www.geocities.com/alkresin/
//

/*
 Function Rdini scans file line by line, creates variables ( if they doesn't
 declared yet ) as Public and asiignes them values.
 File format:
      ...
      [SECTION1_NAME]
      ...
      [SECTION2_NAME]
      ...
 Function reads variables from beginning of file until first section
 and from sections, named in function call.
 Comments must have symbol ';' in the first position of a line.
 Symbol '&' indicate continue on the next line.
 Variables may be logical:

    var_name=On
    var_name=Off
    var_name=

  character:

    var_name="stroka"

  numeric:

    var_name=999

  codeblock:

    var_name={|| ... }

  array of any structure, including all types of variables:

    var_name={ ... { ... } ... }

 Syntax: Rdini ( ini_file_name, [section1_name], [section2_name],;
                 [section3_name], [section4_name] ),
   where ini_file_name - name of .ini - file you want to read,
   section1_name, ..., section4_name - names of sections in .ini - file
    which you want to read.
*/

#include "fileio.ch"
#define STR_BUFLEN  1024

FUNCTION RDINI(fname, prm1, prm2, prm3, prm4)

LOCAL han, stroka, strfull, kolstr
//LOCAL rez (variable not used)
LOCAL poz1, vname
//LOCAL i (variable not used)
LOCAL prblo, lTruncAr
LOCAL lWinIni  := (hb_IsArray(prm1))
LOCAL strbuf := Space(STR_BUFLEN), poz := STR_BUFLEN+1
LOCAL iniDbf := (Upper(FilExten(fname)) == "DBF")

   kolstr := 0
   prblo  := .T.
   IF iniDbf
      USE (fname) NEW
      han := IIf(NetErr(), -1, 0)
   ELSE
      han    := FOpen(fname, FO_READ + FO_SHARED)
   ENDIF
   IF han != - 1
      strfull := ""
      DO WHILE .T.
         kolstr++
         stroka := IIf(iniDbf, RDSTRDBF(), RDSTR(han, @strbuf, @poz, STR_BUFLEN))
         IF Len(stroka) == 0
            EXIT
         ENDIF
         IF Right(stroka, 2) == "&&"
            strfull += Left(stroka, Len(stroka) - 2)
            LOOP
         ELSEIF Right(stroka, 1) == "&"
            strfull += Left(stroka, Len(stroka) - 1)
            LOOP
         ELSE
            IF !Empty(strfull)
               stroka := strfull + stroka
            ENDIF
            strfull := ""
         ENDIF
         //
         IF Left(stroka, 1) = "["
            stroka := Upper(SubStr(stroka, 2, At("]", stroka) - 2))
            IF lWinIni
               AAdd(prm1, {Upper(stroka), {}})
            ELSE
               prblo := .F.
               SET EXACT ON
               IF stroka == prm1 .OR. stroka == prm2 .OR. stroka == prm3 .OR. stroka == prm4
                  prblo := .T.
               ENDIF
               SET EXACT OFF
            ENDIF
         ELSEIF (prblo .OR. lWinIni) .AND. Left(stroka, 1) != ";"
            poz1 := At("=", stroka)
            IF poz1 != 0
               lTruncAr := IIf(SubStr(stroka, poz1 - 1, 1) == "+", .F., .T.)
               vname    := RTrim(SubStr(stroka, 1, IIf(lTruncAr, poz1 - 1, poz1 - 2)))
               stroka   := AllTrim(SubStr(stroka, poz1 + 1))
               IF lWinIni
                  AAdd(prm1[Len(prm1), 2], {Upper(vname), stroka})
               ELSE
                  IF Type(vname) = "U"
                     IF Asc(stroka) == 123                 // {
                        IF Asc(vname) == 35                // #
                           vname := SubStr(vname, 2)
                           PRIVATE &vname := {}
                        ELSE
                           PUBLIC &vname := {}
                        ENDIF
                     ELSE
                        IF Asc(vname) == 35                // #
                           vname := SubStr(vname, 2)
                           PRIVATE &vname
                        ELSE
                           PUBLIC &vname
                        ENDIF
                     ENDIF
                  ELSE
                     IF lTruncAr .AND. Asc(stroka) == 123 .AND. Len(&vname) > 0
                        ASize(&vname, 0)
                     ENDIF
                  ENDIF
                  DO CASE
                  CASE stroka = "on" .OR. stroka = "ON" .OR. stroka = "On"
                     &vname := .T.
                  CASE stroka = "off" .OR. stroka = "OFF" .OR. stroka = "Off" .OR. Empty(stroka)
                     &vname := .F.
                  CASE Asc(stroka) == 123 .AND. SubStr(stroka, 2, 1) != "|"  // {
                     RDARR(vname, stroka)
                  OTHERWISE
                     &vname := RDZNACH(stroka)
                  ENDCASE
               ENDIF
            ENDIF
            //
         ENDIF
      ENDDO
      FClose(han)
   ELSE
      RETURN 0
   ENDIF
   IF iniDbf
      USE
   ENDIF
RETURN kolstr

STATIC FUNCTION RDZNACH(ps)

LOCAL poz, znc
   ps := AllTrim(ps)
   IF Asc(ps) == 34
      poz := At(Chr(34), SubStr(ps, 2))
      IF poz != 0
         znc := SubStr(ps, 2, poz - 1)
      ENDIF
   ELSE
      znc := &ps
   ENDIF
RETURN znc

STATIC FUNCTION RDARR(vname, stroka)

LOCAL poz1
//LOCAL i := 0 (variable/value not used)
//LOCAL lenm (variable not used)
LOCAL len1, strv, newname
   poz1 := FIND_Z(SubStr(stroka, 2), "}")
   IF poz1 != 0
      stroka := SubStr(stroka, 2, poz1 - 1)
      //lenm   := Len(&vname) (value not used)
      DO WHILE poz1 != 0
         IF Empty(stroka)
            EXIT
         ELSE
            //i++ (value not used)
            poz1 := FIND_Z(stroka)
            strv := LTrim(SubStr(stroka, 1, IIf(poz1 == 0, 9999, poz1 - 1)))
            IF Asc(strv) == 123 .AND. SubStr(strv, 2, 1) != "|"              // {
               AAdd(&vname, {})
               len1    := Len(&vname)
               newname := vname + "[" + LTrim(Str(len1, 3)) + "]"
               RDARR(newname, strv)
            ELSE
               AAdd(&vname, RDZNACH(strv))
            ENDIF
            stroka := SubStr(stroka, poz1 + 1)
         ENDIF
      ENDDO
   ENDIF
RETURN NIL

STATIC FUNCTION RDSTRDBF
LOCAL stroka
FIELD INICOND, INITEXT
   IF Eof()
      RETURN ""
   ENDIF
   stroka := IIf(Empty(INICOND) .OR. &(INICOND), Trim(INITEXT), "")
   SKIP
RETURN stroka
