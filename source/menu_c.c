//
// $Id: menu_c.c 1819 2011-12-26 11:17:03Z LFBASSO $
//
// HWGUI - Harbour Win32 GUI library source code:
// C level menu functions
//
// Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
// www - http://kresin.belgorod.su
//

#define OEMRESOURCE

#include "hwingui.h"
#include <commctrl.h>
#ifdef __DMC__
#define MIIM_BITMAP 0x00000080
#endif
#include <hbapiitm.h>
#include <hbvm.h>
#include <hbstack.h>

#define FLAG_DISABLED 1

/*
 *  CreateMenu() --> hMenu
 */

/*
HWG__CREATEMENU() --> HMENU
*/
HB_FUNC(HWG__CREATEMENU)
{
  hwg_ret_HMENU(CreateMenu());
}

/*
HWG__CREATEPOPUPMENU() --> HMENU
*/
HB_FUNC(HWG__CREATEPOPUPMENU)
{
  hwg_ret_HMENU(CreatePopupMenu());
}

/*
 *  AddMenuItem(hMenu,cCaption,nPos,fByPosition,nId,fState,lSubMenu) --> lResult
 */

/*
HWG__ADDMENUITEM(HMENU, cCaption, nPosition, p4, p5, np6, lp7) --> HMENU|0
*/
HB_FUNC(HWG__ADDMENUITEM) // TODO: revisar retorno
{
  UINT uFlags = MF_BYPOSITION;
  void *hNewItem;
  LPCTSTR lpNewItem;
  int nPos;
  MENUITEMINFO mii;

  if (!HB_ISNIL(6) && (hb_parni(6) & FLAG_DISABLED))
  {
    uFlags |= MFS_DISABLED;
  }

  lpNewItem = HB_PARSTR(2, &hNewItem, NULL);
  if (lpNewItem)
  {
    BOOL lString = 0;
    LPCTSTR ptr = lpNewItem;

    while (*ptr)
    {
      if (*ptr != ' ' && *ptr != '-')
      {
        lString = 1;
        break;
      }
      ptr++;
    }
    uFlags |= (lString) ? MF_STRING : MF_SEPARATOR;
  }
  else
  {
    uFlags |= MF_SEPARATOR;
  }

  if (hb_parl(7))
  {
    HMENU hSubMenu = CreateMenu();

    uFlags |= MF_POPUP;
    InsertMenu(hwg_par_HMENU(1), hwg_par_UINT(3), uFlags, (UINT_PTR)hSubMenu, lpNewItem);
    hwg_ret_HMENU(hSubMenu);

    // Code to set the ID of submenus, the API seems to assume that you wouldn't really want to,
    // but if you are used to getting help via IDs for popups in 16bit, then this will help you.
    nPos = GetMenuItemCount(hwg_par_HMENU(1));
    mii.cbSize = sizeof(MENUITEMINFO);
    mii.fMask = MIIM_ID;
    if (GetMenuItemInfo(hwg_par_HMENU(1), nPos - 1, TRUE, &mii))
    {
      mii.wID = hb_parni(5);
      SetMenuItemInfo(hwg_par_HMENU(1), nPos - 1, TRUE, &mii);
    }
  }
  else
  {
    InsertMenu(hwg_par_HMENU(1), hwg_par_UINT(3), uFlags, hb_parni(5), lpNewItem);
    hb_retnl(0);
  }
  hb_strfree(hNewItem);
}

/*
HB_FUNC(HWG__ADDMENUITEM)
{
  MENUITEMINFO mii;
  BOOL fByPosition = ( HB_ISNIL(4) )? 0:(BOOL) hb_parl(4);
  void * hData;

  mii.cbSize = sizeof( MENUITEMINFO );
  mii.fMask = MIIM_TYPE | MIIM_STATE | MIIM_ID;
  mii.fState = ( HB_ISNIL(6) || hb_parl(6) )? 0:MFS_DISABLED;
  mii.wID = hb_parni( 5 );
  if (HB_ISCHAR(2))
  {
    mii.dwTypeData = (LPTSTR)HB_PARSTR(2, &hData, NULL);
    mii.cch = strlen(mii.dwTypeData);
    mii.fType = MFT_STRING;
  }
  else
  {
    mii.fType = MFT_SEPARATOR;
  }

  hb_retl(InsertMenuItem((HMENU)HB_PARHANDLE(1), hb_parni(3), fByPosition, &mii));
  hb_strfree(hData);
}
*/

/*
 *  CreateSubMenu(hMenu, nMenuId) --> hSubMenu
 */

/*
HWG__CREATESUBMENU() --> HMENU
*/
HB_FUNC(HWG__CREATESUBMENU)
{
  MENUITEMINFO mii;
  HMENU hSubMenu = CreateMenu();

  mii.cbSize = sizeof(MENUITEMINFO);
  mii.fMask = MIIM_SUBMENU;
  mii.hSubMenu = hSubMenu;

  if (SetMenuItemInfo(hwg_par_HMENU(1), hwg_par_UINT(2), 0, &mii))
  {
    hwg_ret_HMENU(hSubMenu);
  }
  else
  {
    hwg_ret_HMENU(NULL);
  }
}

/*
 *  SetMenu(hWnd, hMenu) --> lResult
 */

/*
HWG__SETMENU(HWND, HMENU) --> BOOL
*/
HB_FUNC(HWG__SETMENU)
{
  hwg_ret_BOOL(SetMenu(hwg_par_HWND(1), hwg_par_HMENU(2)));
}

/*
GETMENUHANDLE() --> HMENU
*/
HB_FUNC(GETMENUHANDLE)
{
  HWND handle = (hb_pcount() > 0 && !HB_ISNIL(1)) ? hwg_par_HWND(1) : aWindows[0];
  hwg_ret_HMENU(GetMenu(handle));
}

/*
CHECKMENUITEM(oObject|HWND|NIL, nID, lChecked) -->
*/
HB_FUNC(CHECKMENUITEM)
{
  HMENU hMenu;
  UINT uCheck = (hb_pcount() < 3 || !HB_ISLOG(3) || hb_parl(3)) ? MF_CHECKED : MF_UNCHECKED;

  if (HB_ISOBJECT(1))
  {
    PHB_ITEM pObject = hb_param(1, HB_IT_OBJECT);
    hMenu = (HMENU)HB_GETHANDLE(GetObjectVar(pObject, "HANDLE"));
  }
  else
  {
    HWND handle = (hb_pcount() > 0 && !HB_ISNIL(1)) ? (hwg_par_HWND(1)) : aWindows[0];
    hMenu = GetMenu(handle);
  }
  if (!hMenu)
  {
    hMenu = hwg_par_HMENU(1);
  }

  if (!hMenu)
  {
    MessageBox(GetActiveWindow(), TEXT(""), TEXT("No Menu!"), MB_OK | MB_ICONINFORMATION);
  }
  else
  {
    CheckMenuItem(hMenu, hwg_par_UINT(2), MF_BYCOMMAND | uCheck);
  }
}

/*
ISCHECKEDMENUITEM(oObject|HWND|NIL, nID) --> .T.|.F.
*/
HB_FUNC(ISCHECKEDMENUITEM)
{
  HMENU hMenu;
  UINT uCheck;

  if (HB_ISOBJECT(1))
  {
    PHB_ITEM pObject = hb_param(1, HB_IT_OBJECT);
    hMenu = (HMENU)HB_GETHANDLE(GetObjectVar(pObject, "HANDLE"));
  }
  else
  {
    HWND handle = (hb_pcount() > 0 && !HB_ISNIL(1)) ? (hwg_par_HWND(1)) : aWindows[0];
    hMenu = GetMenu(handle);
  }
  if (!hMenu)
  {
    hMenu = hwg_par_HMENU(1);
  }

  if (!hMenu)
  {
    hb_retl(FALSE);
  }
  else
  {
    uCheck = GetMenuState(hMenu, hwg_par_UINT(2), MF_BYCOMMAND);
    hb_retl(uCheck & MF_CHECKED);
  }
}

/*
ENABLEMENUITEM(oObject|HWND|NIL, nID, lEnabled, lFlag) -->
*/
HB_FUNC(ENABLEMENUITEM)
{
  HMENU hMenu; // = ( hb_pcount()>0 && !HB_ISNIL(1) )? (( HMENU ) HB_PARHANDLE(1)) : GetMenu(aWindows[0]);
  UINT uEnable = (hb_pcount() < 3 || !HB_ISLOG(3) || hb_parl(3)) ? MF_ENABLED : MF_GRAYED;
  UINT uFlag = (hb_pcount() < 4 || !HB_ISLOG(4) || hb_parl(4)) ? MF_BYCOMMAND : MF_BYPOSITION;

  if (HB_ISOBJECT(1))
  {
    PHB_ITEM pObject = hb_param(1, HB_IT_OBJECT);
    hMenu = (HMENU)HB_GETHANDLE(GetObjectVar(pObject, "HANDLE"));
  }
  else
  {
    HWND handle = (hb_pcount() > 0 && !HB_ISNIL(1)) ? (hwg_par_HWND(1)) : aWindows[0];
    hMenu = GetMenu(handle);
  }
  if (!hMenu)
  {
    hMenu = hwg_par_HMENU(1);
  }

  if (!hMenu)
  {
    MessageBox(GetActiveWindow(), TEXT(""), TEXT("No Menu!"), MB_OK | MB_ICONINFORMATION);
    HB_RETHANDLE(NULL);
  }
  else
  {
    HB_RETHANDLE(EnableMenuItem(hMenu, hwg_par_UINT(2),
                                uFlag | uEnable)); // TODO: revisar retorno (o retorno é BOOL e não um handle)
  }
}

/*
ISENABLEDMENUITEM(oObject|HWND|NIL, nID, lFlag) --> .T.|.F.
*/
HB_FUNC(ISENABLEDMENUITEM)
{
  HMENU hMenu; // = ( hb_pcount()>0 && !HB_ISNIL(1) )? (( HMENU ) HB_PARHANDLE(1)):GetMenu(aWindows[0]);
  UINT uCheck;
  UINT uFlag = (hb_pcount() < 3 || !HB_ISLOG(3) || hb_parl(3)) ? MF_BYCOMMAND : MF_BYPOSITION;

  if (HB_ISOBJECT(1))
  {
    PHB_ITEM pObject = hb_param(1, HB_IT_OBJECT);
    hMenu = (HMENU)HB_GETHANDLE(GetObjectVar(pObject, "HANDLE"));
  }
  else
  {
    HWND handle = (hb_pcount() > 0 && !HB_ISNIL(1)) ? (hwg_par_HWND(1)) : aWindows[0];
    hMenu = GetMenu(handle);
  }
  if (!hMenu)
  {
    hMenu = hwg_par_HMENU(1);
  }

  if (!hMenu)
  {
    hb_retl(FALSE);
  }
  else
  {
    uCheck = GetMenuState(hMenu, hwg_par_UINT(2), uFlag);
    hb_retl(!(uCheck & MF_GRAYED));
  }
}

/*
HWG_DELETEMENU(HMENU|NIL, nPosition) -->
*/
HB_FUNC(HWG_DELETEMENU)
{
  HMENU hMenu = (hb_pcount() > 0 && !HB_ISNIL(1)) ? (hwg_par_HMENU(1)) : GetMenu(aWindows[0]);

  if (hMenu)
  {
    DeleteMenu(hMenu, hwg_par_UINT(2), MF_BYCOMMAND);
  }
}

/*
HWG_TRACKMENU(HMENU, nX, nY, HWND, nFlags) --> .T.|.F.
*/
HB_FUNC(HWG_TRACKMENU)
{
  HWND hWnd = hwg_par_HWND(4);
  SetForegroundWindow(hWnd);
  hwg_ret_BOOL(TrackPopupMenu(hwg_par_HMENU(1), HB_ISNIL(5) ? TPM_RIGHTALIGN : hwg_par_UINT(5), hwg_par_int(2),
                              hwg_par_int(3), 0, hWnd, NULL));
  PostMessage(hWnd, 0, 0, 0);
}

/*
HWG_DESTROYMENU(HMENU) --> .T.|.F.
*/
HB_FUNC(HWG_DESTROYMENU)
{
  hwg_ret_BOOL(DestroyMenu(hwg_par_HMENU(1)));
}

/*
 * CreateAcceleratorTable(_aAccel)
 */
HB_FUNC(CREATEACCELERATORTABLE)
{
  PHB_ITEM pArray = hb_param(1, HB_IT_ARRAY), pSubArr;
  LPACCEL lpaccl;
  ULONG ul, ulEntries = (ULONG)hb_arrayLen(pArray);
  HACCEL h;

  lpaccl = (LPACCEL)hb_xgrab(sizeof(ACCEL) * ulEntries);

  for (ul = 1; ul <= ulEntries; ul++)
  {
    pSubArr = hb_arrayGetItemPtr(pArray, ul);
    lpaccl[ul - 1].fVirt = (BYTE)hb_arrayGetNL(pSubArr, 1) | FNOINVERT | FVIRTKEY;
    lpaccl[ul - 1].key = (WORD)hb_arrayGetNL(pSubArr, 2);
    lpaccl[ul - 1].cmd = (WORD)hb_arrayGetNL(pSubArr, 3);
  }
  h = CreateAcceleratorTable(lpaccl, (int)ulEntries);

  hb_xfree(lpaccl);
  hwg_ret_HACCEL(h);
}

/*
 * DestroyAcceleratorTable(hAccel)
 */

/*
DESTROYACCELERATORTABLE(HACCEL) --> .T.|.F.
*/
HB_FUNC(DESTROYACCELERATORTABLE)
{
  hwg_ret_BOOL(DestroyAcceleratorTable(hwg_par_HACCEL(1)));
}

/*
DRAWMENUBAR(HWND) --> .T.|.F.
*/
HB_FUNC(DRAWMENUBAR)
{
  hwg_ret_BOOL(DrawMenuBar(hwg_par_HWND(1)));
}

/*
 *  GetMenuCaption(hWnd | oWnd, nMenuId)
 */

/*
GETMENUCAPTION(oObject|HWND|HMENU|NIL, nItem) --> .F.|string
*/
HB_FUNC(GETMENUCAPTION)
{
  HMENU hMenu;

  if (HB_ISOBJECT(1))
  {
    PHB_ITEM pObject = hb_param(1, HB_IT_OBJECT);
    hMenu = (HMENU)HB_GETHANDLE(GetObjectVar(pObject, "HANDLE"));
  }
  else
  {
    HWND handle = (hb_pcount() > 0 && !HB_ISNIL(1)) ? (hwg_par_HWND(1)) : aWindows[0];
    hMenu = GetMenu(handle);
  }
  if (!hMenu)
  {
    hMenu = hwg_par_HMENU(1);
  }

  if (!hMenu)
  {
    MessageBox(GetActiveWindow(), TEXT(""), TEXT("No Menu!"), MB_OK | MB_ICONINFORMATION);
    hb_retl(FALSE);
  }
  else
  {
    MENUITEMINFO mii;
    LPTSTR lpBuffer;

    memset(&mii.cbSize, 0, sizeof(MENUITEMINFO));
    mii.cbSize = sizeof(MENUITEMINFO);
    mii.fMask = MIIM_TYPE;
    mii.fType = MFT_STRING;
    GetMenuItemInfo(hMenu, hwg_par_UINT(2), 0, &mii);
    mii.cch++;
    lpBuffer = (LPTSTR)hb_xgrab(mii.cch * sizeof(TCHAR));
    lpBuffer[0] = '\0';
    mii.dwTypeData = lpBuffer;
    if (GetMenuItemInfo(hMenu, hwg_par_UINT(2), 0, &mii))
    {
      HB_RETSTR(mii.dwTypeData);
    }
    else
    {
      hb_retc("Error");
    }
    hb_xfree(lpBuffer);
  }
}

/*
 *  SetMenuCaption(hWnd | oWnd, nMenuId, cCaption)
 */

/*
SETMENUCAPTION(oObject|HWND|HMENU|NIL, nItem, cText) --> .T.|.F.
*/
HB_FUNC(SETMENUCAPTION)
{
  HMENU hMenu;

  if (HB_ISOBJECT(1))
  {
    PHB_ITEM pObject = hb_param(1, HB_IT_OBJECT);
    hMenu = (HMENU)HB_GETHANDLE(GetObjectVar(pObject, "HANDLE"));
  }
  else
  {
    HWND handle = (hb_pcount() > 0 && !HB_ISNIL(1)) ? (hwg_par_HWND(1)) : aWindows[0];
    hMenu = GetMenu(handle);
  }
  if (!hMenu)
  {
    hMenu = hwg_par_HMENU(1);
  }

  if (!hMenu)
  {
    MessageBox(GetActiveWindow(), TEXT(""), TEXT("No Menu!"), MB_OK | MB_ICONINFORMATION);
    hb_retl(FALSE);
  }
  else
  {
    MENUITEMINFO mii;
    void *hData;
    mii.cbSize = sizeof(MENUITEMINFO);
    mii.fMask = MIIM_TYPE;
    mii.fType = MFT_STRING;
    mii.dwTypeData = (LPTSTR)HB_PARSTR(3, &hData, NULL);

    if (SetMenuItemInfo(hMenu, hwg_par_UINT(2), 0, &mii))
    {
      hb_retl(TRUE);
    }
    else
    {
      hb_retl(FALSE);
    }
    hb_strfree(hData);
  }
}

/*
SETMENUITEMBITMAPS(HMENU, nPosition, HBITMAP, HBITMAP) --> .T.|.F.
*/
HB_FUNC(SETMENUITEMBITMAPS)
{
  hwg_ret_BOOL(
      SetMenuItemBitmaps(hwg_par_HMENU(1), hwg_par_UINT(2), MF_BYCOMMAND, hwg_par_HBITMAP(3), hwg_par_HBITMAP(4)));
}

/*
GETMENUCHECKMARKDIMENSIONS() --> numeric
*/
HB_FUNC(GETMENUCHECKMARKDIMENSIONS)
{
  hwg_ret_LONG(GetMenuCheckMarkDimensions());
}

/*
GETSIZEMENUBITMAPWIDTH() --> numeric
*/
HB_FUNC(GETSIZEMENUBITMAPWIDTH)
{
  hwg_ret_int(GetSystemMetrics(SM_CXMENUSIZE));
}

/*
GETSIZEMENUBITMAPHEIGHT() --> numeric
*/
HB_FUNC(GETSIZEMENUBITMAPHEIGHT)
{
  hwg_ret_int(GetSystemMetrics(SM_CYMENUSIZE));
}

/*
GETMENUCHECKMARKWIDTH() --> numeric
*/
HB_FUNC(GETMENUCHECKMARKWIDTH)
{
  hwg_ret_int(GetSystemMetrics(SM_CXMENUCHECK));
}

/*
GETMENUCHECKMARKHEIGHT() --> numeric
*/
HB_FUNC(GETMENUCHECKMARKHEIGHT)
{
  hwg_ret_int(GetSystemMetrics(SM_CYMENUCHECK));
}

/*
STRETCHBLT(HDCDEST, nXDest, nYDest, nWDest, nHDest, HDCSRC, nXSrc, nYSrc, nWSrc, nHSrc, nRop) --> .T.|.F.
*/
HB_FUNC(STRETCHBLT)
{
  hwg_ret_BOOL(StretchBlt(hwg_par_HDC(1), hwg_par_int(2), hwg_par_int(3), hwg_par_int(4), hwg_par_int(5),
                          hwg_par_HDC(6), hwg_par_int(7), hwg_par_int(8), hwg_par_int(9), hwg_par_int(10),
                          hwg_par_DWORD(11)));
}

/*
HWG__INSERTBITMAPMENU(HMENU, nItem, HBITMAP) --> .T.|.F.
*/
HB_FUNC(HWG__INSERTBITMAPMENU)
{
  MENUITEMINFO mii;
  mii.cbSize = sizeof(MENUITEMINFO);
  mii.fMask = MIIM_ID | MIIM_BITMAP | MIIM_DATA;
  mii.hbmpItem = hwg_par_HBITMAP(3);
  hwg_ret_BOOL(SetMenuItemInfo(hwg_par_HMENU(1), hwg_par_UINT(2), 0, &mii));
}

/*
CHANGEMENU() -->
*/
HB_FUNC(CHANGEMENU)
{
  void *hStr;
  hb_retl(ChangeMenu(hwg_par_HMENU(1), hwg_par_UINT(2), HB_PARSTR(3, &hStr, NULL), hwg_par_UINT(4), hwg_par_UINT(5)));
  hb_strfree(hStr);
}

/*
MODIFYMENU(HMENU, nPosition, nFlags, nIDNewItem) --> .T.|.F.
*/
HB_FUNC(MODIFYMENU)
{
  void *hStr;
  hwg_ret_BOOL(
      ModifyMenu(hwg_par_HMENU(1), hwg_par_UINT(2), hwg_par_UINT(3), hwg_par_UINT_PTR(4), HB_PARSTR(5, &hStr, NULL)));
  hb_strfree(hStr);
}

/*
ENABLEMENUSYSTEMITEM(HWND, nPosition, lEnable, lFlag) -->
*/
HB_FUNC(ENABLEMENUSYSTEMITEM)
{
  HMENU hMenu;
  UINT uEnable = (hb_pcount() < 3 || !HB_ISLOG(3) || hb_parl(3)) ? MF_ENABLED : MF_GRAYED;
  UINT uFlag = (hb_pcount() < 4 || !HB_ISLOG(4) || hb_parl(4)) ? MF_BYCOMMAND : MF_BYPOSITION;

  hMenu = GetSystemMenu(hwg_par_HWND(1), FALSE);
  if (!hMenu)
  {
    HB_RETHANDLE(NULL);
  }
  else
  {
    HB_RETHANDLE(EnableMenuItem(hMenu, hwg_par_UINT(2),
                                uFlag | uEnable)); // TODO: revisar retorno (o retorno é BOOL e não um handle)
  }
}

/*
HWG_SETMENUINFO(oObject|HWND|HMENU|NIL, nColor) -->
*/
HB_FUNC(HWG_SETMENUINFO)
{
  HMENU hMenu;
  MENUINFO mi;
  HBRUSH hbrush;

  if (HB_ISOBJECT(1))
  {
    PHB_ITEM pObject = hb_param(1, HB_IT_OBJECT);
    hMenu = (HMENU)HB_GETHANDLE(GetObjectVar(pObject, "HANDLE"));
  }
  else
  {
    HWND handle = (hb_pcount() > 0 && !HB_ISNIL(1)) ? (hwg_par_HWND(1)) : aWindows[0];
    hMenu = GetMenu(handle);
  }
  if (!hMenu)
  {
    hMenu = hwg_par_HMENU(1);
  }
  if (hMenu)
  {
    hbrush = hb_pcount() > 1 && !HB_ISNIL(2) ? CreateSolidBrush(hwg_par_COLORREF(2)) : NULL;
    mi.cbSize = sizeof(mi);
    mi.fMask = MIM_APPLYTOSUBMENUS | MIM_BACKGROUND;
    mi.hbrBack = hbrush;
    SetMenuInfo(hMenu, &mi);
  }
}
