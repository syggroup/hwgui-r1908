//
// Mysql client ( Harbour + HWGUI )
// Main file
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "fileio.ch"
#include "hwgui.ch"
#include "hwmysql.h"

REQUEST BRWPROC
REQUEST DEFWNDPROC
REQUEST DBSTRUCT
REQUEST FIELDGET
REQUEST PADL
REQUEST OEMTOANSI
REQUEST OPENREPORT

MEMVAR connHandle
MEMVAR cServer
MEMVAR cDatabase
MEMVAR cUser
MEMVAR cDataDef
MEMVAR queHandle
MEMVAR nNumFields
MEMVAR nNumRows
MEMVAR aQueries

FUNCTION Main()

   LOCAL oFont
   LOCAL oIcon := HIcon():AddResource("ICON_1")

   PUBLIC hBitmap := LoadBitmap("BITMAP_1")
   PUBLIC connHandle := 0
   PUBLIC cServer := ""
   PUBLIC cDatabase := ""
   PUBLIC cUser := ""
   PUBLIC cDataDef := ""
   PUBLIC mypath := "\" + CurDir() + IIf(Empty(CurDir()), "", "\")
   PUBLIC queHandle := 0
   PUBLIC nNumFields
   PUBLIC nNumRows
   PUBLIC aQueries := {}
   PUBLIC nHistCurr
   PUBLIC nHistoryMax := 20

   PRIVATE oBrw
   PRIVATE BrwFont := NIL
   PRIVATE oBrwFont := NIL
   PRIVATE oMainWindow
   PRIVATE oEdit
   PRIVATE oPanel
   PRIVATE oPanelE

   SET EPOCH TO 1960
   SET DATE FORMAT "dd/mm/yyyy"

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -12
   INIT WINDOW oMainWindow MAIN ICON oIcon COLOR COLOR_3DLIGHT ;
       TITLE "Harbour mySQL client"                            ;
       AT 20, 20 SIZE 500, 500

   ADD STATUS TO oMainWindow PARTS 0, 0, 0
   @ 0, 380 EDITBOX oEdit CAPTION ""      ;
       SIZE 476, 95                       ;
       ON SIZE {|o, x, y|ResizeEditQ(x, y)} ;
       STYLE ES_MULTILINE+ES_AUTOVSCROLL+ES_AUTOHSCROLL

   @ 0, 0 PANEL oPanel SIZE 0, 44

   @ 2, 3 OWNERBUTTON OF oPanel ID 108 ON CLICK {||Connect()} ;
        SIZE 80, 40 FLAT ;
        TEXT "Connect" FONT oFont COORDINATES 0, 20, 0, 0;
        BITMAP "BMP_NETWORK" FROM RESOURCE COORDINATES 0, 4, 0, 0
   @ 82, 3 OWNERBUTTON OF oPanel ID 109 ON CLICK {||Databases()} ;
        SIZE 80, 40 FLAT ;
        TEXT "Database" FONT oFont COORDINATES 0, 20, 0, 0;
        BITMAP "BMP_OPNPRJ" FROM RESOURCE COORDINATES 0, 4, 0, 0
   @ 162, 3 OWNERBUTTON OF oPanel ID 110 ON CLICK {||Tables()} ;
        SIZE 80, 40 FLAT ;
        TEXT "Tables" FONT oFont COORDINATES 0, 20, 0, 0;
        BITMAP "BMP_TABLE" FROM RESOURCE COORDINATES 0, 4, 0, 0
   @ 242, 3 OWNERBUTTON OF oPanel ID 111 ON CLICK {||Execute()} ;
        SIZE 80, 40 FLAT ;
        TEXT "Execute" FONT oFont COORDINATES 0, 20, 0, 0;
        BITMAP "BMP_BROWSE" FROM RESOURCE COORDINATES 0, 4, 0, 0
   @ 322, 3 OWNERBUTTON OF oPanel ID 112 ON CLICK {||About()} ;
        SIZE 80, 40 FLAT ;
        TEXT "About" FONT oFont COORDINATES 0, 20, 0, 0 ;
        BITMAP "BMP_HELP" FROM RESOURCE COORDINATES 0, 4, 0, 0
   @ 402, 3 OWNERBUTTON OF oPanel ID 113 ON CLICK {||hwg_EndWindow()} ;
        SIZE 80, 40 FLAT ;
        TEXT "Exit" FONT oFont COORDINATES 0, 20, 0, 0 ;
        BITMAP "BMP_EXIT" FROM RESOURCE COORDINATES 0, 4, 0, 0

   @ 0, 0 PANEL oPanelE OF oMainWindow SIZE 0, 24 ON SIZE {||.T.}

   @ 0, 2 OWNERBUTTON OF oPanelE ID 114 ON CLICK {||oEdit:SetText(Memoread(hwg_SelectFile("Script files( *.scr )", "*.scr", mypath)))};
        SIZE 20, 22 FLAT ;
        BITMAP "BMP_OPEN" FROM RESOURCE TOOLTIP "Load script"
   @ 0, 24 OWNERBUTTON OF oPanelE ID 115 ON CLICK {||SaveScript()} ;
        SIZE 20, 22 FLAT ;
        BITMAP "BMP_SAVE" FROM RESOURCE TOOLTIP "Save script"
   @ 0, 46 OWNERBUTTON OF oPanelE ID 116 ON CLICK {||BrowHistory()} ;
        SIZE 20, 22 FLAT ;
        BITMAP "BMP_HIST" FROM RESOURCE TOOLTIP "Show history"
   @ 0, 68 OWNERBUTTON OF oPanelE ID 117 ON CLICK {||oEdit:SetText(""), hwg_SetFocus(oEdit:handle)} ;
        SIZE 20, 22 FLAT ;
        BITMAP "BMP_CLEAR" FROM RESOURCE TOOLTIP "Clear"

   @ 0, 0 BROWSE oBrw ARRAY OF oMainWindow SIZE 500, 376 ;
           ON SIZE {|o, x, y|ResizeBrwQ(o, x, y)}
   oBrw:active := .F.

   Rdini("demo.ini")
   IF ValType(BrwFont) == "A"
      oBrwFont := HFont():Add(BrwFont[1], BrwFont[2], BrwFont[3])
   ENDIF
   ReadHistory("qhistory.txt")

   WriteStatus(Hwindow():GetMain(), 1, "Not Connected")
   hwg_SetFocus(oEdit:handle)
   // hwg_HideWindow(oBrw:handle)
   SetCtrlFont(oEdit:oParent:handle, oEdit:id, oBrwFont:handle)

   ACTIVATE WINDOW oMainWindow

   WriteHistory("qhistory.txt")

RETURN NIL

FUNCTION About()

   LOCAL oModDlg
   LOCAL oFont

   INIT DIALOG oModDlg FROM RESOURCE "ABOUTDLG" ON PAINT {||AboutDraw()}
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13 ITALIC UNDERLINE

   REDEFINE OWNERBUTTON OF oModDlg ID IDC_OWNB1 ON CLICK {||EndDialog(getmodalhandle())} ;
       FLAT TEXT "Close" COLOR VColor("0000FF") FONT oFont

   oModDlg:Activate()

RETURN NIL

FUNCTION AboutDraw()

   LOCAL pps
   LOCAL hDC

   pps := hwg_DefinePaintStru()
   hDC := hwg_BeginPaint(getmodalhandle(), pps)
   DrawBitmap(hDC, hBitmap,, 0, 0)
   hwg_EndPaint(getmodalhandle(), pps)

RETURN NIL

FUNCTION DataBases()

   LOCAL aBases
   LOCAL nChoic

   IF connHandle == 0
      Connect()
      IF connHandle == 0
         RETURN .F.
      ENDIF
   ENDIF
   aBases := sqlListDB(connHandle)
   nChoic := WChoice(aBases, "DataBases", 0, 50)
   IF nChoic != 0
      cDatabase := aBases[nChoic]
      IF sqlSelectD(connHandle, cDatabase) != 0
         hwg_MsgStop("Can't connect to "+cDataBase)
         cDatabase := ""
      ELSE
         WriteStatus(Hwindow():GetMain(), 2, "DataBase: " + cDataBase)
      ENDIF
   ENDIF

RETURN NIL

FUNCTION Tables()

   LOCAL aTables
   LOCAL nChoic
   LOCAL cTable

   IF connHandle == 0
      Connect()
      IF connHandle == 0
         RETURN .F.
      ENDIF
   ENDIF
   aTables := sqlListTbl(connHandle)
   IF Empty(aTables)
      hwg_MsgInfo("No tables !")
      RETURN .F.
   ENDIF

   nChoic := WChoice(aTables, cDataBase + "  tables", 50, 50)
   IF nChoic != 0
      cTable := aTables[nChoic]
      execSQL("SHOW COLUMNS FROM " + cTable)
   ENDIF

RETURN NIL

FUNCTION Connect()

   LOCAL aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DIALOG_1" ON INIT {||InitConnect()}
   DIALOG ACTIONS OF aModDlg ;
          ON 0, IDOK     ACTION {||EndConnect()} ;
          ON 0, IDCANCEL ACTION {||EndDialog(getmodalhandle())}

   aModDlg:Activate()

RETURN NIL

FUNCTION InitConnect()

   LOCAL hDlg := getmodalhandle()

   hwg_SetDlgItemText(hDlg, IDC_EDIT1, cServer)
   hwg_SetDlgItemText(hDlg, IDC_EDIT2, cUser)
   hwg_SetDlgItemText(hDlg, IDC_EDIT4, cDataDef)
   IF Empty(cServer)
      hwg_SetFocus(hwg_GetDlgItem(hDlg, IDC_EDIT1))
   ELSEIF Empty(cUser)
      hwg_SetFocus(hwg_GetDlgItem(hDlg, IDC_EDIT2))
   ELSE
      hwg_SetFocus(hwg_GetDlgItem(hDlg, IDC_EDIT3))
   ENDIF

RETURN .F.

FUNCTION EndConnect()

   LOCAL hDlg := getmodalhandle()

   IF connHandle > 0
      sqlClose(connHandle)
      connHandle := 0
      IF queHandle > 0
         sqlFreeR(queHandle)
         queHandle := 0
      ENDIF
   ENDIF
   cServer := hwg_GetDlgItemText(hDlg, IDC_EDIT1, 30)
   cUser := hwg_GetDlgItemText(hDlg, IDC_EDIT2, 20)
   cPassword := hwg_GetDlgItemText(hDlg, IDC_EDIT3, 20)
   cDataDef := get_GetDlgItemText(hDlg, IDC_EDIT4, 20)

   hwg_SetDlgItemText(hDlg, IDC_TEXT1, "Wait, please ...")
   connHandle := sqlConnect(cServer, Trim(cUser), Trim(cPassword))
   IF connHandle != 0 .AND. !Empty(cDataDef)
      cDatabase := cDataDef
      IF sqlSelectD(connHandle, cDatabase) != 0
         cDatabase := ""
         hwg_SetDlgItemText(hDlg, IDC_TEXT1, "Can't connect to " + cDataBase)
      ENDIF
   ELSE
      hwg_SetDlgItemText(hDlg, IDC_TEXT1, "Can't connect to " + cServer)
      cDatabase := ""
   ENDIF
   IF connHandle == 0
      WriteStatus(Hwindow():GetMain(), 1, "Not Connected")
      WriteStatus(Hwindow():GetMain(), 2, "")
      hwg_SetFocus(hwg_GetDlgItem(hDlg, IDC_EDIT1))
   ELSE
      WriteStatus(Hwindow():GetMain(), 1, "Connected to " + cServer)
      IF !Empty(cDataBase)
         WriteStatus(Hwindow():GetMain(), 2, "DataBase: " + cDataBase)
      ENDIF
      EndDialog(hDlg)
      hwg_SetFocus(oEdit:handle)
   ENDIF

RETURN NIL

FUNCTION ResizeEditQ(nWidth, nHeight)

   hwg_MoveWindow(oEdit:handle, 0, nHeight-oMainWindow:aOffset[4]-95, nWidth-24, 95)
   hwg_MoveWindow(oPanelE:handle, nWidth-23, nHeight-oMainWindow:aOffset[4]-95, 24, 95)

RETURN NIL

FUNCTION ResizeBrwQ(oBrw, nWidth, nHeight)

   LOCAL aRect
   LOCAL i
   LOCAL nHbusy := oMainWindow:aOffset[4]

   aRect := hwg_GetClientRect(oEdit:handle)
   nHbusy += aRect[4]
   hwg_MoveWindow(oBrw:handle, 0, oPanel:nHeight+1, nWidth, nHeight-nHBusy-oPanel:nHeight-8)

RETURN NIL

FUNCTION Execute()

   LOCAL cQuery := Ltrim(oEdit:GetText())
   LOCAL arScr
   LOCAL nError
   LOCAL nLineEr

   IF Empty(cQuery)
      RETURN .F.
   ENDIF
   IF Left(cQuery, 2) == "//"
      IF ( arScr := RdScript(, cQuery) ) <> Nil
         DoScript(arScr)
      ELSE
         nError := CompileErr(@nLineEr)
         hwg_MsgStop("Script error ("+Ltrim(Str(nError))+"), line "+Ltrim(Str(nLineEr)))
      ENDIF
   ELSE
      execSQL(cQuery)
   ENDIF

RETURN .T.

FUNCTION execSQL(cQuery)

   LOCAL res
   LOCAL stroka
   LOCAL poz := 0
   LOCAL lFirst := .T.
   LOCAL i := 1

   IF connHandle == 0
      Connect()
      IF connHandle == 0
         RETURN .F.
      ENDIF
   ENDIF
   IF ( res := sqlQuery(connHandle, cQuery)) != 0
      cQuery := ""
      hwg_MsgInfo("Operation failed: " + STR(res) + "( " + sqlGetErr(connHandle) + " )")
      WriteStatus(Hwindow():GetMain(), 3, sqlGetErr(connHandle))
   ELSE
      IF nHistCurr < nHistoryMax
         DO WHILE Len(stroka := RDSTR(Nil,@cQuery,@poz)) != 0
            IF Asc(Ltrim(stroka)) > 32
               Aadd(aQueries, Nil)
               Ains(aQueries, i)
               aQueries[i] := { Padr(stroka, 76), lFirst }
               lFirst := .F.
               i ++
            ENDIF
         ENDDO
         Aadd(aQueries, Nil)
         Ains(aQueries, i)
         aQueries[i] := { Space(76), .F. }
         nHistCurr ++
      ENDIF
      IF ( queHandle := sqlStoreR(connHandle) ) != 0
         sqlBrowse(queHandle)
      ELSE
         // Should query have returned rows? (Was it a SELECT like query?)
         IF ( nNumFields := sqlFiCou(connHandle) ) == 0
            // Was not a SELECT so reset ResultHandle changed by previous sqlStoreR()
            WriteStatus(Hwindow():GetMain(), 3, Str(sqlAffRows(connHandle)) + " rows updated.")
         ELSE
            @ 20, 2 SAY "Operation failed:" + sqlGetErr(connHandle)
            hwg_MsgInfo("Operation failed: " + "( " + sqlGetErr(connHandle) + " )")
            WriteStatus(Hwindow():GetMain(), 3, sqlGetErr(connHandle))
            res := -1
         ENDIF
      ENDIF
   ENDIF

RETURN res == 0

FUNCTION sqlBrowse(queHandle)

   LOCAL aQueRows
   LOCAL i
   LOCAL j
   LOCAL vartmp
   LOCAL af := {}

   nNumRows := sqlNRows(queHandle)
   WriteStatus(Hwindow():GetMain(), 3, Str(nNumRows, 5) + " rows")
   IF nNumRows == 0
      RETURN NIL
   ENDIF
   oBrw:InitBrw()
   oBrw:active := .T.
   nNumFields := sqlNumFi(queHandle)
   aQueRows := Array(nNumRows)

   FOR i := 1 TO nNumRows
      aQueRows[i] := sqlFetchR(queHandle)
      IF i == 1
         FOR j := 1 TO nNumFields
            AAdd(af, {ValType(aQueRows[i, j]), 0, 0})
         NEXT
      ENDIF
      FOR j := 1 TO nNumFields
         IF af[j, 1] == "C"
            af[j, 2] := Max(af[j, 2], Len(aQueRows[i, j]))
         ELSEIF af[j, 1] == "N"
            vartmp := STR(aQueRows[i, j])
            af[j, 2] := Max(af[j, 2], Len(vartmp))
            af[j, 3] := Max(af[j, 3], IIf("." $ vartmp, af[j, 2] - AT(".", vartmp), 0))
         ELSEIF af[j, 1] == "D"
            af[j, 2] := 8
         ELSEIF af[j, 1] == "L"
            af[j, 2] := 1
         ENDIF
      NEXT
   NEXT
   hwg_CreateArList(oBrw, aQueRows)
   FOR i := 1 TO nNumFields
      oBrw:aColumns[i]:heading := SqlFetchF(queHandle)[1]
      oBrw:aColumns[i]:type := af[i, 1]
      oBrw:aColumns[i]:length := af[i, 2]
      oBrw:aColumns[i]:dec := af[i, 3]
   NEXT
   oBrw:bcolorSel := VColor("800080")
   oBrw:ofont := oBrwFont
   hwg_RedrawWindow(oBrw:handle, RDW_ERASE + RDW_INVALIDATE)

RETURN NIL

FUNCTION BrowHistory()

   IF nHistCurr == 0
      RETURN NIL
   ENDIF
   oBrw:active := .T.
   oBrw:InitBrw()
   oBrw:aArray := aQueries
   oBrw:AddColumn(HColumn():New("History of queries", {|value, o|o:aArray[o:nCurrent, 1]}, "C", 76, 0))

   oBrw:bcolorSel := VColor("800080")
   oBrw:ofont := oBrwFont
   oBrw:bEnter := {|h, o|GetFromHistory(h, o)}
   hwg_RedrawWindow(oBrw:handle, RDW_ERASE + RDW_INVALIDATE)

RETURN NIL

STATIC FUNCTION GetFromHistory()

   LOCAL cQuery := ""
   LOCAL i := oBrw:nCurrent

   IF !Empty(oBrw:aArray[i, 1])
      DO WHILE !oBrw:aArray[i, 2]; i--; ENDDO
      DO WHILE i <= oBrw:nRecords .AND. !Empty(oBrw:aArray[i, 1])
         cQuery += Rtrim(oBrw:aArray[i, 1]) + Chr(13) + Chr(10)
         i++
      ENDDO
      oEdit:SetText(cQuery)
      hwg_SetFocus(oEdit:handle)
   ENDIF

RETURN NIL

STATIC FUNCTION ReadHistory(fname)

   LOCAL han
   LOCAL stroka
   LOCAL lFirst := .T.
   LOCAL lEmpty := .F.
   LOCAL strbuf := Space(512)
   LOCAL poz := 513

   nHistCurr := 0
   han := FOpen(fname, FO_READ + FO_SHARED)
   IF han <> - 1
      DO WHILE .T.
         stroka := RDSTR(han,@strbuf,@poz, 512)
         IF Len(stroka) == 0
            EXIT
         ENDIF
         IF Left(stroka, 1) == Chr(10) .OR. Left(stroka, 1) == Chr(13)
            lEmpty := .T.
         ELSE
            IF lEmpty .AND. nHistCurr > 0
               Aadd(aQueries, { Space(76), .F. })
               lFirst := .T.
            ENDIF
            lEmpty := .F.
            Aadd(aQueries, { Padr(stroka, 76), lFirst })
            IF lFirst
               nHistCurr ++
            ENDIF
            lFirst := .F.
         ENDIF
      ENDDO
      FClose(han)
   ENDIF

RETURN nHistCurr

STATIC FUNCTION WriteHistory(fname)

   LOCAL han
   LOCAL i
   LOCAL lEmpty := .T.

   IF !Empty(aQueries)
      han := FCreate(fname)
      IF han <> - 1
         FOR i := 1 TO Len(aQueries)
            IF !Empty(aQueries[i, 1]) .OR. !lEmpty
               FWrite(han, Trim(aQueries[i, 1]) + Chr(13) + Chr(10))
               lEmpty := Empty(aQueries[i, 1])
            ENDIF
         NEXT
         FClose(han)
      ENDIF
   ENDIF

RETURN NIL

FUNCTION DoSQL(cQuery)

   LOCAL aRes
   LOCAL qHandle
   LOCAL nNumFields
   LOCAL nNumRows
   LOCAL i

   IF sqlQuery(connHandle, cQuery) != 0
      RETURN {1}
   ELSE
      IF ( qHandle := sqlStoreR(connHandle) ) != 0
         nNumRows := sqlNRows(qHandle)
         nNumFields := sqlNumFi(qHandle)
         aRes := { 0, Array(nNumFields), Array(nNumRows) }
         FOR i := 1 TO nNumFields
            aRes[2, i] := SqlFetchF(qHandle)[1]
         NEXT
         FOR i := 1 TO nNumRows
            aRes[3, i] := sqlFetchR(qHandle)
         NEXT
         sqlFreeR(qHandle)
         RETURN aRes
      ELSE
         // Should query have returned rows? (Was it a SELECT like query?)
         IF sqlFiCou(connHandle) == 0
            // Was not a SELECT so reset ResultHandle changed by previous sqlStoreR()
            RETURN {0, sqlAffRows(connHandle)}
         ELSE
            RETURN {2}
         ENDIF
      ENDIF
   ENDIF

RETURN NIL

FUNCTION FilExten(fname)

   LOCAL i

RETURN IIf(( i := RAT(".", fname) ) = 0, "", SubStr(fname, i + 1))

FUNCTION SaveScript()

   LOCAL fname := hwg_SaveFile("*.scr", "Script files( *.scr )", "*.scr", mypath)

   cQuery := oEdit:GetText()
   IF !Empty(fname)
      MemoWrit(fname, cQuery)
   ENDIF

RETURN NIL

FUNCTION WndOut()
RETURN NIL

FUNCTION MsgSay(cText)

   hwg_MsgStop(cText)

RETURN NIL

EXIT PROCEDURE cleanup

   IF connHandle > 0
      sqlClose(connHandle)
      IF queHandle > 0
         sqlFreeR(queHandle)
      ENDIF
   ENDIF

RETURN
