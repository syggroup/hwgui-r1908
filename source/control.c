//
// $Id: control.c 1897 2012-09-17 23:12:45Z marcosgambeta $
//
// HWGUI - Harbour Win32 GUI library source code:
// C level controls functions
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

#if defined(__BORLANDC__) || (defined(_MSC_VER) && !defined(__XCC__) || defined(__WATCOMC__) || defined(__DMC__))
HB_EXTERN_BEGIN
WINUSERAPI HWND WINAPI GetAncestor(HWND hwnd, UINT gaFlags);
HB_EXTERN_END
#endif

#ifndef TTS_BALLOON
#define TTS_BALLOON 0x40 // added by MAG
#endif
#ifndef CCM_SETVERSION
#define CCM_SETVERSION (CCM_FIRST + 0x7)
#endif
#ifndef CCM_GETVERSION
#define CCM_GETVERSION (CCM_FIRST + 0x8)
#endif
#ifndef TB_GETIMAGELIST
#define TB_GETIMAGELIST (WM_USER + 49)
#endif

#if _MSC_VER
#define snprintf _snprintf
#endif

// LRESULT CALLBACK OwnBtnProc (HWND, UINT, WPARAM, LPARAM) ;
LRESULT CALLBACK WinCtrlProc(HWND, UINT, WPARAM, LPARAM);
LRESULT APIENTRY SplitterProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT APIENTRY StaticSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT APIENTRY ButtonSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT APIENTRY ComboSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT APIENTRY ListSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT APIENTRY UpDownSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT APIENTRY DatePickerSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT APIENTRY TrackSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT APIENTRY TabSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT APIENTRY TreeViewSubclassProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
static void CALLBACK s_timerProc(HWND, UINT, UINT, DWORD);

static HWND s_hWndTT = 0;
static BOOL s_lInitCmnCtrl = 0;
static BOOL s_lToolTipBalloon = FALSE; // added by MAG
static WNDPROC s_wpOrigTrackProc, s_wpOrigTabProc, s_wpOrigComboProc, s_wpOrigStaticProc, s_wpOrigListProc, s_wpOrigUpDownProc,
    s_wpOrigDatePickerProc, s_wpOrigTreeViewProc; // s_wpOrigButtonProc
static LONG_PTR s_wpOrigButtonProc;

HB_FUNC(HWG_INITCOMMONCONTROLSEX)
{
  if (!s_lInitCmnCtrl)
  {
    INITCOMMONCONTROLSEX i;

    i.dwSize = sizeof(INITCOMMONCONTROLSEX);
    i.dwICC = ICC_DATE_CLASSES | ICC_INTERNET_CLASSES | ICC_BAR_CLASSES | ICC_LISTVIEW_CLASSES | ICC_TAB_CLASSES |
              ICC_TREEVIEW_CLASSES;
    InitCommonControlsEx(&i);
    s_lInitCmnCtrl = 1;
  }
}

HB_FUNC(HWG_MOVEWINDOW)
{
  RECT rc;

  GetWindowRect(hwg_par_HWND(1), &rc);
  MoveWindow(hwg_par_HWND(1),                                  // handle of window
             (HB_ISNIL(2)) ? rc.left : hb_parni(2),            // horizontal position
             (HB_ISNIL(3)) ? rc.top : hb_parni(3),             // vertical position
             (HB_ISNIL(4)) ? rc.right - rc.left : hb_parni(4), // width
             (HB_ISNIL(5)) ? rc.bottom - rc.top : hb_parni(5), // height
             (hb_pcount() < 6) ? TRUE : hb_parl(6)             // repaint flag
  );
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(MOVEWINDOW, HWG_MOVEWINDOW);
#endif

/*
   CreateProgressBar(hParentWindow, nRange)
*/
HB_FUNC(CREATEPROGRESSBAR)
{
  HWND hPBar, hParentWindow = hwg_par_HWND(1);
  RECT rcClient;
  DWORD ulStyle;
  int cyVScroll = GetSystemMetrics(SM_CYVSCROLL);
  int x1, y1, nwidth, nheight;

  if (hb_pcount() > 2)
  {
    ulStyle = hwg_par_DWORD(3);
    x1 = hwg_par_int(4);
    y1 = hwg_par_int(5);
    nwidth = hwg_par_int(6);
    nheight = hb_pcount() > 6 && !HB_ISNIL(7) ? hwg_par_int(7) : cyVScroll;
  }
  else
  {
    GetClientRect(hParentWindow, &rcClient);
    ulStyle = 0;
    x1 = rcClient.left;
    y1 = rcClient.bottom - cyVScroll;
    nwidth = rcClient.right;
    nheight = cyVScroll;
  }

  hPBar = CreateWindowEx(0, PROGRESS_CLASS, NULL, WS_CHILD | WS_VISIBLE | ulStyle, x1, y1, nwidth, nheight,
                         hParentWindow, NULL, GetModuleHandle(NULL), NULL);

  SendMessage(hPBar, PBM_SETRANGE, 0, MAKELPARAM(0, hb_parni(2)));
  SendMessage(hPBar, PBM_SETSTEP, 1, 0);

  hwg_ret_HWND(hPBar);
}

/*
   UpdateProgressBar(hPBar)
*/
HB_FUNC(UPDATEPROGRESSBAR)
{
  SendMessage(hwg_par_HWND(1), PBM_STEPIT, 0, 0);
}

HB_FUNC(SETPROGRESSBAR)
{
  SendMessage(hwg_par_HWND(1), PBM_SETPOS, hwg_par_WPARAM(2), 0);
}

/*
   CreatePanel(hParentWindow, nPanelControlID, nStyle, x1, y1, nWidth, nHeight)
*/
HB_FUNC(CREATEPANEL)
{
  hwg_ret_HWND(CreateWindowEx(0, TEXT("PANEL"), NULL,
                              WS_CHILD | WS_VISIBLE | SS_GRAYRECT | SS_OWNERDRAW | CCS_TOP | hwg_par_DWORD(3),
                              hwg_par_int(4), hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1),
                              hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL));
}

/*
   CreateOwnBtn(hParentWIndow, nBtnControlID, x, y, nWidth, nHeight)
*/
HB_FUNC(CREATEOWNBTN)
{
  hwg_ret_HWND(CreateWindowEx(0, TEXT("OWNBTN"), NULL, WS_CHILD | WS_VISIBLE | SS_GRAYRECT | SS_OWNERDRAW,
                              hwg_par_int(3), hwg_par_int(4), hwg_par_int(5), hwg_par_int(6), hwg_par_HWND(1),
                              hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL));
}

/*
   CreateStatic(hParentWyndow, nControlID, nStyle, x, y, nWidth, nHeight)
*/
HB_FUNC(CREATESTATIC)
{
  DWORD ulStyle = hwg_par_DWORD(3);
  DWORD ulExStyle = ((!HB_ISNIL(8)) ? hwg_par_DWORD(8) : 0) | ((ulStyle & WS_BORDER) ? WS_EX_CLIENTEDGE : 0);
  hwg_ret_HWND(CreateWindowEx(ulExStyle, TEXT("STATIC"), NULL, WS_CHILD | WS_VISIBLE | ulStyle, hwg_par_int(4),
                              hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2),
                              GetModuleHandle(NULL), NULL));

  /*
     if (hb_pcount() > 7)
     {
        void * hStr;
        LPCTSTR lpText = HB_PARSTR(8, &hStr, NULL);
        if (lpText)
           SendMessage(hWndEdit, WM_SETTEXT, 0, (LPARAM) lpText);
        hb_strfree(hStr);
     }
   */
}

/*
   CreateButton(hParentWIndow, nButtonID, nStyle, x, y, nWidth, nHeight, cCaption)
*/
HB_FUNC(CREATEBUTTON)
{
  void *hStr;
  hwg_ret_HWND(CreateWindowEx(0, TEXT("BUTTON"), HB_PARSTR(8, &hStr, NULL), WS_CHILD | WS_VISIBLE | hwg_par_DWORD(3),
                              hwg_par_int(4), hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1),
                              hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL));
  hb_strfree(hStr);
}

/*
   CreateCombo(hParentWIndow, nComboID, nStyle, x, y, nWidth, nHeight, cInitialString)
*/
HB_FUNC(CREATECOMBO)
{
  hwg_ret_HWND(CreateWindowEx(0, TEXT("COMBOBOX"), TEXT(""), WS_CHILD | WS_VISIBLE | hwg_par_DWORD(3), hwg_par_int(4),
                              hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2),
                              GetModuleHandle(NULL), NULL));
}

/*
   CreateBrowse(hParentWIndow, nControlID, nStyle, x, y, nWidth, nHeight,
               cTitle)
*/
HB_FUNC(CREATEBROWSE)
{
  DWORD dwStyle = hwg_par_DWORD(3);
  void *hStr;
  hwg_ret_HWND(CreateWindowEx((dwStyle & WS_BORDER) ? WS_EX_CLIENTEDGE : 0, TEXT("BROWSE"), HB_PARSTR(8, &hStr, NULL),
                              WS_CHILD | WS_VISIBLE | dwStyle, hwg_par_int(4), hwg_par_int(5), hwg_par_int(6),
                              hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL));
  hb_strfree(hStr);
}

/* CreateStatusWindow - creates a status window and divides it into
     the specified number of parts.
 Returns the handle to the status window.
 hwndParent - parent window for the status window
 nStatusID - child window identifier
 nParts - number of parts into which to divide the status window
 pArray - Array with Lengths of parts, if first item == 0, status window
          will be divided into equal parts.
*/
HB_FUNC(CREATESTATUSWINDOW)
{
  // Ensure that the common control DLL is loaded.
  InitCommonControls();

  // Create the status window.
  hwg_ret_HWND(CreateWindowEx(0, STATUSCLASSNAME, NULL,
                              SBARS_SIZEGRIP | WS_CHILD | WS_VISIBLE | WS_OVERLAPPED | WS_CLIPSIBLINGS, 0, 0, 0, 0,
                              hwg_par_HWND(1), hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL));
}

HB_FUNC(HWG_INITSTATUS)
{
  HWND hParent = hwg_par_HWND(1);
  HWND hStatus = hwg_par_HWND(2);
  RECT rcClient;
  HLOCAL hloc;
  LPINT lpParts;
  int i, nWidth, j, nParts = hb_parni(3);
  PHB_ITEM pArray = hb_param(4, HB_IT_ARRAY);

  // Allocate an array for holding the right edge coordinates.
  hloc = LocalAlloc(LHND, sizeof(int) * nParts);
  lpParts = (LPINT)LocalLock(hloc);

  if (!pArray || hb_arrayGetNI(pArray, 1) == 0)
  {
    // Get the coordinates of the parent window's client area.
    GetClientRect(hParent, &rcClient);
    // Calculate the right edge coordinate for each part, and
    // copy the coordinates to the array.
    nWidth = rcClient.right / nParts;
    for (i = 0; i < nParts; i++)
    {
      lpParts[i] = nWidth;
      nWidth += nWidth;
    }
  }
  else
  {
    ULONG ul;
    nWidth = 0;
    for (ul = 1; ul <= (ULONG)nParts; ul++)
    {
      j = hb_arrayGetNI(pArray, ul);
      if (ul == (ULONG)nParts && j == 0)
      {
        nWidth = -1;
      }
      else
      {
        nWidth += j;
      }
      lpParts[ul - 1] = nWidth;
    }
  }

  // Tell the status window to create the window parts.
  SendMessage(hStatus, SB_SETPARTS, (WPARAM)nParts, (LPARAM)lpParts);

  // Free the array, and return.
  LocalUnlock(hloc);
  LocalFree(hloc);
}

HB_FUNC(GETNOTIFYSBPARTS)
{
  hb_retnl((LONG)(((NMMOUSE *)HB_PARHANDLE(1))->dwItemSpec));
}

HB_FUNC(HWG_ADDTOOLTIP) // changed by MAG
{
  TOOLINFO ti;
  HWND hWnd = hwg_par_HWND(1);
  DWORD iStyle = TTS_ALWAYSTIP;
  void *hStr;

  if (s_lToolTipBalloon)
  {
    iStyle = iStyle | TTS_BALLOON;
  }

  if (!s_hWndTT)
  {
    s_hWndTT = CreateWindowEx(0, TOOLTIPS_CLASS, NULL, WS_POPUP | TTS_ALWAYSTIP | iStyle, CW_USEDEFAULT, CW_USEDEFAULT,
                            CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, GetModuleHandle(NULL), NULL);
  }
  if (!s_hWndTT)
  {
    hb_retnl(0);
    return;
  }
  ti.uFlags = TTF_SUBCLASS | TTF_IDISHWND;
  ti.hwnd = hWnd;
  ti.uId = (UINT)hb_parnl(2);
  // ti.uId = (UINT)GetDlgItem(hWnd, hb_parni(2));
  ti.hinst = GetModuleHandle(NULL);
  ti.lpszText = (LPTSTR)HB_PARSTR(3, &hStr, NULL);

  hb_retl((BOOL)SendMessage(s_hWndTT, TTM_ADDTOOL, 0, (LPARAM)(LPTOOLINFO)&ti));
  hb_strfree(hStr);
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(ADDTOOLTIP, HWG_ADDTOOLTIP);
#endif

HB_FUNC(HWG_DELTOOLTIP)
{
  TOOLINFO ti;

  if (s_hWndTT)
  {
    ti.cbSize = sizeof(TOOLINFO);
    ti.uFlags = TTF_IDISHWND;
    ti.hwnd = hwg_par_HWND(1);
    ti.uId = (UINT)hb_parnl(2);
    // ti.uId = (UINT)GetDlgItem(hWnd, hb_parni(2));
    ti.hinst = GetModuleHandle(NULL);

    SendMessage(s_hWndTT, TTM_DELTOOL, 0, (LPARAM)(LPTOOLINFO)&ti);
  }
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(DELTOOLTIP, HWG_DELTOOLTIP);
#endif

HB_FUNC(HWG_SETTOOLTIPTITLE)
{
  HWND hWnd = hwg_par_HWND(1);

  if (s_hWndTT)
  {
    TOOLINFO ti;
    void *hStr;

    ti.cbSize = sizeof(TOOLINFO);
    ti.uFlags = TTF_IDISHWND;
    ti.hwnd = hWnd;
    ti.uId = (UINT)hb_parnl(2);
    ti.hinst = GetModuleHandle(NULL);
    ti.lpszText = (LPTSTR)HB_PARSTR(3, &hStr, NULL);

    hb_retl((BOOL)SendMessage(s_hWndTT, TTM_SETTOOLINFO, 0, (LPARAM)(LPTOOLINFO)&ti));
    hb_strfree(hStr);
  }
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(SETTOOLTIPTITLE, HWG_SETTOOLTIPTITLE);
#endif

#if 0
HB_FUNC(HWG_SHOWTOOLTIP)
{
  MSG msg;

  msg.lParam = hb_parnl(3);
  msg.wParam = hb_parnl(2);
  msg.message = WM_MOUSEMOVE;
  msg.hwnd = hwg_par_HWND(1);
  hb_retnl(SendMessage(s_hWndTT, TTM_RELAYEVENT, 0, (LPARAM)(LPMSG)&msg));
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(SHOWTOOLTIP, HWG_SHOWTOOLTIP);
#endif
#endif

HB_FUNC(CREATEUPDOWNCONTROL)
{
  hwg_ret_HWND(CreateUpDownControl(WS_CHILD | WS_BORDER | WS_VISIBLE | hb_parni(3), hb_parni(4), hb_parni(5),
                                   hb_parni(6), hb_parni(7), hwg_par_HWND(1), hb_parni(2), GetModuleHandle(NULL),
                                   hwg_par_HWND(8), hb_parni(9), hb_parni(10), hb_parni(11)));
}

HB_FUNC(SETUPDOWN)
{
  SendMessage(hwg_par_HWND(1), UDM_SETPOS, 0, hb_parnl(2));
}

HB_FUNC(SETRANGEUPDOWN)
{
  SendMessage(hwg_par_HWND(1), UDM_SETRANGE32, hb_parnl(2), hb_parnl(3));
}

HB_FUNC(GETNOTIFYDELTAPOS)
{
  int iItem = hb_parnl(2);
  if (iItem < 2)
  {
    hb_retni((LONG)(((NMUPDOWN *)HB_PARHANDLE(1))->iPos));
  }
  else
  {
    hb_retni((LONG)(((NMUPDOWN *)HB_PARHANDLE(1))->iDelta));
  }
}

HB_FUNC(CREATEDATEPICKER)
{
  hwg_ret_HWND(CreateWindowEx(WS_EX_CLIENTEDGE, TEXT("SYSDATETIMEPICK32"), NULL,
                              WS_CHILD | WS_VISIBLE | WS_TABSTOP | hwg_par_DWORD(7), hwg_par_int(3), hwg_par_int(4),
                              hwg_par_int(5), hwg_par_int(6), hwg_par_HWND(1), hwg_par_HMENU_ID(2),
                              GetModuleHandle(NULL), NULL));
}

HB_FUNC(SETDATEPICKER)
{
  PHB_ITEM pDate = hb_param(2, HB_IT_DATE);
  ULONG ulLen;
  long lSeconds = 0;

  if (pDate)
  {
    SYSTEMTIME sysTime, st;
#ifndef HARBOUR_OLD_VERSION
    int lYear, lMonth, lDay;
    int lHour, lMinute;
#else
    long lYear, lMonth, lDay;
    long lHour, lMinute;
#endif
    int lMilliseconds = 0;
#ifdef __XHARBOUR__
    double lSecond;
#else
    int lSecond;
#endif

    hb_dateDecode(hb_itemGetDL(pDate), &lYear, &lMonth, &lDay);
    if (hb_pcount() < 3)
    {
      GetLocalTime(&st);
      lHour = st.wHour;
      lMinute = st.wMinute;
      lSecond = st.wSecond;
    }
    else
    {
      const char *szTime = hb_parc(3);
      if (szTime)
      {
        ulLen = (ULONG)strlen(szTime);
        if (ulLen >= 4)
        {
          lSeconds = (LONG)hb_strVal(szTime, 2) * 3600 * 1000 + (LONG)hb_strVal(szTime + 2, 2) * 60 * 1000 +
                     (LONG)(hb_strVal(szTime + 4, ulLen - 4) * 1000);
        }
      }
#ifdef __XHARBOUR__
      hb_timeDecode(lSeconds, &lHour, &lMinute, &lSecond);
#else
      hb_timeDecode(lSeconds, &lHour, &lMinute, &lSecond, &lMilliseconds);
#endif
    }

    sysTime.wYear = (WORD)lYear;
    sysTime.wMonth = (WORD)lMonth;
    sysTime.wDay = (WORD)lDay;
    sysTime.wDayOfWeek = 0;
    sysTime.wHour = (WORD)lHour;
    sysTime.wMinute = (WORD)lMinute;
    sysTime.wSecond = (WORD)lSecond;
    sysTime.wMilliseconds = (WORD)lMilliseconds;

    SendMessage(hwg_par_HWND(1), DTM_SETSYSTEMTIME, GDT_VALID, (LPARAM)&sysTime);
  }
}

HB_FUNC(SETDATEPICKERNULL)
{
  SendMessage(hwg_par_HWND(1), DTM_SETSYSTEMTIME, GDT_NONE, 0);
}

HB_FUNC(GETDATEPICKER)
{
  SYSTEMTIME st;

  SendMessage(hwg_par_HWND(1), DTM_GETSYSTEMTIME, 0, (LPARAM)&st);
  hb_retd(st.wYear, st.wMonth, st.wDay);
}

HB_FUNC(GETTIMEPICKER)
{
  SYSTEMTIME st;
  char szTime[9];

  SendMessage(hwg_par_HWND(1), DTM_GETSYSTEMTIME, 0, (LPARAM)&st);

#if __HARBOUR__ - 0 >= 0x010100
  hb_snprintf(szTime, 9, "%02d:%02d:%02d", st.wHour, st.wMinute, st.wSecond);
#else
  snprintf(szTime, 9, "%02d:%02d:%02d", st.wHour, st.wMinute, st.wSecond);
#endif
  hb_retc(szTime);
}

HB_FUNC(CREATETABCONTROL)
{
  hwg_ret_HWND(CreateWindowEx(0, WC_TABCONTROL, NULL, WS_CHILD | WS_VISIBLE | hwg_par_DWORD(3), hwg_par_int(4),
                              hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2),
                              GetModuleHandle(NULL), NULL));
}

HB_FUNC(INITTABCONTROL)
{
  HWND hTab = hwg_par_HWND(1);
  PHB_ITEM pArr = hb_param(2, HB_IT_ARRAY);
  int iItems = hb_parnl(3);
  TC_ITEM tie;
  ULONG ul, ulTabs = (ULONG)hb_arrayLen(pArr);

  tie.mask = TCIF_TEXT | TCIF_IMAGE;
  tie.iImage = iItems == 0 ? -1 : 0;

  for (ul = 1; ul <= ulTabs; ul++)
  {
    void *hStr;

    tie.pszText = (LPTSTR)HB_ARRAYGETSTR(pArr, ul, &hStr, NULL);
    if (tie.pszText == NULL)
    {
      tie.pszText = (LPTSTR)TEXT("");
    }

    if (TabCtrl_InsertItem(hTab, ul - 1, &tie) == -1)
    {
      DestroyWindow(hTab);
      hTab = NULL;
    }
    hb_strfree(hStr);

    if (tie.iImage > -1)
    {
      tie.iImage++;
    }
  }
}

HB_FUNC(ADDTAB)
{
  TC_ITEM tie;
  void *hStr;

  tie.mask = TCIF_TEXT | TCIF_IMAGE;
  tie.iImage = -1;
  tie.pszText = (LPTSTR)HB_PARSTR(3, &hStr, NULL);
  TabCtrl_InsertItem(hwg_par_HWND(1), hb_parni(2), &tie);
  hb_strfree(hStr);
}

HB_FUNC(ADDTABDIALOG)
{
  TC_ITEM tie;
  void *hStr;
  HWND pWnd = hwg_par_HWND(4);

  tie.mask = TCIF_TEXT | TCIF_IMAGE | TCIF_PARAM;
  tie.lParam = (LPARAM)pWnd;
  tie.iImage = -1;
  tie.pszText = (LPTSTR)HB_PARSTR(3, &hStr, NULL);
  TabCtrl_InsertItem(hwg_par_HWND(1), hb_parni(2), &tie);
  hb_strfree(hStr);
}

HB_FUNC(DELETETAB)
{
  TabCtrl_DeleteItem(hwg_par_HWND(1), hb_parni(2));
}

HB_FUNC(GETCURRENTTAB)
{
  hb_retni(TabCtrl_GetCurSel(hwg_par_HWND(1)) + 1);
}

HB_FUNC(SETTABSIZE)
{
  SendMessage(hwg_par_HWND(1), TCM_SETITEMSIZE, 0, MAKELPARAM(hb_parni(2), hb_parni(3)));
}

HB_FUNC(SETTABNAME)
{
  TC_ITEM tie;
  void *hStr;

  tie.mask = TCIF_TEXT;
  tie.pszText = (LPTSTR)HB_PARSTR(3, &hStr, NULL);

  TabCtrl_SetItem(hwg_par_HWND(1), hb_parni(2), &tie);
  hb_strfree(hStr);
}

HB_FUNC(TAB_HITTEST)
{
  TC_HITTESTINFO ht;
  HWND hTab = hwg_par_HWND(1);
  int res;

  if (hb_pcount() > 1 && HB_ISNUM(2) && HB_ISNUM(3))
  {
    ht.pt.x = hb_parni(2);
    ht.pt.y = hb_parni(3);
  }
  else
  {
    GetCursorPos(&(ht.pt));
    ScreenToClient(hTab, &(ht.pt));
  }

  res = (int)SendMessage(hTab, TCM_HITTEST, 0, (LPARAM)&ht);

  hb_storni(ht.flags, 4);
  hb_retni(res);
}

HB_FUNC(GETNOTIFYKEYDOWN)
{
  hb_retni((WORD)(((TC_KEYDOWN *)HB_PARHANDLE(1))->wVKey));
}

HB_FUNC(CREATETREE)
{
  HWND hCtrl = CreateWindowEx(WS_EX_CLIENTEDGE, WC_TREEVIEW, 0, WS_CHILD | WS_VISIBLE | WS_TABSTOP | hwg_par_DWORD(3),
                              hwg_par_int(4), hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1),
                              hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL);

  if (!HB_ISNIL(8))
  {
    SendMessage(hCtrl, TVM_SETTEXTCOLOR, 0, hwg_par_LPARAM(8));
  }
  if (!HB_ISNIL(9))
  {
    SendMessage(hCtrl, TVM_SETBKCOLOR, 0, hwg_par_LPARAM(9));
  }

  hwg_ret_HWND(hCtrl);
}

HB_FUNC(TREEADDNODE)
{
  TV_ITEM tvi;
  TV_INSERTSTRUCT is;

  int nPos = hb_parni(5);
  PHB_ITEM pObject = hb_param(1, HB_IT_OBJECT);
  void *hStr;

  tvi.iImage = 0;
  tvi.iSelectedImage = 0;

  tvi.mask = TVIF_TEXT | TVIF_PARAM;
  tvi.pszText = (LPTSTR)HB_PARSTR(6, &hStr, NULL);
  tvi.lParam = (LPARAM)(hb_itemNew(pObject));
  if (hb_pcount() > 6 && !HB_ISNIL(7))
  {
    tvi.iImage = hb_parni(7);
    tvi.mask |= TVIF_IMAGE;
    if (hb_pcount() > 7 && !HB_ISNIL(8))
    {
      tvi.iSelectedImage = hb_parni(8);
      tvi.mask |= TVIF_SELECTEDIMAGE;
    }
  }

#if !defined(__BORLANDC__) || (__BORLANDC__ > 1424)
  is.item = tvi;
#else
  is.DUMMYUNIONNAME.item = tvi;
#endif

  is.hParent = (HB_ISNIL(3) ? NULL : (HTREEITEM)HB_PARHANDLE(3));
  if (nPos == 0)
  {
    is.hInsertAfter = (HTREEITEM)HB_PARHANDLE(4);
  }
  else if (nPos == 1)
  {
    is.hInsertAfter = TVI_FIRST;
  }
  else if (nPos == 2)
  {
    is.hInsertAfter = TVI_LAST;
  }

  HB_RETHANDLE(SendMessage(hwg_par_HWND(2), TVM_INSERTITEM, 0, (LPARAM)(&is)));

  if (tvi.mask & TVIF_IMAGE)
  {
    if (tvi.iImage)
    {
      DeleteObject((HGDIOBJ)(INT_PTR)tvi.iImage);
    }
  }
  if (tvi.mask & TVIF_SELECTEDIMAGE)
  {
    if (tvi.iSelectedImage)
    {
      DeleteObject((HGDIOBJ)(INT_PTR)tvi.iSelectedImage);
    }
  }

  hb_strfree(hStr);
}

/*
HB_FUNC(TREEDELNODE)
{

   hb_parl(TreeView_DeleteItem(hwg_par_HWND(1), (HTREEITEM)HB_PARHANDLE(2)));
}

HB_FUNC(TREEDELALLNODES)
{

   TreeView_DeleteAllItems(hwg_par_HWND(1));
}
*/

HB_FUNC(TREEGETSELECTED)
{
  TV_ITEM TreeItem;

  memset(&TreeItem, 0, sizeof(TV_ITEM));
  TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
  TreeItem.hItem = TreeView_GetSelection(hwg_par_HWND(1));

  if (TreeItem.hItem)
  {
    PHB_ITEM oNode; // = hb_itemNew(NULL);
    SendMessage(hwg_par_HWND(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem));
    oNode = (PHB_ITEM)TreeItem.lParam;
    hb_itemReturn(oNode);
  }
}

/*
HB_FUNC(TREENODEHASCHILDREN)
{

   TV_ITEM TreeItem;

   memset(&TreeItem, 0, sizeof(TV_ITEM));
   TreeItem.mask = TVIF_HANDLE | TVIF_CHILDREN;
   TreeItem.hItem = (HTREEITEM) HB_PARHANDLE(2);

   SendMessage(hwg_par_HWND(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem));
   hb_retni(TreeItem.cChildren);
}

*/

HB_FUNC(TREEGETNODETEXT)
{
  TV_ITEM TreeItem;
  TCHAR ItemText[256] = {0};

  memset(&TreeItem, 0, sizeof(TV_ITEM));
  TreeItem.mask = TVIF_HANDLE | TVIF_TEXT;
  TreeItem.hItem = (HTREEITEM)HB_PARHANDLE(2);
  TreeItem.pszText = ItemText;
  TreeItem.cchTextMax = 256;

  SendMessage(hwg_par_HWND(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem));
  HB_RETSTR(TreeItem.pszText);
}

#define TREE_SETITEM_TEXT 1
#define TREE_SETITEM_CHECK 2

HB_FUNC(TREESETITEM)
{
  TV_ITEM TreeItem;
  int iType = hb_parni(3);
  void *hStr = NULL;

  memset(&TreeItem, 0, sizeof(TV_ITEM));
  TreeItem.mask = TVIF_HANDLE;
  TreeItem.hItem = (HTREEITEM)HB_PARHANDLE(2);

  if (iType == TREE_SETITEM_TEXT)
  {
    TreeItem.mask |= TVIF_TEXT;
    TreeItem.pszText = (LPTSTR)HB_PARSTR(4, &hStr, NULL);
  }
  if (iType == TREE_SETITEM_CHECK)
  {
    TreeItem.mask |= TVIF_STATE;
    TreeItem.stateMask = TVIS_STATEIMAGEMASK;
    TreeItem.state = hb_parni(4);
    TreeItem.state = TreeItem.state << 12;
  }

  SendMessage(hwg_par_HWND(1), TVM_SETITEM, 0, (LPARAM)(&TreeItem));
  hb_strfree(hStr);
}

#define TREE_GETNOTIFY_HANDLE 1
#define TREE_GETNOTIFY_PARAM 2
#define TREE_GETNOTIFY_EDIT 3
#define TREE_GETNOTIFY_EDITPARAM 4
#define TREE_GETNOTIFY_ACTION 5
#define TREE_GETNOTIFY_OLDPARAM 6

HB_FUNC(TREE_GETNOTIFY)
{
  int iType = hb_parni(2);

  if (iType == TREE_GETNOTIFY_HANDLE)
  {
    hb_retnint((LONG_PTR)(((NM_TREEVIEW *)HB_PARHANDLE(1))->itemNew.hItem)); // TODO: retorno é HTREEITEM
  }

  if (iType == TREE_GETNOTIFY_ACTION)
  {
    hb_retnl((LONG)(((NM_TREEVIEW *)HB_PARHANDLE(1))->action));
  }
  else if (iType == TREE_GETNOTIFY_PARAM || iType == TREE_GETNOTIFY_EDITPARAM || iType == TREE_GETNOTIFY_OLDPARAM)
  {
    PHB_ITEM oNode; // = hb_itemNew(NULL);
    if (iType == TREE_GETNOTIFY_EDITPARAM)
    {
      oNode = (PHB_ITEM)(((TV_DISPINFO *)HB_PARHANDLE(1))->item.lParam);
    }
    else if (iType == TREE_GETNOTIFY_OLDPARAM)
    {
      oNode = (PHB_ITEM)(((NM_TREEVIEW *)HB_PARHANDLE(1))->itemOld.lParam);
    }
    else
    {
      oNode = (PHB_ITEM)(((NM_TREEVIEW *)HB_PARHANDLE(1))->itemNew.lParam);
    }

    hb_itemReturn(oNode);
  }
  else if (iType == TREE_GETNOTIFY_EDIT)
  {
    TV_DISPINFO *tv;
    tv = (TV_DISPINFO *)HB_PARHANDLE(1);

    HB_RETSTR((tv->item.pszText) ? tv->item.pszText : TEXT(""));
  }
}

/*
 * Tree_Hittest(hTree, x, y) --> oNode
 */
HB_FUNC(TREE_HITTEST)
{
  TV_HITTESTINFO ht;
  HWND hTree = hwg_par_HWND(1);

  if (hb_pcount() > 1 && HB_ISNUM(2) && HB_ISNUM(3))
  {
    ht.pt.x = hb_parni(2);
    ht.pt.y = hb_parni(3);
  }
  else
  {
    GetCursorPos(&(ht.pt));
    ScreenToClient(hTree, &(ht.pt));
  }

  SendMessage(hTree, TVM_HITTEST, 0, (LPARAM)&ht);

  if (ht.hItem)
  {
    PHB_ITEM oNode; // = hb_itemNew(NULL);
    TV_ITEM TreeItem;

    memset(&TreeItem, 0, sizeof(TV_ITEM));
    TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
    TreeItem.hItem = ht.hItem;

    SendMessage(hTree, TVM_GETITEM, 0, (LPARAM)(&TreeItem));
    oNode = (PHB_ITEM)TreeItem.lParam;
    hb_itemReturn(oNode);
    if (hb_pcount() > 3)
    {
      hb_storni((int)ht.flags, 4);
    }
  }
  else
  {
    hb_ret();
  }
}

HB_FUNC(TREE_RELEASENODE)
{
  TV_ITEM TreeItem;

  memset(&TreeItem, 0, sizeof(TV_ITEM));
  TreeItem.mask = TVIF_HANDLE | TVIF_PARAM;
  TreeItem.hItem = (HTREEITEM)HB_PARHANDLE(2);

  if (TreeItem.hItem)
  {
    SendMessage(hwg_par_HWND(1), TVM_GETITEM, 0, (LPARAM)(&TreeItem));
    hb_itemRelease((PHB_ITEM)TreeItem.lParam);
    TreeItem.lParam = 0;
    SendMessage(hwg_par_HWND(1), TVM_SETITEM, 0, (LPARAM)(&TreeItem));
  }
}

/*
 * CreateImagelist(array, cx, cy, nGrow, flags)
 */
HB_FUNC(CREATEIMAGELIST)
{
  PHB_ITEM pArray = hb_param(1, HB_IT_ARRAY);
  UINT flags = (HB_ISNIL(5)) ? ILC_COLOR : hb_parni(5);
  HIMAGELIST himl;
  ULONG ul, ulLen = (ULONG)hb_arrayLen(pArray);
  HBITMAP hbmp;

  himl = ImageList_Create(hb_parni(2), hb_parni(3), flags, ulLen, hb_parni(4));

  for (ul = 1; ul <= ulLen; ul++)
  {
    hbmp = (HBITMAP)HB_GETPTRHANDLE(pArray, ul);
    ImageList_Add(himl, hbmp, NULL);
    DeleteObject(hbmp);
  }

  HB_RETHANDLE(himl);
}

HB_FUNC(IMAGELIST_ADD)
{
  hb_retnl(ImageList_Add(hwg_par_HIMAGELIST(1), hwg_par_HBITMAP(2), NULL));
}

HB_FUNC(IMAGELIST_ADDMASKED)
{
  hb_retnl(ImageList_AddMasked(hwg_par_HIMAGELIST(1), hwg_par_HBITMAP(2), hwg_par_COLORREF(3)));
}

/*
 *  SetTimer(hWnd, idTimer, i_MilliSeconds)
 */

/* 22/09/2005 - <maurilio.longo@libero.it>
      If I pass a fourth parameter as 0 (zero) I don't set
      the TimerProc, this way I can receive WM_TIMER messages
      inside an ON OTHER MESSAGES code block
*/
HB_FUNC(SETTIMER)
{
  SetTimer(hwg_par_HWND(1), (UINT)hb_parni(2), hwg_par_UINT(3), hb_pcount() == 3 ? (TIMERPROC)s_timerProc : NULL);
}

/*
 *  KillTimer(hWnd, idTimer)
 */

HB_FUNC(KILLTIMER)
{
  hwg_ret_BOOL(KillTimer(hwg_par_HWND(1), (UINT)hb_parni(2)));
}

HB_FUNC(HWG_GETPARENT)
{
  hwg_ret_HWND(GetParent(hwg_par_HWND(1)));
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(GETPARENT, HWG_GETPARENT);
#endif

HB_FUNC(HWG_GETANCESTOR)
{
  hwg_ret_HWND(GetAncestor(hwg_par_HWND(1), hb_parni(2)));
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(GETANCESTOR, HWG_GETANCESTOR);
#endif

HB_FUNC(HWG_LOADCURSOR)
{
  void *hStr;
  LPCTSTR lpStr = HB_PARSTR(1, &hStr, NULL);

  if (lpStr)
  {
    hwg_ret_HCURSOR(LoadCursor(GetModuleHandle(NULL), lpStr));
  }
  else
  {
    hwg_ret_HCURSOR(LoadCursor(NULL, MAKEINTRESOURCE(hb_parni(1))));
  }
  hb_strfree(hStr);
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(LOADCURSOR, HWG_LOADCURSOR);
#endif

HB_FUNC(HWG_SETCURSOR)
{
  hwg_ret_HCURSOR(SetCursor(hwg_par_HCURSOR(1)));
}

HB_FUNC(HWG_GETCURSOR)
{
  hwg_ret_HCURSOR(GetCursor());
}

HB_FUNC(HWG_GETTOOLTIPHANDLE) // added by MAG
{
  hwg_ret_HWND(s_hWndTT);
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(GETTOOLTIPHANDLE, HWG_GETTOOLTIPHANDLE);
#endif

HB_FUNC(HWG_SETTOOLTIPBALLOON) // added by MAG
{
  s_lToolTipBalloon = hb_parl(1);
  s_hWndTT = 0;
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(SETTOOLTIPBALLOON, HWG_SETTOOLTIPBALLOON);
#endif

HB_FUNC(HWG_GETTOOLTIPBALLOON) // added by MAG
{
  hb_retl(s_lToolTipBalloon);
}

#ifdef HWGUI_FUNC_TRANSLATE_ON
HB_FUNC_TRANSLATE(GETTOOLTIPBALLOON, HWG_GETTOOLTIPBALLOON);
#endif

HB_FUNC(HWG_REGPANEL)
{
  static BOOL bRegistered = FALSE;

  if (!bRegistered)
  {
    WNDCLASS wndclass;

    wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
    wndclass.lpfnWndProc = DefWindowProc;
    wndclass.cbClsExtra = 0;
    wndclass.cbWndExtra = 0;
    wndclass.hInstance = GetModuleHandle(NULL);
    wndclass.hIcon = NULL;
    wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH)(COLOR_3DFACE + 1);
    wndclass.lpszMenuName = NULL;
    wndclass.lpszClassName = TEXT("PANEL");

    RegisterClass(&wndclass);
    bRegistered = TRUE;
  }
}

HB_FUNC(HWG_REGOWNBTN)
{
  static BOOL bRegistered = FALSE;

  WNDCLASS wndclass;

  if (!bRegistered)
  {
    wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
    wndclass.lpfnWndProc = WinCtrlProc;
    wndclass.cbClsExtra = 0;
    wndclass.cbWndExtra = 0;
    wndclass.hInstance = GetModuleHandle(NULL);
    wndclass.hIcon = NULL;
    wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH)(COLOR_3DFACE + 1);
    wndclass.lpszMenuName = NULL;
    wndclass.lpszClassName = TEXT("OWNBTN");

    RegisterClass(&wndclass);
    bRegistered = TRUE;
  }
}

HB_FUNC(HWG_REGBROWSE)
{

  static BOOL bRegistered = FALSE;

  if (!bRegistered)
  {
    WNDCLASS wndclass;

    wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
    wndclass.lpfnWndProc = WinCtrlProc;
    wndclass.cbClsExtra = 0;
    wndclass.cbWndExtra = 0;
    wndclass.hInstance = GetModuleHandle(NULL);
    // wndclass.hIcon         = LoadIcon (NULL, IDI_APPLICATION) ;
    wndclass.hIcon = NULL;
    wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wndclass.lpszMenuName = NULL;
    wndclass.lpszClassName = TEXT("BROWSE");

    RegisterClass(&wndclass);
    bRegistered = TRUE;
  }
}

static void CALLBACK s_timerProc(HWND hWnd, UINT message, UINT idTimer, DWORD dwTime)
{
  static PHB_DYNS s_pSymTest = NULL;

  HB_SYMBOL_UNUSED(message);

  if (s_pSymTest == NULL)
  {
    s_pSymTest = hb_dynsymGetCase("TIMERPROC");
  }

  if (hb_dynsymIsFunction(s_pSymTest))
  {
    hb_vmPushDynSym(s_pSymTest);
    hb_vmPushNil(); /* places NIL at self */
                    //      hb_vmPushLong((LONG)hWnd);    /* pushes parameters on to the hvm stack */
    HB_PUSHITEM(hWnd);
    hb_vmPushLong((LONG)idTimer);
    hb_vmPushLong((LONG)dwTime);
    hb_vmDo(3); /* where iArgCount is the number of pushed parameters */
  }
}

BOOL RegisterWinCtrl(void) // Added by jamaj - Used by WinCtrl
{
  WNDCLASS wndclass;

  wndclass.style = CS_OWNDC | CS_VREDRAW | CS_HREDRAW | CS_DBLCLKS;
  wndclass.lpfnWndProc = WinCtrlProc;
  wndclass.cbClsExtra = 0;
  wndclass.cbWndExtra = 0;
  wndclass.hInstance = GetModuleHandle(NULL);
  wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
  wndclass.hbrBackground = (HBRUSH)(COLOR_3DFACE + 1);
  wndclass.lpszMenuName = NULL;
  wndclass.lpszClassName = TEXT("WINCTRL");

  return RegisterClass(&wndclass);
}

HB_FUNC(HWG_INITTREEVIEW)
{
  s_wpOrigTreeViewProc = (WNDPROC)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)TreeViewSubclassProc);
}

LRESULT APIENTRY TreeViewSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? CallWindowProc(s_wpOrigTreeViewProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc(s_wpOrigTreeViewProc, hWnd, uMsg, wParam, lParam);
  }
}

HB_FUNC(HWG_INITWINCTRL)
{
  SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)WinCtrlProc);
}

LRESULT CALLBACK WinCtrlProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? DefWindowProc(hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return DefWindowProc(hWnd, uMsg, wParam, lParam);
  }
}

HB_FUNC(HWG_INITSTATICPROC)
{
  s_wpOrigStaticProc = (WNDPROC)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)StaticSubclassProc);
}

LRESULT APIENTRY StaticSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? CallWindowProc(s_wpOrigStaticProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc(s_wpOrigStaticProc, hWnd, uMsg, wParam, lParam);
  }
}

HB_FUNC(HWG_INITBUTTONPROC)
{
  //   s_wpOrigButtonProc = (WNDPROC)SetWindowLong(hwg_par_HWND(1), GWLP_WNDPROC, (LONG)ButtonSubclassProc);
  s_wpOrigButtonProc = (LONG_PTR)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)ButtonSubclassProc);
}

LRESULT APIENTRY ButtonSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? CallWindowProc((WNDPROC)s_wpOrigButtonProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc((WNDPROC)s_wpOrigButtonProc, hWnd, uMsg, wParam, lParam);
  }
}

LRESULT APIENTRY ComboSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? CallWindowProc(s_wpOrigComboProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc(s_wpOrigComboProc, hWnd, uMsg, wParam, lParam);
  }
}

HB_FUNC(HWG_INITCOMBOPROC)
{
  s_wpOrigComboProc = (WNDPROC)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)ComboSubclassProc);
}

LRESULT APIENTRY ListSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? CallWindowProc(s_wpOrigListProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc(s_wpOrigListProc, hWnd, uMsg, wParam, lParam);
  }
}

HB_FUNC(HWG_INITLISTPROC)
{
  s_wpOrigListProc = (WNDPROC)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)ListSubclassProc);
}

HB_FUNC(HWG_INITUPDOWNPROC)
{
  s_wpOrigUpDownProc = (WNDPROC)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)UpDownSubclassProc);
}

LRESULT APIENTRY UpDownSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? CallWindowProc(s_wpOrigUpDownProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc(s_wpOrigUpDownProc, hWnd, uMsg, wParam, lParam);
  }
}

HB_FUNC(HWG_INITDATEPICKERPROC)
{
  s_wpOrigDatePickerProc = (WNDPROC)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)DatePickerSubclassProc);
}

LRESULT APIENTRY DatePickerSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? CallWindowProc(s_wpOrigDatePickerProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc(s_wpOrigDatePickerProc, hWnd, uMsg, wParam, lParam);
  }
}

HB_FUNC(HWG_INITTRACKPROC)
{
  s_wpOrigTrackProc = (WNDPROC)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)TrackSubclassProc);
}

LRESULT APIENTRY TrackSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? CallWindowProc(s_wpOrigTrackProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc(s_wpOrigTrackProc, hWnd, uMsg, wParam, lParam);
  }
}

HB_FUNC(HWG_INITTABPROC)
{
  s_wpOrigTabProc = (WNDPROC)SetWindowLongPtr(hwg_par_HWND(1), GWLP_WNDPROC, (LONG_PTR)TabSubclassProc);
}

LRESULT APIENTRY TabSubclassProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
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
    return (res == -1) ? CallWindowProc(s_wpOrigTabProc, hWnd, uMsg, wParam, lParam) : res;
  }
  else
  {
    return CallWindowProc(s_wpOrigTabProc, hWnd, uMsg, wParam, lParam);
  }
}

#if (defined(__MINGW32__) || defined(__MINGW64__)) && !defined(LPNMTBGETINFOTIP)
typedef struct tagNMTBGETINFOTIPA
{
  NMHDR hdr;
  LPSTR pszText;
  int cchTextMax;
  int iItem;
  LPARAM lParam;
} NMTBGETINFOTIPA, *LPNMTBGETINFOTIPA;

typedef struct tagNMTBGETINFOTIPW
{
  NMHDR hdr;
  LPWSTR pszText;
  int cchTextMax;
  int iItem;
  LPARAM lParam;
} NMTBGETINFOTIPW, *LPNMTBGETINFOTIPW;

#ifdef UNICODE
#define LPNMTBGETINFOTIP LPNMTBGETINFOTIPW
#else
#define LPNMTBGETINFOTIP LPNMTBGETINFOTIPA
#endif

#endif

HB_FUNC(CREATETOOLBAR)
{
  DWORD ulStyle = hwg_par_DWORD(3);
  DWORD ulExStyle = ((!HB_ISNIL(8)) ? hwg_par_DWORD(8) : 0) | ((ulStyle & WS_BORDER) ? WS_EX_CLIENTEDGE : 0);
  hwg_ret_HWND(CreateWindowEx(ulExStyle, TOOLBARCLASSNAME, NULL,
                              WS_CHILD | WS_OVERLAPPED | WS_VISIBLE | TBSTYLE_ALTDRAG | TBSTYLE_TOOLTIPS |
                                  TBSTYLE_WRAPABLE | CCS_TOP | CCS_NORESIZE | ulStyle,
                              hwg_par_int(4), hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1),
                              hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL));
}

HB_FUNC(TOOLBARADDBUTTONS)
{
  HWND hWndCtrl = hwg_par_HWND(1);
  /* HWND hToolTip = hwg_par_HWND(4); */
  PHB_ITEM pArray = hb_param(2, HB_IT_ARRAY);
  int iButtons = hb_parni(3);
  TBBUTTON *tb = (struct _TBBUTTON *)hb_xgrab(iButtons * sizeof(TBBUTTON));
  PHB_ITEM pTemp;

  ULONG ulCount;
  ULONG ulID;
  DWORD style = GetWindowLong(hWndCtrl, GWL_STYLE);

  // SendMessage(hWndCtrl, CCM_SETVERSION, (WPARAM) 4, 0);

  SetWindowLong(hWndCtrl, GWL_STYLE, style | TBSTYLE_TOOLTIPS | TBSTYLE_FLAT);

  SendMessage(hWndCtrl, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0L);

  for (ulCount = 0; (ulCount < hb_arrayLen(pArray)); ulCount++)
  {
    pTemp = hb_arrayGetItemPtr(pArray, ulCount + 1);
    ulID = hb_arrayGetNI(pTemp, 1);
    if (hb_arrayGetNI(pTemp, 4) == TBSTYLE_SEP)
    {
      tb[ulCount].iBitmap = 8;
    }
    else
    {
      tb[ulCount].iBitmap = ulID - 1; // ulID > 0 ? (int)ulCount : -1;
    }
    tb[ulCount].idCommand = hb_arrayGetNI(pTemp, 2);
    tb[ulCount].fsState = (BYTE)hb_arrayGetNI(pTemp, 3);
    tb[ulCount].fsStyle = (BYTE)hb_arrayGetNI(pTemp, 4);
    tb[ulCount].dwData = hb_arrayGetNI(pTemp, 5);
    tb[ulCount].iString = hb_arrayGetCLen(pTemp, 6) > 0 ? (INT_PTR)hb_arrayGetCPtr(pTemp, 6) : 0;
  }

  SendMessage(hWndCtrl, TB_ADDBUTTONS, (WPARAM)iButtons, (LPARAM)(LPTBBUTTON)tb);
  SendMessage(hWndCtrl, TB_AUTOSIZE, 0, 0);

  hb_xfree(tb);
}

HB_FUNC(TOOLBAR_SETBUTTONINFO)
{
  TBBUTTONINFO tb;
  HWND hWndCtrl = hwg_par_HWND(1);
  int iIDB = hb_parni(2);
  void *hStr;

  tb.cbSize = sizeof(tb);
  tb.dwMask = TBIF_TEXT;
  tb.pszText = (LPTSTR)HB_PARSTR(3, &hStr, NULL);
  // tb.cchText = 1000  ;

  SendMessage(hWndCtrl, TB_SETBUTTONINFO, iIDB, (LPARAM)&tb);
}

HB_FUNC(TOOLBAR_LOADIMAGE)
{
  TBADDBITMAP tbab;
  HWND hWndCtrl = hwg_par_HWND(1);
  int iIDB = hb_parni(2);

  tbab.hInst = NULL;
  tbab.nID = iIDB;

  SendMessage(hWndCtrl, TB_ADDBITMAP, 0, (LPARAM)&tbab);
}

HB_FUNC(TOOLBAR_LOADSTANDARTIMAGE)
{
  TBADDBITMAP tbab;
  HWND hWndCtrl = hwg_par_HWND(1);
  int iIDB = hb_parni(2);
  HIMAGELIST himl;

  tbab.hInst = HINST_COMMCTRL;
  tbab.nID = iIDB; // IDB_HIST_SMALL_COLOR / IDB_VIEW_SMALL_COLOR / IDB_VIEW_SMALL_COLOR;

  SendMessage(hWndCtrl, TB_ADDBITMAP, 0, (LPARAM)&tbab);
  himl = (HIMAGELIST)SendMessage(hWndCtrl, TB_GETIMAGELIST, 0, 0);
  hb_retni((int)ImageList_GetImageCount(himl));
}

HB_FUNC(ImageList_GetImageCount)
{
  HIMAGELIST hWndCtrl = hwg_par_HIMAGELIST(1);
  hb_retni(ImageList_GetImageCount(hWndCtrl));
}

HB_FUNC(TOOLBAR_SETDISPINFO)
{
  // LPTOOLTIPTEXT pDispInfo = (LPTOOLTIPTEXT)HB_PARHANDLE(1);
  LPNMTTDISPINFO pDispInfo = (LPNMTTDISPINFO)HB_PARHANDLE(1);

  if (pDispInfo)
  {
    HB_ITEMCOPYSTR(hb_param(2, HB_IT_ANY), pDispInfo->szText, HB_SIZEOFARRAY(pDispInfo->szText));
    pDispInfo->szText[HB_SIZEOFARRAY(pDispInfo->szText) - 1] = 0;
#if 0
      /* is it necessary? */
      if (!pDispInfo->hinst)
         pDispInfo->lpszText = pDispInfo->szText;
#endif
  }
}

HB_FUNC(TOOLBAR_GETDISPINFOID)
{
  // LPTOOLTIPTEXT pDispInfo = (LPTOOLTIPTEXT)hb_parnl(1);
  LPNMTTDISPINFO pDispInfo = (LPNMTTDISPINFO)HB_PARHANDLE(1);
  DWORD idButton = (DWORD)pDispInfo->hdr.idFrom;
  hb_retnl(idButton);
}

HB_FUNC(TOOLBAR_GETINFOTIP)
{
  LPNMTBGETINFOTIP pDispInfo = (LPNMTBGETINFOTIP)HB_PARHANDLE(1);
  if (pDispInfo && pDispInfo->cchTextMax > 0)
  {
    HB_ITEMCOPYSTR(hb_param(2, HB_IT_ANY), pDispInfo->pszText, pDispInfo->cchTextMax);
    pDispInfo->pszText[pDispInfo->cchTextMax - 1] = 0;
  }
}

HB_FUNC(TOOLBAR_GETINFOTIPID)
{
  LPNMTBGETINFOTIP pDispInfo = (LPNMTBGETINFOTIP)HB_PARHANDLE(1);
  DWORD idButton = pDispInfo->iItem;
  hb_retnl(idButton);
}

HB_FUNC(TOOLBAR_IDCLICK)
{
  LPNMMOUSE pDispInfo = (LPNMMOUSE)HB_PARHANDLE(1);
  DWORD idButton = (DWORD)pDispInfo->dwItemSpec;
  hb_retnl(idButton);
}

HB_FUNC(TOOLBAR_SUBMENU)
{
  LPNMTOOLBAR lpnmTB = (LPNMTOOLBAR)HB_PARHANDLE(1);
  RECT rc = {0, 0, 0, 0};
  TPMPARAMS tpm;
  HMENU hPopupMenu;
  HMENU hMenuLoaded;
  HWND g_hwndMain = hwg_par_HWND(3);
  HANDLE g_hinst = GetModuleHandle(0);

  SendMessage(lpnmTB->hdr.hwndFrom, TB_GETRECT, (WPARAM)lpnmTB->iItem, (LPARAM)&rc);

  MapWindowPoints(lpnmTB->hdr.hwndFrom, HWND_DESKTOP, (LPPOINT)(void *)&rc, 2);

  tpm.cbSize = sizeof(TPMPARAMS);
  // tpm.rcExclude = rc;
  tpm.rcExclude.left = rc.left;
  tpm.rcExclude.top = rc.top;
  tpm.rcExclude.bottom = rc.bottom;
  tpm.rcExclude.right = rc.right;
  hMenuLoaded = LoadMenu((HINSTANCE)g_hinst, MAKEINTRESOURCE(hb_parni(2)));
  hPopupMenu = GetSubMenu(LoadMenu((HINSTANCE)g_hinst, MAKEINTRESOURCE(hb_parni(2))), 0);

  TrackPopupMenuEx(hPopupMenu, TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_VERTICAL, rc.left, rc.bottom, g_hwndMain, &tpm);
  // rc.left, rc.bottom, g_hwndMain, &tpm);

  DestroyMenu(hMenuLoaded);
}

HB_FUNC(TOOLBAR_SUBMENUEX)
{
  LPNMTOOLBAR lpnmTB = (LPNMTOOLBAR)HB_PARHANDLE(1);
  RECT rc = {0, 0, 0, 0};
  TPMPARAMS tpm;
  HMENU hPopupMenu = hwg_par_HMENU(2);
  HWND g_hwndMain = hwg_par_HWND(3);

  SendMessage(lpnmTB->hdr.hwndFrom, TB_GETRECT, (WPARAM)lpnmTB->iItem, (LPARAM)&rc);

  MapWindowPoints(lpnmTB->hdr.hwndFrom, HWND_DESKTOP, (LPPOINT)(void *)&rc, 2);

  tpm.cbSize = sizeof(TPMPARAMS);
  // tpm.rcExclude = rc;
  tpm.rcExclude.left = rc.left;
  tpm.rcExclude.top = rc.top;
  tpm.rcExclude.bottom = rc.bottom;
  tpm.rcExclude.right = rc.right;
  TrackPopupMenuEx(hPopupMenu, TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_VERTICAL, rc.left, rc.bottom, g_hwndMain, &tpm);
  // rc.left, rc.bottom, g_hwndMain, &tpm);
}

HB_FUNC(TOOLBAR_SUBMENUEXGETID)
{

  LPNMTOOLBAR lpnmTB = (LPNMTOOLBAR)HB_PARHANDLE(1);
  hb_retnl((LONG)lpnmTB->iItem);
}

HB_FUNC(CREATEPAGER)
{
  BOOL bVert = hb_parl(8);
  hwg_ret_HWND(CreateWindowEx(0, WC_PAGESCROLLER, NULL,
                              WS_CHILD | WS_VISIBLE | bVert ? PGS_VERT : PGS_HORZ | hwg_par_DWORD(3), hwg_par_int(4),
                              hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2),
                              GetModuleHandle(NULL), NULL));
}

HB_FUNC(CREATEREBAR)
{
  DWORD ulStyle = hwg_par_DWORD(3);
  DWORD ulExStyle =
      ((!HB_ISNIL(8)) ? hwg_par_DWORD(8) : 0) | ((ulStyle & WS_BORDER) ? WS_EX_CLIENTEDGE : 0) | WS_EX_TOOLWINDOW;
  hwg_ret_HWND(CreateWindowEx(ulExStyle, REBARCLASSNAME, NULL,
                              WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | RBS_VARHEIGHT |
                                  CCS_NODIVIDER | ulStyle,
                              hwg_par_int(4), hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), hwg_par_HWND(1),
                              hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL));
}

HB_FUNC(REBARSETIMAGELIST)
{
  HWND hWnd = hwg_par_HWND(1);
  HIMAGELIST p = (HB_ISNUM(2) || HB_ISPOINTER(2)) ? hwg_par_HIMAGELIST(2) : NULL;
  REBARINFO rbi;

  memset(&rbi, '\0', sizeof(rbi));
  rbi.cbSize = sizeof(REBARINFO);
  rbi.fMask = (HB_ISNUM(2) || HB_ISPOINTER(2)) ? RBIM_IMAGELIST : 0;
  rbi.himl = (HB_ISNUM(2) || HB_ISPOINTER(2)) ? (HIMAGELIST)p : NULL;
  SendMessage(hWnd, RB_SETBARINFO, 0, (LPARAM)&rbi);
}

static BOOL _AddBar(HWND pParent, HWND pBar, REBARBANDINFO *pRBBI)
{
  SIZE size;
  RECT rect;
  BOOL bResult;

  pRBBI->cbSize = sizeof(REBARBANDINFO);
  pRBBI->fMask |= RBBIM_CHILD | RBBIM_CHILDSIZE;
  pRBBI->hwndChild = pBar;

  GetWindowRect(pBar, &rect);

  size.cx = rect.right - rect.left;
  size.cy = rect.bottom - rect.top;

  pRBBI->cxMinChild = size.cx;
  pRBBI->cyMinChild = size.cy;
  bResult = (BOOL)SendMessage(pParent, RB_INSERTBAND, (WPARAM)-1, (LPARAM)pRBBI);

  return bResult;
}

static BOOL AddBar(HWND pParent, HWND pBar, LPCTSTR pszText, HBITMAP pbmp, DWORD dwStyle)
{
  REBARBANDINFO rbBand;

  memset(&rbBand, '\0', sizeof(rbBand));

  rbBand.fMask = RBBIM_STYLE;
  rbBand.fStyle = dwStyle;
  if (pszText != NULL)
  {
    rbBand.fMask |= RBBIM_TEXT;
    rbBand.lpText = (LPTSTR)pszText;
  }
  if (pbmp != NULL)
  {
    rbBand.fMask |= RBBIM_BACKGROUND;
    rbBand.hbmBack = (HBITMAP)pbmp;
  }
  return _AddBar(pParent, pBar, &rbBand);
}

static BOOL AddBar1(HWND pParent, HWND pBar, COLORREF clrFore, COLORREF clrBack, LPCTSTR pszText, DWORD dwStyle)
{
  REBARBANDINFO rbBand;
  memset(&rbBand, '\0', sizeof(rbBand));
  rbBand.fMask = RBBIM_STYLE | RBBIM_COLORS;
  rbBand.fStyle = dwStyle;
  rbBand.clrFore = clrFore;
  rbBand.clrBack = clrBack;
  if (pszText != NULL)
  {
    rbBand.fMask |= RBBIM_TEXT;
    rbBand.lpText = (LPTSTR)pszText;
  }
  return _AddBar(pParent, pBar, &rbBand);
}

HB_FUNC(ADDBARBITMAP)
{
  HWND pParent = hwg_par_HWND(1);
  HWND pBar = hwg_par_HWND(2);
  void *hStr;
  LPCTSTR pszText = HB_PARSTR(3, &hStr, NULL);
  HBITMAP pbmp = hwg_par_HBITMAP(4);
  DWORD dwStyle = hb_parnl(5);
  hb_retl(AddBar(pParent, pBar, pszText, pbmp, dwStyle));
  hb_strfree(hStr);
}

HB_FUNC(ADDBARCOLORS)
{
  HWND pParent = hwg_par_HWND(1);
  HWND pBar = hwg_par_HWND(2);
  COLORREF clrFore = hwg_par_COLORREF(3);
  COLORREF clrBack = hwg_par_COLORREF(4);
  void *hStr;
  LPCTSTR pszText = HB_PARSTR(5, &hStr, NULL);
  DWORD dwStyle = hb_parnl(6);

  hb_retl(AddBar1(pParent, pBar, clrFore, clrBack, pszText, dwStyle));
  hb_strfree(hStr);
}

// Combo Box Procedure

HB_FUNC(GETCOMBOWNDPROC)
{
  hb_retnint((LONG_PTR)s_wpOrigComboProc);
}

HB_FUNC(COMBOGETITEMRECT)
{
  HWND hWnd = hwg_par_HWND(1);

  int nIndex = hb_parnl(2);
  RECT rcItem;
  SendMessage(hWnd, LB_GETITEMRECT, nIndex, (LONG_PTR)(VOID *)&rcItem);
  hb_itemReturnRelease(Rect2Array(&rcItem));
}

HB_FUNC(COMBOBOXGETITEMDATA)
{
  HWND hWnd = hwg_par_HWND(1);
  int nIndex = hb_parnl(2);
  DWORD_PTR p;
  p = (DWORD_PTR)SendMessage(hWnd, CB_GETITEMDATA, nIndex, 0);
  hb_retnl((long)p);
}

HB_FUNC(COMBOBOXSETITEMDATA)
{
  HWND hWnd = hwg_par_HWND(1);
  int nIndex = hb_parnl(2);
  DWORD_PTR dwItemData = (DWORD_PTR)hb_parnl(3);
  hb_retnl((long)SendMessage(hWnd, CB_SETITEMDATA, nIndex, (LPARAM)dwItemData));
}

HB_FUNC(GETLOCALEINFO)
{
  TCHAR szBuffer[10] = {0};
  GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SLIST, szBuffer, HB_SIZEOFARRAY(szBuffer));
  HB_RETSTR(szBuffer);
}

HB_FUNC(COMBOBOXGETLBTEXT)
{
  HWND hWnd = hwg_par_HWND(1);
  int nIndex = hb_parnl(2);
  TCHAR lpszText[255] = {0};
  hb_retni((int)SendMessage(hWnd, CB_GETLBTEXT, nIndex, (LPARAM)lpszText));
  HB_STORSTR(lpszText, 3);
}

/*
DEFWINDOWPROC(HWND, nMsg, wParam, lParam) --> numeric
*/
HB_FUNC(DEFWINDOWPROC)
{
  // WNDPROC wpProc = (WNDPROC) hb_parnl(1);
  hwg_ret_LRESULT(DefWindowProc(hwg_par_HWND(1), hwg_par_UINT(2), hwg_par_WPARAM(3), hwg_par_LPARAM(4)));
}

/*
CALLWINDOWPROC(WNDPROC, HWND, nMsg, wParam, lParam) --> numeric
*/
HB_FUNC(CALLWINDOWPROC)
{
  hwg_ret_LRESULT(
      CallWindowProc(hwg_par_WNDPROC(1), hwg_par_HWND(2), hwg_par_UINT(3), hwg_par_WPARAM(4), hwg_par_LPARAM(5)));
}

HB_FUNC(BUTTONGETDLGCODE)
{
  LPARAM lParam = (LPARAM)HB_PARHANDLE(1);
  if (lParam)
  {
    MSG *pMsg = (MSG *)lParam;

    if (pMsg && (pMsg->message == WM_KEYDOWN) && (pMsg->wParam == VK_TAB))
    {
      // don't interfere with tab processing
      hb_retnl(0);
      return;
    }
  }
  hb_retnl(DLGC_WANTALLKEYS); // we want all keys except TAB key
}

HB_FUNC(GETDLGMESSAGE)
{
  LPARAM lParam = (LPARAM)HB_PARHANDLE(1);
  if (lParam)
  {
    MSG *pMsg = (MSG *)lParam;

    if (pMsg)
    {
      hb_retnl(pMsg->message);
      return;
    }
  }
  hb_retnl(0);
}

HB_FUNC(HANDLETOPTR)
{
  DWORD h = hb_parnl(1);
#ifdef HWG_USE_POINTER_ITEM
  // hb_retptr(ULongToPtr(h)); // TODO: Error: Unresolved external 'ULongToPtr'
  hb_retptr((void *)(ULONG_PTR)(h));
  return;
#endif
  hb_retnl((LONG)h);
}

HB_FUNC(TABITEMPOS)
{
  RECT pRect;
  TabCtrl_GetItemRect(hwg_par_HWND(1), hb_parni(2), &pRect);
  hb_itemReturnRelease(Rect2Array(&pRect));
}

HB_FUNC(GETTABNAME)
{
  TC_ITEM tie;
  TCHAR d[255] = {0};

  tie.mask = TCIF_TEXT;
  tie.cchTextMax = HB_SIZEOFARRAY(d) - 1;
  tie.pszText = d;
  TabCtrl_GetItem(hwg_par_HWND(1), hb_parni(2) - 1, (LPTCITEM)&tie);
  HB_RETSTR(tie.pszText);
}
