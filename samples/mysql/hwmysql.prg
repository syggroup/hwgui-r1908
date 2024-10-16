/*
 * Mysql client ( Harbour + HWGUI )
 * Main file
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

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

Memvar connHandle, cServer, cDatabase, cUser, cDataDef, queHandle, nNumFields
Memvar nNumRows, aQueries

Function Main()
Local oFont, oIcon := HIcon():AddResource("ICON_1")
Public hBitmap := LoadBitmap( "BITMAP_1" )
Public connHandle := 0, cServer := "", cDatabase := "", cUser := ""
Public cDataDef := ""
Public mypath := "\" + CURDIR() + IIF( EMPTY( CURDIR() ), "", "\" )
Public queHandle := 0, nNumFields, nNumRows
Public aQueries := {}, nHistCurr, nHistoryMax := 20
Private oBrw, BrwFont := Nil, oBrwFont := Nil
Private oMainWindow, oEdit, oPanel, oPanelE

   SET EPOCH TO 1960
   SET DATE FORMAT "dd/mm/yyyy"

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -12
   INIT WINDOW oMainWindow MAIN ICON oIcon COLOR COLOR_3DLIGHT ;
       TITLE "Harbour mySQL client"                            ;
       AT 20,20 SIZE 500,500

   ADD STATUS TO oMainWindow PARTS 0,0,0
   @ 0,380 EDITBOX oEdit CAPTION ""      ;
       SIZE 476,95                       ;
       ON SIZE {|o,x,y|ResizeEditQ(x,y)} ;
       STYLE ES_MULTILINE+ES_AUTOVSCROLL+ES_AUTOHSCROLL

   @ 0,0 PANEL oPanel SIZE 0,44

   @ 2,3 OWNERBUTTON OF oPanel ID 108 ON CLICK {||Connect()} ;
        SIZE 80,40 FLAT ;
        TEXT "Connect" FONT oFont COORDINATES 0,20,0,0;
        BITMAP "BMP_NETWORK" FROM RESOURCE COORDINATES 0,4,0,0
   @ 82,3 OWNERBUTTON OF oPanel ID 109 ON CLICK {||Databases()} ;
        SIZE 80,40 FLAT ;
        TEXT "Database" FONT oFont COORDINATES 0,20,0,0;
        BITMAP "BMP_OPNPRJ" FROM RESOURCE COORDINATES 0,4,0,0
   @ 162,3 OWNERBUTTON OF oPanel ID 110 ON CLICK {||Tables()} ;
        SIZE 80,40 FLAT ;
        TEXT "Tables" FONT oFont COORDINATES 0,20,0,0;
        BITMAP "BMP_TABLE" FROM RESOURCE COORDINATES 0,4,0,0
   @ 242,3 OWNERBUTTON OF oPanel ID 111 ON CLICK {||Execute()} ;
        SIZE 80,40 FLAT ;
        TEXT "Execute" FONT oFont COORDINATES 0,20,0,0;
        BITMAP "BMP_BROWSE" FROM RESOURCE COORDINATES 0,4,0,0
   @ 322,3 OWNERBUTTON OF oPanel ID 112 ON CLICK {||About()} ;
        SIZE 80,40 FLAT ;
        TEXT "About" FONT oFont COORDINATES 0,20,0,0;
        BITMAP "BMP_HELP" FROM RESOURCE COORDINATES 0,4,0,0
   @ 402,3 OWNERBUTTON OF oPanel ID 113 ON CLICK {||EndWindow()} ;
        SIZE 80,40 FLAT ;
        TEXT "Exit" FONT oFont COORDINATES 0,20,0,0;
        BITMAP "BMP_EXIT" FROM RESOURCE COORDINATES 0,4,0,0

   @ 0,0 PANEL oPanelE OF oMainWindow SIZE 0,24 ON SIZE {||.T.}

   @ 0,2 OWNERBUTTON OF oPanelE ID 114 ON CLICK {||oEdit:SetText( Memoread( SelectFile( "Script files( *.scr )", "*.scr", mypath )))} ;
        SIZE 20,22 FLAT ;
        BITMAP "BMP_OPEN" FROM RESOURCE TOOLTIP "Load script"
   @ 0,24 OWNERBUTTON OF oPanelE ID 115 ON CLICK {||SaveScript()} ;
        SIZE 20,22 FLAT ;
        BITMAP "BMP_SAVE" FROM RESOURCE TOOLTIP "Save script"
   @ 0,46 OWNERBUTTON OF oPanelE ID 116 ON CLICK {||BrowHistory()} ;
        SIZE 20,22 FLAT ;
        BITMAP "BMP_HIST" FROM RESOURCE TOOLTIP "Show history"
   @ 0,68 OWNERBUTTON OF oPanelE ID 117 ON CLICK {||oEdit:SetText(""),SetFocus(oEdit:handle)} ;
        SIZE 20,22 FLAT ;
        BITMAP "BMP_CLEAR" FROM RESOURCE TOOLTIP "Clear"

   @ 0,0 BROWSE oBrw ARRAY OF oMainWindow SIZE 500,376 ;
           ON SIZE {|o,x,y|ResizeBrwQ(o,x,y)}
   oBrw:active := .F.

   Rdini( "demo.ini" )
   IF Valtype( BrwFont ) == "A"
      oBrwFont := HFont():Add( BrwFont[1], BrwFont[2], BrwFont[3] )
   ENDIF
   ReadHistory( "qhistory.txt" )

   WriteStatus( Hwindow():GetMain(),1,"Not Connected" )
   SetFocus( oEdit:handle )
   // HideWindow( oBrw:handle )
   SetCtrlFont( oEdit:oParent:handle, oEdit:id, oBrwFont:handle )

   ACTIVATE WINDOW oMainWindow

   WriteHistory( "qhistory.txt" )

Return Nil

Function About
Local oModDlg, oFont

   INIT DIALOG oModDlg FROM RESOURCE "ABOUTDLG" ON PAINT {||AboutDraw()}
   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -13 ITALIC UNDERLINE

   REDEFINE OWNERBUTTON OF oModDlg ID IDC_OWNB1 ON CLICK {|| EndDialog( getmodalhandle() )} ;
       FLAT TEXT "Close" COLOR Vcolor("0000FF") FONT oFont

   oModDlg:Activate()
Return Nil

Function AboutDraw
Local pps
Local hDC
   pps := DefinePaintStru()
   hDC := BeginPaint( getmodalhandle(), pps )
   DrawBitmap( hDC, hBitmap,, 0, 0 )
   EndPaint( getmodalhandle(), pps )
Return Nil

Function DataBases
Local aBases, nChoic

   IF connHandle == 0
      Connect()
      IF connHandle == 0
         Return .F.
      ENDIF
   ENDIF
   aBases := sqlListDB( connHandle )
   nChoic := WChoice( aBases,"DataBases",0,50 )
   IF nChoic != 0
      cDatabase := aBases[ nChoic ]
      IF sqlSelectD( connHandle, cDatabase ) != 0
         HWG_MsgStop( "Can't connect to "+cDataBase )
         cDatabase := ""
      ELSE
         WriteStatus( Hwindow():GetMain(),2,"DataBase: " + cDataBase )
      ENDIF
   ENDIF

Return Nil

Function Tables
Local aTables, nChoic
Local cTable

   IF connHandle == 0
      Connect()
      IF connHandle == 0
         Return .F.
      ENDIF
   ENDIF
   aTables := sqlListTbl( connHandle )
   IF Empty( aTables )
      HWG_MSGINFO( "No tables !" )
      Return .F.
   ENDIF

   nChoic := WChoice( aTables,cDataBase+"  tables",50,50 )
   IF nChoic != 0
      cTable := aTables[ nChoic ]
      execSQL( "SHOW COLUMNS FROM " + cTable )
   ENDIF

Return Nil

Function Connect
Local aModDlg

   INIT DIALOG aModDlg FROM RESOURCE "DIALOG_1" ON INIT {|| InitConnect() }
   DIALOG ACTIONS OF aModDlg ;
          ON 0,IDOK     ACTION {|| EndConnect() } ;
          ON 0,IDCANCEL ACTION {|| EndDialog( getmodalhandle() )}

   aModDlg:Activate()
Return Nil

Function InitConnect
Local hDlg := getmodalhandle()
   SetDlgItemText( hDlg, IDC_EDIT1, cServer )
   SetDlgItemText( hDlg, IDC_EDIT2, cUser )
   SetDlgItemText( hDlg, IDC_EDIT4, cDataDef )
   IF Empty( cServer )
      SetFocus( GetDlgItem( hDlg, IDC_EDIT1 ) )
   ELSEIF Empty( cUser )
      SetFocus( GetDlgItem( hDlg, IDC_EDIT2 ) )
   ELSE
      SetFocus( GetDlgItem( hDlg, IDC_EDIT3 ) )
   ENDIF
Return .F.

Function EndConnect
Local hDlg := getmodalhandle()
   IF connHandle > 0
      sqlClose( connHandle )
      connHandle := 0
      IF queHandle > 0
         sqlFreeR( queHandle )
         queHandle := 0
      ENDIF
   ENDIF
   cServer := GetDlgItemText( hDlg, IDC_EDIT1, 30 )
   cUser := GetDlgItemText( hDlg, IDC_EDIT2, 20 )
   cPassword := GetDlgItemText( hDlg, IDC_EDIT3, 20 )
   cDataDef := GetDlgItemText( hDlg, IDC_EDIT4, 20 )

   SetDlgItemText( hDlg, IDC_TEXT1, "Wait, please ..." )
   connHandle := sqlConnect( cServer,Trim( cUser ),Trim( cPassword ) )
   IF connHandle != 0 .AND. !Empty( cDataDef )
      cDatabase := cDataDef
      IF sqlSelectD( connHandle, cDatabase ) != 0
         cDatabase := ""
         SetDlgItemText( hDlg, IDC_TEXT1, "Can't connect to " + cDataBase )
      ENDIF
   ELSE
      SetDlgItemText( hDlg, IDC_TEXT1, "Can't connect to " + cServer )
      cDatabase := ""
   ENDIF
   IF connHandle == 0
      WriteStatus( Hwindow():GetMain(),1,"Not Connected" )
      WriteStatus( Hwindow():GetMain(),2,"" )
      SetFocus( GetDlgItem( hDlg, IDC_EDIT1 ) )
   ELSE
      WriteStatus( Hwindow():GetMain(),1,"Connected to " + cServer )
      IF !Empty( cDataBase )
         WriteStatus( Hwindow():GetMain(),2,"DataBase: " + cDataBase )
      ENDIF
      EndDialog( hDlg )
      SetFocus( oEdit:handle )
   ENDIF
Return

Function ResizeEditQ( nWidth, nHeight )

   MoveWindow( oEdit:handle, 0, nHeight-oMainWindow:aOffset[4]-95, nWidth-24, 95 )
   MoveWindow( oPanelE:handle, nWidth-23, nHeight-oMainWindow:aOffset[4]-95, 24, 95 )
Return Nil

Function ResizeBrwQ( oBrw, nWidth, nHeight )
Local aRect, i, nHbusy := oMainWindow:aOffset[4]

   aRect := GetClientRect( oEdit:handle )
   nHbusy += aRect[ 4 ]
   MoveWindow( oBrw:handle, 0, oPanel:nHeight+1, nWidth, nHeight-nHBusy-oPanel:nHeight-8 )
Return Nil

Function Execute
Local cQuery := Ltrim( oEdit:GetText() )
Local arScr, nError, nLineEr

   IF Empty( cQuery )
      Return .F.
   ENDIF
   IF Left( cQuery,2 ) == "//"
      IF ( arScr := RdScript( ,cQuery ) ) <> Nil
         DoScript( arScr )
      ELSE
         nError := CompileErr( @nLineEr )
         HWG_MsgStop( "Script error ("+Ltrim(Str(nError))+"), line "+Ltrim(Str(nLineEr)) )
      ENDIF
   ELSE
      execSQL( cQuery )
   ENDIF

Return .T.

Function execSQL( cQuery )
Local res, stroka, poz := 0, lFirst := .T., i := 1

   IF connHandle == 0
      Connect()
      IF connHandle == 0
         Return .F.
      ENDIF
   ENDIF
   IF ( res := sqlQuery( connHandle, cQuery) ) != 0
      cQuery := ""
      HWG_MSGINFO( "Operation failed: " + STR( res ) + "( " + sqlGetErr( connHandle ) + " )" )
      WriteStatus( Hwindow():GetMain(), 3, sqlGetErr( connHandle ) )
   ELSE
      IF nHistCurr < nHistoryMax
         DO WHILE Len( stroka := RDSTR( Nil,@cQuery,@poz ) ) != 0
            IF Asc( Ltrim( stroka ) ) > 32
               Aadd( aQueries, Nil )
               Ains( aQueries, i )
               aQueries[ i ] := { Padr( stroka,76 ), lFirst }
               lFirst := .F.
               i ++
            ENDIF
         ENDDO
         Aadd( aQueries, Nil )
         Ains( aQueries, i )
         aQueries[ i ] := { Space( 76 ), .F. }
         nHistCurr ++
      ENDIF
      IF ( queHandle := sqlStoreR( connHandle ) ) != 0
         sqlBrowse( queHandle )
      ELSE
         // Should query have returned rows? (Was it a SELECT like query?)
         IF ( nNumFields := sqlFiCou( connHandle ) ) == 0
            // Was not a SELECT so reset ResultHandle changed by previous sqlStoreR()
            WriteStatus( Hwindow():GetMain(), 3, Str( sqlAffRows( connHandle ) ) + " rows updated." )
         ELSE
            @ 20,2 SAY "Operation failed:" + sqlGetErr( connHandle )
            HWG_MSGINFO( "Operation failed: " + "( " + sqlGetErr( connHandle ) + " )" )
            WriteStatus( Hwindow():GetMain(), 3, sqlGetErr( connHandle ) )
            res := -1
         ENDIF
      ENDIF
   ENDIF
Return res == 0

Function sqlBrowse( queHandle )
Local aQueRows, i, j, vartmp, af := {}
   nNumRows := sqlNRows( queHandle )
   WriteStatus( Hwindow():GetMain(), 3, Str( nNumRows,5 ) + " rows" )
   IF nNumRows == 0
      Return Nil
   ENDIF
   oBrw:InitBrw()
   oBrw:active := .T.
   nNumFields := sqlNumFi( queHandle )
   aQueRows := Array( nNumRows )

   FOR i := 1 TO nNumRows
      aQueRows[ i ] := sqlFetchR( queHandle )
      IF i == 1
         FOR j := 1 TO nNumFields
            Aadd( af,{ Valtype(aQueRows[ i,j ]),0,0 } )
         NEXT
      ENDIF
      FOR j := 1 TO nNumFields
         IF af[ j,1 ] == "C"
            af[ j,2 ] := Max( af[ j,2 ], Len( aQueRows[ i,j ] ) )
         ELSEIF af[ j,1 ] == "N"
            vartmp := STR( aQueRows[ i,j ] )
            af[ j,2 ] := Max( af[ j,2 ], Len( vartmp ) )
            af[ j,3 ] := Max( af[ j,3 ], IIF( '.' $ vartmp,af[ j,2 ] - AT( '.',vartmp ),0 ) )
         ELSEIF af[ j,1 ] == "D"
            af[ j,2 ] := 8
         ELSEIF af[ j,1 ] == "L"
            af[ j,2 ] := 1
         ENDIF
      NEXT
   NEXT
   CreateArList( oBrw, aQueRows )
   FOR i := 1 TO nNumFields
      oBrw:aColumns[i]:heading := SqlFetchF(queHandle)[1]
      oBrw:aColumns[i]:type   := af[i,1]
      oBrw:aColumns[i]:length := af[i,2]
      oBrw:aColumns[i]:dec    := af[i,3]
   NEXT
   oBrw:bcolorSel := VColor( "800080" )
   oBrw:ofont      := oBrwFont
   RedrawWindow( oBrw:handle, RDW_ERASE + RDW_INVALIDATE )
Return Nil

Function BrowHistory()

   IF nHistCurr == 0
      Return Nil
   ENDIF
   oBrw:active := .T.
   oBrw:InitBrw()
   oBrw:aArray := aQueries
   oBrw:AddColumn( HColumn():New( "History of queries", ;
            {|value,o|o:aArray[o:nCurrent,1] },             ;
            "C",76,0  ) )

   oBrw:bcolorSel := VColor( "800080" )
   oBrw:ofont := oBrwFont
   oBrw:bEnter := {|h,o|GetFromHistory(h,o)}
   RedrawWindow( oBrw:handle, RDW_ERASE + RDW_INVALIDATE )
Return Nil

Static Function GetFromHistory()
Local cQuery := "", i := oBrw:nCurrent

   IF !Empty( oBrw:aArray[ i,1 ] )
      DO WHILE !oBrw:aArray[ i,2 ]; i--; ENDDO
      DO WHILE i <= oBrw:nRecords .AND. !Empty( oBrw:aArray[ i,1 ] )
         cQuery += Rtrim( oBrw:aArray[ i,1 ] ) + Chr( 13 ) + Chr( 10 )
         i++
      ENDDO
      oEdit:SetText( cQuery )
      SetFocus( oEdit:handle )
   ENDIF
Return Nil

Static Function ReadHistory( fname )
Local han, stroka, lFirst := .T., lEmpty := .F.
LOCAL strbuf := Space(512), poz := 513

   nHistCurr := 0
   han := FOPEN( fname, FO_READ + FO_SHARED )
   IF han <> - 1
      DO WHILE .T.
         stroka := RDSTR( han,@strbuf,@poz,512 )
         IF LEN( stroka ) == 0
            EXIT
         ENDIF
         IF LEFT( stroka, 1 ) == Chr(10) .OR. LEFT( stroka, 1 ) == CHR(13)
            lEmpty := .T.
         ELSE
            IF lEmpty .AND. nHistCurr > 0
               Aadd( aQueries, { Space( 76 ),.F. } )
               lFirst := .T.
            ENDIF
            lEmpty := .F.
            Aadd( aQueries, { Padr( stroka,76 ), lFirst } )
            IF lFirst
               nHistCurr ++
            ENDIF
            lFirst := .F.
         ENDIF
      ENDDO
      FCLOSE( han )
   ENDIF
Return nHistCurr

Static Function WriteHistory( fname )
Local han, i, lEmpty := .T.
   IF !Empty( aQueries )
      han := FCREATE( fname )
      IF han <> - 1
         FOR i := 1 TO Len( aQueries )
            IF !Empty( aQueries[ i,1 ] ) .OR. !lEmpty
               FWRITE( han, Trim( aQueries[ i,1 ] ) + Chr(13) + Chr(10) )
               lEmpty := Empty( aQueries[ i,1 ] )
            ENDIF
         NEXT
         FCLOSE( han )
      ENDIF
   ENDIF
Return Nil

FUNCTION DoSQL( cQuery )
Local aRes, qHandle, nNumFields, nNumRows, i
   IF sqlQuery( connHandle, cQuery) != 0
      Return { 1 }
   ELSE
      IF ( qHandle := sqlStoreR( connHandle ) ) != 0
         nNumRows := sqlNRows( qHandle )
         nNumFields := sqlNumFi( qHandle )
         aRes := { 0, Array(nNumFields), Array(nNumRows) }
         FOR i := 1 TO nNumFields
            aRes[ 2,i ] := SqlFetchF(qHandle)[1]
         NEXT
         FOR i := 1 TO nNumRows
            aRes[ 3,i ] := sqlFetchR( qHandle )
         NEXT
         sqlFreeR( qHandle )
         Return aRes
      ELSE
         // Should query have returned rows? (Was it a SELECT like query?)
         IF sqlFiCou( connHandle ) == 0
            // Was not a SELECT so reset ResultHandle changed by previous sqlStoreR()
            Return { 0, sqlAffRows( connHandle ) }
         ELSE
            Return { 2 }
         ENDIF
      ENDIF
   ENDIF
Return Nil

FUNCTION FilExten( fname )
LOCAL i
RETURN IIF( ( i := RAT( '.', fname ) ) = 0, "", SUBSTR( fname, i + 1 ) )

Function SaveScript
Local fname := SaveFile( "*.scr","Script files( *.scr )", "*.scr", mypath )
   cQuery := oEdit:GetText()
   IF !Empty( fname )
      MemoWrit( fname,cQuery )
   ENDIF
Return Nil

Function WndOut()
Return Nil

Function MsgSay( cText )
   HWG_MsgStop( cText )
Return Nil

EXIT PROCEDURE cleanup
   IF connHandle > 0
      sqlClose( connHandle )
      IF queHandle > 0
         sqlFreeR( queHandle )
      ENDIF
   ENDIF
Return
