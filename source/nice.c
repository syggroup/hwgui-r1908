//
// $Id: nice.c 1846 2012-07-02 16:52:31Z LFBASSO $
//
// HWGUI - Harbour Win32 GUI library source code:
//
// Copyright 2003 Luiz Rafael Culik Guimaraes <culikr@brtrubo.com>
// www - http://sites.uol.com.br/culikr/
//

#include "hwingui.h"
#include <commctrl.h>

#include <hbapiitm.h>
#include <hbvm.h>
#include <hbstack.h>

#ifndef GRADIENT_FILL_RECT_H

#define GRADIENT_FILL_RECT_H 0
#define GRADIENT_FILL_RECT_V 1

#if !defined(__WATCOMC__) && !defined(__MINGW32__) && !defined(__MINGW64__)
typedef struct _GRADIENT_RECT
{
  ULONG UpperLeft;
  ULONG LowerRight;
} GRADIENT_RECT, *PGRADIENT_RECT, *LPGRADIENT_RECT;
#endif

#if defined(__DMC__)
typedef struct _TRIVERTEX
{
  LONG x;
  LONG y;
  USHORT Red;
  USHORT Green;
  USHORT Blue;
  USHORT Alpha;
} TRIVERTEX, *PTRIVERTEX, *LPTRIVERTEX;
#endif

#endif

typedef int(_stdcall *GRADIENTFILL)(HDC, PTRIVERTEX, int, PVOID, int, int);
LRESULT CALLBACK NiceButtProc(HWND, UINT, WPARAM, LPARAM);

static GRADIENTFILL s_pGradientfill = NULL;

void Draw_Gradient(HDC hdc, int x, int y, int w, int h, int r, int g, int b)
{
  TRIVERTEX Vert[2];
  GRADIENT_RECT Rect;
  HB_SYMBOL_UNUSED(x);
  HB_SYMBOL_UNUSED(y);
  // ******************************************************
  Vert[0].x = 0;
  Vert[0].y = 0;
  Vert[0].Red = (COLOR16)(65535 - (65535 - (r * 256)));
  Vert[0].Green = (COLOR16)(65535 - (65535 - (g * 256)));
  Vert[0].Blue = (COLOR16)(65535 - (65535 - (b * 256)));
  Vert[0].Alpha = 0;
  // ******************************************************
  Vert[1].x = w;
  Vert[1].y = h / 2;
  Vert[1].Red = 65535 - (65535 - (255 * 256));
  Vert[1].Green = 65535 - (65535 - (255 * 256));
  Vert[1].Blue = 65535 - (65535 - (255 * 256));
  Vert[1].Alpha = 0;
  // ******************************************************
  Rect.UpperLeft = 0;
  Rect.LowerRight = 1;
  // ******************************************************
  s_pGradientfill(hdc, Vert, 2, &Rect, 1, GRADIENT_FILL_RECT_V);
  // ******************************************************
  Vert[0].x = 0;
  Vert[0].y = h / 2;
  Vert[0].Red = 65535 - (65535 - (255 * 256));
  Vert[0].Green = 65535 - (65535 - (255 * 256));
  Vert[0].Blue = 65535 - (65535 - (255 * 256));
  Vert[0].Alpha = 0;
  // ******************************************************
  Vert[1].x = w;
  Vert[1].y = h;
  Vert[1].Red = (COLOR16)(65535 - (65535 - (r * 256)));
  Vert[1].Green = (COLOR16)(65535 - (65535 - (g * 256)));
  Vert[1].Blue = (COLOR16)(65535 - (65535 - (b * 256)));
  Vert[1].Alpha = 0;
  // ******************************************************
  Rect.UpperLeft = 0;
  Rect.LowerRight = 1;
  // ******************************************************
  s_pGradientfill(hdc, Vert, 2, &Rect, 1, GRADIENT_FILL_RECT_V);
}

void Gradient(HDC hdc, int x, int y, int w, int h, int color1, int color2, int nmode) // int , int g, int b, int nMode )
{
  TRIVERTEX Vert[2];
  GRADIENT_RECT Rect;
  int r, g, b, r2, g2, b2;
  HB_SYMBOL_UNUSED(x);
  HB_SYMBOL_UNUSED(y);

  r = color1 % 256;
  g = color1 / 256 % 256;
  b = color1 / 256 / 256 % 256;
  r2 = color2 % 256;
  g2 = color2 / 256 % 256;
  b2 = color2 / 256 / 256 % 256;

  // ******************************************************
  Vert[0].x = 0;
  Vert[0].y = 0;
  Vert[0].Red = (COLOR16)(65535 - (65535 - (r * 256)));
  Vert[0].Green = (COLOR16)(65535 - (65535 - (g * 256)));
  Vert[0].Blue = (COLOR16)(65535 - (65535 - (b * 256)));
  Vert[0].Alpha = 0;
  // ******************************************************
  Vert[1].x = w;
  Vert[1].y = h;
  Vert[1].Red = (COLOR16)(65535 - (65535 - (r2 * 256)));
  Vert[1].Green = (COLOR16)(65535 - (65535 - (g2 * 256)));
  Vert[1].Blue = (COLOR16)(65535 - (65535 - (b2 * 256)));
  Vert[1].Alpha = 0;
  // ******************************************************
  Rect.UpperLeft = 0;
  Rect.LowerRight = 1;
  // ******************************************************
  s_pGradientfill(hdc, Vert, 2, &Rect, 1, nmode); // GRADIENT_FILL_RECT_H );
}

LRESULT CALLBACK NiceButtProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
  LRESULT res;
  PHB_DYNS pSymTest;
  if ((pSymTest = hb_dynsymFind("NICEBUTTPROC")) != NULL)
  {
    hb_vmPushSymbol(hb_dynsymSymbol(pSymTest));
    hb_vmPushNil();       /* places NIL at self */
    hwg_vmPushHWND(hWnd); /* pushes parameters on to the hvm stack */
    hwg_vmPushUINT(uMsg);
    hwg_vmPushWPARAM(wParam);
    hwg_vmPushLPARAM(lParam);
    hb_vmDo(4);        /* where iArgCount is the number of pushed parameters */
    res = hb_parl(-1); // TODO: revisar
    if (res)
    {
      return 0;
    }
    else
    {
      return DefWindowProc(hWnd, uMsg, wParam, lParam);
    }
  }
  else
  {
    return DefWindowProc(hWnd, uMsg, wParam, lParam);
  }
}

HB_FUNC(CREATEROUNDRECTRGN)
{
  hwg_ret_HRGN(CreateRoundRectRgn(hwg_par_int(1), hwg_par_int(2), hwg_par_int(3), hwg_par_int(4), hwg_par_int(5),
                                  hwg_par_int(6)));
}

HB_FUNC(SETWINDOWRGN)
{
  hwg_ret_int(SetWindowRgn(hwg_par_HWND(1), hwg_par_HRGN(2), hwg_par_BOOL(3)));
}

HB_FUNC(HWG_REGNICE)
{
  // **********[ DLL Declarations ]**********
  static LPCTSTR s_szAppName = TEXT("NICEBUTT");
  static BOOL s_bRegistered = 0;

  s_pGradientfill = (GRADIENTFILL)GetProcAddress(LoadLibrary(TEXT("MSIMG32.DLL")), "GradientFill");
  //    if (Gradientfill == NULL)
  //        return FALSE;
  if (!s_bRegistered)
  {
    WNDCLASS wc;

    wc.style = CS_HREDRAW | CS_VREDRAW | CS_GLOBALCLASS;
    wc.hInstance = GetModuleHandle(0);
    wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
    wc.lpszClassName = s_szAppName;
    wc.lpfnWndProc = NiceButtProc;
    wc.cbClsExtra = 0;
    wc.cbWndExtra = 0;
    wc.hIcon = NULL;
    wc.hCursor = NULL;
    wc.lpszMenuName = 0;

    RegisterClass(&wc);
    s_bRegistered = 1;
  }
}

HB_FUNC(CREATENICEBTN)
{
  DWORD ulStyle = HB_ISNUM(3) ? hwg_par_DWORD(3) : WS_CLIPCHILDREN | WS_CLIPSIBLINGS;
  void *hTitle;
  hwg_ret_HWND(CreateWindowEx(hb_parni(8), TEXT("NICEBUTT"), HB_PARSTR(9, &hTitle, NULL),
                              WS_CHILD | WS_VISIBLE | ulStyle, hwg_par_int(4), hwg_par_int(5), hwg_par_int(6),
                              hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL));
  hb_strfree(hTitle);
}

HB_FUNC(ISMOUSEOVER)
{
  RECT Rect;
  POINT Pt;
  GetWindowRect(hwg_par_HWND(1), &Rect);
  GetCursorPos(&Pt);
  hwg_ret_BOOL(PtInRect(&Rect, Pt));
}

HB_FUNC(RGB)
{
  hb_retnl(RGB(hb_parni(1), hb_parni(2), hb_parni(3)));
}

HB_FUNC(DRAW_GRADIENT)
{
  Draw_Gradient(hwg_par_HDC(1), hb_parni(2), hb_parni(3), hb_parni(4), hb_parni(5), hb_parni(6), hb_parni(7),
                hb_parni(8));
}

HB_FUNC(GRADIENT)
{
  if (s_pGradientfill == NULL)
  {
    s_pGradientfill = (GRADIENTFILL)GetProcAddress(LoadLibrary(TEXT("MSIMG32.DLL")), "GradientFill");
  }
  // void Gradient(HDC hdc, int x, int y, int w, int h, int color1, int color2, int nmode)

  Gradient(hwg_par_HDC(1), hb_parni(2), hb_parni(3), hb_parni(4), hb_parni(5),
           (hb_pcount() > 5 && !HB_ISNIL(6)) ? hb_parni(6) : 16777215,
           (hb_pcount() > 6 && !HB_ISNIL(7)) ? hb_parni(7) : 16777215,
           (hb_pcount() > 7 && !HB_ISNIL(8)) ? hb_parni(8) : 0);
}

HB_FUNC(MAKELONG)
{
  hb_retnl((LONG)MAKELONG((WORD)hb_parnl(1), (WORD)hb_parnl(2)));
}

HB_FUNC(GETWINDOWLONG)
{
  hwg_ret_LONG(GetWindowLong(hwg_par_HWND(1), hwg_par_int(2)));
}

HB_FUNC(SETBKMODE)
{
  hwg_ret_int(SetBkMode(hwg_par_HDC(1), hwg_par_int(2)));
}
