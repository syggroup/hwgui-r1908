//
// $Id: control.c 1897 2012-09-17 23:12:45Z marcosgambeta $
//
// HWGUI - Harbour Win32 GUI library source code:
// C level controls functions (Edit control)
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#define HB_OS_WIN_32_USED

#define OEMRESOURCE

#include "hwingui.h"
#include <commctrl.h>
#include <winuser.h>
#if defined(__DMC__)
#include "missing.h"
#endif

#include <hbapiitm.h>
#include <hbvm.h>
#include <hbdate.h>
#include <hbtrace.h>
#ifdef __XHARBOUR__
#include <hbfast.h>
#endif

LRESULT APIENTRY EditSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

static WNDPROC wpOrigEditProc;

#if 0
HB_FUNC(HWG_INITEDITPROC)
{
  wpOrigEditProc = (WNDPROC)(LONG_PTR)SetWindowLong(hwg_par_HWND(1), GWLP_WNDPROC,
                                                    (LONG)(LONG_PTR)EditSubclassProc); // TODO: SetWindowLongPtr
}
#endif

HB_FUNC(HWG_INITEDITPROC)
{
  wpOrigEditProc = (WNDPROC)(LONG_PTR)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)EditSubclassProc);
}

LRESULT APIENTRY EditSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  LRESULT res;
  PHB_ITEM pObject = (PHB_ITEM)GetWindowLongPtr(hWnd, GWLP_USERDATA);

  if (!pSym_onEvent)
  {
    pSym_onEvent = hb_dynsymFindName("ONEVENT");
  }

  if (pSym_onEvent && pObject)
  {
    hb_vmPushSymbol(hb_dynsymSymbol(pSym_onEvent));
    hb_vmPush(pObject);
    hwg_vmPushUINT(uMsg);
    hwg_vmPushWPARAM(wParam);
    hwg_vmPushLPARAM(lParam);
    hb_vmSend(3);
    res = hwg_par_LRESULT(-1);
    return (res == -1) ? CallWindowProc(wpOrigEditProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc(wpOrigEditProc, hWnd, uMsg, wParam, lParam);
  }
}

/*
   CreateEdit(hParentWIndow, nEditControlID, nStyle, x, y, nWidth, nHeight, cInitialString)
*/
HB_FUNC(CREATEEDIT)
{
  HWND hWndEdit;
  DWORD ulStyle = hwg_par_DWORD(3);
  ULONG ulStyleEx = (ulStyle & WS_BORDER) ? WS_EX_CLIENTEDGE : 0;

  if ((ulStyle & WS_BORDER)) //&& (ulStyle & WS_DLGFRAME))
  {
    ulStyle &= ~WS_BORDER;
  }
  hWndEdit =
      CreateWindowEx(ulStyleEx, TEXT("EDIT"), NULL, WS_CHILD | WS_VISIBLE | ulStyle, hwg_par_int(4), hwg_par_int(5),
                     hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL);

  if (hb_pcount() > 7)
  {
    void *hStr;
    LPCTSTR lpText = HB_PARSTR(8, &hStr, NULL);
    if (lpText)
    {
      SendMessage(hWndEdit, WM_SETTEXT, 0, (LPARAM)lpText);
    }
    hb_strfree(hStr);
  }

  hwg_ret_HWND(hWndEdit);
}
