//
// $Id: misc.c 1846 2012-07-02 16:52:31Z LFBASSO $
//
// HWGUI - Harbour Win32 GUI library source code:
// Miscellaneous functions
//
// Copyright 2003 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://www.geocities.com/alkresin/
//

#define OEMRESOURCE
#include "hwingui.h"
#include <commctrl.h>
#include <math.h>

#include <hbmath.h>
#include <hbapifs.h>
#include <hbapiitm.h>
#include <hbvm.h>

#include "missing.h"

#if defined(__BORLANDC__) && defined(__clang__) && defined(HB_OS_WIN_64)
#define PtrToUlong(p) ((ULONG)(ULONG_PTR)(p))
#endif

void writelog(char *s)
{
  HB_FHANDLE handle;

  if (hb_fsFile("ac.log"))
  {
    handle = hb_fsOpen("ac.log", FO_WRITE);
  }
  else
  {
    handle = hb_fsCreate("ac.log", 0);
  }

  hb_fsSeek(handle, 0, SEEK_END);
  hb_fsWrite(handle, (const char *)s, (USHORT)strlen(s));
  hb_fsWrite(handle, "\n\r", 2);

  hb_fsClose(handle);
}

HB_FUNC(HWG_SETDLGRESULT)
{
  SetWindowLong(hwg_par_HWND(1), DWLP_MSGRESULT, hb_parni(2));
}

HB_FUNC(SETCAPTURE)
{
  hwg_ret_HWND(SetCapture(hwg_par_HWND(1)));
}

HB_FUNC(RELEASECAPTURE)
{
  hwg_ret_BOOL(ReleaseCapture());
}

HB_FUNC(COPYSTRINGTOCLIPBOARD)
{
  if (OpenClipboard(GetActiveWindow()))
  {
    HGLOBAL hglbCopy;
    char *lptstrCopy;
    void *hStr;
    HB_SIZE nLen;
    LPCTSTR lpStr;

    EmptyClipboard();

    lpStr = HB_PARSTRDEF(1, &hStr, &nLen);
    hglbCopy = GlobalAlloc(GMEM_DDESHARE, (nLen + 1) * sizeof(TCHAR));
    if (hglbCopy != NULL)
    {
      // Lock the handle and copy the text to the buffer.
      lptstrCopy = (char *)GlobalLock(hglbCopy);
      memcpy(lptstrCopy, lpStr, nLen * sizeof(TCHAR));
      lptstrCopy[nLen] = 0; // null character
      GlobalUnlock(hglbCopy);
      hb_strfree(hStr);

      // Place the handle on the clipboard.
#ifdef UNICODE
      SetClipboardData(CF_UNICODETEXT, hglbCopy);
#else
      SetClipboardData(CF_TEXT, hglbCopy);
#endif
    }
    CloseClipboard();
  }
}

HB_FUNC(GETCLIPBOARDTEXT)
{
  HWND hWnd = hwg_par_HWND(1);
  LPTSTR lpText = NULL;

  if (OpenClipboard(hWnd))
  {
#ifdef UNICODE
    HGLOBAL hglb = GetClipboardData(CF_UNICODETEXT);
#else
    HGLOBAL hglb = GetClipboardData(CF_TEXT);
#endif
    if (hglb)
    {
      LPVOID lpMem = GlobalLock(hglb);
      if (lpMem)
      {
        HB_SIZE nSize = (HB_SIZE)GlobalSize(hglb);
        if (nSize)
        {
          lpText = (LPTSTR)hb_xgrab(nSize + 1);
          memcpy(lpText, lpMem, nSize);
          lpText[nSize] = 0;
        }
        (void)GlobalUnlock(hglb);
      }
    }
    CloseClipboard();
  }
  HB_RETSTR(lpText);
  if (lpText)
  {
    hb_xfree(lpText);
  }
}

HB_FUNC(GETSTOCKOBJECT)
{
  hwg_ret_HGDIOBJ(GetStockObject(hb_parni(1)));
}

HB_FUNC(HWG_LOWORD)
{
  hb_retni((int)((HB_ISPOINTER(1) ? PtrToUlong(hb_parptr(1)) : (ULONG)hb_parnl(1)) & 0xFFFF));
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(LOWORD, HWG_LOWORD);
#endif

HB_FUNC(HWG_HIWORD)
{
  hb_retni((int)(((HB_ISPOINTER(1) ? PtrToUlong(hb_parptr(1)) : (ULONG)hb_parnl(1)) >> 16) & 0xFFFF));
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(HIWORD, HWG_HIWORD);
#endif

HB_FUNC(HWG_BITOR)
{
  hb_retnl((HB_ISPOINTER(1) ? PtrToUlong(hb_parptr(1)) : (ULONG)hb_parnl(1)) | hb_parnl(2));
}

HB_FUNC(HWG_BITAND)
{
  hb_retnl((HB_ISPOINTER(1) ? PtrToUlong(hb_parptr(1)) : (ULONG)hb_parnl(1)) & hb_parnl(2));
}

HB_FUNC(HWG_BITANDINVERSE)
{
  hb_retnl((HB_ISPOINTER(1) ? PtrToUlong(hb_parptr(1)) : (ULONG)hb_parnl(1)) & (~hb_parnl(2)));
}

HB_FUNC(SETBIT)
{
  if (hb_pcount() < 3 || hb_parni(3))
  {
    hb_retnl(hb_parnl(1) | (1 << (hb_parni(2) - 1)));
  }
  else
  {
    hb_retnl(hb_parnl(1) & ~(1 << (hb_parni(2) - 1)));
  }
}

HB_FUNC(CHECKBIT)
{
  hb_retl((HB_ISPOINTER(1) ? PtrToUlong(hb_parptr(1)) : (ULONG)hb_parnl(1)) & (1 << (hb_parni(2) - 1)));
}

HB_FUNC(HWG_SIN)
{
  hb_retnd(sin(hb_parnd(1)));
}

HB_FUNC(HWG_COS)
{
  hb_retnd(cos(hb_parnd(1)));
}

HB_FUNC(HWG_CLIENTTOSCREEN)
{
  POINT pt;
  PHB_ITEM aPoint = hb_itemArrayNew(2);
  PHB_ITEM temp;

  pt.x = hb_parnl(2);
  pt.y = hb_parnl(3);
  ClientToScreen(hwg_par_HWND(1), &pt);

  temp = hb_itemPutNL(NULL, pt.x);
  hb_itemArrayPut(aPoint, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, pt.y);
  hb_itemArrayPut(aPoint, 2, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aPoint);
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(CLIENTTOSCREEN, HWG_CLIENTTOSCREEN);
#endif

HB_FUNC(HWG_SCREENTOCLIENT)
{
  POINT pt;
  RECT R;
  PHB_ITEM aPoint = hb_itemArrayNew(2);
  PHB_ITEM temp;

  if (hb_pcount() > 2)
  {
    pt.x = hb_parnl(2);
    pt.y = hb_parnl(3);

    ScreenToClient(hwg_par_HWND(1), &pt);
  }
  else
  {
    Array2Rect(hb_param(2, HB_IT_ARRAY), &R);
    ScreenToClient(hwg_par_HWND(1), (LPPOINT)(void *)&R);
    ScreenToClient(hwg_par_HWND(1), ((LPPOINT)(void *)&R) + 1);
    hb_itemReturnRelease(Rect2Array(&R));
    return;
  }

  temp = hb_itemPutNL(NULL, pt.x);
  hb_itemArrayPut(aPoint, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, pt.y);
  hb_itemArrayPut(aPoint, 2, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aPoint);
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(SCREENTOCLIENT, HWG_SCREENTOCLIENT);
#endif

HB_FUNC(HWG_GETCURSORPOS)
{
  POINT pt;
  PHB_ITEM aPoint = hb_itemArrayNew(2);
  PHB_ITEM temp;

  GetCursorPos(&pt);
  temp = hb_itemPutNL(NULL, pt.x);
  hb_itemArrayPut(aPoint, 1, temp);
  hb_itemRelease(temp);

  temp = hb_itemPutNL(NULL, pt.y);
  hb_itemArrayPut(aPoint, 2, temp);
  hb_itemRelease(temp);

  hb_itemReturnRelease(aPoint);
}

HB_FUNC(HWG_SETCURSORPOS)
{
  int x, y;

  x = hb_parni(1);
  y = hb_parni(2);

  SetCursorPos(x, y);
}

HB_FUNC(GETCURRENTDIR)
{
  TCHAR buffer[HB_PATH_MAX];

  GetCurrentDirectory(HB_PATH_MAX, buffer);
  HB_RETSTR(buffer);
}

HB_FUNC(WINEXEC)
{
  hb_retni(WinExec(hb_parc(1), hwg_par_UINT(2)));
}

HB_FUNC(GETKEYBOARDSTATE)
{
  BYTE lpbKeyState[256];
  GetKeyboardState(lpbKeyState);
  lpbKeyState[255] = '\0';
  hb_retclen((char *)lpbKeyState, 255);
}

HB_FUNC(GETKEYSTATE)
{
  hb_retni(GetKeyState(hb_parni(1)));
}

HB_FUNC(GETKEYNAMETEXT)
{
  TCHAR cText[MAX_PATH];
  int iRet = GetKeyNameText(hb_parnl(1), cText, MAX_PATH);

  if (iRet)
  {
    HB_RETSTRLEN(cText, iRet);
  }
}

HB_FUNC(ACTIVATEKEYBOARDLAYOUT)
{
  void *hLayout;
  LPCTSTR lpLayout = HB_PARSTR(1, &hLayout, NULL);
  HKL curr = GetKeyboardLayout(0);
  TCHAR sBuff[KL_NAMELENGTH];
  UINT num = GetKeyboardLayoutList(0, NULL), i = 0;

  do
  {
    GetKeyboardLayoutName(sBuff);
    if (!lstrcmp(sBuff, lpLayout))
    {
      break;
    }
    ActivateKeyboardLayout(0, 0);
    i++;
  }

  while (i < num);
  if (i >= num)
  {
    ActivateKeyboardLayout(curr, 0);
  }

  hb_strfree(hLayout);
}

/*
 * Pts2Pix(nPoints [,hDC]) --> nPixels
 * Conversion from points to pixels, provided by Vic McClung.
 */

HB_FUNC(PTS2PIX)
{

  HDC hDC;
  BOOL lDC = 1;

  if (hb_pcount() > 1 && !HB_ISNIL(1))
  {
    hDC = hwg_par_HDC(2);
    lDC = 0;
  }
  else
  {
    hDC = CreateDC(TEXT("DISPLAY"), NULL, NULL, NULL);
  }

  hb_retni(MulDiv(hb_parni(1), GetDeviceCaps(hDC, LOGPIXELSY), 72));
  if (lDC)
  {
    DeleteDC(hDC);
  }
}

/* Functions Contributed  By Luiz Rafael Culik Guimaraes (culikr@uol.com.br) */

HB_FUNC(GETWINDOWSDIR)
{
  TCHAR szBuffer[MAX_PATH + 1] = {0};

  GetWindowsDirectory(szBuffer, MAX_PATH);
  HB_RETSTR(szBuffer);
}

HB_FUNC(GETSYSTEMDIR)
{
  TCHAR szBuffer[MAX_PATH + 1] = {0};

  GetSystemDirectory(szBuffer, MAX_PATH);
  HB_RETSTR(szBuffer);
}

HB_FUNC(GETTEMPDIR)
{
  TCHAR szBuffer[MAX_PATH + 1] = {0};

  GetTempPath(MAX_PATH, szBuffer);
  HB_RETSTR(szBuffer);
}

HB_FUNC(POSTQUITMESSAGE)
{
  PostQuitMessage(hb_parni(1));
}

/*
Contributed by Rodrigo Moreno rodrigo_moreno@yahoo.com base upon code minigui
*/

HB_FUNC(SHELLABOUT)
{
  void *hStr1, *hStr2;

  hb_retni(ShellAbout(0, HB_PARSTRDEF(1, &hStr1, NULL), HB_PARSTRDEF(2, &hStr2, NULL),
                      (HB_ISNIL(3) ? NULL : hwg_par_HICON(3))));
  hb_strfree(hStr1);
  hb_strfree(hStr2);
}

HB_FUNC( HWG_GETNUMMONITORS ) // PEGA O NUMERO DE MONITORES QUE EST� RODANDO
{
   hb_retni( GetSystemMetrics( SM_CMONITORS ) );
}

HB_FUNC( HWG_GETDESKTOPWIDTH_VS )
{
   hb_retni( GetSystemMetrics( SM_CXVIRTUALSCREEN ) );
}

HB_FUNC( HWG_GETDESKTOPHEIGHT_VS )
{
   hb_retni( GetSystemMetrics( SM_CYVIRTUALSCREEN ) );
}

HB_FUNC(HWG_GETDESKTOPWIDTH)
{
  hb_retni(GetSystemMetrics(SM_CXSCREEN));
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(GETDESKTOPWIDTH, HWG_GETDESKTOPWIDTH);
#endif

HB_FUNC(HWG_GETDESKTOPHEIGHT)
{
  hb_retni(GetSystemMetrics(SM_CYSCREEN));
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(GETDESKTOPHEIGHT, HWG_GETDESKTOPHEIGHT);
#endif

HB_FUNC(GETHELPDATA)
{
  hb_retnint((LONG_PTR)(((HELPINFO FAR *)(LONG_PTR)hb_parnl(1))->hItemHandle));
}

HB_FUNC(WINHELP)
{
  DWORD context;
  UINT style;
  void *hStr;

  switch (hb_parni(3))
  {
  case 0:
    style = HELP_FINDER;
    context = 0;
    break;

  case 1:
    style = HELP_CONTEXT;
    context = hb_parni(4);
    break;

  case 2:
    style = HELP_CONTEXTPOPUP;
    context = hb_parni(4);
    break;

  default:
    style = HELP_CONTENTS;
    context = 0;
  }

  hb_retni(WinHelp(hwg_par_HWND(1), HB_PARSTR(2, &hStr, NULL), style, context));
  hb_strfree(hStr);
}

HB_FUNC(GETNEXTDLGTABITEM)
{
  hwg_ret_HWND(GetNextDlgTabItem(hwg_par_HWND(1), hwg_par_HWND(2), hb_parl(3)));
}

HB_FUNC(SLEEP)
{
  if (hb_parinfo(1))
  {
    Sleep(hb_parnl(1));
  }
}

HB_FUNC(KEYB_EVENT)
{
  DWORD dwFlags = (!(HB_ISNIL(2)) && hb_parl(2)) ? KEYEVENTF_EXTENDEDKEY : 0;
  int bShift = (!(HB_ISNIL(3)) && hb_parl(3)) ? TRUE : FALSE;
  int bCtrl = (!(HB_ISNIL(4)) && hb_parl(4)) ? TRUE : FALSE;
  int bAlt = (!(HB_ISNIL(5)) && hb_parl(5)) ? TRUE : FALSE;

  if (bShift)
  {
    keybd_event(VK_SHIFT, 0, 0, 0);
  }
  if (bCtrl)
  {
    keybd_event(VK_CONTROL, 0, 0, 0);
  }
  if (bAlt)
  {
    keybd_event(VK_MENU, 0, 0, 0);
  }

  keybd_event((BYTE)hb_parni(1), 0, dwFlags, 0);
  keybd_event((BYTE)hb_parni(1), 0, dwFlags | KEYEVENTF_KEYUP, 0);

  if (bShift)
  {
    keybd_event(VK_SHIFT, 0, KEYEVENTF_KEYUP, 0);
  }
  if (bCtrl)
  {
    keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
  }
  if (bAlt)
  {
    keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
  }
}

/* SetScrollInfo(hWnd, nType, nRedraw, nPos, nPage, nmax)
 */
HB_FUNC(SETSCROLLINFO)
{
  SCROLLINFO si;
  UINT fMask = (hb_pcount() < 4) ? SIF_DISABLENOSCROLL : 0;

  if (hb_pcount() > 3 && !HB_ISNIL(4))
  {
    si.nPos = hb_parni(4);
    fMask |= SIF_POS;
  }

  if (hb_pcount() > 4 && !HB_ISNIL(5))
  {
    si.nPage = hb_parni(5);
    fMask |= SIF_PAGE;
  }

  if (hb_pcount() > 5 && !HB_ISNIL(6))
  {
    si.nMin = 0;
    si.nMax = hb_parni(6);
    fMask |= SIF_RANGE;
  }

  si.cbSize = sizeof(SCROLLINFO);
  si.fMask = fMask;

  SetScrollInfo(hwg_par_HWND(1), // handle of window with scroll bar
                hb_parni(2),     // scroll bar flags
                &si, hb_parni(3) // redraw flag
  );
}

HB_FUNC(GETSCROLLRANGE)
{
  int MinPos, MaxPos;

  GetScrollRange(hwg_par_HWND(1), // handle of window with scroll bar
                 hb_parni(2),     // scroll bar flags
                 &MinPos,         // address of variable that receives minimum position
                 &MaxPos          // address of variable that receives maximum position
  );
  hb_storni(MinPos, 3);
  hb_storni(MaxPos, 4);
}

HB_FUNC(SETSCROLLRANGE)
{
  hwg_ret_BOOL(SetScrollRange(hwg_par_HWND(1), hb_parni(2), hb_parni(3), hb_parni(4), hb_parl(5)));
}

HB_FUNC(GETSCROLLPOS)
{
  hb_retni(GetScrollPos(hwg_par_HWND(1), // handle of window with scroll bar
                        hb_parni(2)      // scroll bar flags
                        ));
}

HB_FUNC(SETSCROLLPOS)
{
  SetScrollPos(hwg_par_HWND(1), // handle of window with scroll bar
               hb_parni(2),     // scroll bar flags
               hb_parni(3), TRUE);
}

HB_FUNC(SHOWSCROLLBAR)
{
  ShowScrollBar(hwg_par_HWND(1), // handle of window with scroll bar
                hb_parni(2),     // scroll bar flags
                hb_parl(3)       // scroll bar visibility
  );
}

HB_FUNC(SCROLLWINDOW)
{
  ScrollWindow(hwg_par_HWND(1), hb_parni(2), hb_parni(3), NULL, NULL);
}

HB_FUNC(ISCAPSLOCKACTIVE)
{
  hb_retl(GetKeyState(VK_CAPITAL));
}

HB_FUNC(ISNUMLOCKACTIVE)
{
  hb_retl(GetKeyState(VK_NUMLOCK));
}

HB_FUNC(ISSCROLLLOCKACTIVE)
{
  hb_retl(GetKeyState(VK_SCROLL));
}

/* Added By Sandro Freire sandrorrfreire_nospam_yahoo.com.br*/

HB_FUNC(HWG_CREATEDIRECTORY)
{
  void *hStr;
  CreateDirectory(HB_PARSTR(1, &hStr, NULL), NULL);
  hb_strfree(hStr);
}

HB_FUNC(HWG_REMOVEDIRECTORY)
{
  void *hStr;
  hwg_ret_BOOL(RemoveDirectory(HB_PARSTR(1, &hStr, NULL)));
  hb_strfree(hStr);
}

HB_FUNC(HWG_SETCURRENTDIRECTORY)
{
  void *hStr;
  SetCurrentDirectory(HB_PARSTR(1, &hStr, NULL));
  hb_strfree(hStr);
}

HB_FUNC(HWG_DELETEFILE)
{
  void *hStr;
  hwg_ret_BOOL(DeleteFile(HB_PARSTR(1, &hStr, NULL)));
  hb_strfree(hStr);
}

HB_FUNC(HWG_GETFILEATTRIBUTES)
{
  void *hStr;
  hb_retnl((LONG)GetFileAttributes(HB_PARSTR(1, &hStr, NULL)));
  hb_strfree(hStr);
}

HB_FUNC(HWG_SETFILEATTRIBUTES)
{
  void *hStr;
  hwg_ret_BOOL(SetFileAttributes(HB_PARSTR(1, &hStr, NULL), (DWORD)hb_parnl(2)));
  hb_strfree(hStr);
}

/* Add by Richard Roesnadi (based on What32) */
// GETCOMPUTERNAME([@nLengthChar]) -> cComputerName
HB_FUNC(HWG_GETCOMPUTERNAME)
{
  TCHAR cText[64] = {0};
  DWORD nSize = HB_SIZEOFARRAY(cText);
  GetComputerName(cText, &nSize);
  HB_RETSTR(cText);
  hb_stornl(nSize, 1);
}

// GETUSERNAME([@nLengthChar]) -> cUserName
HB_FUNC(HWG_GETUSERNAME)
{
  TCHAR cText[64] = {0};
  DWORD nSize = HB_SIZEOFARRAY(cText);
  GetUserName(cText, &nSize);
  HB_RETSTR(cText);
  hb_stornl(nSize, 1);
}

HB_FUNC(ISDOWNPRESSESED)
{
  hb_retl(HIWORD(GetKeyState(VK_DOWN)) > 0);
}

HB_FUNC(ISPGDOWNPRESSESED)
{
  hb_retl(HIWORD(GetKeyState(VK_NEXT)) > 0);
}

HB_FUNC(EDIT1UPDATECTRL)
{
  HWND hChild = hwg_par_HWND(1);
  HWND hParent = hwg_par_HWND(2);
  RECT *rect = NULL;

  GetWindowRect(hChild, rect);
  ScreenToClient(hParent, (LPPOINT)rect);
  ScreenToClient(hParent, ((LPPOINT)rect) + 1);
  InflateRect(rect, -2, -2);
  InvalidateRect(hParent, rect, TRUE);
  UpdateWindow(hParent);
}

HB_FUNC(BUTTON1GETSCREENCLIENT)
{
  HWND hChild = hwg_par_HWND(1);
  HWND hParent = hwg_par_HWND(2);
  RECT *rect = NULL;

  GetWindowRect(hChild, rect);
  ScreenToClient(hParent, (LPPOINT)rect);
  ScreenToClient(hParent, ((LPPOINT)rect) + 1);
  hb_itemReturnRelease(Rect2Array(rect));
}

HB_FUNC(HEDITEX_CTLCOLOR)
{
  HDC hdc = hwg_par_HDC(1);
  // UINT h = hb_parni( 2 ) ;
  PHB_ITEM pObject = hb_param(3, HB_IT_OBJECT);
  PHB_ITEM p, p1, p2, temp;
  LONG i;
  HBRUSH hBrush;
  COLORREF cColor;

  if (!pObject)
  {
    hb_retnint((LONG_PTR)GetStockObject(HOLLOW_BRUSH)); // TODO: revisar (retornar HBRUSH ?)
    SetBkMode(hdc, TRANSPARENT);
    return;
  }

  p = GetObjectVar(pObject, "M_BRUSH");
  p2 = GetObjectVar(pObject, "M_TEXTCOLOR");
  cColor = (COLORREF)hb_itemGetNL(p2);
  hBrush = (HBRUSH)HB_GETHANDLE(p);

  DeleteObject(hBrush);

  p1 = GetObjectVar(pObject, "M_BACKCOLOR");
  i = hb_itemGetNL(p1);
  if (i == -1)
  {
    hBrush = (HBRUSH)GetStockObject(HOLLOW_BRUSH);
    SetBkMode(hdc, TRANSPARENT);
  }
  else
  {
    hBrush = CreateSolidBrush((COLORREF)i);
    SetBkColor(hdc, (COLORREF)i);
  }

  temp = HB_PUTHANDLE(NULL, hBrush);
  SetObjectVar(pObject, "_M_BRUSH", temp);
  hb_itemRelease(temp);

  SetTextColor(hdc, cColor);
  hwg_ret_HBRUSH(hBrush);
}

HB_FUNC(GETKEYBOARDCOUNT)
{
  LPARAM lParam = hwg_par_LPARAM(1);

  hb_retni((WORD)lParam);
}

HB_FUNC(GETNEXTDLGGROUPITEM)
{
  hwg_ret_HWND(GetNextDlgGroupItem(hwg_par_HWND(1), hwg_par_HWND(2), hb_parl(3)));
}

HB_FUNC(PTRTOULONG)
{
  hb_retnl(HB_ISPOINTER(1) ? (LONG)PtrToUlong(hb_parptr(1)) : hb_parnl(1));
}

HB_FUNC(OUTPUTDEBUGSTRING)
{
  void *hStr;
  OutputDebugString(HB_PARSTRDEF(1, &hStr, NULL));
  hb_strfree(hStr);
}

HB_FUNC(HWG_GETSYSTEMMETRICS)
{
  hb_retni(GetSystemMetrics(hb_parni(1)));
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(GETSYSTEMMETRICS, HWG_GETSYSTEMMETRICS);
#endif

// nando
HB_FUNC(HWG_LASTKEY)
{
  BYTE kbBuffer[256];
  int i;

  GetKeyboardState(kbBuffer);

  for (i = 0; i < 256; i++)
  {
    if (kbBuffer[i] & 0x80)
    {
      hb_retni(i);
      return;
    }
  }
  hb_retni(0);
}

HB_FUNC(HWG_ISWIN7)
{
  OSVERSIONINFO ovi;
  ovi.dwOSVersionInfoSize = sizeof ovi;
  ovi.dwMajorVersion = 0;
  ovi.dwMinorVersion = 0;
  GetVersionEx(&ovi);
  hb_retl(ovi.dwMajorVersion >= 6 && ovi.dwMinorVersion == 1);
}
