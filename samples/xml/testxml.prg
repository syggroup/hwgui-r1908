//
// $Id: testxml.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// This sample demonstrates reading/writing XML file and handling menu items
// while run-time.
//

#include "hwgui.ch"
#include "hxml.ch"

FUNCTION Main()

   LOCAL oXmlNode
   LOCAL i
   LOCAL j
   LOCAL fname := ""

   PRIVATE oXmlDoc
   PRIVATE lIniChanged := .F.
   PRIVATE nCurrentItem
   PRIVATE oMainWindow
   PRIVATE oFont

   oXmlDoc := HXMLDoc():Read("testxml.xml")

   PREPARE FONT oFont NAME "Times New Roman" WIDTH 0 HEIGHT -17 CHARSET 204

   INIT WINDOW oMainWindow MAIN TITLE "XML Sample"  ;
     COLOR COLOR_3DLIGHT + 1                       ;
     AT 200, 0 SIZE 600, 300                       ;
     ON EXIT {||SaveOptions()}                   ;
     FONT oFont

   MENU OF oMainWindow
      MENU TITLE "File"
         MENUITEM "New item" ACTION NewItem(0)
         SEPARATOR
         IF !Empty(oXmlDoc:aItems)
            nCurrentItem := 1
            FOR i := 1 TO Len(oXmlDoc:aItems[1]:aItems)
               oXmlNode := oXmlDoc:aItems[1]:aItems[i]
               fname := oXmlNode:GetAttribute("name")
               hwg_DefineMenuItem(fname, 1020 + i, &("{||NewItem(" + LTrim(Str(i, 2)) + ")}"))
            NEXT
            SEPARATOR
         ENDIF
         MENUITEM "Exit" ACTION hwg_EndWindow()
      ENDMENU

      MENU TITLE "Help"
         MENUITEM "About" ACTION ShellAbout("", "")
      ENDMENU
   ENDMENU

   ACTIVATE WINDOW oMainWindow

RETURN NIL

FUNCTION NewItem(nItem)

   LOCAL oDlg
   LOCAL oItemFont
   LOCAL oFontNew
   LOCAL oXmlNode
   LOCAL fname
   LOCAL i
   LOCAL j
   LOCAL aMenu
   LOCAL nId
   LOCAL cName
   LOCAL cInfo

   IF nItem > 0
      oXmlNode := oXmlDoc:aItems[1]:aItems[nItem]
      cName := oXmlNode:GetAttribute("name")
      FOR i := 1 TO Len(oXmlNode:aItems)
         IF ValType(oXmlNode:aItems[i]) == "C"
            cInfo := oXmlNode:aItems[i]
         ELSEIF oXmlNode:aItems[i]:title == "font"
            oItemFont := FontFromXML(oXmlNode:aItems[i])
         ENDIF
      NEXT
   ELSE
      cName := Space(30)
      cInfo := Space(100)
      oItemFont := oFont
   ENDIF

   INIT DIALOG oDlg TITLE IIf(nItem == 0, "New item", "Change item")  ;
      AT 210, 10 SIZE 300, 150 FONT oFont

   @ 20, 20 SAY "Name:" SIZE 60, 22
   @ 80, 20 GET cName SIZE 150, 26

   @ 240, 20 BUTTON "Font" SIZE 40, 32 ON CLICK {||oFontNew := HFont():Select(oItemFont)}

   @ 20, 50 SAY "Info:" SIZE 60, 22
   @ 80, 50 GET cInfo SIZE 150, 26

   @ 20, 110 BUTTON "Ok" SIZE 100, 32 ON CLICK {||oDlg:lResult := .T., EndDialog()}
   @ 180, 110 BUTTON "Cancel" ID IDCANCEL SIZE 100, 32

   ACTIVATE DIALOG oDlg

   IF oDlg:lResult .AND. !Empty(cName) .AND. !Empty(cInfo)
      IF nItem == 0
         oXmlNode := oXmlDoc:aItems[1]:Add(HXMLNode():New("item"))
         oXmlNode:SetAttribute("name", Trim(cName))
         oXmlNode:Add(Trim(cInfo))
         oXMLNode:Add(Font2XML(IIf(oFontNew != Nil, oFontNew, oFont)))
         lIniChanged := .T.

         aMenu := oMainWindow:menu[1, 1]
         nId := aMenu[1][Len(aMenu[1])-2, 3]+1
         hwg_AddMenuItem(aMenu, cName, nId, .F., ;
              &("{||NewItem(" + LTrim(Str(nId - 1020, 2)) + ")}"), Len(aMenu[1]) - 1)

      ELSE
         IF oXmlNode:GetAttribute("name") != cName
            oXmlNode:SetAttribute("name", cName)
            lIniChanged := .T.
            SetMenuCaption(, 1020 + nItem, cName)
         ENDIF
         FOR i := 1 TO Len(oXmlNode:aItems)
            IF ValType(oXmlNode:aItems[i]) == "C"
               IF cInfo != oXmlNode:aItems[i]
                  oXmlNode:aItems[i] := cInfo
                  lIniChanged := .T.
               ENDIF
            ELSEIF oXmlNode:aItems[i]:title == "font"
               IF oFontNew != Nil
                  oXMLNode:aItems[i] := Font2XML(oFontNew)
                  lIniChanged := .T.
               ENDIF
            ENDIF
         NEXT
      ENDIF
   ENDIF

RETURN NIL

FUNCTION FontFromXML(oXmlNode)

   LOCAL width := oXmlNode:GetAttribute("width")
   LOCAL height := oXmlNode:GetAttribute("height")
   LOCAL weight := oXmlNode:GetAttribute("weight")
   LOCAL charset := oXmlNode:GetAttribute("charset")
   LOCAL ita := oXmlNode:GetAttribute("italic")
   LOCAL under := oXmlNode:GetAttribute("underline")

  IF width != Nil
     width := Val(width)
  ENDIF
  IF height != Nil
     height := Val(height)
  ENDIF
  IF weight != Nil
     weight := Val(weight)
  ENDIF
  IF charset != Nil
     charset := Val(charset)
  ENDIF
  IF ita != Nil
     ita := Val(ita)
  ENDIF
  IF under != Nil
     under := Val(under)
  ENDIF

RETURN HFont():Add(oXmlNode:GetAttribute("name"), width, height, weight, charset, ita, under)

FUNCTION Font2XML(oFont)

   LOCAL aAttr := {}

   AAdd(aAttr, { "name", oFont:name })
   AAdd(aAttr, { "width", Ltrim(Str(oFont:width, 5)) })
   AAdd(aAttr, { "height", Ltrim(Str(oFont:height, 5)) })
   IF oFont:weight != 0
      AAdd(aAttr, { "weight", Ltrim(Str(oFont:weight, 5)) })
   ENDIF
   IF oFont:charset != 0
      AAdd(aAttr, { "charset", Ltrim(Str(oFont:charset, 5)) })
   ENDIF
   IF oFont:Italic != 0
      AAdd(aAttr, { "italic", Ltrim(Str(oFont:Italic, 5)) })
   ENDIF
   IF oFont:Underline != 0
      AAdd(aAttr, { "underline", Ltrim(Str(oFont:Underline, 5)) })
   ENDIF

RETURN HXMLNode():New("font", HBXML_TYPE_SINGLE, aAttr)

FUNCTION SaveOptions()

   IF lIniChanged
      oXmlDoc:Save("testxml.xml")
   ENDIF
   CLOSE ALL

RETURN NIL
