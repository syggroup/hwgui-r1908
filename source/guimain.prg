//
// $Id: guimain.prg 1896 2012-09-14 13:39:10Z lfbasso $
//
// HWGUI - Harbour Win32 GUI library source code:
// Main prg level functions
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "guilib.ch"
#include "common.ch"

#ifdef __XHARBOUR__
   #xtranslate hb_processOpen([<x,...>])   => hb_openProcess(<x>)
   #xtranslate hb_NumToHex([<n,...>])      => NumToHex(<n>)
#endif

//STATIC _winwait (variable not used)

FUNCTION InitObjects(oWnd)
   LOCAL i, pArray := oWnd:aObjects 
   LOCAL LoadArray := HObject():aObjects
   
   IF !Empty(LoadArray)
      FOR i := 1 TO Len(LoadArray)
         IF !Empty(oWnd:handle)
            IF __ObjHasMsg(LoadArray[i], "INIT")
               LoadArray[i]:Init(oWnd)
               LoadArray[i]:lInit := .T.
            ENDIF
         ENDIF
      NEXT   
   ENDIF
   IF pArray != NIL
      FOR i := 1 TO Len(pArray)
         IF __ObjHasMsg(pArray[i], "INIT")
            pArray[i]:Init(oWnd)
         ENDIF
      NEXT
   ENDIF
   HObject():aObjects := {}
   RETURN .T.

FUNCTION InitControls(oWnd, lNoActivate)
   LOCAL i, pArray := oWnd:aControls, lInit

   lNoActivate := IIf(lNoActivate == NIL, .F., lNoActivate)

   IF pArray != NIL
      FOR i := 1 TO Len(pArray)
         // hwg_WriteLog("InitControl1" + Str(pArray[i]:handle) + "/" + pArray[i]:classname + " " + Str(pArray[i]:nWidth) + "/" + Str(pArray[i]:nHeight))
         IF Empty(pArray[i]:handle) .AND. !lNoActivate
//         IF Empty(pArray[i]:handle) .AND. !lNoActivate
            lInit := pArray[i]:lInit
            pArray[i]:lInit := .T.
            pArray[i]:Activate()
            pArray[i]:lInit := lInit
         ELSEIF !lNoActivate
            pArray[i]:lInit := .T.
         ENDIF
//           IF Empty(pArray[i]:handle)// <= 0
         IF IIf(hb_IsPointer(pArray[i]:handle), ptrtoulong(pArray[i]:handle), pArray[i]:handle) <= 0 // TODO: verificar
            pArray[i]:handle := hwg_GetDlgItem(oWnd:handle, pArray[i]:id)

            // hwg_WriteLog("InitControl2" + Str(pArray[i]:handle) + "/" + pArray[i]:classname)
         ENDIF
         IF !Empty(pArray[i]:aControls)
            InitControls(pArray[i])
         ENDIF
         pArray[i]:Init()
          // nando required to classes that inherit the class of patterns hwgui
         IF !pArray[i]:lInit
            pArray[i]:Super:Init()
         ENDIF
      NEXT
   ENDIF

   RETURN .T.

FUNCTION FindParent(hCtrl, nLevel)
   LOCAL i, oParent, hParent := hwg_GetParent(hCtrl)
   IF !Empty(hParent)
      IF (i := AScan(HDialog():aModalDialogs, {|o|o:handle == hParent})) != 0
         RETURN HDialog():aModalDialogs[i]
      ELSEIF (oParent := HDialog():FindDialog(hParent)) != NIL
         RETURN oParent
      ELSEIF (oParent := HWindow():FindWindow(hParent)) != NIL
         RETURN oParent
      ENDIF
   ENDIF
   IF nLevel == NIL
      nLevel := 0
   ENDIF
   IF nLevel < 2
      IF (oParent := FindParent(hParent, nLevel + 1)) != NIL
         RETURN oParent:FindControl(, hParent)
      ENDIF
   ENDIF
   RETURN NIL

FUNCTION FindSelf(hCtrl)
   LOCAL oParent
   oParent := FindParent(hCtrl)
   IF oParent == NIL
      oParent := hwg_GetAncestor(hCtrl, GA_PARENT)
   ENDIF
   IF oParent != NIL .AND. !hb_IsNumeric(oParent)
      RETURN oParent:FindControl(, hCtrl)
   ENDIF
   RETURN NIL

FUNCTION WriteStatus(oWnd, nPart, cText, lRedraw)
   LOCAL aControls, i
   aControls := oWnd:aControls
   IF (i := AScan(aControls, {|o|o:ClassName() == "HSTATUS"})) > 0
      WriteStatusWindow(aControls[i]:handle, nPart - 1, cText)
      IF lRedraw != NIL .AND. lRedraw
         hwg_RedrawWindow(aControls[i]:handle, RDW_ERASE + RDW_INVALIDATE)
      ENDIF
   ENDIF
   RETURN NIL

FUNCTION ReadStatus(oWnd, nPart)
   LOCAL aControls, i, ntxtLen, cText := ""
   aControls := oWnd:aControls
   IF (i := AScan(aControls, {|o|o:ClassName() == "HSTATUS"})) > 0
      ntxtLen := hwg_SendMessage(aControls[i]:handle, SB_GETTEXTLENGTH, nPart - 1, 0)
      cText := Replicate(Chr(0), ntxtLen)
      hwg_SendMessage(aControls[i]:handle, SB_GETTEXT, nPart - 1, @cText)
   ENDIF
   RETURN cText

FUNCTION hwg_VColor(cColor)
   LOCAL i, res := 0, n := 1, iValue
   cColor := Trim(cColor)
   FOR i := 1 TO Len(cColor)
      iValue := Asc(SubStr(cColor, Len(cColor) - i + 1, 1))
      IF iValue < 58 .AND. iValue > 47
         iValue -= 48
      ELSEIF iValue >= 65 .AND. iValue <= 70
         iValue -= 55
      ELSEIF iValue >= 97 .AND. iValue <= 102
         iValue -= 87
      ELSE
         RETURN 0
      ENDIF
      res += iValue * n
      n *= 16
   NEXT
   RETURN res

FUNCTION MsgGet(cTitle, cText, nStyle, x, y, nDlgStyle, cResIni)
   LOCAL oModDlg, oFont := HFont():Add("MS Sans Serif", 0, -13)
   LOCAL cRes := IIf(cResIni != NIL, Trim(cResIni), "")
   /*
   IF !Empty(cRes)
      Keyb_Event(VK_END)
   ENDIF
   */
   nStyle := IIf(nStyle == NIL, 0, nStyle)
   x := IIf(x == NIL, 210, x)
   y := IIf(y == NIL, 10, y)
   nDlgStyle := IIf(nDlgStyle == NIL, 0, nDlgStyle)

   INIT DIALOG oModDlg TITLE cTitle At x, y SIZE 300, 140 ;
        FONT oFont CLIPPER ;
        STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + nDlgStyle

   @ 20, 10 SAY cText SIZE 260, 22
   @ 20, 35 GET cRes  SIZE 260, 26 STYLE WS_TABSTOP + ES_AUTOHSCROLL + nStyle
   oModDlg:aControls[2]:Anchor := 11
   @ 20, 95 BUTTON "Ok" ID IDOK SIZE 100, 32
   @ 180, 95 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32
   oModDlg:aControls[4]:Anchor := 9
   
   ACTIVATE DIALOG oModDlg ON ACTIVATE {||IIf(!Empty(cRes), KEYB_EVENT(VK_END), .T.)}

   oFont:Release()
   IF oModDlg:lResult
      RETURN Trim(cRes)
   ELSE
      cRes := ""
   ENDIF

   RETURN cRes

FUNCTION WAITRUN(cRun)
//#ifdef __XHARBOUR__
Local hIn, hOut, nRet, hProc
   // "Launching process", cProc
   hProc := hb_processOpen(cRun, @hIn, @hOut, @hOut)

   // "Reading output"
   // "Waiting for process termination"
   nRet := HB_ProcessValue(hProc)

   FClose(hProc)
   FClose(hIn)
   FClose(hOut)

   RETURN nRet
//#else
//  __Run(cRun)
//   RETURN 0
//#endif

FUNCTION WChoice(arr, cTitle, nLeft, nTop, oFont, clrT, clrB, clrTSel, clrBSel, cOk, cCancel)
   LOCAL oDlg, oBrw, nChoice := 0, lArray := .T., nField, lNewFont := .F.
   LOCAL i, aLen, nLen := 0, addX := 20, addY := 20, minWidth := 0, x1
   LOCAL hDC, aMetr, width, height, aArea, aRect
   LOCAL nStyle := WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX

   IF cTitle == NIL
      cTitle := ""
   ENDIF
   IF nLeft == NIL .AND. nTop == NIL
      nStyle += DS_CENTER
   ENDIF
   IF nLeft == NIL
      nLeft := 0
   ENDIF
   IF nTop == NIL
      nTop := 0
   ENDIF
   IF oFont == NIL
      oFont := HFont():Add("MS Sans Serif", 0, -13)
      lNewFont := .T.
   ENDIF
   IF cOk != NIL
      minWidth += 120
      IF cCancel != NIL
         minWidth += 100
      ENDIF
      addY += 30
   ENDIF

   IF hb_IsChar(arr)
      lArray := .F.
      aLen := RecCount()
      IF (nField := FieldPos(arr)) == 0
         RETURN 0
      ENDIF
      nLen := dbFieldInfo(3, nField)
   ELSE
      aLen := Len(arr)
      IF hb_IsArray(arr[1])
         FOR i := 1 TO aLen
            nLen := Max(nLen, Len(arr[i, 1]))
         NEXT
      ELSE
         FOR i := 1 TO aLen
            nLen := Max(nLen, Len(arr[i]))
         NEXT
      ENDIF
   ENDIF

   hDC := hwg_GetDC(hwg_GetActiveWindow())
   hwg_SelectObject(hDC, oFont:handle)
   aMetr := GetTextMetric(hDC)
   aArea := GetDeviceArea(hDC)
   aRect := hwg_GetWindowRect(hwg_GetActiveWindow())
   hwg_ReleaseDC(hwg_GetActiveWindow(), hDC)
   height := (aMetr[1] + 1) * aLen + 4 + addY + 8
   IF height > aArea[2] - aRect[2] - nTop - 60
      height := aArea[2] - aRect[2] - nTop - 60
   ENDIF
   width := Max(aMetr[2] * 2 * nLen + addX, minWidth)

   INIT DIALOG oDlg TITLE cTitle ;
        At nLeft, nTop           ;
        SIZE width, height       ;
        STYLE nStyle            ;
        FONT oFont              ;
        ON INIT {|o|hwg_ResetWindowPos(o:handle), o:nInitFocus := oBrw}
       //ON INIT {|o|hwg_ResetWindowPos(o:handle), oBrw:setfocus()}
   IF lArray
      @ 0, 0 Browse oBrw Array
      oBrw:aArray := arr
      IF hb_IsArray(arr[1])
         oBrw:AddColumn(HColumn():New(, {|value, o|HB_SYMBOL_UNUSED(value), o:aArray[o:nCurrent, 1]}, "C", nLen))
      ELSE
         oBrw:AddColumn(HColumn():New(, {|value, o|HB_SYMBOL_UNUSED(value), o:aArray[o:nCurrent]}, "C", nLen))
      ENDIF
   ELSE
      @ 0, 0 Browse oBrw DATABASE
      oBrw:AddColumn(HColumn():New(, {|value, o|HB_SYMBOL_UNUSED(value), (o:Alias)->(FieldGet(nField))}, "C", nLen))
   ENDIF

   oBrw:oFont  := oFont
   oBrw:bSize  := {|o, x, y|hwg_MoveWindow(o:handle, addX / 2, 10, x - addX, y - addY)}
   oBrw:bEnter := {|o|nChoice := o:nCurrent, EndDialog(o:oParent:handle)}
   oBrw:bKeyDown := {|o, key|HB_SYMBOL_UNUSED(o), IIf(key == 27, (EndDialog(oDlg:handle), .F.), .T.)}

   oBrw:lDispHead := .F.
   IF clrT != NIL
      oBrw:tcolor := clrT
   ENDIF
   IF clrB != NIL
      oBrw:bcolor := clrB
   ENDIF
   IF clrTSel != NIL
      oBrw:tcolorSel := clrTSel
   ENDIF
   IF clrBSel != NIL
      oBrw:bcolorSel := clrBSel
   ENDIF

   IF cOk != NIL
      x1 := Int(width / 2) - IIf(cCancel != NIL, 90, 40)
      @ x1, height - 36 BUTTON cOk SIZE 80, 30 ON CLICK {||nChoice := oBrw:nCurrent, EndDialog(oDlg:handle)}
      IF cCancel != NIL
         @ x1 + 100, height - 36 BUTTON cCancel SIZE 80, 30 ON CLICK {||nChoice := 0, EndDialog(oDlg:handle)}
      ENDIF
   ENDIF

   oDlg:Activate()
   IF lNewFont
      oFont:Release()
   ENDIF

   RETURN nChoice

FUNCTION ShowProgress(nStep, maxPos, nRange, cTitle, oWnd, x1, y1, width, height)
   LOCAL nStyle := WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX
   STATIC oDlg, hPBar, iCou, nLimit

   IF nStep == 0
      nLimit := IIf(nRange != NIL, Int(nRange / maxPos), 1)
      iCou := 0
      x1 := IIf(x1 == NIL, 0, x1)
      y1 := IIf(x1 == NIL, 0, y1)
      width := IIf(width == NIL, 220, width)
      height := IIf(height == NIL, 55, height)
      IF x1 == 0
         nStyle += DS_CENTER
      ENDIF
      IF oWnd != NIL
         oDlg := NIL
         hPBar := CreateProgressBar(oWnd:handle, maxPos, 20, 25, width - 40, 20)
      ELSE
         INIT DIALOG oDlg TITLE cTitle   ;
              At x1, y1 SIZE width, height ;
              STYLE nStyle               ;
              ON INIT {|o|hPBar := CreateProgressBar(o:handle, maxPos, 20, 25, width - 40, 20)}
         ACTIVATE DIALOG oDlg NOMODAL
      ENDIF
   ELSEIF nStep == 1
      iCou++
      IF iCou == nLimit
         iCou := 0
         UpdateProgressBar(hPBar)
      ENDIF
   ELSEIF nStep == 2
      UpdateProgressBar(hPBar)
   ELSEIF nStep == 3
      hwg_SetWindowText(oDlg:handle, cTitle)
      IF maxPos != NIL
         SetProgressBar(hPBar, maxPos)
      ENDIF
   ELSE
      hwg_DestroyWindow(hPBar)
      IF oDlg != NIL
         EndDialog(oDlg:handle)
      ENDIF
   ENDIF

   RETURN NIL

FUNCTION hwg_EndWindow()
   IF HWindow():GetMain() != NIL
      hwg_SendMessage(HWindow():aWindows[1]:handle, WM_SYSCOMMAND, SC_CLOSE, 0)
   ENDIF
   RETURN NIL

FUNCTION HdSerial(cDrive)

   LOCAL n       :=  hwg_HDGetSerial(cDrive)
   LOCAL cHex    :=  HB_NUMTOHEX(n)
   LOCAL cResult
   cResult := SubStr(cHex, 1, 4) + "-" + SubStr(cHex, 5, 4)

   RETURN cResult

FUNCTION hwg_GetIni(cSection, cEntry, cDefault, cFile)
   RETURN hwg_GetPrivateProfileString(cSection, cEntry, cDefault, cFile)

FUNCTION hwg_WriteIni(cSection, cEntry, cValue, cFile)
   RETURN hwg_WritePrivateProfileString(cSection, cEntry, cValue, cFile)

FUNCTION SetHelpFileName(cNewName)
   STATIC cName := ""
   LOCAL cOldName := cName
   IF cNewName != NIL
      cName := cNewName
   ENDIF
   RETURN cOldName

FUNCTION RefreshAllGets(oDlg)

   AEval(oDlg:GetList, {|o|o:Refresh()})
   RETURN NIL

/*

cTitle:   Window Title
cDescr:  'Data Bases','*.dbf'
cTip  :   *.dbf
cInitDir: Initial directory

*/

FUNCTION SelectMultipleFiles(cDescr, cTip, cIniDir, cTitle)

   LOCAL aFiles, cPath, cFile, cFilter, nAt
   LOCAL hWnd := 0
   LOCAL nFlags := NIL
   LOCAL nIndex := 1

   cFilter := cDescr + Chr(0) + cTip + Chr(0)
   /* initialize buffer with 0 bytes. Important is the 1-st character,
    * from MSDN:  The first character of this buffer must be NULL
    *             if initialization is not necessary
    */
   cFile := repl(Chr(0), 32000)
   aFiles := {}

   cPath := hwg__GetOpenFileName(hWnd, @cFile, cTitle, cFilter, nFlags, cIniDir, NIL, @nIndex)

   nAt := At(Chr(0) + Chr(0), cFile)
   IF nAt != 0
      cFile := Left(cFile, nAt - 1)
      nAt := At(Chr(0), cFile)
      IF nAt != 0
         /* skip path which is already in cPath variable */
         cFile := SubStr(cFile, nAt + 1)
         /* decode files */
         DO WHILE !(cFile == "")
            nAt := At(Chr(0), cFile)
            IF nAt != 0
               AAdd(aFiles, cPath + hb_osPathSeparator() + Left(cFile, nAt - 1))
               cFile := SubStr(cFile, nAt + 1)
            ELSE
               AAdd(aFiles, cPath + hb_osPathSeparator() + cFile)
               EXIT
            ENDIF
         ENDDO
      ELSE
         /* only single file selected */
         AAdd(aFiles, cPath)
      ENDIF
   ENDIF
   RETURN aFiles

FUNCTION HWG_Version(oTip)
   LOCAL oVersion
   IF oTip == 1
      oVersion := "HwGUI " + HWG_VERSION + " " + Version()
   ELSE
      oVersion := "HwGUI " + HWG_VERSION
   ENDIF
   RETURN oVersion

FUNCTION TxtRect(cTxt, oWin, oFont)

   LOCAL hDC
   LOCAL ASize
   LOCAL hFont

   oFont := IIf(oFont != NIL, oFont, oWin:oFont)

   hDC       := hwg_GetDC(oWin:handle)
   IF oFont == NIL .AND. oWin:oParent != NIL
      oFont := oWin:oParent:oFont
   ENDIF
   IF oFont != NIL
      hFont := hwg_SelectObject(hDC, oFont:handle)
   ENDIF
   ASize     := GetTextSize(hDC, cTxt)
   IF oFont != NIL
      hwg_SelectObject(hDC, hFont)
   ENDIF
   hwg_ReleaseDC(oWin:handle, hDC)
   RETURN ASize

#pragma BEGINDUMP

#include <hbapi.h>

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(ENDWINDOW, HWG_ENDWINDOW);
HB_FUNC_TRANSLATE(VCOLOR, HWG_VCOLOR);
#endif

#pragma ENDDUMP
