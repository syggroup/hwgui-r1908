//
// $Id: buildpelles.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library
//
// File to Build APP using Pelles C Compiler
// Copyright 2004 Sandro R. R. Freire <sandrorrfreire@yahoo.com.br>
// www - http://www.lumainformatica.com.br
//

#include "hwgui.ch"

#DEFINE  ID_EXENAME     10001
#DEFINE  ID_LIBFOLDER   10002
#DEFINE  ID_INCFOLDER   10003
#DEFINE  ID_PRGFLAG     10004
#DEFINE  ID_CFLAG       10005
#DEFINE  ID_PRGMAIN     10006

FUNCTION Main()

   LOCAL oFont
   LOCAL aBrowse1
   LOCAL aBrowse2
   LOCAL aBrowse3
   LOCAL aBrowse4
   LOCAL oPasta := DiskName() + ":\" + CurDir() + "\"
   LOCAL vGt1 := Space(80)
   LOCAL vGt2 := Space(80)
   LOCAL vGt3 := Space(80)
   LOCAL vGt4 := Space(80)
   LOCAL vGt5 := Space(80)
   LOCAL vGt6 := Space(80)
   LOCAL aFiles1 := {""}
   LOCAL aFiles2 := {""}
   LOCAL aFiles3 := {""}
   LOCAL aFiles4 := {""}

   PRIVATE oDirec := DiskName() + ":\" + CurDir() + "\"

   If !File(oDirec + "BuildPelles.Ini")
     hwg_WriteIni("Config", "Dir_HwGUI", "C:\HwGUI", oDirec + "BuildPelles.Ini")
     hwg_WriteIni("Config", "Dir_HARBOUR", "C:\xHARBOUR", oDirec + "BuildPelles.Ini")
     hwg_WriteIni("Config", "Dir_PELLES", "C:\POCC", oDirec + "BuildPelles.Ini")
   EndIf

   PRIVATE lSaved := .F.
   PRIVATE oBrowse1
   PRIVATE oBrowse2
   PRIVATE oBrowse3
   PRIVATE oDlg
   PRIVATE oButton1
   PRIVATE oExeName
   PRIVATE oLabel1
   PRIVATE oLibFolder
   PRIVATE oButton4
   PRIVATE oLabel2
   PRIVATE oIncFolder
   PRIVATE oLabel3
   PRIVATE oButton3
   PRIVATE oPrgFlag
   PRIVATE oLabel4
   PRIVATE oCFlag
   PRIVATE oLabel5
   PRIVATE oButton2
   PRIVATE oMainPrg
   PRIVATE oLabel6
   PRIVATE oTab

   PREPARE FONT oFont NAME "MS Sans Serif" WIDTH 0 HEIGHT -12

   INIT DIALOG oDlg CLIPPER NOEXIT TITLE "HwGUI Build For Pelles C Compiler" ;
        AT 213, 195 SIZE 513, 265  font oFont

   @ 14, 16 TAB oTAB ITEMS {} SIZE 391, 242

   BEGIN PAGE "Config" Of oTAB
      @  20, 44 SAY oLabel1 CAPTION "Exe Name" SIZE 80, 22
      @ 136, 44 GET oExeName VAR vGt1 ID ID_EXENAME SIZE 206, 24

      @  20, 74 SAY oLabel2 CAPTION "Lib Folder" SIZE 80, 22
      @ 136, 74 GET oLibFolder  VAR vGt2 ID ID_LIBFOLDER SIZE 234, 24

      @  20, 104 SAY oLabel3 CAPTION "Include Folder" SIZE 105, 22
      @ 136, 104 GET oIncFolder VAR vGt3 ID ID_INCFOLDER SIZE 234, 24

      @  20, 134 SAY oLabel4 CAPTION "PRG Flags" SIZE 80, 22
      @ 136, 134 GET oPrgFlag VAR vGt4 ID ID_PRGFLAG SIZE 230, 24  

      @  20, 164 SAY oLabel5 CAPTION "C Flags" SIZE 80, 22
      @ 136, 164 GET oCFlag VAR vGt5  ID ID_CFLAG SIZE 230, 24  
 
      @  20, 194 SAY oLabel6 CAPTION "Main PRG" SIZE 80, 22
      @ 136, 194 GET oMainPrg VAR vGt6 ID ID_PRGMAIN SIZE 206, 24
      @ 347, 194 OWNERBUTTON SIZE 24, 24   ;
          ON CLICK {||searchFileName("xBase Files *.prg ", oMainPrg, "*.prg")};//       FLAT;
          TEXT "..." ;//BITMAP "SEARCH" FROM RESOURCE TRANSPARENT COORDINATES 0, 0, 0, 0 ;
          TOOLTIP "Search main file" 

   END PAGE of oTAB
   BEGIN PAGE "Prg (Files)" of oTAB
      @ 21, 29 BROWSE oBrowse1 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse1, "*.prg")};
 	            STYLE WS_VSCROLL + WS_HSCROLL SIZE 341, 170  
      hwg_CreateArList(oBrowse1, aFiles1)
      obrowse1:acolumns[1]:heading := "File Names"
      obrowse1:acolumns[1]:length := 50
      oBrowse1:bcolorSel := VColor("800080")
      oBrowse1:ofont := HFont():Add("Arial", 0, -12)
      @ 10, 205 BUTTON "Add" SIZE 60, 25 ON CLICK {||SearchFile(oBrowse1, "*.prg")}
      @ 70, 205 BUTTON "Delete" SIZE 60, 25 ON CLICK {||Adel(oBrowse1:aArray, oBrowse1:nCurrent), oBrowse1:Refresh()}

   END PAGE of oTAB
   BEGIN PAGE "C (Files)" of oTAB
      @ 21, 29 BROWSE oBrowse2 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse2, "*.c")};
 	            STYLE WS_VSCROLL + WS_HSCROLL SIZE 341, 170  
      hwg_CreateArList(oBrowse2, aFiles2)
      obrowse2:acolumns[1]:heading := "File Names"
      obrowse2:acolumns[1]:length := 50
      oBrowse2:bcolorSel := VColor("800080")
      oBrowse2:ofont := HFont():Add("Arial", 0, -12)
      @ 10, 205 BUTTON "Add" SIZE 60, 25 ON CLICK {||SearchFile(oBrowse2, "*.c")}
      @ 70, 205 BUTTON "Delete" SIZE 60, 25 ON CLICK {||Adel(oBrowse1:aArray, oBrowse2:nCurrent), oBrowse2:Refresh()}
   END PAGE of oTAB
   BEGIN PAGE "Lib (Files)" of oTAB
      @ 21, 29 BROWSE oBrowse3 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse3, "*.lib")};
 	            STYLE WS_VSCROLL + WS_HSCROLL SIZE 341, 170  
      hwg_CreateArList(oBrowse3, aFiles3)
      obrowse3:acolumns[1]:heading := "File Names"
      obrowse3:acolumns[1]:length := 50
      oBrowse3:bcolorSel := VColor("800080")
      oBrowse3:ofont := HFont():Add("Arial", 0, -12)
      @ 10, 205 BUTTON "Add" SIZE 60, 25 ON CLICK {||SearchFile(oBrowse3, "*.lib")}
      @ 70, 205 BUTTON "Delete" SIZE 60, 25 ON CLICK {||Adel(oBrowse3:aArray, oBrowse3:nCurrent), oBrowse3:Refresh()}
   END PAGE of oTAB
   BEGIN PAGE "Resource (Files)" of oTAB
      @ 21, 29 BROWSE oBrowse4 ARRAY of oTAB ON CLICK {||SearchFile(oBrowse3, "*.rc")};
 	            STYLE WS_VSCROLL + WS_HSCROLL SIZE 341, 170  
      hwg_CreateArList(oBrowse4, aFiles4)
      obrowse4:acolumns[1]:heading := "File Names"
      obrowse4:acolumns[1]:length := 50
      oBrowse4:bcolorSel := VColor("800080")
      oBrowse4:ofont := HFont():Add("Arial", 0, -12)
      @ 10, 205 BUTTON "Add" SIZE 60, 25 ON CLICK {||SearchFile(oBrowse4, "*.rc")}
      @ 70, 205 BUTTON "Delete" SIZE 60, 25 ON CLICK {||Adel(oBrowse4:aArray, oBrowse4:nCurrent), oBrowse4:Refresh()}
   END PAGE of oTAB
   
   @ 419, 20 BUTTON oButton1 CAPTION "Build" ON CLICK {||BuildApp()} SIZE 78, 52
   @ 419, 80 BUTTON oButton2 CAPTION "Exit" ON CLICK {||EndDialog()} SIZE 78, 52
   @ 419, 140 BUTTON oButton3 CAPTION "Open" ON CLICK {||ReadBuildFile()} SIZE 78, 52
   @ 419, 200 BUTTON oButton4 CAPTION "Save" ON CLICK {||SaveBuildFile()} SIZE 78, 52

   ACTIVATE DIALOG oDlg

RETURN NIL

STATIC FUNCTION SearchFile(oBrow, oFile)

   LOCAL oTotReg := {}
   LOCAL i
   LOCAL aSelect := SelectMultipleFiles("xBase Files (" + oFile + ")", oFile)

   if Len(aSelect) ==0
      RETURN NIL
   endif
   if Len(oBrow:aArray) == 1 .AND. obrow:aArray[1] == ""
      obrow:aArray := {}
   endif
   For i := 1 to Len(oBrow:aArray)
     AAdd(oTotReg, oBrow:aArray[i])
   Next
   For i := 1 to Len(aSelect)
     AAdd(oTotReg, aSelect[i])
   Next
   obrow:aArray := oTotReg
   obrow:refresh()

RETURN NIL

STATIC FUNCTION SearchFileName(nName, oGet, oFile)

   LOCAL oTextAnt := oGet:GetText()
   LOCAL fFile := hwg_SelectFile(nName + " (" + oFile + ")", oFile, , , .T.)

   If !Empty(oTextAnt)
      fFile := oTextAnt //
   endif

   oGet:SetText(fFile)
   oGet:Refresh()

RETURN NIL

FUNCTION ReadBuildFile()

   LOCAL oLibFiles
   LOCAL oBr1 := {}
   LOCAL oBr2 := {}
   LOCAL oBr3 := {}
   LOCAL oBr4 := {}
   LOCAL oSel1
   LOCAL oSel2
   LOCAL oSel3
   LOCAL i
   LOCAL oSel4
   LOCAL aPal := ""
   LOCAL oFolderFile := hwg_SelectFile("HwGUI File Build (*.bld)", "*.bld")

   if Empty(oFolderFile)
      RETURN NIL
   Endif

   oExeName:SetText(hwg_GetIni("Config", "ExeName", , oFolderFile))
   oLibFolder:SetText(hwg_GetIni("Config", "LibFolder", , oFolderFile))
   oIncFolder:SetText(hwg_GetIni("Config", "IncludeFolder", , oFolderFile))
   oPrgFlag:SetText(hwg_GetIni("Config", "PrgFlags", , oFolderFile))
   oCFlag:SetText(hwg_GetIni("Config", "CFlags", , oFolderFile))
   oMainPrg:SetText(hwg_GetIni("Config", "PrgMain", , oFolderFile))
   
   For i := 1 to 300
       oSel1 := hwg_GetIni("FilesPRG", AllTrim(Str(i)), , oFolderFile)
       if !Empty(oSel1) //.or. oSel1#Nil
           AAdd(oBr1, oSel1)
       EndIf
   Next
   
   
   For i := 1 to 300
       oSel2 := hwg_GetIni("FilesC", AllTrim(Str(i)), , oFolderFile)
       if !Empty(oSel2) //.or. oSel2#Nil
           AAdd(oBr2, oSel2)
       EndIf
   Next
   
   For i := 1 to 300
       oSel3 := hwg_GetIni("FilesLIB", AllTrim(Str(i)), , oFolderFile)
       if !Empty(oSel3) //.or. oSel3#Nil
           AAdd(oBr3, oSel3)
       EndIf
   Next
   
   For i := 1 to 300
       oSel4 := hwg_GetIni("FilesRES", AllTrim(Str(i)), , oFolderFile)
       if !Empty(oSel4) //.or. oSel4#Nil
           AAdd(oBr4, oSel4)
       EndIf
   Next
   
   oBrowse1:aArray := oBr1
   oBrowse2:aArray := oBr2
   oBrowse3:aArray := oBr3
   oBrowse4:aArray := oBr4
   oBrowse1:Refresh()
   oBrowse2:Refresh()
   oBrowse3:Refresh()
   oBrowse4:Refresh()

RETURN NIL

FUNCTION SaveBuildFile()

   LOCAL oLibFiles
   LOCAL i
   LOCAL oNome
   LOCAL g
   LOCAL oFolderFile := hwg_SaveFile("*.bld", "HwGUI File Build (*.bld)", "*.bld")

   if Empty(oFolderFile)
      RETURN NIL
   Endif
   if file(oFolderFile)
      If(hwg_MsgYesNo("File " + oFolderFile + " EXIT ..Replace?"))
        Erase(oFolderFile)
      Else
        hwg_MsgInfo("No file SAVED.")
        RETURN NIL
      EndIf
   EndIf
   hwg_WriteIni("Config", "ExeName", oExeName:GetText(), oFolderFile)
   hwg_WriteIni("Config", "LibFolder", oLibFolder:GetText(), oFolderFile)
   hwg_WriteIni("Config", "IncludeFolder", oIncFolder:GetText(), oFolderFile)
   hwg_WriteIni("Config", "PrgFlags", oPrgFlag:GetText(), oFolderFile)
   hwg_WriteIni("Config", "CFlags", oCFlag:GetText(), oFolderFile)
   hwg_WriteIni("Config", "PrgMain", oMainPrg:GetText(), oFolderFile)
   oNome := ""

   if Len(oBrowse1:aArray)>=1
      for i := 1 to Len(oBrowse1:aArray)

         if !Empty(oBrowse1:aArray[i])

            hwg_WriteIni("FilesPRG", AllTrim(Str(i)), oBrowse1:aArray[i], oFolderFile)

         EndIf

       Next

   endif


   if Len(oBrowse2:aArray)>=1
      for i := 1 to Len(oBrowse2:aArray)
         if !Empty(oBrowse2:aArray[i])
            hwg_WriteIni("FilesC", AllTrim(Str(i)), oBrowse2:aArray[i], oFolderFile)
        endif
      Next
   endif

   if Len(oBrowse3:aArray)>=1
      for i := 1 to Len(oBrowse3:aArray)
         if !Empty(oBrowse3:aArray[i])
            hwg_WriteIni("FilesLIB", AllTrim(Str(i)), oBrowse3:aArray[i], oFolderFile)
         endif
      Next
   endif

   if Len(oBrowse4:aArray)>=1
      for i := 1 to Len(oBrowse4:aArray)
         if !Empty(oBrowse4:aArray[i])
            hwg_WriteIni("FilesRES", AllTrim(Str(i)), oBrowse4:aArray[i], oFolderFile)
        endif
      Next
   endif

   hwg_Msginfo("File " + oFolderFile + " saved", "HwGUI Build")

RETURN NIL

FUNCTION BuildApp()

If hwg_MsgYesNo("Yes Compile to BAT, No compile to PoMake")
   BuildBat()
Else
   BuildPoMake()
EndIf

RETURN NIL

FUNCTION BuildBat()

   LOCAL voExeName
   LOCAL voLibFolder
   LOCAL voIncFolder
   LOCAL voPrgFlag
   LOCAL voCFlag
   LOCAL voPrgMain
   LOCAL voPrgFiles
   LOCAL voCFiles
   LOCAL voResFiles
   LOCAL oLibFiles
   LOCAL CRF := Chr(13) + Chr(10)
   LOCAL oName
   LOCAL oInc
   LOCAL lName
   LOCAL gDir
   LOCAL oArq := FCreate("Hwg_Build.bat")
   LOCAL i
   LOCAL vHwGUI
   LOCAL vHarbour
   LOCAL vPelles

   If File(oDirec + "BuildPelles.Ini")
      vHwGUI := hwg_GetIni("Config", "DIR_HwGUI", , oDirec + "BuildPelles.Ini")
      vHarbour := hwg_GetIni("Config", "DIR_HARBOUR", , oDirec + "BuildPelles.Ini")
      vPelles := hwg_GetIni("Config", "DIR_PELLES", , oDirec + "BuildPelles.Ini")
   Else
      vHwGUI := "C:\HWGUI"
      vHarbour := "C:\Harbour"
      vPelles := "C:\Pocc"
   EndIf
   voExeName := oExeName:GetText()
   voLibFolder := oLibFolder:GetText()
   voIncFolder := oIncFolder:GetText()
   voPrgFlag := oPrgFlag:GetText()
   voCFlag := oCFlag:GetText()
   voPrgMain := oMainPrg:GetText()

   voPrgFiles := oBrowse1:aArray
   voCFiles := oBrowse2:aArray
   voLibFiles := oBrowse3:aArray
   voResFiles := oBrowse4:aArray
   
   FWrite(oArq, "@echo off" + CRF)
   
   oName := SubStr(voPrgMain, 1, Len(voPrgMain) - 4)
   lName := ""
   for i := 1 to Len(oName)
      if SubStr(oName, -i, 1) == "\"
         Exit
      Endif
      lName += SubStr(oName, -i, 1)
   Next
   oName := ""
   for i := 1 to Len(lName)         
      oName += SubStr(lName, -i, 1)
   Next   
   FWrite(oArq, "ECHO " + oName + ".obj > make.tmp " + CRF)
   
   if Len(voPrgFiles)>0 
   
      for i := 1 to Len(voPrgFiles)
      
         if !Empty(voPrgFiles[i])
    
            oName := SubStr(voPrgFiles[i], 1, Len(voPrgFiles[i]) - 4)
            lName := ""
            for g := 1 to Len(oName)
               if SubStr(oName, -g, 1) == "\"
                  Exit
               Endif
               lName += SubStr(oName, -g, 1)
            Next
            oName := ""
            for g := 1 to Len(lName)         
               oName += SubStr(lName, -g, 1)
            Next   
   
            FWrite(oArq, "ECHO " + oName + ".obj >> make.tmp " + CRF)
            
         Endif   
         
      Next
   Endif
      
   //FWrite(oArq, "ECHO " + voExeName + ".obj > make.tmp " + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\rtl%HB_MT%.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\vm%HB_MT%.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\gtwin.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\lang.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\codepage.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\macro%HB_MT%.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\rdd%HB_MT%.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\dbfntx%HB_MT%.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\dbfcdx%HB_MT%.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\dbfdbt%HB_MT%.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\common.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\debug.lib  >> make.tmp" + CRF)
   FWrite(oArq, "echo " + vHarbour + "\lib\pp.lib  >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vHarbour + "\LIB\optcon.lib>> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vHarbour + "\LIB\optgui.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vHarbour + "\LIB\nulsys.lib  >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vHarbour + "\LIB\hbodbc.lib   >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vHarbour + "\LIB\samples.lib   >> make.tmp" + CRF)
   
   FWrite(oArq, "ECHO " + vHwGUI + "\LIB\hwgui.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vHwGUI + "\LIB\procmisc.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vHwGUI + "\LIB\hbxml.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vHwGUI + "\LIB\hwg_qhtm.lib >> make.tmp" + CRF)
   
   FWrite(oArq, "ECHO " + vPelles + "\LIB\kernel32.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\comctl32.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\comdlg32.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\delayimp.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\ole32.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\shell32.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\oleaut32.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\user32.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\gdi32.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\winspool.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\uuid.lib >> make.tmp" + CRF)
   FWrite(oArq, "ECHO " + vPelles + "\LIB\portio.lib >> make.tmp" + CRF)
   FWrite(oArq, "IF EXIST " + voExeName + ".res echo " + voExeName + ".res  >> make.tmp" + CRF)
   
   oName := SubStr(voPrgMain, 1, Len(voPrgMain) - 4)
   
   FWrite(oArq, vHarbour + "\BIN\HARBOUR " + voPrgMain + ;
   " -o" + oName + ;
   " -i" + vPelles + "\INCLUDE;" + vHarbour + "\INCLUDE;" + vHwGUI + "\INCLUDE" + IIf(!Empty(voIncFolder), ";", "") + voIncFolder + " " + voPrgFlag + " -n -q0 -es2 -gc0" + CRF)
   
   
   if Len(voPrgFiles)>0 
   for i := 1 to Len(voPrgFiles)
       if !Empty(voPrgFiles[i])
    
          oName := SubStr(voPrgFiles[i], 1, Len(voPrgFiles[i]) - 4)
          FWrite(oArq, vHarbour + "\BIN\HARBOUR " + voPrgFiles[i] + ;
          " -o" + oName + ;
          " -i" + vPelles + "\INCLUDE;" + vHarbour + "\INCLUDE;" + vHwGUI + "\INCLUDE" + IIf(!Empty(voIncFolder), ";", "") + voIncFolder + " " + voPrgFlag + " -n -q0 -es2 -gc0" + CRF)
      ENDIF    
   Next
   endif
   
   oName := SubStr(voPrgMain, 1, Len(voPrgMain) - 4)
   FWrite(oArq, vPelles + "\bin\pocc " + oName + ".c " + voCFlag + ' /Ze /D"NEED_DUMMY_RETURN" /D"__XCC__" /I"INCLUDE" /I"'+vHarbour+'\INCLUDE" /I"'+vPelles+'\INCLUDE" /I"'+vPelles+'\INCLUDE\WIN" /I"'+vPelles+'\INCLUDE\MSVC" /D"HB_STATIC_STARTUP" /c' + CRF)
   
   
   if Len(voPrgFiles)>0 
   for i := 1 to Len(voPrgFiles)
      if !Empty(voPrgFiles[i])
         oName := SubStr(voPrgFiles[i], 1, Len(voPrgFiles[i]) - 4)
         FWrite(oArq, vPelles + "\bin\pocc " + oName + ".c " + voCFlag + ' /Ze /D"NEED_DUMMY_RETURN" /D"__XCC__" /I"INCLUDE" /I"'+vHarbour+'\INCLUDE" /I"'+vPelles+'\INCLUDE" /I"'+vPelles+'\INCLUDE\WIN" /I"'+vPelles+'\INCLUDE\MSVC" /D"HB_STATIC_STARTUP" /c' + CRF)
     endif  
   next
   endif 
   
   if Len(voCFiles)>0 
   oInc := ""
   for i := 1 to Len(voCFiles)
       if !Empty(voCFiles[i])
          if !Empty(oIncFolder)
             oInc := '/I"'+voIncFolder+'"'
          endif   
          FWrite(oArq, vPelles + "\bin\pocc " + voCFiles[i] + ' /Ze /D"NEED_DUMMY_RETURN" /D"__XCC__" /I"INCLUDE" /I"" + vHarbour + "\INCLUDE" /I"" + vPelles + "\INCLUDE" /I"" + vPelles + "\INCLUDE\WIN" /I"'+vPelles+'\INCLUDE\MSVC" '+oInc+' /D"HB_STATIC_STARTUP" /c' + CRF)
       endif   
   Next
   Endif
   
   if Len(voResFiles)>0 
   oInc := ""
   for i := 1 to Len(voResFiles)
     if !Empty(voResFiles[i])
        FWrite(oArq, vPelles + "\BIN\porc -r " + voResFiles[i] + ' -foobj\' + voExeName + CRF)
     EndIf   
   Next
   EndIf 
   
   FWrite(oArq, vPelles + "\bin\POLINK /LIBPATH:" + vPelles + "\lib /OUT:" + voExeName + ".EXE /MACHINE:IX86 /OPT:WIN98 /SUBSYSTEM:WINDOWS /FORCE:MULTIPLE @make.tmp >error.log" + CRF)
   FWrite(oArq, "DEL make.tmp" + CRF)
   
   oName := SubStr(voPrgMain, 1, Len(voPrgMain) - 4)
   /*
   FWrite(oArq, "Del " + oName + ".c " + CRF)
   FWrite(oArq, "Del " + oName + ".map" + CRF)
   FWrite(oArq, "Del " + oName + ".obj" + CRF)
   
   for i := 1 to Len(voPrgFiles)
      if !Empty(voPrgFiles[i])
         oName := SubStr(voPrgFiles[i], 1, Len(voPrgFiles[i]) - 4)
         FWrite(oArq, "Del " + oName + ".c " + CRF)
         FWrite(oArq, "Del " + oName + ".map" + CRF)
         FWrite(oArq, "Del " + oName + ".obj" + CRF)
     endif  
   next
   */ 
   FClose(oArq)
   
   __Run("Hwg_Build.bat>Error.log")
   
   if file(voExeName + ".exe")
      hwg_MsgInfo("File " + voExeName + ".exe Build correct")
   Else 
      hwg_ShellExecute("NotePad error.log")   
   Endif   

RETURN NIL

FUNCTION BuildPoMake()

   LOCAL voExeName
   LOCAL voLibFolder
   LOCAL voIncFolder
   LOCAL voPrgFlag
   LOCAL voCFlag
   LOCAL voPrgMain
   LOCAL voPrgFiles
   LOCAL voCFiles
   LOCAL voResFiles
   LOCAL oLibFiles
   LOCAL CRF := Chr(13) + Chr(10)
   LOCAL oName
   LOCAL oInc
   LOCAL lName
   LOCAL gDir
   LOCAL oArq := FCreate("Makefile.pc")
   LOCAL i
   LOCAL vHwGUI
   LOCAL vHarbour
   LOCAL vPelles

   If File(oDirec + "BuildPelles.Ini")
      vHwGUI := hwg_GetIni("Config", "DIR_HwGUI", , oDirec + "BuildPelles.Ini")
      vHarbour := hwg_GetIni("Config", "DIR_HARBOUR", , oDirec + "BuildPelles.Ini")
      vPelles := hwg_GetIni("Config", "DIR_PELLES", , oDirec + "BuildPelles.Ini")
   Else
      vHwGUI := "C:\HWGUI"
      vHarbour := "C:\Harbour"
      vPelles := "C:\Pocc"
   EndIf

   voExeName := oExeName:GetText()
   voLibFolder := oLibFolder:GetText()
   voIncFolder := oIncFolder:GetText()
   voPrgFlag := oPrgFlag:GetText()
   voCFlag := oCFlag:GetText()
   voPrgMain := oMainPrg:GetText()

   voPrgFiles := oBrowse1:aArray
   voCFiles := oBrowse2:aArray
   voLibFiles := oBrowse3:aArray
   voResFiles := oBrowse4:aArray
   
   FWrite(oArq, "# makefile for Pelles C 32 bits" + CRF)
   FWrite(oArq, "# Building of App Using Pomake" + CRF)
   
   FWrite(oArq, "# Comment the following for HARBOUR" + CRF)
   FWrite(oArq, "__XHARBOUR__ = 1" + CRF)
   
   FWrite(oArq, "HRB_DIR = " + vHarbour + CRF)
   FWrite(oArq, "POCCMAIN = " + vPelles + CRF)
   FWrite(oArq, "INCLUDE_DIR = include;" + vHarbour + "\include" + ;
   IIf(!Empty(voIncFolder), ";" + voIncFolder, "") + CRF)
   FWrite(oArq, "OBJ_DIR = obj" + CRF)
   FWrite(oArq, "LIB_DIR = " + vHwGUI + "\lib" + CRF)
   FWrite(oArq, "SRC_DIR = source" + CRF + CRF)
   
   FWrite(oArq, "HARBOUR_EXE = HARBOUR " + CRF)
   FWrite(oArq, "CC_EXE = $(POCCMAIN)\BIN\POCC.EXE " + CRF)
   FWrite(oArq, "LIB_EXE = $(POCCMAIN)\BIN\POLINK.EXE " + CRF)
   FWrite(oArq, "HARBOURFLAGS = -i$(INCLUDE_DIR) -n1 -q0 -w -es2 -gc0" + CRF)
   FWrite(oArq, 'CFLAGS = /Ze /I"INCLUDE" /I"$(HRB_DIR)\INCLUDE" /I"$(POCCMAIN)\INCLUDE" /I"$(POCCMAIN)\INCLUDE\WIN" /I"$(POCCMAIN)\INCLUDE\MSVC" /D"HB_STATIC_STARTUP" /c' + CRF)
   
   //# Please Note that /Op and /Go requires POCC version 2.80 or later
   FWrite(oArq, "CFLAGS = $(CFLAGS) /Op /Go" + CRF)
   
   FWrite(oArq, "!ifdef __XHARBOUR__ " + CRF)
   FWrite(oArq, 'CFLAGS = $(CFLAGS) /D"XHBCVS" ' + CRF)
   FWrite(oArq, "!endif " + CRF)

   FWrite(oArq, "!ifndef ECHO" + CRF)
   FWrite(oArq, "ECHO = echo." + CRF)
   FWrite(oArq, "!endif" + CRF)
   FWrite(oArq, "!ifndef DEL" + CRF)
   FWrite(oArq, "DEL = del" + CRF)
   FWrite(oArq, "!endif" + CRF + CRF)
   
   FWrite(oArq, "HWGUI_LIB = $(LIB_DIR)\hwgui.lib" + CRF)
   FWrite(oArq, "PROCMISC_LIB = $(LIB_DIR)\procmisc.lib" + CRF)
   FWrite(oArq, "XML_LIB = $(LIB_DIR)\hbxml.lib" + CRF)
   FWrite(oArq, "QHTM_LIB = $(LIB_DIR)\hwg_qhtm.lib" + CRF + CRF)

   FWrite(oArq, "all: \" + CRF)
   FWrite(oArq, "   $(HWGUI_LIB) \" + CRF)
   FWrite(oArq, "   $(PROCMISC_LIB) \" + CRF)
   FWrite(oArq, "   $(XML_LIB) \" + CRF)
   FWrite(oArq, "   $(QHTM_LIB)" + CRF + CRF)

   FWrite(oArq, "FILE_OBJS = \" + CRF)
   oName := SubStr(voPrgMain, 1, Len(voPrgMain) - 4)
   /*lName := ""
   for i := 1 to Len(oName)
      if SubStr(oName, -i, 1) == "\"
         Exit
      Endif
      lName += SubStr(oName, -i, 1)
   Next
   oName := ""
   for i := 1 to Len(lName)         
      oName += SubStr(lName, -i, 1)
   Next   
   */
   FWrite(oArq, oName + ".obj \ " + CRF)
   
   if Len(voPrgFiles)>0 
   
      for i := 1 to Len(voPrgFiles)
      
         if !Empty(voPrgFiles[i])
    
            oName := SubStr(voPrgFiles[i], 1, Len(voPrgFiles[i]) - 4)
            lName := ""
   /*         for g := 1 to Len(oName)
               if SubStr(oName, -g, 1) == "\"
                  Exit
               Endif
               lName += SubStr(oName, -g, 1)
            Next
            oName := ""
            for g := 1 to Len(lName)         
               oName += SubStr(lName, -g, 1)
            Next   
   
            FWrite(oArq, "$(OBJ_DIR)\" + oName + ".obj ")
   */
            FWrite(oArq, oName + ".obj ")
   
            IF i < Len(voPrgFiles)
               FWrite(oArq, "\" + CRF)
            Else
               FWrite(oArq, CRF + CRF)
            Endif
         Endif   
         
      Next
   Endif
   
   FWrite(oArq, voExeName + ": $(FILE_OBJS)" + CRF)
   FWrite(oArq, "   $(LIB_EXE) /out:$@ $** " + CRF + CRF)
   
   
   oName := SubStr(voPrgMain, 1, Len(voPrgMain) - 4)
   
   FWrite(oArq, oName + ".c : " + voPrgMain + CRF)
   FWrite(oArq, "   $(HARBOUR_EXE) $(HARBOURFLAGS) $** -o$@" + CRF + CRF)
   
   if Len(voPrgFiles)>0 
   for i := 1 to Len(voPrgFiles)
       if !Empty(voPrgFiles[i])
    
          oName := SubStr(voPrgFiles[i], 1, Len(voPrgFiles[i]) - 4)
          FWrite(oArq, oName + ".c : " + voPrgFiles[i] + CRF)
          FWrite(oArq, "   $(HARBOUR_EXE) $(HARBOURFLAGS) $** -o$@" + CRF + CRF)
      ENDIF    
   Next
   endif
   oName := SubStr(voPrgMain, 1, Len(voPrgMain) - 4)
   FWrite(oArq, oName + ".obj : " + oName + ".c" + CRF)
   FWrite(oArq, "   $(CC_EXE) $(CFLAGS) /Fo$@ $** " + CRF + CRF)
   
   if Len(voPrgFiles)>0 
   for i := 1 to Len(voPrgFiles)
       if !Empty(voPrgFiles[i])
          oName := SubStr(voPrgFiles[i], 1, Len(voPrgFiles[i]) - 4)
          FWrite(oArq, oName + ".obj : " + oName + ".c" + CRF)
          FWrite(oArq, "   $(CC_EXE) $(CFLAGS) /Fo$@ $** " + CRF + CRF)
      ENDIF    
   Next
   endif
   
   if Len(voCFiles)>0 
   oInc := ""
   for i := 1 to Len(voCFiles)
       if !Empty(voCFiles[i])
          if !Empty(oIncFolder)
             oInc := '/I"'+voIncFolder+'"'
          endif   
          oName := SubStr(voCFiles[i], 1, Len(voCFiles[i]) - 4)
   
          FWrite(oArq, oName + ".obj : " + voCFiles[i] + CRF)
          FWrite(oArq, "   $(CC_EXE) $(CFLAGS) /Fo$@ $** " + CRF)
   
       endif
   Next
   Endif
    
   FClose(oName)

RETURN NIL
