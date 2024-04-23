/*
 * HWGUI - Harbour Win32 GUI library source code:
 * C functions for HAnimation class
 *
 * Copyright 2004 Marcos Antonio Gambeta <marcos_gambeta@hotmail.com>
 * www - http://geocities.yahoo.com.br/marcosgambeta/
 */

#include "hwingui.h"
#include <commctrl.h>

/*
ANIMATE_CREATE(HWND, nId, nStyle, nX, nY, nWidth, nHeight) --> HWND
*/
HB_FUNC(ANIMATE_CREATE)
{
  HWND hwnd;
  hwnd = Animate_Create(hwg_par_HWND(1), hwg_par_UINT(2), hwg_par_DWORD(3), GetModuleHandle(NULL));
  MoveWindow(hwnd, hwg_par_int(4), hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), TRUE);
  hwg_ret_HWND(hwnd);
}

/*
ANIMATE_OPEN(HWND, cFileName) -->
*/
HB_FUNC(ANIMATE_OPEN) // TODO: adicionar opção de usar 'resources'
{
  void *hStr;
  Animate_Open(hwg_par_HWND(1), HB_PARSTR(2, &hStr, NULL));
  hb_strfree(hStr);
}

/*
ANIMATE_PLAY(HWND, nFrom, nTo, nReplay) -->
*/
HB_FUNC(ANIMATE_PLAY)
{
  Animate_Play(hwg_par_HWND(1), hwg_par_UINT(2), hwg_par_UINT(3), hwg_par_UINT(4));
}

/*
ANIMATE_SEEK(HWND, nFrame) -->
*/
HB_FUNC(ANIMATE_SEEK)
{
  Animate_Seek(hwg_par_HWND(1), hwg_par_UINT(2));
}

/*
ANIMATE_STOP(HWND) -->
*/
HB_FUNC(ANIMATE_STOP)
{
  Animate_Stop(hwg_par_HWND(1));
}

/*
ANIMATE_CLOSE(HWND) -->
*/
HB_FUNC(ANIMATE_CLOSE)
{
  Animate_Close(hwg_par_HWND(1));
}

/*
ANIMATE_DESTROY(HWND) -->
*/
HB_FUNC(ANIMATE_DESTROY)
{
  DestroyWindow(hwg_par_HWND(1));
}

/*
ANIMATE_OPENEX(HWND, HINSTANCE, cFileName|cResource|nResource) -->
*/
HB_FUNC(ANIMATE_OPENEX)
{
#if defined(__DMC__)
#define Animate_OpenEx(hwnd, hInst, szName) (BOOL) SNDMSG(hwnd, ACM_OPEN, (WPARAM)hInst, (LPARAM)(LPTSTR)(szName))
#endif
  void *hResource;
  LPCTSTR lpResource = HB_PARSTR(3, &hResource, NULL);

  if (!lpResource && HB_ISNUM(3))
  {
    lpResource = MAKEINTRESOURCE(hb_parni(3));
  }

  Animate_OpenEx(hwg_par_HWND(1), hwg_par_HINSTANCE(2), lpResource);

  hb_strfree(hResource);
}
