//
// $Id: drawtext.c 1835 2012-01-21 09:37:51Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// C level text functions
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://www.geocities.com/alkresin/
//

#define OEMRESOURCE
#include "hwingui.h"
#include <commctrl.h>
#include <hbapiitm.h>
#include <hbvm.h>
#include <hbstack.h>

HB_FUNC_EXTERN(HB_OEMTOANSI);
HB_FUNC_EXTERN(HB_ANSITOOEM);

/*
HWG_DEFINEPAINTSTRU(PAINTSTRUCT) -->
*/
HB_FUNC(HWG_DEFINEPAINTSTRU)
{
  hwg_ret_PAINTSTRUCT((PAINTSTRUCT *)hb_xgrab(sizeof(PAINTSTRUCT)));
}

HB_FUNC_TRANSLATE(DEFINEPAINTSTRU, HWG_DEFINEPAINTSTRU);

/*
HWG_BEGINPAINT(HWND, PAINTSTRUCT) -->
*/
HB_FUNC(HWG_BEGINPAINT)
{
  hwg_ret_HDC(BeginPaint(hwg_par_HWND(1), hwg_par_PAINTSTRUCT(2)));
}

HB_FUNC_TRANSLATE(BEGINPAINT, HWG_BEGINPAINT);

/*
HWG_ENDPAINT(HWND, PAINTSTRUCT) -->
*/
HB_FUNC(HWG_ENDPAINT)
{
  PAINTSTRUCT *pps = hwg_par_PAINTSTRUCT(2);
  EndPaint(hwg_par_HWND(1), pps); // TODO: o retorno é BOOL
  hb_xfree(pps);
}

HB_FUNC_TRANSLATE(ENDPAINT, HWG_ENDPAINT);

/*
DELETEDC(HDC) -->
*/
HB_FUNC(DELETEDC)
{
  DeleteDC(hwg_par_HDC(1)); // TODO: o retorno é BOOL
}

/*
TEXTOUT(HDC, nX, nY, cString) -->
*/
HB_FUNC(TEXTOUT)
{
  void *hText;
  HB_SIZE nLen;
  LPCTSTR lpText = HB_PARSTR(4, &hText, &nLen);
  TextOut(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), lpText, (int)nLen); // TODO: o retorno é BOOL
  hb_strfree(hText);
}

/*
DRAWTEXT(HDC, cText, nLeft, nTop, nRight, nBottom, nFormat, p8) --> numeric
DRAWTEXT(HDC, cText, aRect, nFormat, p8) --> numeric
*/
HB_FUNC(DRAWTEXT)
{
  void *hText;
  HB_SIZE nLen;
  LPCTSTR lpText = HB_PARSTR(2, &hText, &nLen);
  RECT rc;
  UINT uFormat = hb_pcount() == 4 ? hwg_par_UINT(4) : hwg_par_UINT(7);
  // int uiPos = (hb_pcount() == 4 ? 3 : hb_parni(8));
  int heigh;

  if (hb_pcount() > 4)
  {
    rc.left = hb_parni(3);
    rc.top = hb_parni(4);
    rc.right = hb_parni(5);
    rc.bottom = hb_parni(6);
  }
  else
  {
    Array2Rect(hb_param(3, HB_IT_ARRAY), &rc);
  }

  heigh = DrawText(hwg_par_HDC(1), lpText, (int)nLen, &rc, uFormat);
  hb_strfree(hText);

  // if (HB_ISBYREF(uiPos))
  if (HB_ISARRAY(8))
  {
    hb_storvni(rc.left, 8, 1);
    hb_storvni(rc.top, 8, 2);
    hb_storvni(rc.right, 8, 3);
    hb_storvni(rc.bottom, 8, 4);
  }
  hwg_ret_int(heigh); // TODO: remover variável heigh
}

/*
GETTEXTMETRIC(HDC) --> array[8]
*/
HB_FUNC(GETTEXTMETRIC)
{
  TEXTMETRIC tm;
  PHB_ITEM aMetr = hb_itemArrayNew(8);
  PHB_ITEM temp;

  GetTextMetrics(hwg_par_HDC(1), &tm);

  temp = hb_itemPutNL(NULL, tm.tmHeight);
  hb_itemArrayPut(aMetr, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, tm.tmAveCharWidth);
  hb_itemArrayPut(aMetr, 2, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, tm.tmMaxCharWidth);
  hb_itemArrayPut(aMetr, 3, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, tm.tmExternalLeading);
  hb_itemArrayPut(aMetr, 4, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, tm.tmInternalLeading);
  hb_itemArrayPut(aMetr, 5, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, tm.tmAscent);
  hb_itemArrayPut(aMetr, 6, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, tm.tmDescent);
  hb_itemArrayPut(aMetr, 7, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, tm.tmWeight);
  hb_itemArrayPut(aMetr, 8, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aMetr);
}

/*
GETTEXTSIZE(HDC, cText) -->
*/
HB_FUNC(GETTEXTSIZE)
{
  void *hText;
  HB_SIZE nLen;
  LPCTSTR lpText = HB_PARSTR(2, &hText, &nLen);
  SIZE sz;
  PHB_ITEM aMetr = hb_itemArrayNew(2);
  PHB_ITEM temp;

  GetTextExtentPoint32(hwg_par_HDC(1), lpText, (int)nLen, &sz); // TODO: o retorno é BOOL
  hb_strfree(hText);

  temp = hb_itemPutNL(NULL, sz.cx);
  hb_itemArrayPut(aMetr, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, sz.cy);
  hb_itemArrayPut(aMetr, 2, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aMetr);
}

/*
HWG_GETCLIENTRECT(HWND) --> aRect[4]
*/
HB_FUNC(HWG_GETCLIENTRECT)
{
  RECT rc;
  PHB_ITEM aMetr = hb_itemArrayNew(4);
  PHB_ITEM temp;

  GetClientRect(hwg_par_HWND(1), &rc); // TODO: o retorno é BOOL

  temp = hb_itemPutNL(NULL, rc.left);
  hb_itemArrayPut(aMetr, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, rc.top);
  hb_itemArrayPut(aMetr, 2, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, rc.right);
  hb_itemArrayPut(aMetr, 3, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, rc.bottom);
  hb_itemArrayPut(aMetr, 4, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aMetr);
}

HB_FUNC_TRANSLATE(GETCLIENTRECT, HWG_GETCLIENTRECT);

/*
GETWINDOWRECT(HWND) --> aRect[4]
*/
HB_FUNC(HWG_GETWINDOWRECT)
{
  RECT rc;
  PHB_ITEM aMetr = hb_itemArrayNew(4);
  PHB_ITEM temp;

  GetWindowRect(hwg_par_HWND(1), &rc); // TODO: o retorno é BOOL

  temp = hb_itemPutNL(NULL, rc.left);
  hb_itemArrayPut(aMetr, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, rc.top);
  hb_itemArrayPut(aMetr, 2, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, rc.right);
  hb_itemArrayPut(aMetr, 3, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, rc.bottom);
  hb_itemArrayPut(aMetr, 4, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aMetr);
}

HB_FUNC_TRANSLATE(GETWINDOWRECT, HWG_GETWINDOWRECT);

/*
GETCLIENTAREA(PAINTSTRUCT) --> aRect[4]
*/
HB_FUNC(GETCLIENTAREA)
{
  PAINTSTRUCT *pps = hwg_par_PAINTSTRUCT(1);
  PHB_ITEM aMetr = hb_itemArrayNew(4);
  PHB_ITEM temp;

  temp = hb_itemPutNL(NULL, pps->rcPaint.left);
  hb_itemArrayPut(aMetr, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, pps->rcPaint.top);
  hb_itemArrayPut(aMetr, 2, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, pps->rcPaint.right);
  hb_itemArrayPut(aMetr, 3, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, pps->rcPaint.bottom);
  hb_itemArrayPut(aMetr, 4, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aMetr);
}

/*
SETTEXTCOLOR(HDC, COLORREF) --> COLORREF
*/
HB_FUNC(SETTEXTCOLOR)
{
  hwg_ret_COLORREF(SetTextColor(hwg_par_HDC(1), hwg_par_COLORREF(2)));
}

/*
SETBKCOLOR(HDC, COLORREF) --> COLORREF
*/
HB_FUNC(SETBKCOLOR)
{
  hwg_ret_COLORREF(SetBkColor(hwg_par_HDC(1), hwg_par_COLORREF(2)));
}

/*
SETTRANSPARENTMODE(HDC, lTransparent) --> .T.|.F.
*/
HB_FUNC(SETTRANSPARENTMODE)
{
  int iMode = SetBkMode(hwg_par_HDC(1), hb_parl(2) ? TRANSPARENT : OPAQUE);
  hb_retl(iMode == TRANSPARENT);
}

/*
GETTEXTCOLOR(HDC) --> COLORREF
*/
HB_FUNC(GETTEXTCOLOR)
{
  hwg_ret_COLORREF(GetTextColor(hwg_par_HDC(1)));
}

/*
GETBKCOLOR(HDC) --> COLORREF
*/
HB_FUNC(GETBKCOLOR)
{
  hwg_ret_COLORREF(GetBkColor(hwg_par_HDC(1)));
}

/*
HB_FUNC(GETTEXTSIZE)
{
   HDC hdc = GetDC(hwg_par_HWND(1));
   SIZE size;
   PHB_ITEM aMetr = hb_itemArrayNew(2);
   PHB_ITEM temp;
   void * hString;

   GetTextExtentPoint32(hdc, HB_PARSTR(2, &hString, NULL),
      lpString,         // address of text string
      strlen(cbString), // number of characters in string
      &size            // address of structure for string size
   );
   hb_strfree(hString);

   temp = hb_itemPutNI(NULL, size.cx);
   hb_itemArrayPut(aMetr, 1, temp);
   hb_itemRelease(temp);

   temp = hb_itemPutNI(NULL, size.cy);
   hb_itemArrayPut(aMetr, 2, temp);
   hb_itemRelease(temp);

   hb_itemReturnRelease(aMetr);
}
*/

/*
EXTTEXTOUT(HDC, nX, nY, nLeft, nTop, nRight, nBottom, cText) -->
*/
HB_FUNC(EXTTEXTOUT)
{
  RECT rc;
  void *hText;
  HB_SIZE nLen;
  LPCTSTR lpText = HB_PARSTR(8, &hText, &nLen);
  rc.left = hb_parni(4);
  rc.top = hb_parni(5);
  rc.right = hb_parni(6);
  rc.bottom = hb_parni(7);
  ExtTextOut(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), ETO_OPAQUE, &rc, lpText, (UINT)nLen, NULL);
  hb_strfree(hText);
}

/*
WRITESTATUSWINDOW(HWND, nIndex) -->
*/
HB_FUNC(WRITESTATUSWINDOW)
{
  void *hString;
  SendMessage(hwg_par_HWND(1), SB_SETTEXT, hwg_par_WPARAM(2), (LPARAM)HB_PARSTR(3, &hString, NULL));
  hb_strfree(hString);
}

/*
WINDOWFROMDC(HDC) --> HWND
*/
HB_FUNC(WINDOWFROMDC)
{
  hwg_ret_HWND(WindowFromDC(hwg_par_HDC(1)));
}

/* CreateFont(fontName, nWidth, hHeight [,fnWeight] [,fdwCharSet], [,fdwItalic] [,fdwUnderline] [,fdwStrikeOut])
 */

/*
CREATEFONT(cFontName, nWidth, nHeight, nWeight, nCharSet, nItalic, nUnderline, nStrikeOut) --> HFONT
*/
HB_FUNC(CREATEFONT)
{
  HFONT hFont;
  int fnWeight = (HB_ISNIL(4)) ? 0 : hwg_par_int(4);
  DWORD fdwCharSet = (HB_ISNIL(5)) ? 0 : hwg_par_DWORD(5);
  DWORD fdwItalic = (HB_ISNIL(6)) ? 0 : hwg_par_DWORD(6);
  DWORD fdwUnderline = (HB_ISNIL(7)) ? 0 : hwg_par_DWORD(7);
  DWORD fdwStrikeOut = (HB_ISNIL(8)) ? 0 : hwg_par_DWORD(8);
  void *hString;
  hFont = CreateFont(hwg_par_int(3), hwg_par_int(2), 0, 0, fnWeight, fdwItalic, fdwUnderline, fdwStrikeOut, fdwCharSet,
                     0, 0, 0, 0, HB_PARSTR(1, &hString, NULL));
  hb_strfree(hString);
  hwg_ret_HFONT(hFont);
}

/*
 * SetCtrlFont(hWnd, ctrlId, hFont)
 */

/*
SETCTRLFONT(HWND, nID, HFONT) -->
*/
HB_FUNC(SETCTRLFONT)
{
  SendDlgItemMessage(hwg_par_HWND(1), hwg_par_int(2), WM_SETFONT, (WPARAM)hwg_par_HFONT(3), 0);
}

/*
 */
HB_FUNC(OEMTOANSI)
{
  HB_FUNC_EXEC(HB_OEMTOANSI);
}

/*
 */
HB_FUNC(ANSITOOEM)
{
  HB_FUNC_EXEC(HB_ANSITOOEM);
}

/*
CREATERECTRGN(nX1, nY1, nX2, nY2) --> HRGN
*/
HB_FUNC(CREATERECTRGN)
{
  hwg_ret_HRGN(CreateRectRgn(hwg_par_int(1), hwg_par_int(2), hwg_par_int(3), hwg_par_int(4)));
}

/*
CREATERECTRGNINDIRECT(NIL, nLeft, nTop, nRight, nBottom) --> HRGN
*/
HB_FUNC(CREATERECTRGNINDIRECT)
{
  RECT rc;
  rc.left = hb_parni(2);
  rc.top = hb_parni(3);
  rc.right = hb_parni(4);
  rc.bottom = hb_parni(5);
  hwg_ret_HRGN(CreateRectRgnIndirect(&rc));
}

/*
EXTSELECTCLIPRGN(HDC, HRGN, nMode) --> numeric
*/
HB_FUNC(EXTSELECTCLIPRGN)
{
  hwg_ret_int(ExtSelectClipRgn(hwg_par_HDC(1), hwg_par_HRGN(2), hwg_par_int(3)));
}

/*
SELECTCLIPRGN(HDC, HRGN) --> numeric
*/
HB_FUNC(SELECTCLIPRGN)
{
  hwg_ret_int(SelectClipRgn(hwg_par_HDC(1), hwg_par_HRGN(2)));
}

/*
CREATEFONTINDIRECT(cFontName, nWeight, nHeight, nQuality) --> HFONT
*/
HB_FUNC(CREATEFONTINDIRECT)
{
  LOGFONT lf;
  HFONT f;
  memset(&lf, 0, sizeof(LOGFONT));
  lf.lfQuality = hwg_par_BYTE(4);
  lf.lfHeight = hwg_par_LONG(3);
  lf.lfWeight = hwg_par_LONG(2);
  HB_ITEMCOPYSTR(hb_param(1, HB_IT_ANY), lf.lfFaceName, HB_SIZEOFARRAY(lf.lfFaceName));
  lf.lfFaceName[HB_SIZEOFARRAY(lf.lfFaceName) - 1] = '\0';
  f = CreateFontIndirect(&lf);
  hwg_ret_HFONT(f);
}
