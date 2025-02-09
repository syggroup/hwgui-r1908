//
// $Id: hprogres.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// HProgressBar class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"


CLASS HProgressBar INHERIT HControl

CLASS VAR winclass   INIT "msctls_progress32"
   DATA  maxPos
   DATA  nRange
   DATA  lNewBox
   DATA  nCount INIT 0
   DATA  nLimit
    DATA  nAnimation
    DATA  LabelBox
    DATA  nPercent INIT 0
    DATA  lPercent INIT .F.

   METHOD New(oWndParent, nId, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bInit, bSize, bPaint, ctooltip, nAnimation, lVertical)
   METHOD NewBox(cTitle, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bExit, lPercent)
   METHOD Init()
   METHOD Activate()
   METHOD Increment() INLINE UpdateProgressBar(::handle)
   METHOD STEP(cTitle)
   METHOD SET(cTitle, nPos)
   METHOD SetLabel(cCaption)
   METHOD SetAnimation(nAnimation) SETGET
   METHOD Close()
   METHOD End() INLINE hwg_DestroyWindow(::handle)

ENDCLASS

METHOD New(oWndParent, nId, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bInit, bSize, bPaint, ctooltip, nAnimation, lVertical) CLASS HProgressBar

   ::Style := IIf(lvertical != NIL .AND. lVertical, PBS_VERTICAL, 0)
    ::Style += IIf(nAnimation != NIL .AND. nAnimation > 0, PBS_MARQUEE, 0)
    ::nAnimation := nAnimation

   ::Super:New(oWndParent, nId, ::Style, nLeft, nTop, nWidth, nHeight,, bInit, bSize, bPaint, ctooltip)

   ::maxPos  := IIf(maxPos != NIL .AND. maxPos != 0, maxPos, 20)
   ::lNewBox := .F.
   ::nRange := IIf(nRange != NIL .AND. nRange != 0, nRange, 100)
   ::nLimit := Int(::nRange/::maxPos)

   ::Activate()

   RETURN Self

METHOD NewBox(cTitle, nLeft, nTop, nWidth, nHeight, maxPos, nRange, bExit, lPercent) CLASS HProgressBar

   // ::classname:= "HPROGRESSBAR"
   ::style   := WS_CHILD + WS_VISIBLE
   nWidth := IIf(nWidth == NIL, 220, nWidth)
   nHeight := IIf(nHeight == NIL, 55, nHeight)
   nLeft   := IIf(nLeft == NIL, 0, nLeft)
   nTop    := IIf(nTop == NIL, 0, nTop)
   //nWidth  := IIf(nWidth == NIL, 220, nWidth)
  // nHeight := IIf(nHeight == NIL, 55, nHeight)
   ::nLeft := 20
   ::nTop  := 25
   ::nWidth  := nWidth - 40
   ::maxPos  := IIf(maxPos == NIL, 20, maxPos)
   ::lNewBox := .T.
   ::nRange := IIf(nRange != NIL .AND. nRange != 0, nRange, 100)
   ::nLimit := IIf(nRange != NIL, Int(::nRange / ::maxPos), 1)
    ::lPercent := lPercent

   INIT DIALOG ::oParent TITLE cTitle       ;
        At nLeft, nTop SIZE nWidth, nHeight   ;
        STYLE WS_POPUP + WS_VISIBLE + WS_CAPTION + WS_SYSMENU + WS_SIZEBOX + IIf(nTop == 0, DS_CENTER, 0) + DS_SYSMODAL + MB_USERICON

   @ ::nLeft, nTop + 5 SAY ::LabelBox CAPTION IIf(Empty(lPercent), "", "%")  SIZE ::nWidth, 19 ;
       STYLE SS_CENTER

   IF bExit != NIL
      ::oParent:bDestroy := bExit
   ENDIF

   ACTIVATE DIALOG ::oParent NOMODAL

   ::id := ::NewId()
   ::nHeight := 0
   ::Activate()
   ::oParent:AddControl(Self)

   RETURN Self

METHOD Activate() CLASS HProgressBar

   IF !Empty(::oParent:handle)
      ::handle := CreateProgressBar(::oParent:handle, ::maxPos, ::style, ;
                                     ::nLeft, ::nTop, ::nWidth, IIf(::nHeight == 0, NIL, ::nHeight))
      ::Init()
   ENDIF
   RETURN NIL

METHOD Init() CLASS HProgressBar

   IF !::lInit
      ::Super:Init()
       IF ::nAnimation != NIL .AND. ::nAnimation > 0
          hwg_SendMessage(::handle, PBM_SETMARQUEE, 1, ::nAnimation)
       ENDIF
   ENDIF

  RETURN NIL

METHOD STEP(cTitle)

   ::nCount++
   IF ::nCount == ::nLimit
      ::nCount := 0
      UpdateProgressBar(::handle)
      ::SET(cTitle)
      IF !Empty(::lPercent)
         ::nPercent += ::maxPos  //::nLimit
         ::setLabel(LTrim(Str(::nPercent, 3)) + " %")
      ENDIF
      RETURN .T.
   ENDIF

   RETURN .F.

METHOD SET(cTitle, nPos) CLASS HProgressBar

   IF cTitle != NIL
      hwg_SetWindowText(::oParent:handle, cTitle)
   ENDIF
   IF nPos != NIL
      SetProgressBar(::handle, nPos)
   ENDIF

   RETURN NIL

METHOD SetLabel(cCaption) CLASS HProgressBar

   IF cCaption != NIL .AND. ::lNewBox
      ::LabelBox:SetValue(cCaption)
   ENDIF

   RETURN NIL

METHOD SetAnimation(nAnimation) CLASS HProgressBar

   IF nAnimation != NIL
       IF nAnimation <= 0
          hwg_SendMessage(::handle, PBM_SETMARQUEE, 0, NIL)
          MODIFYSTYLE(::handle, PBS_MARQUEE, 0)
          hwg_SendMessage(::handle, PBM_SETPOS, 0, 0)
       ELSE
          IF hwg_BitAND(::Style, PBS_MARQUEE) == 0
             MODIFYSTYLE(::handle, PBS_MARQUEE, PBS_MARQUEE)
         ENDIF
         hwg_SendMessage(::handle, PBM_SETMARQUEE, 1, nAnimation)
       ENDIF
       ::nAnimation := nAnimation
   ENDIF
   RETURN IIf(::nAnimation != NIL, ::nAnimation, 0)

METHOD Close()

   hwg_DestroyWindow(::handle)
   IF ::lNewBox
      EndDialog(::oParent:handle)
   ENDIF

   RETURN NIL

