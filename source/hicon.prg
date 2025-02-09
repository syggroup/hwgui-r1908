//
// $Id: drawwidg.prg 1740 2011-09-23 12:06:53Z LFBASSO $
//
// HWGUI - Harbour Win32 GUI library source code:
// Icons handling
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://www.geocities.com/alkresin/
//

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

//-------------------------------------------------------------------------------------------------------------------//

CLASS HIcon INHERIT HObject

   CLASS VAR aIcons INIT {}

   DATA handle
   DATA name
   DATA nWidth
   DATA nHeight
   DATA nCounter INIT 1

   METHOD AddResource(name, nWidth, nHeight, nFlags, lOEM)
   METHOD AddFile(name, nWidth, nHeight)
   METHOD Draw(hDC, x, y) INLINE DrawIcon(hDC, ::handle, x, y)
   METHOD Release()

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD AddResource(name, nWidth, nHeight, nFlags, lOEM) CLASS HIcon

   LOCAL lPreDefined := .F.
   LOCAL item
   LOCAL aIconSize

   IF nWidth == NIL
      nWidth := 0
   ENDIF
   IF nHeight == NIL
      nHeight := 0
   ENDIF
   IF nFlags == NIL
      nFlags := 0
   ENDIF
   IF lOEM == NIL
      lOEM := .F.
   ENDIF
   IF hb_IsNumeric(name)
      name := LTrim(Str(name))
      lPreDefined := .T.
   ENDIF
   FOR EACH item IN ::aIcons
      IF item:name == name
         item:nCounter++
         RETURN item
      ENDIF
   NEXT
   // ::classname := "HICON"
   IF lOEM // LR_SHARED is required for OEM images
      ::handle := LoadImage(0, Val(name), IMAGE_ICON, nWidth, nHeight, hwg_bitor(nFlags, LR_SHARED))
   ELSE
      ::handle := LoadImage(NIL, IIf(lPreDefined, Val(name), name), IMAGE_ICON, nWidth, nHeight, nFlags)
   ENDIF
   ::name := name
   aIconSize := GetIconSize(::handle)
   ::nWidth := aIconSize[1]
   ::nHeight := aIconSize[2]

   AAdd(::aIcons, SELF)

RETURN SELF

//-------------------------------------------------------------------------------------------------------------------//

METHOD AddFile(name, nWidth, nHeight) CLASS HIcon

   LOCAL item
   LOCAL aIconSize
   LOCAL cname
   LOCAL cCurDir

   IF nWidth == NIL
      nWidth := 0
   ENDIF
   IF nHeight == NIL
      nHeight := 0
   ENDIF
   cname := CutPath(name)
   FOR EACH item IN ::aIcons
      IF item:name == name
         item:nCounter++
         RETURN item
      ENDIF
   NEXT
   // ::classname := "HICON"
   name := IIf(!File(name) .AND. FILE(CutPath(name)), CutPath(name), name)
   IF !File(name)
      cCurDir := DiskName() + ":\" + CurDir()
      name := hwg_SelectFile("Image Files( *.jpg;*.gif;*.bmp;*.ico )", CutPath(name), FilePath(name), "Locate " + name) //"*.jpg;*.gif;*.bmp;*.ico"
      DirChange(cCurDir)
   ENDIF

   //::handle := LoadImage(0, name, IMAGE_ICON, 0, 0, LR_DEFAULTSIZE + LR_LOADFROMFILE)
   ::handle := LoadImage(0, name, IMAGE_ICON, nWidth, nHeight, LR_DEFAULTSIZE + LR_LOADFROMFILE + LR_SHARED)
   ::name := cname
   aIconSize := GetIconSize(::handle)
   ::nWidth := aIconSize[1]
   ::nHeight := aIconSize[2]

   AAdd(::aIcons, SELF)

RETURN SELF

//-------------------------------------------------------------------------------------------------------------------//

METHOD Release() CLASS HIcon

   LOCAL item
   LOCAL nlen := Len(::aIcons)

   ::nCounter--
   IF ::nCounter == 0
      FOR EACH item IN ::aIcons
         IF item:handle == ::handle
            hwg_DeleteObject(::handle)
            #ifdef __XHARBOUR__
            ADel(::aIcons, hb_enumindex())
            #else
            ADel(::aIcons, item:__enumindex())
            #endif
            ASize(::aIcons, nlen - 1)
            EXIT
         ENDIF
      NEXT
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

EXIT PROCEDURE CleanDrawWidgHIcon

   LOCAL item

   FOR EACH item IN HIcon():aIcons
      hwg_DeleteObject(item:handle)
   NEXT

RETURN

//-------------------------------------------------------------------------------------------------------------------//
