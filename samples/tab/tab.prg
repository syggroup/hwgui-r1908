#include "hwgui.ch"
#include "tab.rh"

FUNCTION Main()

   LOCAL oDlg1
   LOCAL oDlg2
   LOCAL oDlg3
   LOCAL oTab
   LOCAL aDlg1
   LOCAL aDlg2
   LOCAL aCombo := {"Aaaa", "Bbbb"}
   LOCAL oBrw1
   LOCAL oBrw2
   LOCAL aSample1 := {{"Alex", 17}, {"Victor", 42}, {"John", 31}}
   LOCAL aSample2 := {{"Line 1", 10}, {"Line 2", 22}, {"Line 3", 40}}
   LOCAL e1 := "Xxxx"
   LOCAL e2 := "Xxxx"
   LOCAL e3 := "Xxxx"

   INIT DIALOG oDlg1 FROM RESOURCE DIALOG_1 CLIPPER NOEXIT NOEXITESC ON INIT {||buildtabPages(oTab, {adlg1, adlg2}, {"pagina1", "pagina2"})}

/*
aDlg1:oParent := oTab, aDlg2:oParent := oTab,;
aDlg1:Activate(.T.),      aDlg2:Activate(.T.), ;
aDlg2:hide(),    oTab:StartPage("pagina1", aDlg1),    oTab:EndPage(), ;
oTab:StartPage("pagina2", aDlg2),    oTab:EndPage(), otab:changepage(1)

}
*/

REDEFINE TAB oTab ID IDC_1

oDlg1:lRouteCommand := .T.
   INIT DIALOG aDlg1 FROM RESOURCE  PAGE_1 CLIPPER NOEXIT NOEXITESC ON EXIT {||hwg_MsgInfo("Exit"), .T.}
   REDEFINE GET e1 ID 103
   REDEFINE GET e2 ID 104
   REDEFINE GET e3 ID 105

   INIT DIALOG aDlg2 FROM RESOURCE  PAGE_2 CLIPPER NOEXIT NOEXITESC ON EXIT {||hwg_MsgInfo("Exit"), .T.}
   REDEFINE COMBOBOX aCombo ID 101
   REDEFINE BROWSE oBrw1 ARRAY ID 104
   REDEFINE BROWSE oBrw2 ARRAY ID 105

   hwg_CreateArList(oBrw1, aSample1)
   hwg_CreateArList(oBrw2, aSample2)
  activate dialog oDlg1

RETURN NIL

FUNCTION buildtabPages(oTab, aPage, aTitle)

   LOCAL n

   for each n in aPage
      n:oParent := oTab
      n:activate(.T.)
      oTab:startpage(aTitle[hb_enumindex()], n)
      otab:endpage()
      n:oParent := nil
   next

RETURN .T.
