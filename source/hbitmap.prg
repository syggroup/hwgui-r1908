/*
 * $Id: drawwidg.prg 1740 2011-09-23 12:06:53Z LFBASSO $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * Bitmaps handling
 *
 * Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://www.geocities.com/alkresin/
*/

#include "hbclass.ch"
#include "windows.ch"
#include "guilib.ch"

CLASS HBitmap INHERIT HObject

CLASS VAR aBitmaps   INIT {}
   DATA handle
   DATA name
   DATA nWidth, nHeight
   DATA nCounter   INIT 1

   METHOD AddResource(name, nFlags, lOEM, nWidth, nHeight)
   METHOD AddStandard(nId)
   METHOD AddFile(name, hDC, lTranparent, nWidth, nHeight)
   METHOD AddWindow(oWnd, lFull)
   METHOD Draw(hDC, x1, y1, width, height) INLINE DrawBitmap(hDC, ::handle, SRCCOPY, x1, y1, width, height)
   METHOD Release()

ENDCLASS

METHOD AddResource(name, nFlags, lOEM, nWidth, nHeight) CLASS HBitmap
   LOCAL lPreDefined := .F., i, aBmpSize

   IF nFlags == NIL
      nFlags := LR_DEFAULTCOLOR
   ENDIF
   IF lOEM == NIL
      lOEM := .F.
   ENDIF
   IF hb_IsNumeric(name)
      name := LTrim(Str(name))
      lPreDefined := .T.
   ENDIF
   #ifdef __XHARBOUR__
      FOR EACH i  IN  ::aBitmaps
         IF i:name == name .AND. (nWidth == NIL .OR. nHeight == NIL)
            i:nCounter ++
            RETURN i
         ENDIF
      NEXT
   #else
      FOR i := 1 TO Len(::aBitmaps)
         IF ::aBitmaps[i]:name == name .AND. (nWidth == NIL .OR. nHeight == NIL)
            ::aBitmaps[i]:nCounter++
            RETURN ::aBitmaps[i]
         ENDIF
      NEXT
   #endif
   IF lOEM
      ::handle := LoadImage(0, Val(name), IMAGE_BITMAP, NIL, NIL, Hwg_bitor(nFlags, LR_SHARED))
   ELSE
      //::handle := LoadImage(NIL, IIf(lPreDefined, Val(name), name), IMAGE_BITMAP, NIL, NIL, nFlags)
      ::handle := LoadImage(NIL, IIf(lPreDefined, Val(name), name), IMAGE_BITMAP, nWidth, nHeight, nFlags)
   ENDIF
   ::name   := name
   aBmpSize  := GetBitmapSize(::handle)
   ::nWidth  := aBmpSize[1]
   ::nHeight := aBmpSize[2]
   AAdd(::aBitmaps, Self)

   RETURN Self

METHOD AddStandard(nId) CLASS HBitmap
   LOCAL i, aBmpSize, name := "s" + LTrim(Str(nId))

   #ifdef __XHARBOUR__
      FOR EACH i  IN  ::aBitmaps
         IF i:name == name
            i:nCounter ++
            RETURN i
         ENDIF
      NEXT
   #else
      FOR i := 1 TO Len(::aBitmaps)
         IF ::aBitmaps[i]:name == name
            ::aBitmaps[i]:nCounter++
            RETURN ::aBitmaps[i]
         ENDIF
      NEXT
   #endif
   ::handle :=   LoadBitmap(nId, .T.)
   ::name   := name
   aBmpSize  := GetBitmapSize(::handle)
   ::nWidth  := aBmpSize[1]
   ::nHeight := aBmpSize[2]
   AAdd(::aBitmaps, Self)

   RETURN Self

METHOD AddFile(name, hDC, lTranparent, nWidth, nHeight) CLASS HBitmap
   LOCAL i, aBmpSize, cname, cCurDir

   cname := CutPath(name)
   #ifdef __XHARBOUR__
      FOR EACH i IN ::aBitmaps
         IF i:name == name .AND. (nWidth == NIL .OR. nHeight == NIL)
            i:nCounter ++
            RETURN i
         ENDIF
      NEXT
   #else
      FOR i := 1 TO Len(::aBitmaps)
         IF ::aBitmaps[i]:name == name .AND. (nWidth == NIL .OR. nHeight == NIL)
            ::aBitmaps[i]:nCounter++
            RETURN ::aBitmaps[i]
         ENDIF
      NEXT
   #endif
   name := IIf(!File(name) .AND. FILE(CutPath(name)), CutPath(name), name)
   IF !File(name)
      cCurDir  := DiskName() + ':\' + CurDir()
      name := SelectFile("Image Files( *.jpg;*.gif;*.bmp;*.ico )", CutPath(name), FilePath(name), "Locate " + name) //"*.jpg;*.gif;*.bmp;*.ico"
      DirChange(cCurDir)
   ENDIF

    IF Lower(Right(name, 4)) != ".bmp" .OR. (nWidth == NIL .AND. nHeight == NIL .AND. lTranparent == Nil)
      IF Lower(Right(name, 4)) == ".bmp"
         ::handle := OpenBitmap(name, hDC)
      ELSE
         ::handle := OpenImage(name)
      ENDIF
   ELSE
      IF lTranparent != Nil .AND. lTranparent
         ::handle := LoadImage(NIL, name, IMAGE_BITMAP, nWidth, nHeight, LR_LOADFROMFILE + LR_LOADTRANSPARENT + LR_LOADMAP3DCOLORS)
      ELSE
         ::handle := LoadImage(NIL, name, IMAGE_BITMAP, nWidth, nHeight, LR_LOADFROMFILE)
         ENDIF
    ENDIF
   IF Empty(::handle)
      RETURN Nil
   ENDIF
   ::name := cname
   aBmpSize  := GetBitmapSize(::handle)
   ::nWidth  := aBmpSize[1]
   ::nHeight := aBmpSize[2]
   AAdd(::aBitmaps, Self)

   RETURN Self

METHOD AddWindow(oWnd, lFull) CLASS HBitmap
   LOCAL aBmpSize

   ::handle := Window2Bitmap(oWnd:handle, lFull)
   ::name := LTrim(hb_valToStr(oWnd:handle)) // TODO: verificar o que ocorre quando for tipo P
   aBmpSize  := GetBitmapSize(::handle)
   ::nWidth  := aBmpSize[1]
   ::nHeight := aBmpSize[2]
   AAdd(::aBitmaps, Self)

   RETURN Self

METHOD Release() CLASS HBitmap
   LOCAL i, nlen := Len(::aBitmaps)

   ::nCounter --
   IF ::nCounter == 0
      #ifdef __XHARBOUR__
         FOR EACH i IN ::aBitmaps
            IF i:handle == ::handle
               DeleteObject(::handle)
               ADel(::aBitmaps, hB_enumIndex())
               ASize(::aBitmaps, nlen - 1)
               EXIT
            ENDIF
         NEXT
      #else
         FOR i := 1 TO nlen
            IF ::aBitmaps[i]:handle == ::handle
               DeleteObject(::handle)
               ADel(::aBitmaps, i)
               ASize(::aBitmaps, nlen - 1)
               EXIT
            ENDIF
         NEXT
      #endif
   ENDIF
   RETURN Nil


EXIT PROCEDURE CleanDrawWidgHBitmap

   LOCAL item

   FOR EACH item IN HBitmap():aBitmaps
      DeleteObject(item:handle)
   NEXT

RETURN
