//
// $Id: listbox.c 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// HList class
//
// Copyright 2002 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://www.geocities.com/alkresin/
// Listbox class and accompanying code added Feb 22nd, 2004 by
// Vic McClung
//

#include "hwingui.h"
#if defined(__MINGW32__) || defined(__MINGW64__) || defined(__WATCOMC__)
#include <prsht.h>
#endif
#include <hbapiitm.h>
#include <hbvm.h>
#include <hbstack.h>

HB_FUNC(HWG_LISTBOXADDSTRING)
{
  void *hString;
  SendMessage(hwg_par_HWND(1), LB_ADDSTRING, 0, (LPARAM)HB_PARSTR(2, &hString, NULL));
  hb_strfree(hString);
}

HB_FUNC_TRANSLATE(LISTBOXADDSTRING, HWG_LISTBOXADDSTRING);

HB_FUNC(HWG_LISTBOXSETSTRING)
{
  SendMessage(hwg_par_HWND(1), LB_SETCURSEL, hwg_par_WPARAM(2) - 1, 0);
}

HB_FUNC_TRANSLATE(LISTBOXSETSTRING, HWG_LISTBOXSETSTRING);

/*
   hwg_CreateListbox(hParentWIndow, nListboxID, nStyle, x, y, nWidth, nHeight)
*/
HB_FUNC(HWG_CREATELISTBOX)
{
  hwg_ret_HWND(CreateWindowEx(0, TEXT("LISTBOX"), TEXT(""), WS_CHILD | WS_VISIBLE | hwg_par_DWORD(3), hwg_par_int(4),
                              hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2),
                              GetModuleHandle(NULL), NULL));
}

HB_FUNC_TRANSLATE(CREATELISTBOX, HWG_CREATELISTBOX);

HB_FUNC(HWG_LISTBOXDELETESTRING)
{
  SendMessage(hwg_par_HWND(1), LB_DELETESTRING, 0, 0);
}

HB_FUNC_TRANSLATE(LISTBOXDELETESTRING, HWG_LISTBOXDELETESTRING);
