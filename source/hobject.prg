/*
 *$Id: hcwindow.prg 1868 2012-08-27 17:33:11Z lfbasso $
 *
 * HWGUI - Harbour Win32 GUI library source code:
 * HObject class
 *
 * Copyright 2004 Alexander S.Kresin <alex@belacy.belgorod.su>
 * www - http://kresin.belgorod.su
*/

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"
#include "common.ch"

//-------------------------------------------------------------------------------------------------------------------//

CLASS HObject

   DATA aObjects INIT {}

   METHOD AddObject(oCtrl) INLINE AAdd(::aObjects, oCtrl)
   METHOD DelObject(oCtrl)
   METHOD Release() INLINE ::DelObject(Self)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD DelObject(oCtrl) CLASS HObject

   LOCAL h := oCtrl:handle
   LOCAL i := Ascan(::aObjects, {|o|o:handle == h})

   SendMessage(h, WM_CLOSE, 0, 0)
   IF i != 0
      Adel(::aObjects, i)
      Asize(::aObjects, Len(::aObjects) - 1)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

PROCEDURE HB_GT_DEFAULT_NUL()
RETURN

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION ADDMETHOD(oObjectName, cMethodName, pFunction)

   IF hb_IsObject(oObjectName) .AND. !Empty(cMethodName)
      IF !__ObjHasMsg(oObjectName, cMethodName)
         __objAddMethod(oObjectName, cMethodName, pFunction)
      ENDIF
      RETURN .T.
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION ADDPROPERTY(oObjectName, cPropertyName, eNewValue)

   IF hb_IsObject(oObjectName) .AND. !Empty(cPropertyName)
      IF !__objHasData(oObjectName, cPropertyName)
         IF Empty(__objAddData(oObjectName, cPropertyName))
            RETURN .F.
         ENDIF
      ENDIF
      IF !Empty(eNewValue)
         IF hb_IsBlock(eNewValue)
            oObjectName: &(cPropertyName) := EVAL(eNewValue)
         ELSE
            oObjectName: &(cPropertyName) := eNewValue
         ENDIF
      ENDIF
      RETURN .T.
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION REMOVEPROPERTY(oObjectName, cPropertyName)

   IF hb_IsObject(oObjectName) .AND. !Empty(cPropertyName) .AND. __objHasData(oObjectName, cPropertyName)
       RETURN Empty(__objDelData(oObjectName, cPropertyName))
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//
/*
INIT PROCEDURE HWGINIT

   hwg_ErrorSys()

RETURN
*/
//-------------------------------------------------------------------------------------------------------------------//
