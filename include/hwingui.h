/*
 *$Id: hwingui.h 1615 2011-02-18 13:53:35Z mlacecilia $
 */

#define HB_OS_WIN_32_USED

#ifndef _WIN32_WINNT
   #define _WIN32_WINNT   0x0502
#endif
#ifndef _WIN32_IE
   #define _WIN32_IE      0x0501
#endif
#ifndef WINVER
    #define WINVER  0x0500
#endif

#include <windows.h>
#include "guilib.h"

#if ((defined(_MSC_VER)&&(_MSC_VER<1300)&&!defined(__POCC__)) || defined(__WATCOMC__)|| defined(__DMC__))
   #define IS_INTRESOURCE(_r) ((((ULONG_PTR)(_r)) >> 16) == 0)
   #if (defined(_MSC_VER)&&(_MSC_VER<1300)||defined(__DMC__))
      #define GetWindowLongPtr    GetWindowLong
      #define SetWindowLongPtr    SetWindowLong
      #define DWORD_PTR           DWORD
      #define LONG_PTR            LONG
      #define ULONG_PTR           ULONG
      #define GWLP_WNDPROC        GWL_WNDPROC
   #endif
#endif

#if !defined( __XHARBOUR__ ) && ( __HARBOUR__ - 0 > 0x020000 ) && \
    !defined( HB_EMULATE_STR_API )
   #include "hbwinuni.h"
   #if !defined(__HARBOURPP__)
   #include "hbwince.h"
   #endif
   #define HB_HAS_STR_FUNC
#else
   #undef HB_HAS_STR_FUNC

   #if !defined( HB_EMULATE_STR_API ) && defined( UNICODE )
      #define HB_EMULATE_STR_API
   #endif

   #if defined( HB_EMULATE_STR_API ) && defined( UNICODE )
      #define HB_PARSTR( n, h, len )                hwg_wstrget( hb_param( n, HB_IT_ANY ), h, len )
      #define HB_PARSTRDEF( n, h, len )             hwg_wstrnull( hwg_wstrget( hb_param( n, HB_IT_ANY ), h, len ) )
      #define HB_RETSTR( str )                      hwg_wstrset( hb_param( -1, HB_IT_ANY ), str )
      #define HB_RETSTRLEN( str, len )              hwg_wstrlenset( hb_param( -1, HB_IT_ANY ), str, len )
      #define HB_STORSTR( str, n )                  hwg_wstrset( hb_param( n, HB_IT_BYREF ), str )
      #define HB_STORSTRLEN( str, len, n )          hwg_wstrlenset( hb_param( n, HB_IT_BYREF ), str, len )
      #define HB_ARRAYGETSTR( arr, n, h, len )      hwg_wstrget( hb_arrayGetItemPtr( arr, n ), h, len )
      #define HB_ARRAYSETSTR( arr, n, str )         hwg_wstrset( hb_arrayGetItemPtr( arr, n ), str )
      #define HB_ARRAYSETSTRLEN( arr, n, str, len ) hwg_wstrlenset( hb_arrayGetItemPtr( arr, n ), str, len )
      #define HB_ITEMCOPYSTR( itm, str, len )       hwg_wstrcopy( itm, str, len )
      #define HB_ITEMGETSTR( itm, h, len )          hwg_wstrget( itm, h, len )
      #define HB_ITEMPUTSTR( itm, str )             hwg_wstrput( itm, str )
      #define HB_ITEMPUTSTRLEN( itm, str, len )     hwg_wstrlenput( itm, str, len )
      #define HB_STRUNSHARE( h, str, len )          hwg_wstrunshare( h, str, len )
      #define hb_strfree( h )                       hwg_wstrfree( h )
   #else
      #define HB_PARSTR( n, h, len )                hwg_strget( hb_param( n, HB_IT_ANY ), h, len )
      #define HB_PARSTRDEF( n, h, len )             hwg_strnull( hwg_strget( hb_param( n, HB_IT_ANY ), h, len ) )
      #define HB_RETSTR( str )                      hb_retc( str )
      #define HB_RETSTRLEN( str, len )              hb_retclen( str, len )
      #define HB_STORSTR( str, n )                  hb_storc( str, n )
      #define HB_STORSTRLEN( str, len, n )          hb_storclen( str, len, n )
      #define HB_ARRAYGETSTR( arr, n, h, len )      hwg_strget( hb_arrayGetItemPtr( arr, n ), h, len )
      #define HB_ARRAYSETSTR( arr, n, str )         hb_arraySetC( arr, n, str )
      #define HB_ARRAYSETSTRLEN( arr, n, str, len ) hb_arraySetCL( arr, n, str, len )
      #define HB_ITEMCOPYSTR( itm, str, len )       hwg_strcopy( itm, str, len )
      #define HB_ITEMGETSTR( itm, h, len )          hwg_strget( itm, h, len )
      #define HB_ITEMPUTSTR( itm, str )             hb_itemPutC( itm, str )
      #define HB_ITEMPUTSTRLEN( itm, str, len )     hb_itemPutCL( itm, str, len )
      #define HB_STRUNSHARE( h, str, len )          hwg_strunshare( h, str, len )
      #define hb_strfree( h )                       hwg_strfree( h )

      /* hack to pacify warning in old [x]Harbour versions which wrongly
       * defined some functions using strings
       */
      #if defined( __XHARBOUR__ ) || ( __HARBOUR__ - 0  == 0 )
         #undef HB_STORSTR
         #define HB_STORSTR( str, n )                  hb_storc( ( char * ) str, n )
      #endif
   #endif

   HB_EXTERN_BEGIN
   extern const char *  hwg_strnull( const char * str );
   extern const char *  hwg_strget( PHB_ITEM pItem, void ** phStr, HB_SIZE * pulLen );
   extern HB_SIZE       hwg_strcopy( PHB_ITEM pItem, char * pStr, HB_SIZE ulLen );
   extern char *        hwg_strunshare( void ** phStr, const char * pStr, HB_SIZE ulLen );
   extern void          hwg_strfree( void * hString );
   #if defined( HB_EMULATE_STR_API )
      extern const wchar_t *  hwg_wstrnull( const wchar_t * str );
      extern const wchar_t *  hwg_wstrget( PHB_ITEM pItem, void ** phStr, HB_SIZE * pulLen );
      extern PHB_ITEM         hwg_wstrput( PHB_ITEM pItem, const wchar_t * pStr );
      extern void             hwg_wstrset( PHB_ITEM pItem, const wchar_t * pStr );
      extern PHB_ITEM         hwg_wstrlenput( PHB_ITEM pItem, const wchar_t * pStr, HB_SIZE ulLen );
      extern void             hwg_wstrlenset( PHB_ITEM pItem, const wchar_t * pStr, HB_SIZE ulLen );
      extern HB_SIZE          hwg_wstrcopy( PHB_ITEM pItem, wchar_t * pStr, HB_SIZE ulLen );
      extern wchar_t *        hwg_wstrunshare( void ** phStr, const wchar_t * pStr, HB_SIZE ulLen );
      extern void             hwg_wstrfree( void * hString );
   #endif
   HB_EXTERN_END

   #if defined( HB_OS_WIN_CE )
      #undef  GetProcAddress
      #define GetProcAddress  GetProcAddressA
   #endif

#endif

HB_EXTERN_BEGIN

extern void writelog( char* s );

extern PHB_ITEM GetObjectVar( PHB_ITEM pObject, const char *varname );
extern void SetObjectVar( PHB_ITEM pObject, const char *varname, PHB_ITEM pValue );

extern void SetWindowObject( HWND hWnd, PHB_ITEM pObject );
extern PHB_ITEM Rect2Array( RECT * rc );
extern BOOL Array2Rect( PHB_ITEM aRect, RECT * rc );

extern HWND aWindows[];
extern HWND *aDialogs;
extern int iDialogs;
extern HMODULE hModule;
extern PHB_DYNS pSym_onEvent;

HB_EXTERN_END

#define hwg_par_COLORREF(n) (COLORREF)hb_parnl(n)
#define hwg_par_HBITMAP(n) (HBITMAP)HB_PARHANDLE(n)
#define hwg_par_HBRUSH(n) (HBRUSH)HB_PARHANDLE(n)
#define hwg_par_HDC(n) (HDC)HB_PARHANDLE(n)
#define hwg_par_HFONT(n) (HFONT)HB_PARHANDLE(n)
#define hwg_par_HGDIOBJ(n) (HGDIOBJ)HB_PARHANDLE(n)
#define hwg_par_HICON(n) (HICON)HB_PARHANDLE(n)
#define hwg_par_HIMAGELIST(n) (HIMAGELIST)HB_PARHANDLE(n)
#define hwg_par_HINSTANCE(n) (HINSTANCE)HB_PARHANDLE(n)
#define hwg_par_HMENU(n) (HMENU)HB_PARHANDLE(n)
#define hwg_par_HMENU_ID(n)(HMENU)(INT_PTR)hb_parni(n)
#define hwg_par_HRGN(n) (HRGN)HB_PARHANDLE(n)
#define hwg_par_HWND(n) (HWND)HB_PARHANDLE(n)
#define hwg_par_LPARAM(n) (LPARAM)hb_parnl(n)
//#define hwg_par_PAINTSTRUCT(n) (PAINTSTRUCT *)HB_PARHANDLE(n)
#define hwg_par_PAINTSTRUCT(n) (PAINTSTRUCT *)hb_parptr(n)
#define hwg_par_UINT(n) (UINT)hb_parni(n)
#define hwg_par_WNDPROC(n) (WNDPROC)(LONG_PTR)hb_parnl(n)
#define hwg_par_WPARAM(n) (WPARAM)hb_parnl(n)
#define hwg_par_int(n) hb_parni(n)
#define hwg_par_BOOL(n) hb_parl(n)
#define hwg_par_DWORD(n) hb_parnl(n)
#define hwg_par_LONG(n) hb_parnl(n)
#define hwg_par_BYTE(n) (BYTE)hb_parni(n)
#define hwg_par_LRESULT(n) (LRESULT)hb_parnl(n)
#define hwg_par_HACCEL(n) (HACCEL)HB_PARHANDLE(n)
#define hwg_par_UINT_PTR(n) (UINT_PTR)hb_parni(n)
#define hwg_par_HTHEME(n) (HTHEME)hb_parptr(n)
#define hwg_par_HCURSOR(n) (HCURSOR)HB_PARHANDLE(n)

#define hwg_ret_BOOL(x) hb_retl(x)
#define hwg_ret_HWND(n) HB_RETHANDLE(n)
#define hwg_ret_LRESULT(x) hb_retnl((long)x)
//#define hwg_ret_PAINTSTRUCT(n) HB_RETHANDLE(n)
#define hwg_ret_PAINTSTRUCT(n) hb_retptr(n)
#define hwg_ret_HBRUSH(x) HB_RETHANDLE(x)
#define hwg_ret_HDC(x) HB_RETHANDLE(x)
#define hwg_ret_HGDIOBJ(x) HB_RETHANDLE(x)
#define hwg_ret_HBITMAP(x) HB_RETHANDLE(x)
#define hwg_ret_HMENU(x) HB_RETHANDLE(x)
#define hwg_ret_HCURSOR(x) HB_RETHANDLE(x)
#define hwg_ret_HPEN(x) HB_RETHANDLE(x)
#define hwg_ret_HICON(x) HB_RETHANDLE(x)
#define hwg_ret_HFONT(x) HB_RETHANDLE(x)
#define hwg_ret_HRGN(x) HB_RETHANDLE(x)
#define hwg_ret_HANDLE(x) HB_RETHANDLE(x)
#define hwg_ret_int(x) hb_retni(x)
#define hwg_ret_UINT_PTR(x) hb_retni(x)
#define hwg_ret_UINT(x) hb_retni(x)
#define hwg_ret_LONG(x) hb_retnl(x)
#define hwg_ret_long(x) hb_retnl(x)
#define hwg_ret_DWORD(x) hb_retnl(x)
#define hwg_ret_COLORREF(x) hb_retnl(x)
#define hwg_ret_HACCEL(x) HB_RETHANDLE(x)
#define hwg_ret_HTHEME(n) hb_retptr(n)
#define hwg_ret_HPROPSHEETPAGE(x) HB_RETHANDLE(x)

#define hwg_vmPushHWND(x) HB_PUSHITEM(x)
#define hwg_vmPushUINT(x) hb_vmPushInteger(x)
#define hwg_vmPushWPARAM(x) hb_vmPushLong((long)x)
#define hwg_vmPushLPARAM(x) HB_PUSHITEM(x)
