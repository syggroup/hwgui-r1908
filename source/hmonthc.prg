//
// $Id: hmonthc.prg 1615 2011-02-18 13:53:35Z mlacecilia $
//
// HWGUI - Harbour Win32 GUI library source code:
// HMonthCalendar class
//
// Copyright 2004 Marcos Antonio Gambeta <marcos_gambeta@hotmail.com>
// www - http://geocities.yahoo.com.br/marcosgambeta/
//

//--------------------------------------------------------------------------//

#include "windows.ch"
#include "hbclass.ch"
#include "guilib.ch"

#define MCS_DAYSTATE             1
#define MCS_MULTISELECT          2
#define MCS_WEEKNUMBERS          4
#define MCS_NOTODAYCIRCLE        8
#define MCS_NOTODAY             16

//--------------------------------------------------------------------------//

CLASS HMonthCalendar INHERIT HControl

CLASS VAR winclass   INIT "SysMonthCal32"

   DATA value
   DATA bChange
   DATA bSelect

   METHOD New(oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
               oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
               lWeekNumbers, bSelect)
   METHOD Activate()
   METHOD Init()
   METHOD SetValue(dValue)
   METHOD GetValue()
   METHOD onChange()
   METHOD onSelect()


ENDCLASS

//--------------------------------------------------------------------------//

METHOD New(oWndParent, nId, vari, nStyle, nLeft, nTop, nWidth, nHeight, ;
            oFont, bInit, bChange, cTooltip, lNoToday, lNoTodayCircle, ;
            lWeekNumbers, bSelect) CLASS HMonthCalendar

   nStyle := hwg_BitOr(IIf(nStyle == NIL, 0, nStyle), 0) //WS_TABSTOP)
   nStyle   += IIf(lNoToday == NIL .OR. !lNoToday, 0, MCS_NOTODAY)
   nStyle   += IIf(lNoTodayCircle == NIL .OR. !lNoTodayCircle, 0, MCS_NOTODAYCIRCLE)
   nStyle   += IIf(lWeekNumbers == NIL .OR. !lWeekNumbers, 0, MCS_WEEKNUMBERS)
   ::Super:New(oWndParent, nId, nStyle, nLeft, nTop, nWidth, nHeight, oFont, bInit, ;
              ,, cTooltip)

   ::value   := IIf(hb_IsDate(vari) .And. !Empty(vari), vari, Date())

   ::bChange := bChange
   ::bSelect := bSelect

   HWG_InitCommonControlsEx()

   /*
   IF bChange != NIL
      ::oParent:AddEvent(MCN_SELECT, Self, bChange, .T., "onChange")
      ::oParent:AddEvent(MCN_SELCHANGE, Self, bChange, .T., "onChange")
   ENDIF
   */

   ::Activate()
   RETURN Self

//--------------------------------------------------------------------------//

METHOD Activate() CLASS HMonthCalendar

   IF !Empty(::oParent:handle)
      ::handle := InitMonthCalendar(::oParent:handle, ::id, ::style, ::nLeft, ::nTop, ::nWidth, ::nHeight)
      ::Init()
   ENDIF

   RETURN NIL

//--------------------------------------------------------------------------//

METHOD Init() CLASS HMonthCalendar

   IF !::lInit
      ::Super:Init()
      IF !Empty(::value)
         SetMonthCalendarDate(::handle, ::value)
      ENDIF
      ::oParent:AddEvent(MCN_SELECT, Self, {||::onSelect()}, .T., "onSelect")
      ::oParent:AddEvent(MCN_SELCHANGE, Self, {||::onChange()}, .T., "onChange")

   ENDIF

   RETURN NIL

//--------------------------------------------------------------------------//

METHOD SetValue(dValue) CLASS HMonthCalendar

   IF hb_IsDate(dValue) .And. !Empty(dValue)
      SetMonthCalendarDate(::handle, dValue)
      ::value := dValue
   ENDIF

   RETURN NIL

//--------------------------------------------------------------------------//

METHOD GetValue() CLASS HMonthCalendar

   ::value := GetMonthCalendarDate(::handle)

   RETURN ::value

METHOD onChange() CLASS HMonthCalendar

   IF hb_IsBlock(::bChange) .AND. !::oparent:lSuspendMsgsHandling
      hwg_SendMessage(::handle, WM_LBUTTONDOWN, 0, MAKELPARAM(1, 1))
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bChange, ::value, Self)
      ::oparent:lSuspendMsgsHandling := .F.
    ENDIF

   RETURN 0

METHOD onSelect() CLASS HMonthCalendar

   IF hb_IsBlock(::bSelect) .AND. !::oparent:lSuspendMsgsHandling
      ::oparent:lSuspendMsgsHandling := .T.
      Eval(::bSelect, ::value, Self)
      ::oparent:lSuspendMsgsHandling := .F.
    ENDIF

   RETURN NIL

//--------------------------------------------------------------------------//

#pragma BEGINDUMP

#include "hwingui.h"
#include <commctrl.h>
#include <hbapiitm.h>
#include <hbdate.h>
#if defined(__DMC__)
#include "missing.h"
#endif

HB_FUNC(INITMONTHCALENDAR)
{
  RECT rc;

  HWND hMC = CreateWindowEx(0, MONTHCAL_CLASS, TEXT(""), hwg_par_DWORD(3), hwg_par_int(4), hwg_par_int(5), hwg_par_int(6),
                       hwg_par_int(7), hwg_par_HWND(1), hwg_par_HMENU_ID(2), GetModuleHandle(NULL), NULL);

  MonthCal_GetMinReqRect(hMC, &rc);

  //SetWindowPos(hMC, NULL, hb_parni(4), hb_parni(5), rc.right, rc.bottom, SWP_NOZORDER);
  SetWindowPos(hMC, NULL, hwg_par_int(4), hwg_par_int(5), hwg_par_int(6), hwg_par_int(7), SWP_NOZORDER);

  hwg_ret_HWND(hMC);
}

HB_FUNC(SETMONTHCALENDARDATE) // adaptation of function SetDatePicker of file Control.c
{
  PHB_ITEM pDate = hb_param(2, HB_IT_DATE);

  if (pDate)
  {
    SYSTEMTIME sysTime;
    #ifndef HARBOUR_OLD_VERSION
    int lYear, lMonth, lDay;
    #else
    long lYear, lMonth, lDay;
    #endif

    hb_dateDecode(hb_itemGetDL(pDate), &lYear, &lMonth, &lDay);

    sysTime.wYear = (unsigned short)lYear;
    sysTime.wMonth = (unsigned short)lMonth;
    sysTime.wDay = (unsigned short)lDay;
    sysTime.wDayOfWeek = 0;
    sysTime.wHour = 0;
    sysTime.wMinute = 0;
    sysTime.wSecond = 0;
    sysTime.wMilliseconds = 0;

    MonthCal_SetCurSel(hwg_par_HWND(1), &sysTime);
  }
}

HB_FUNC(GETMONTHCALENDARDATE) // adaptation of function GetDatePicker of file Control.c
{
  SYSTEMTIME st;
  char szDate[9];
  SendMessage(hwg_par_HWND(1), MCM_GETCURSEL, 0, (LPARAM)&st);
  hb_dateStrPut(szDate, st.wYear, st.wMonth, st.wDay);
  szDate[8] = 0;
  hb_retds(szDate);
}

#pragma ENDDUMP
