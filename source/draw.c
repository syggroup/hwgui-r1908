//
// $Id: draw.c 1846 2012-07-02 16:52:31Z LFBASSO $
//
// HWGUI - Harbour Win32 GUI library source code:
// C level painting functions
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#define OEMRESOURCE
#ifdef __DMC__
#define __DRAW_C__
#endif
#include "hwingui.h"
#include <hbapiitm.h>
#include <hbvm.h>
#include <hbstack.h>
#include "missing.h"

#if defined(__BORLANDC__) && __BORLANDC__ == 0x0550
#ifdef __cplusplus
extern "C"
{
  STDAPI OleLoadPicture(LPSTREAM, LONG, BOOL, REFIID, PVOID *);
}
#else
STDAPI OleLoadPicture(LPSTREAM, LONG, BOOL, REFIID, PVOID *);
#endif
#endif /* __BORLANDC__ */

#ifdef __cplusplus
#ifdef CINTERFACE
#undef CINTERFACE
#endif
#endif

typedef int(_stdcall *TRANSPARENTBLT)(HDC, int, int, int, int, HDC, int, int, int, int, int);

static TRANSPARENTBLT s_pTransparentBlt = NULL;

void TransparentBmp(HDC hDC, int x, int y, int nWidthDest, int nHeightDest, HDC dcImage, int bmWidth, int bmHeight,
                    int trColor)
{
  if (s_pTransparentBlt == NULL)
  {
    s_pTransparentBlt = (TRANSPARENTBLT)GetProcAddress(LoadLibrary(TEXT("MSIMG32.DLL")), "TransparentBlt");
  }
  s_pTransparentBlt(hDC, x, y, nWidthDest, nHeightDest, dcImage, 0, 0, bmWidth, bmHeight, trColor);
}

BOOL Array2Rect(PHB_ITEM aRect, RECT *rc)
{
  if (HB_IS_ARRAY(aRect) && hb_arrayLen(aRect) == 4)
  {
    rc->left = hb_arrayGetNL(aRect, 1);
    rc->top = hb_arrayGetNL(aRect, 2);
    rc->right = hb_arrayGetNL(aRect, 3);
    rc->bottom = hb_arrayGetNL(aRect, 4);
    return TRUE;
  }
  else
  {
    rc->left = rc->top = rc->right = rc->bottom = 0;
  }
  return FALSE;
}

PHB_ITEM Rect2Array(RECT *rc)
{
  PHB_ITEM aRect = hb_itemArrayNew(4);
  PHB_ITEM element = hb_itemNew(NULL);

  hb_arraySet(aRect, 1, hb_itemPutNL(element, rc->left));
  hb_arraySet(aRect, 2, hb_itemPutNL(element, rc->top));
  hb_arraySet(aRect, 3, hb_itemPutNL(element, rc->right));
  hb_arraySet(aRect, 4, hb_itemPutNL(element, rc->bottom));
  hb_itemRelease(element);
  return aRect;
}

/*
GETPPSRECT(PAINTSTRUCT) --> aRect
*/
HB_FUNC(GETPPSRECT)
{
  PAINTSTRUCT *pps = hwg_par_PAINTSTRUCT(1);
  PHB_ITEM aMetr = Rect2Array(&pps->rcPaint);
  hb_itemReturnRelease(aMetr);
}

/*
HWG_INVALIDATERECT(HWND, nEraseBackgroundFlag, nLeft, nTop, nRight, nBottom) -->
*/
HB_FUNC(HWG_INVALIDATERECT)
{
  RECT rc;

  if (hb_pcount() > 2)
  {
    rc.left = hb_parni(3);
    rc.top = hb_parni(4);
    rc.right = hb_parni(5);
    rc.bottom = hb_parni(6);
  }

  // TODO: parâmetro 3 é do tipo BOOL
  InvalidateRect(hwg_par_HWND(1), (hb_pcount() > 2) ? &rc : NULL, hb_parni(2));
}

HB_FUNC_TRANSLATE(INVALIDATERECT, HWG_INVALIDATERECT);

/*
MOVETO(HDC, nX, nY) -->
*/
HB_FUNC(MOVETO) // TODO: sincronizar nome da função com função da WINAPI
{
  MoveToEx(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), NULL);
}

/*
LINETO(HDC, nX, nY) -->
*/
HB_FUNC(LINETO)
{
  LineTo(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3));
}

/*
RECTANGLE(HDC, nX1, nY1, nX2, nY2) -->
*/
HB_FUNC(RECTANGLE) // TODO: usar outro nome para esta função
{
  HDC hDC = hwg_par_HDC(1);
  int x1 = hb_parni(2);
  int y1 = hb_parni(3);
  int x2 = hb_parni(4);
  int y2 = hb_parni(5);
  MoveToEx(hDC, x1, y1, NULL);
  LineTo(hDC, x2, y1);
  LineTo(hDC, x2, y2);
  LineTo(hDC, x1, y2);
  LineTo(hDC, x1, y1);
}

/*
BOX(HDC, nLeft, nTop, nRight, nBottom) -->
*/
HB_FUNC(BOX) // TODO: sincronizar nome da função com função da WINAPI
{
  Rectangle(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), hwg_par_int(4), hwg_par_int(5));
}

/*
DRAWLINE(HDC, nX1, nY1, nX2, nY2) -->
*/
HB_FUNC(DRAWLINE)
{
  HDC hDC = hwg_par_HDC(1);
  MoveToEx(hDC, hb_parni(2), hb_parni(3), NULL);
  LineTo(hDC, hb_parni(4), hb_parni(5));
}

/*
PIE(HDC, nLeft, nTop, nRight, nBottom, nXR1, nYR1, nXR2, nYR2) --> numeric
*/
HB_FUNC(PIE)
{
  int res = Pie(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), hwg_par_int(4), hwg_par_int(5), hwg_par_int(6),
                hwg_par_int(7), hwg_par_int(8), hwg_par_int(9));
  hb_retnl(res ? 0 : (LONG)GetLastError()); // TODO: o retorno da função é BOOL
}

/*
ELLIPSE(HDC, nLeft, nTop, nRight, nBottom) --> numeric
*/
HB_FUNC(ELLIPSE)
{
  int res = Ellipse(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), hwg_par_int(4), hwg_par_int(5));
  hb_retnl(res ? 0 : (LONG)GetLastError()); // TODO: o retorno da função é BOOL
}

/*
FILLRECT(HDC, nLeft, nTop, nRight, nBottom, HBRUSH) -->
*/
HB_FUNC(FILLRECT)
{
  RECT rc;

  rc.left = hb_parni(2);
  rc.top = hb_parni(3);
  rc.right = hb_parni(4);
  rc.bottom = hb_parni(5);

  // TODO: usar apenas hwg_par_HDC(1)
  FillRect(HB_ISPOINTER(1) ? hwg_par_HDC(1) : (HDC)(LONG_PTR)hb_parnl(1), &rc, hwg_par_HBRUSH(6));
}

/*
ROUNDRECT(HDC, nLeft, nTop, nRight, nBottom, nWidth, nHeight) --> .T.|.F.
*/
HB_FUNC(ROUNDRECT)
{
  hwg_ret_BOOL(RoundRect(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), hwg_par_int(4), hwg_par_int(5), hwg_par_int(6),
                         hwg_par_int(7)));
}

#if 0
HB_FUNC(REDRAWWINDOW)
{
   RedrawWindow(hwg_par_HWND(1), // handle of window
         NULL,                  // address of structure with update rectangle
         NULL,                  // handle of update region
         (UINT)hb_parni(2) // array of redraw flags
          );
}
#endif

/*
HWG_REDRAWWINDOW(HWND, nFlags, nX, nY, nWidth, nHeight) -->
*/
HB_FUNC(HWG_REDRAWWINDOW)
{
  RECT rc;

  if (hb_pcount() > 3)
  {
    int x = (hb_pcount() > 3 && !HB_ISNIL(3)) ? hb_parni(3) : 0;
    int y = (hb_pcount() >= 4 && !HB_ISNIL(4)) ? hb_parni(4) : 0;
    int w = (hb_pcount() >= 5 && !HB_ISNIL(5)) ? hb_parni(5) : 0;
    int h = (hb_pcount() >= 6 && !HB_ISNIL(6)) ? hb_parni(6) : 0;
    rc.left = x - 1;
    rc.top = y - 1;
    rc.right = x + w + 1;
    rc.bottom = y + h + 1;
  }

  RedrawWindow(hwg_par_HWND(1), (hb_pcount() > 3) ? &rc : NULL, NULL, hwg_par_UINT(2));
}

HB_FUNC_TRANSLATE(REDRAWWINDOW, HWG_REDRAWWINDOW);

/*
DRAWBUTTON(HDC, nLeft, nTop, nRight, nBottom, nType) -->
*/
HB_FUNC(DRAWBUTTON)
{
  RECT rc;
  HDC hDC = hwg_par_HDC(1);
  UINT iType = hb_parni(6);

  rc.left = hb_parni(2);
  rc.top = hb_parni(3);
  rc.right = hb_parni(4);
  rc.bottom = hb_parni(5);

  if (iType == 0)
  {
    FillRect(hDC, &rc, (HBRUSH)(COLOR_3DFACE + 1));
  }
  else
  {
    FillRect(hDC, &rc, (HBRUSH)(LONG_PTR)(((iType & 2) ? COLOR_3DSHADOW : COLOR_3DHILIGHT) + 1));
    rc.left++;
    rc.top++;
    FillRect(hDC, &rc,
             (HBRUSH)(LONG_PTR)(((iType & 2)   ? COLOR_3DHILIGHT
                                 : (iType & 4) ? COLOR_3DDKSHADOW
                                               : COLOR_3DSHADOW) +
                                1));
    rc.right--;
    rc.bottom--;
    if (iType & 4)
    {
      FillRect(hDC, &rc, (HBRUSH)(LONG_PTR)(((iType & 2) ? COLOR_3DSHADOW : COLOR_3DLIGHT) + 1));
      rc.left++;
      rc.top++;
      FillRect(hDC, &rc, (HBRUSH)(LONG_PTR)(((iType & 2) ? COLOR_3DLIGHT : COLOR_3DSHADOW) + 1));
      rc.right--;
      rc.bottom--;
    }
    FillRect(hDC, &rc, (HBRUSH)(COLOR_3DFACE + 1));
  }
}

/*
 * DrawEdge(hDC, x1, y1, x2, y2, nFlag, nBorder)
 */

/*
DRAWEDGE(HDC, nLeft, nTop, nRight, nBottom, nEdge, nGrfFlags) --> .T.|.F.
*/
HB_FUNC(DRAWEDGE)
{
  RECT rc;
  UINT edge = (HB_ISNIL(6)) ? EDGE_RAISED : hwg_par_UINT(6);
  UINT grfFlags = (HB_ISNIL(7)) ? BF_RECT : hwg_par_UINT(7);

  rc.left = hb_parni(2);
  rc.top = hb_parni(3);
  rc.right = hb_parni(4);
  rc.bottom = hb_parni(5);

  hwg_ret_BOOL(DrawEdge(hwg_par_HDC(1), &rc, edge, grfFlags));
}

/*
LOADICON(nIcon|cIcon) --> HICON
*/
HB_FUNC(LOADICON)
{
  if (HB_ISNUM(1))
  {
    hwg_ret_HICON(LoadIcon(NULL, MAKEINTRESOURCE(hb_parni(1))));
  }
  else
  {
    void *hString;
    hwg_ret_HICON(LoadIcon(GetModuleHandle(NULL), HB_PARSTR(1, &hString, NULL)));
    hb_strfree(hString);
  }
}

/*
LOADIMAGE(HINSTANCE, nImage|cImage, nType, nWidth, nHeight, nLoadFlags) --> HANDLE
*/
HB_FUNC(LOADIMAGE)
{
  void *hString = NULL;
  hwg_ret_HANDLE(LoadImage(HB_ISNIL(1) ? GetModuleHandle(NULL) : hwg_par_HINSTANCE(1),
                           HB_ISNUM(2) ? MAKEINTRESOURCE(hb_parni(2)) : HB_PARSTR(2, &hString, NULL), hwg_par_UINT(3),
                           hwg_par_int(4), hwg_par_int(5), hwg_par_UINT(6)));
  hb_strfree(hString);
}

/*
LOADBITMAP(nBitmap|cBitmap, lp2) --> HBITMAP
*/
HB_FUNC(LOADBITMAP)
{
  if (HB_ISNUM(1))
  {
    if (!HB_ISNIL(2) && hb_parl(2))
    {
      hwg_ret_HBITMAP(LoadBitmap(NULL, MAKEINTRESOURCE(hb_parni(1))));
    }
    else
    {
      hwg_ret_HBITMAP(LoadBitmap(GetModuleHandle(NULL), MAKEINTRESOURCE(hb_parni(1))));
    }
  }
  else
  {
    void *hString;
    hwg_ret_HBITMAP(LoadBitmap(GetModuleHandle(NULL), HB_PARSTR(1, &hString, NULL)));
    hb_strfree(hString);
  }
}

/*
 * Window2Bitmap(hWnd)
 */

/*
WINDOW2BITMAP(HWND, lFull) --> HBITMAP
*/
HB_FUNC(WINDOW2BITMAP)
{
  HWND hWnd = hwg_par_HWND(1);
  BOOL lFull = (HB_ISNIL(2)) ? 0 : (BOOL)hb_parl(2);
  HDC hDC = (lFull) ? GetWindowDC(hWnd) : GetDC(hWnd);
  HDC hDCmem = CreateCompatibleDC(hDC);
  HBITMAP hBitmap;
  RECT rc;

  if (lFull)
  {
    GetWindowRect(hWnd, &rc);
  }
  else
  {
    GetClientRect(hWnd, &rc);
  }

  hBitmap = CreateCompatibleBitmap(hDC, rc.right - rc.left, rc.bottom - rc.top);
  SelectObject(hDCmem, hBitmap);

  BitBlt(hDCmem, 0, 0, rc.right - rc.left, rc.bottom - rc.top, hDC, 0, 0, SRCCOPY);

  DeleteDC(hDCmem);
  DeleteDC(hDC);
  // hb_retnl((LONG)hBitmap);
  hwg_ret_HBITMAP(hBitmap);
}

/*
 * DrawBitmap(hDC, hBitmap, style, x, y, width, height)
 */

/*
DRAWBITMAP(HDC, HBITMAP, np3, nX, nY, nWidth, nHeight) -->
*/
HB_FUNC(DRAWBITMAP)
{
  HDC hDC = hwg_par_HDC(1);
  HDC hDCmem = CreateCompatibleDC(hDC);
  DWORD dwraster = (HB_ISNIL(3)) ? SRCCOPY : (DWORD)hb_parnl(3);
  HBITMAP hBitmap = hwg_par_HBITMAP(2);
  BITMAP bitmap;
  int nWidthDest = (hb_pcount() >= 5 && !HB_ISNIL(6)) ? hb_parni(6) : 0;
  int nHeightDest = (hb_pcount() >= 6 && !HB_ISNIL(7)) ? hb_parni(7) : 0;

  SelectObject(hDCmem, hBitmap);
  GetObject(hBitmap, sizeof(BITMAP), (LPVOID)&bitmap);
  if (nWidthDest && (nWidthDest != bitmap.bmWidth || nHeightDest != bitmap.bmHeight))
  {
    SetStretchBltMode(hDC, COLORONCOLOR);
    StretchBlt(hDC, hb_parni(4), hb_parni(5), nWidthDest, nHeightDest, hDCmem, 0, 0, bitmap.bmWidth, bitmap.bmHeight,
               dwraster);
  }
  else
  {
    BitBlt(hDC, hb_parni(4), hb_parni(5), bitmap.bmWidth, bitmap.bmHeight, hDCmem, 0, 0, dwraster);
  }

  DeleteDC(hDCmem);
}

/*
 * DrawTransparentBitmap(hDC, hBitmap, x, y [,trColor])
 */

/*
DRAWTRANSPARENTBITMAP(HDC, HBITMAP, nX, nY, nTrColor, nWidthDest, nHeightDest) -->
*/
HB_FUNC(DRAWTRANSPARENTBITMAP)
{
  HDC hDC = hwg_par_HDC(1);
  HBITMAP hBitmap = hwg_par_HBITMAP(2);
  COLORREF trColor = (HB_ISNIL(5)) ? 0x00FFFFFF : hwg_par_COLORREF(5);
  COLORREF crOldBack = SetBkColor(hDC, 0x00FFFFFF);
  COLORREF crOldText = SetTextColor(hDC, 0);
  HBITMAP bitmapTrans;
  HBITMAP pOldBitmapImage, pOldBitmapTrans;
  BITMAP bitmap;
  HDC dcImage, dcTrans;
  int x = hb_parni(3);
  int y = hb_parni(4);
  int nWidthDest = (hb_pcount() >= 5 && !HB_ISNIL(6)) ? hb_parni(6) : 0;
  int nHeightDest = (hb_pcount() >= 6 && !HB_ISNIL(7)) ? hb_parni(7) : 0;

  // Create two memory dcs for the image and the mask
  dcImage = CreateCompatibleDC(hDC);
  dcTrans = CreateCompatibleDC(hDC);
  // Select the image into the appropriate dc
  pOldBitmapImage = (HBITMAP)SelectObject(dcImage, hBitmap);
  GetObject(hBitmap, sizeof(BITMAP), (LPVOID)&bitmap);
  // Create the mask bitmap
  bitmapTrans = CreateBitmap(bitmap.bmWidth, bitmap.bmHeight, 1, 1, NULL);
  // Select the mask bitmap into the appropriate dc
  pOldBitmapTrans = (HBITMAP)SelectObject(dcTrans, bitmapTrans);
  // Build mask based on transparent colour
  SetBkColor(dcImage, trColor);
  if (nWidthDest && (nWidthDest != bitmap.bmWidth || nHeightDest != bitmap.bmHeight))
  {
    /*
    BitBlt(dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCCOPY);
    SetStretchBltMode(hDC, COLORONCOLOR);
    StretchBlt(hDC, 0, 0, nWidthDest, nHeightDest, dcImage, 0, 0, bitmap.bmWidth, bitmap.bmHeight, SRCINVERT);
    StretchBlt(hDC, 0, 0, nWidthDest, nHeightDest, dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, SRCAND);
    StretchBlt(hDC, 0, 0, nWidthDest, nHeightDest, dcImage, 0, 0, bitmap.bmWidth, bitmap.bmHeight, SRCINVERT);
    */
    SetStretchBltMode(hDC, COLORONCOLOR);
    TransparentBmp(hDC, x, y, nWidthDest, nHeightDest, dcImage, bitmap.bmWidth, bitmap.bmHeight, trColor);
  }
  else
  {
    /*
    BitBlt(dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCCOPY);
    // Do the work - True Mask method - cool if not actual display
    BitBlt(hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT);
    BitBlt(hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcTrans, 0, 0, SRCAND);
    BitBlt(hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT);
   */
    TransparentBmp(hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, bitmap.bmWidth, bitmap.bmHeight, trColor);
  }
  // Restore settings
  SelectObject(dcImage, pOldBitmapImage);
  SelectObject(dcTrans, pOldBitmapTrans);
  SetBkColor(hDC, crOldBack);
  SetTextColor(hDC, crOldText);

  DeleteObject(bitmapTrans);
  DeleteDC(dcImage);
  DeleteDC(dcTrans);
}

/*  SpreadBitmap(hDC, hWnd, hBitmap, style)
 */

/*
SPREADBITMAP(HDC, HWND, HBITMAP, np4) -->
*/
HB_FUNC(SPREADBITMAP)
{
  HDC hDC = HB_ISPOINTER(1) ? hwg_par_HDC(1) : (HDC)(LONG_PTR)hb_parnl(1); // TODO: revisar e usar somente hwg_par_HDC
  HDC hDCmem = CreateCompatibleDC(hDC);
  DWORD dwraster = (HB_ISNIL(4)) ? SRCCOPY : (DWORD)hb_parnl(4);
  HBITMAP hBitmap = hwg_par_HBITMAP(3);
  BITMAP bitmap;
  RECT rc;

  SelectObject(hDCmem, hBitmap);
  GetObject(hBitmap, sizeof(BITMAP), (LPVOID)&bitmap);
  GetClientRect(hwg_par_HWND(2), &rc);

  while (rc.top < rc.bottom)
  {
    while (rc.left < rc.right)
    {
      BitBlt(hDC, rc.left, rc.top, bitmap.bmWidth, bitmap.bmHeight, hDCmem, 0, 0, dwraster);
      rc.left += bitmap.bmWidth;
    }
    rc.left = 0;
    rc.top += bitmap.bmHeight;
  }

  DeleteDC(hDCmem);
}

/*  CenterBitmap(hDC, hWnd, hBitmap, style, brush)
 */

/*
CENTERBITMAP(HDC, HWND, HBITMAP, np4, HBRUSH) -->
*/
HB_FUNC(CENTERBITMAP)
{
  HDC hDC = hwg_par_HDC(1);
  HDC hDCmem = CreateCompatibleDC(hDC);
  DWORD dwraster = (HB_ISNIL(4)) ? SRCCOPY : (DWORD)hb_parnl(4);
  HBITMAP hBitmap = hwg_par_HBITMAP(3);
  BITMAP bitmap;
  RECT rc;
  HBRUSH hBrush = (HB_ISNIL(5)) ? (HBRUSH)(COLOR_WINDOW + 1) : hwg_par_HBRUSH(5);

  SelectObject(hDCmem, hBitmap);
  GetObject(hBitmap, sizeof(BITMAP), (LPVOID)&bitmap);
  GetClientRect(hwg_par_HWND(2), &rc);

  FillRect(hDC, &rc, hBrush);
  BitBlt(hDC, (rc.right - bitmap.bmWidth) / 2, (rc.bottom - bitmap.bmHeight) / 2, bitmap.bmWidth, bitmap.bmHeight,
         hDCmem, 0, 0, dwraster);

  DeleteDC(hDCmem);
}

/*
GETBITMAPSIZE(HBITMAP) --> aInfo[4]
*/
HB_FUNC(GETBITMAPSIZE)
{
  BITMAP bitmap;
  PHB_ITEM aMetr = hb_itemArrayNew(4);
  PHB_ITEM temp;
  int nret;

  nret = GetObject(hwg_par_HBITMAP(1), sizeof(BITMAP), (LPVOID)&bitmap);

  temp = hb_itemPutNL(NULL, bitmap.bmWidth);
  hb_itemArrayPut(aMetr, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, bitmap.bmHeight);
  hb_itemArrayPut(aMetr, 2, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, bitmap.bmBitsPixel);
  hb_itemArrayPut(aMetr, 3, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, nret);
  hb_itemArrayPut(aMetr, 4, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aMetr);
}

/*
GETICONSIZE(HICON) --> aInfo[3]
*/
HB_FUNC(GETICONSIZE)
{
  ICONINFO iinfo;
  PHB_ITEM aMetr = hb_itemArrayNew(3);
  PHB_ITEM temp;
  int nret;

  nret = GetIconInfo(hwg_par_HICON(1), &iinfo);

  temp = hb_itemPutNL(NULL, iinfo.xHotspot * 2);
  hb_itemArrayPut(aMetr, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, iinfo.yHotspot * 2);
  hb_itemArrayPut(aMetr, 2, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, nret);
  hb_itemArrayPut(aMetr, 3, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aMetr);
}

/*
OPENBITMAP(cFileName, HDC) --> HBITMAP
*/
HB_FUNC(OPENBITMAP)
{
  BITMAPFILEHEADER bmfh;
  BITMAPINFOHEADER bmih;
  LPBITMAPINFO lpbmi;
  DWORD dwRead;
  LPVOID lpvBits;
  HGLOBAL hmem1, hmem2;
  HBITMAP hbm;
  HDC hDC = (hb_pcount() > 1 && !HB_ISNIL(2)) ? hwg_par_HDC(2) : NULL;
  void *hString;
  HANDLE hfbm;

  hfbm = CreateFile(HB_PARSTR(1, &hString, NULL), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                    FILE_ATTRIBUTE_READONLY, NULL);
  hb_strfree(hString);
  if (((long int)(LONG_PTR)hfbm) <= 0)
  {
    HB_RETHANDLE(NULL);
    return;
  }
  /* Retrieve the BITMAPFILEHEADER structure. */
  ReadFile(hfbm, &bmfh, sizeof(BITMAPFILEHEADER), &dwRead, NULL);

  /* Retrieve the BITMAPFILEHEADER structure. */
  ReadFile(hfbm, &bmih, sizeof(BITMAPINFOHEADER), &dwRead, NULL);

  /* Allocate memory for the BITMAPINFO structure. */

  hmem1 = GlobalAlloc(GHND, sizeof(BITMAPINFOHEADER) + ((1 << bmih.biBitCount) * sizeof(RGBQUAD)));
  lpbmi = (LPBITMAPINFO)GlobalLock(hmem1);

  /*  Load BITMAPINFOHEADER into the BITMAPINFO  structure. */
  lpbmi->bmiHeader.biSize = bmih.biSize;
  lpbmi->bmiHeader.biWidth = bmih.biWidth;
  lpbmi->bmiHeader.biHeight = bmih.biHeight;
  lpbmi->bmiHeader.biPlanes = bmih.biPlanes;

  lpbmi->bmiHeader.biBitCount = bmih.biBitCount;
  lpbmi->bmiHeader.biCompression = bmih.biCompression;
  lpbmi->bmiHeader.biSizeImage = bmih.biSizeImage;
  lpbmi->bmiHeader.biXPelsPerMeter = bmih.biXPelsPerMeter;
  lpbmi->bmiHeader.biYPelsPerMeter = bmih.biYPelsPerMeter;
  lpbmi->bmiHeader.biClrUsed = bmih.biClrUsed;
  lpbmi->bmiHeader.biClrImportant = bmih.biClrImportant;

  /*  Retrieve the color table.
   * 1 << bmih.biBitCount == 2 ^ bmih.biBitCount
   */
  switch (bmih.biBitCount)
  {
  case 1:
  case 4:
  case 8:
    ReadFile(hfbm, lpbmi->bmiColors, ((1 << bmih.biBitCount) * sizeof(RGBQUAD)), &dwRead, NULL);
    break;

  case 16:
  case 32:
    if (bmih.biCompression == BI_BITFIELDS)
    {
      ReadFile(hfbm, lpbmi->bmiColors, (3 * sizeof(RGBQUAD)), &dwRead, NULL);
    }
    break;

  case 24:
    break;
  }

  /* Allocate memory for the required number of  bytes. */
  hmem2 = GlobalAlloc(GHND, (bmfh.bfSize - bmfh.bfOffBits));
  lpvBits = GlobalLock(hmem2);

  /* Retrieve the bitmap data. */

  ReadFile(hfbm, lpvBits, (bmfh.bfSize - bmfh.bfOffBits), &dwRead, NULL);

  if (!hDC)
  {
    hDC = GetDC(0);
  }

  /* Create a bitmap from the data stored in the .BMP file.  */
  hbm = CreateDIBitmap(hDC, &bmih, CBM_INIT, lpvBits, lpbmi, DIB_RGB_COLORS);

  if (hb_pcount() < 2 || HB_ISNIL(2))
  {
    ReleaseDC(NULL, hDC);
  }

  /* Unlock the global memory objects and close the .BMP file. */
  GlobalUnlock(hmem1);
  GlobalUnlock(hmem2);
  GlobalFree(hmem1);
  GlobalFree(hmem2);
  CloseHandle(hfbm);

  hwg_ret_HBITMAP(hbm);
}

/*
DRAWICON(HDC, HICON, nX, nY) -->
*/
HB_FUNC(DRAWICON) // TODO: ordem dos parâmetros não segue a função da WINAPI
{
  DrawIcon(hwg_par_HDC(1), hwg_par_int(3), hwg_par_int(4), hwg_par_HICON(2)); // TODO: o retorno é BOOL
}

/*
GETSYSCOLOR(nIndex) --> color
*/
HB_FUNC(GETSYSCOLOR)
{
  hwg_ret_DWORD(GetSysColor(hwg_par_int(1)));
}

/*
GETSYSCOLORBRUSH(nIndex) --> HBRUSH
*/
HB_FUNC(GETSYSCOLORBRUSH)
{
  hwg_ret_HBRUSH(GetSysColorBrush(hwg_par_int(1)));
}

/*
CREATEPEN(nStyle, nWidth, nColor) --> HPEN
*/
HB_FUNC(CREATEPEN)
{
  hwg_ret_HPEN(CreatePen(hwg_par_int(1), hwg_par_int(2), hwg_par_COLORREF(3)));
}

/*
CREATESOLIDBRUSH(nColor) --> HBRUSH
*/
HB_FUNC(CREATESOLIDBRUSH)
{
  hwg_ret_HBRUSH(CreateSolidBrush(hwg_par_COLORREF(1)));
}

/*
CREATEHATCHBRUSH(nHatch, nColor) --> HBRUSH
*/
HB_FUNC(CREATEHATCHBRUSH)
{
  hwg_ret_HBRUSH(CreateHatchBrush(hwg_par_int(1), hwg_par_COLORREF(2)));
}

/*
SELECTOBJECT(HDC, HGDIOBJ) --> HGDIOBJ
*/
HB_FUNC(HWG_SELECTOBJECT)
{
  hwg_ret_HGDIOBJ(SelectObject(hwg_par_HDC(1), hwg_par_HGDIOBJ(2)));
}

HB_FUNC_TRANSLATE(SELECTOBJECT, HWG_SELECTOBJECT);

/*
DELETEOBJECT(HGDIOBJ) -->
*/
HB_FUNC(HWG_DELETEOBJECT)
{
  // TODO: retorno BOOL
  DeleteObject(hwg_par_HGDIOBJ(1));
}

HB_FUNC_TRANSLATE(DELETEOBJECT, HWG_DELETEOBJECT);

/*
GETDC(HWND) --> HDC
*/
HB_FUNC(HWG_GETDC)
{
  hwg_ret_HDC(GetDC(hwg_par_HWND(1)));
}

HB_FUNC_TRANSLATE(GETDC, HWG_GETDC);

/*
RELEASEDC(HWND, HDC) --> numeric
*/
HB_FUNC(HWG_RELEASEDC)
{
  hwg_ret_int(ReleaseDC(hwg_par_HWND(1), hwg_par_HDC(2)));
}

HB_FUNC_TRANSLATE(RELEASEDC, HWG_RELEASEDC);

/*
GETDRAWITEMINFO(DRAWITEMSTRUCT) --> aInfo[9]
*/
HB_FUNC(HWG_GETDRAWITEMINFO)
{
  DRAWITEMSTRUCT *lpdis = (DRAWITEMSTRUCT *)HB_PARHANDLE(1); // hb_parnl(1);
  PHB_ITEM aMetr = hb_itemArrayNew(9);
  PHB_ITEM temp;

  temp = hb_itemPutNL(NULL, lpdis->itemID);
  hb_itemArrayPut(aMetr, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, lpdis->itemAction);
  hb_itemArrayPut(aMetr, 2, temp);
  hb_itemRelease(temp);

  temp = HB_PUTHANDLE(NULL, lpdis->hDC);
  hb_itemArrayPut(aMetr, 3, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, lpdis->rcItem.left);
  hb_itemArrayPut(aMetr, 4, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, lpdis->rcItem.top);
  hb_itemArrayPut(aMetr, 5, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, lpdis->rcItem.right);
  hb_itemArrayPut(aMetr, 6, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, lpdis->rcItem.bottom);
  hb_itemArrayPut(aMetr, 7, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNInt(NULL, (LONG_PTR)lpdis->hwndItem);
  hb_itemArrayPut(aMetr, 8, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, (LONG)lpdis->itemState);
  hb_itemArrayPut(aMetr, 9, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aMetr);
}

HB_FUNC_TRANSLATE(GETDRAWITEMINFO, HWG_GETDRAWITEMINFO);

/*
 * DrawGrayBitmap(hDC, hBitmap, x, y)
 */

/*
DRAWGRAYBITMAP(HDC, HBITMAP, nX, nY) -->
*/
HB_FUNC(DRAWGRAYBITMAP)
{
  HDC hDC = hwg_par_HDC(1);
  HBITMAP hBitmap = hwg_par_HBITMAP(2);
  HBITMAP bitmapgray;
  HBITMAP pOldBitmapImage, pOldbitmapgray;
  BITMAP bitmap;
  HDC dcImage, dcTrans;
  int x = hb_parni(3);
  int y = hb_parni(4);

  SetBkColor(hDC, GetSysColor(COLOR_BTNHIGHLIGHT));
  // SetTextColor(hDC, GetSysColor(COLOR_BTNFACE));
  SetTextColor(hDC, GetSysColor(COLOR_BTNSHADOW));
  // Create two memory dcs for the image and the mask
  dcImage = CreateCompatibleDC(hDC);
  dcTrans = CreateCompatibleDC(hDC);
  // Select the image into the appropriate dc
  pOldBitmapImage = (HBITMAP)SelectObject(dcImage, hBitmap);
  GetObject(hBitmap, sizeof(BITMAP), (LPVOID)&bitmap);
  // Create the mask bitmap
  bitmapgray = CreateBitmap(bitmap.bmWidth, bitmap.bmHeight, 1, 1, NULL);
  // Select the mask bitmap into the appropriate dc
  pOldbitmapgray = (HBITMAP)SelectObject(dcTrans, bitmapgray);
  // Build mask based on transparent colour
  SetBkColor(dcImage, RGB(255, 255, 255));
  BitBlt(dcTrans, 0, 0, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCCOPY);
  // Do the work - True Mask method - cool if not actual display
  BitBlt(hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT);
  BitBlt(hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcTrans, 0, 0, SRCAND);
  BitBlt(hDC, x, y, bitmap.bmWidth, bitmap.bmHeight, dcImage, 0, 0, SRCINVERT);
  // Restore settings
  SelectObject(dcImage, pOldBitmapImage);
  SelectObject(dcTrans, pOldbitmapgray);
  SetBkColor(hDC, GetPixel(hDC, 0, 0));
  SetTextColor(hDC, 0);

  DeleteObject(bitmapgray);
  DeleteDC(dcImage);
  DeleteDC(dcTrans);
}

#include <olectl.h>
#include <ole2.h>
#include <ocidl.h>

/*
OPENIMAGE(cFileName, lp2) --> HANDLE
*/
HB_FUNC(OPENIMAGE)
{
  const char *cFileName = hb_parc(1);
  BOOL lString = (HB_ISNIL(2)) ? 0 : hb_parl(2);
  int iFileSize;
  FILE *fp;
  // IPicture * pPic;
  LPPICTURE pPic;
  IStream *pStream;
  HGLOBAL hG;
  HBITMAP hBitmap = 0;

  if (lString)
  {
    iFileSize = (int)hb_parclen(1);
    hG = GlobalAlloc(GPTR, iFileSize);
    if (!hG)
    {
      HB_RETHANDLE(NULL);
      return;
    }
    memcpy((void *)hG, (void *)cFileName, iFileSize);
  }
  else
  {
    fp = fopen(cFileName, "rb");
    if (!fp)
    {
      HB_RETHANDLE(NULL);
      return;
    }

    fseek(fp, 0, SEEK_END);
    iFileSize = ftell(fp);
    hG = GlobalAlloc(GPTR, iFileSize);
    if (!hG)
    {
      fclose(fp);
      HB_RETHANDLE(NULL);
      return;
    }
    fseek(fp, 0, SEEK_SET);
    fread((void *)hG, 1, iFileSize, fp);
    fclose(fp);
  }

  CreateStreamOnHGlobal(hG, 0, &pStream);

  if (!pStream)
  {
    GlobalFree(hG);
    HB_RETHANDLE(NULL);
    return;
  }

#if defined(__cplusplus)
  OleLoadPicture(pStream, 0, 0, IID_IPicture, (void **)&pPic);
  pStream->Release();
#else
  OleLoadPicture(pStream, 0, 0, &IID_IPicture, (void **)(void *)&pPic);
  pStream->lpVtbl->Release(pStream);
#endif

  GlobalFree(hG);

  if (!pPic)
  {
    HB_RETHANDLE(NULL);
    return;
  }

#if defined(__cplusplus)
  pPic->get_Handle((OLE_HANDLE *)&hBitmap);
#else
  pPic->lpVtbl->get_Handle(pPic, (OLE_HANDLE *)(void *)&hBitmap);
#endif

  hwg_ret_HANDLE(CopyImage(hBitmap, IMAGE_BITMAP, 0, 0, LR_COPYRETURNORG));

#if defined(__cplusplus)
  pPic->Release();
#else
  pPic->lpVtbl->Release(pPic);
#endif
}

/*
PATBLT(HDC, nX, nY, nWidth, nHeight, nRop) --> .T.|.F.
*/
HB_FUNC(PATBLT)
{
  hwg_ret_BOOL(
      PatBlt(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), hwg_par_int(4), hwg_par_int(5), hwg_par_DWORD(6)));
}

/*
SAVEDC(HDC) --> .T.|.F.
*/
HB_FUNC(HWG_SAVEDC)
{
  // TODO: o valor de retorno deve ser numérico e não lógico
  hb_retl(SaveDC(hwg_par_HDC(1)));
}

HB_FUNC_TRANSLATE(SAVEDC, HWG_SAVEDC);

/*
RESTOREDC(HDC, nSavedDC) --> .T.|.F.
*/
HB_FUNC(HWG_RESTOREDC)
{
  hwg_ret_BOOL(RestoreDC(hwg_par_HDC(1), hwg_par_int(2)));
}

HB_FUNC_TRANSLATE(RESTOREDC, HWG_RESTOREDC);

/*
CREATECOMPATIBLEDC(HDC) --> HDC
*/
HB_FUNC(HWG_CREATECOMPATIBLEDC)
{
  hwg_ret_HDC(CreateCompatibleDC(hwg_par_HDC(1)));
}

HB_FUNC_TRANSLATE(CREATECOMPATIBLEDC, HWG_CREATECOMPATIBLEDC);

/*
SETMAPMODE(HDC, nMode) --> numeric
*/
HB_FUNC(SETMAPMODE)
{
  hwg_ret_int(SetMapMode(hwg_par_HDC(1), hwg_par_int(2)));
}

/*
SETWINDOWORGEX(HDC, nX, nY) -->
*/
HB_FUNC(SETWINDOWORGEX) // TODO: o retorno é BOOL
{
  SetWindowOrgEx(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), NULL);
  hb_stornl(0, 4);
}

/*
SETWINDOWEXTEX(HDC, nX, nY) -->
*/
HB_FUNC(SETWINDOWEXTEX) // TODO: o retorno é BOOL
{
  SetWindowExtEx(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), NULL);
  hb_stornl(0, 4);
}

/*
SETVIEWPORTORGEX(HDC, nX, nY) -->
*/
HB_FUNC(SETVIEWPORTORGEX) // TODO: o retorno é BOOL
{
  SetViewportOrgEx(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), NULL);
  hb_stornl(0, 4);
}

/*
SETVIEWPORTEXTEX(HDC, nX, nY) -->
*/
HB_FUNC(SETVIEWPORTEXTEX) // TODO: o retorno é BOOL
{
  SetViewportExtEx(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), NULL);
  hb_stornl(0, 4);
}

/*
SETARCDIRECTION(HDC, nDir) --> numeric
*/
HB_FUNC(SETARCDIRECTION)
{
  hwg_ret_int(SetArcDirection(hwg_par_HDC(1), hwg_par_int(2)));
}

/*
SETROP2(HDC, nRop2) --> numeric
*/
HB_FUNC(SETROP2)
{
  hwg_ret_int(SetROP2(hwg_par_HDC(1), hwg_par_int(2)));
}

/*
BITBLT(HDC, nX, nY, nWidth, nHeight, HDCSRC, nX, nY, nRop) --> .T.|.F.
*/
HB_FUNC(BITBLT)
{
  hwg_ret_BOOL(BitBlt(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), hwg_par_int(4), hwg_par_int(5), hwg_par_HDC(6),
                      hwg_par_int(7), hwg_par_int(8), hwg_par_DWORD(9)));
}

/*
CREATECOMPATIBLEBITMAP(HDC, nWidth, nHeight) --> HBITMAP
*/
HB_FUNC(CREATECOMPATIBLEBITMAP)
{
  hwg_ret_HBITMAP(CreateCompatibleBitmap(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3)));
}

/*
INFLATERECT(aRect, nDX, nDY) --> .T.|.F.
*/
HB_FUNC(INFLATERECT)
{
  RECT pRect;

  if (HB_ISARRAY(1))
  {
    Array2Rect(hb_param(1, HB_IT_ARRAY), &pRect);
  }

  hwg_ret_BOOL(InflateRect(&pRect, hwg_par_int(2), hwg_par_int(3)));

  hb_storvni(pRect.left, 1, 1);
  hb_storvni(pRect.top, 1, 2);
  hb_storvni(pRect.right, 1, 3);
  hb_storvni(pRect.bottom, 1, 4);
}

/*
FRAMERECT(HDC, aRect) --> numeric
*/
HB_FUNC(FRAMERECT)
{
  RECT pRect;

  if (HB_ISARRAY(2))
  {
    Array2Rect(hb_param(2, HB_IT_ARRAY), &pRect);
  }

  hb_retni(FrameRect(hwg_par_HDC(1), &pRect, hwg_par_HBRUSH(3)));
}

/*
DRAWFRAMECONTROL(HDC, aRect, nType, nState) --> .T.|.F.
*/
HB_FUNC(DRAWFRAMECONTROL)
{
  RECT pRect;

  if (HB_ISARRAY(2))
  {
    Array2Rect(hb_param(2, HB_IT_ARRAY), &pRect);
  }

  hwg_ret_BOOL(DrawFrameControl(hwg_par_HDC(1), &pRect, hwg_par_UINT(3), hwg_par_UINT(4)));
}

/*
OFFSETRECT(aRect, nX, nY) --> .T.|.F.
*/
HB_FUNC(OFFSETRECT)
{
  RECT pRect;

  if (HB_ISARRAY(1))
  {
    Array2Rect(hb_param(1, HB_IT_ARRAY), &pRect);
  }

  hwg_ret_BOOL(OffsetRect(&pRect, hwg_par_int(2), hwg_par_int(3)));
  hb_storvni(pRect.left, 1, 1);
  hb_storvni(pRect.top, 1, 2);
  hb_storvni(pRect.right, 1, 3);
  hb_storvni(pRect.bottom, 1, 4);
}

/*
DRAWFOCUSRECT(HDC, aRect) --> .T.|.F.
*/
HB_FUNC(DRAWFOCUSRECT)
{
  RECT pRect;

  if (HB_ISARRAY(2))
  {
    Array2Rect(hb_param(2, HB_IT_ARRAY), &pRect);
  }

  hwg_ret_BOOL(DrawFocusRect(hwg_par_HDC(1), &pRect));
}

BOOL Array2Point(PHB_ITEM aPoint, POINT *pt)
{
  if (HB_IS_ARRAY(aPoint) && hb_arrayLen(aPoint) == 2)
  {
    pt->x = hb_arrayGetNL(aPoint, 1);
    pt->y = hb_arrayGetNL(aPoint, 2);
    return TRUE;
  }

  return FALSE;
}

/*
PTINRECT(aRect, aPoint) --> .T.|.F.
*/
HB_FUNC(PTINRECT)
{
  POINT pt;
  RECT rect;

  Array2Rect(hb_param(1, HB_IT_ARRAY), &rect);
  Array2Point(hb_param(2, HB_IT_ARRAY), &pt);
  hwg_ret_BOOL(PtInRect(&rect, pt));
}

/*
GETMEASUREITEMINFO(MEASUREITEMSTRUCT) --> array
*/
HB_FUNC(GETMEASUREITEMINFO)
{
  MEASUREITEMSTRUCT *lpdis = (MEASUREITEMSTRUCT *)HB_PARHANDLE(1); // hb_parnl(1);
  PHB_ITEM aMetr = hb_itemArrayNew(5);
  PHB_ITEM temp;

  temp = hb_itemPutNL(NULL, lpdis->CtlType);
  hb_itemArrayPut(aMetr, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, lpdis->CtlID);
  hb_itemArrayPut(aMetr, 2, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, lpdis->itemID);
  hb_itemArrayPut(aMetr, 3, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, lpdis->itemWidth);
  hb_itemArrayPut(aMetr, 4, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, lpdis->itemHeight);
  hb_itemArrayPut(aMetr, 5, temp);
  hb_itemRelease(temp);
  hb_itemReturnRelease(aMetr);
}

/*
COPYRECT(aRect) --> aRect
*/
HB_FUNC(COPYRECT)
{
  RECT p;
  Array2Rect(hb_param(1, HB_IT_ARRAY), &p);
  hb_itemReturnRelease(Rect2Array(&p));
}

/*
GETWINDOWDC(HWND) --> HDC
*/
HB_FUNC(HWG_GETWINDOWDC)
{
  hwg_ret_HDC(GetWindowDC(hwg_par_HWND(1)));
}

HB_FUNC_TRANSLATE(GETWINDOWDC, HWG_GETWINDOWDC);

/*
MODIFYSTYLE(HWND, np2, np3) -->
*/
HB_FUNC(MODIFYSTYLE)
{
  HWND hWnd = hwg_par_HWND(1);
  DWORD dwStyle = (DWORD)GetWindowLongPtr(hWnd, GWL_STYLE);
  DWORD a = hb_parnl(2);
  DWORD b = hb_parnl(3);
  DWORD dwNewStyle = (dwStyle & ~a) | b;
  SetWindowLongPtr(hWnd, GWL_STYLE, dwNewStyle);
}

#if 0
HB_FUNC(PTRRECT2ARRAY)
{
  RECT *rect = (RECT *)HB_PARHANDLE(1);
  hb_itemReturnRelease(Rect2Array(&rect));
}
#endif
