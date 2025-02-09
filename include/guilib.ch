/*
 *$Id: guilib.ch 1906 2012-09-25 22:23:08Z lfbasso $
 */

#define HWG_VERSION            "2.17"
#define WND_MAIN               1
#define WND_MDI                2
#define WND_MDICHILD           3
#define WND_CHILD              4
#define WND_DLG_RESOURCE       10
#define WND_DLG_NORESOURCE     11

#define OBTN_INIT              0
#define OBTN_NORMAL            1
#define OBTN_MOUSOVER          2
#define OBTN_PRESSED           3

#define SHS_NOISE              0
#define SHS_DIAGSHADE          1
#define SHS_HSHADE             2
#define SHS_VSHADE             3
#define SHS_HBUMP              4
#define SHS_VBUMP              5
#define SHS_SOFTBUMP           6
#define SHS_HARDBUMP           7
#define SHS_METAL              8

#define PAL_DEFAULT            0
#define PAL_METAL              1

#define BRW_ARRAY              1
#define BRW_DATABASE           2

#define ANCHOR_TOPLEFT         0   // Anchors control to the top and left borders of the container and does not change the distance between the top and left borders. (Default)
#define ANCHOR_TOPABS          1   // Anchors control to top border of container and does not change the distance between the top border.
#define ANCHOR_LEFTABS         2   // Anchors control to left border of container and does not change the distance between the left border.
#define ANCHOR_BOTTOMABS       4   // Anchors control to bottom border of container and does not change the distance between the bottom border.
#define ANCHOR_RIGHTABS        8   // Anchors control to right border of container and does not change the distance between the right border.
#define ANCHOR_TOPREL          16  // Anchors control to top border of container and maintains relative distance between the top border.
#define ANCHOR_LEFTREL         32  // Anchors control to left border of container and maintains relative distance between the left border.
#define ANCHOR_BOTTOMREL       64  // Anchors control to bottom border of container and maintains relative distance between the bottom border.
#define ANCHOR_RIGHTREL        128 // Anchors control to right border of container and maintains relative distance between the right border.
#define ANCHOR_HORFIX          256 // Anchors center of control relative to left and right borders but remains fixed in size.
#define ANCHOR_VERTFIX         512 // Anchors center of control relative to top and bottom borders but remains fixed in size.

#define HORZ_PTS 9
#define VERT_PTS 12

#ifdef __XHARBOUR__
  #ifndef HB_SYMBOL_UNUSED
     #define HB_SYMBOL_UNUSED( x )    ( (x) := (x) )
  #endif
#endif

// Allow the definition of different classes without defining a new command

#xtranslate __IIF(.T., [<true>], [<false>]) => <true>
#xtranslate __IIF(.F., [<true>], [<false>]) => <false>

// Commands for windows, dialogs handling

#include "_window.ch"

#include "_dialog.ch"

#xcommand MENU FROM RESOURCE OF <oWnd> ON <id1> ACTION <b1>      ;
             [ ON <idn> ACTION <bn> ]    ;
          => ;
          <oWnd>:aEvents := \{ \{ 0,<id1>, <{b1}> \} [ , \{ 0,<idn>, <{bn}> \} ] \}

#xcommand DIALOG ACTIONS OF <oWnd> ON <id1>,<id2> ACTION <b1>      ;
             [ ON <idn1>,<idn2> ACTION <bn> ]  ;
          => ;
          <oWnd>:aEvents := \{ \{ <id1>,<id2>, <b1> \} [ , \{ <idn1>,<idn2>, <bn> \} ] \}

// Commands for control handling

#include "_progressbar.ch"

#include "_status.ch"

#include "_static.ch"

#include "_saybmp.ch"

#include "_sayicon.ch"

#include "_sayfimage.ch"

#include "_line.ch"

#include "_edit.ch"

#include "_richedit.ch"

#include "_button.ch"

#include "_buttonex.ch"

#include "_group.ch"

#include "_tree.ch"

#include "_tab.ch"

#include "_checkbutton.ch"

#include "_radiogroup.ch"

#include "_radiobutton.ch"

#include "_combobox.ch"

#include "_updown.ch"

#include "_panel.ch"

#include "_browse.ch"

#include "_column.ch"

#include "_grid.ch"

#include "_ownbutton.ch"

#include "_shadebutton.ch"

#include "_datepicker.ch"

#include "_splitter.ch"

#include "_font.ch"

/* Print commands */

#xcommand START PRINTER DEFAULT => OpenDefaultPrinter(); StartDoc()

/* SAY ... GET system     */

#xcommand SAY <value> TO <oDlg> ID <id> ;
          => ;
          hwg_SetDlgItemText( <oDlg>:handle, <id>, <value> )

/*   Menu system     */

#xcommand MENU [ OF <oWnd> ] [ ID <nId> ] [ TITLE <cTitle> ] ;
               [[ BACKCOLOR <bcolor> ][ COLOR <bcolor> ]]    ;
               [ BMPSIZE <nWidthBmp>, <nHeighBmp> ]          ;
          => ;
          hwg_BeginMenu( <oWnd>, <nId>, <cTitle>, <bcolor>, <nWidthBmp>,<nHeighBmp> )

#xcommand CONTEXT MENU <oMenu> => <oMenu> := hwg_ContextMenu()

#xcommand ENDMENU => hwg_EndMenu()

#xcommand MENUITEM <item> [ ID <nId> ]    ;
             ACTION <act>                  ;
             [ BITMAP <bmp> ]               ; //ADDED by Sandro Freire
             [<res: FROM RESOURCE>]        ; //true use image from resource
             [ ACCELERATOR <flag>, <key> ] ;
             [<lDisabled: DISABLED>]       ;
          => ;
          hwg_DefineMenuItem( <item>, <nId>, <{act}>, <.lDisabled.>, <flag>, <key>, <bmp>, <.res.>, .f. )

#xcommand MENUITEMCHECK <item> [ ID <nId> ]    ;
             [ ACTION <act> ]              ;
             [ ACCELERATOR <flag>, <key> ] ;
             [<lDisabled: DISABLED>]       ;
          => ;
          hwg_DefineMenuItem( <item>, <nId>, <{act}>, <.lDisabled.>, <flag>, <key>,,, .t. )

#xcommand MENUITEMBITMAP <oMain>  ID <nId> ;
             BITMAP <bmp>                  ;
             [<res: FROM RESOURCE>]         ;
          => ;
          hwg_InsertBitmapMenu( <oMain>:menu, <nId>, <bmp>, <.res.>)

#xcommand ACCELERATOR <flag>, <key>       ;
             [ ID <nId> ]                  ;
             ACTION <act>                  ;
          => ;
          hwg_DefineAccelItem( <nId>, <{act}>, <flag>, <key> )

#xcommand SEPARATOR => hwg_DefineMenuItem()

#include "_timer.ch"

#xcommand SET KEY <nctrl>,<nkey> [ OF <oDlg> ] [ TO <func> ] ;
          => ;
          SetDlgKey( <oDlg>, <nctrl>, <nkey>, <{func}> )

#translate LastKey( )  =>  HWG_LASTKEY( )

/*             */
#include "_graph.ch"

/* open an .dll resource */
#xcommand SET RESOURCES TO <cName1> => hwg_LoadResource( <cName1> )

#xcommand SET RESOURCES TO => hwg_LoadResource( NIL )

#xcommand SET COLORFOCUS <x:ON,OFF,&> [COLOR [<tColor>],[<bColor>]] [< lFixed : NOFIXED >] [< lPersistent : PERSISTENT >];
          => ;
          SetColorinFocus( <(x)> , <tColor>, <bColor>, <.lFixed.>, <.lPersistent.> )

#xcommand SET DISABLEBACKCOLOR <x:ON,OFF,&> [COLOR [<bColor>]] ;
          => ;
          SetDisableBackColor( <(x)> , <bColor> )

// Addded by jamaj
#xcommand DEFAULT <uVar1> := <uVal1> ;
             [, <uVarN> := <uValN> ] ;
          => ;
          <uVar1> := IIf( <uVar1> == nil, <uVal1>, <uVar1> ) ;;
          [ <uVarN> := IIf( <uVarN> == nil, <uValN>, <uVarN> ); ]

#include "_ipedit.ch"

#define ISOBJECT(c)    ( Valtype(c) == "O" )
#define ISBLOCK(c)     ( Valtype(c) == "B" )
#define ISARRAY(c)     ( Valtype(c) == "A" )
#define ISNUMBER(c)    ( Valtype(c) == "N" )
#define ISLOGICAL(c)   ( Valtype(c) == "L" )

/* Commands for PrintDos Class*/

#xcommand SET PRINTER TO <oPrinter> OF <oPtrObj>     ;
          => ;
          <oPtrObj>:=Printdos():New( <oPrinter>)

#xcommand @ <x>,<y> PSAY  <vari>  ;
             [ PICTURE <cPicture> ] OF <oPtrObj>   ;
          => ;
          <oPtrObj>:Say(<x>, <y>, <vari>, <cPicture>)

#xcommand EJECT OF <oPtrObj> => <oPtrObj>:Eject()

#xcommand END PRINTER <oPtrObj> => <oPtrObj>:End()

/* Hprinter */

#include "_printer.ch"

/*
Command for MonthCalendar Class
Added by Marcos Antonio Gambeta
*/

#include "_monthcalendar.ch"

#include "_listbox.ch"

/* Add Sandro R. R. Freire */

#include "_splash.ch"

// Nice Buttons by Luiz Rafael
#include "_nicebutton.ch"

// trackbar control
#include "_trackbar.ch"

// animation control
#include "_animation.ch"

//Contribution   Ricardo de Moura Marques
#include "_rect.ch"

//New Control
#include "_staticlink.ch"

#include "_toolbar.ch"

#xcommand CREATE MENUBAR <o> => <o> := \{ \}

#xcommand MENUBARITEM  <oWnd> CAPTION <c> ON <id1> ACTION <b1>      ;
          => ;
          Aadd( <oWnd>, \{ <c>, <id1>, <{b1}> \})

#include "_gridex.ch"

#include "_pager.ch"

#include "_rebar.ch"

#xcommand ADDBAND <hWnd> to <opage> ;
             [BACKCOLOR <b> ] [FORECOLOR <f>] ;
             [STYLE <nstyle>] [TEXT <t>] ;
          => ;
          <opage>:ADDBARColor(<hWnd>,<f>,<b>,<t>,<nstyle>)

#xcommand ADDBAND <hWnd> to <opage> ;
             [BITMAP <b> ]  ;
             [STYLE <nstyle>] [TEXT <t>] ;
          => ;
          <opage>:ADDBARBITMAP(<hWnd>,<t>,<b>,<nstyle>)

#include "_checkcombobox.ch"

//Contribution Luis Fernando Basso

#include "_shape.ch"

#include "_container.ch"
