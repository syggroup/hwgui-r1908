// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand @ <x>,<y> BITMAP [ <oBmp> SHOW ] <bitmap> ;
             [<res: FROM RESOURCE>]     ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ STRETCH <nStretch>]      ;
             [<lTransp: TRANSPARENT>]   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON CLICK <bClick> ]      ;
             [ ON DBLCLICK <bDblClick> ];
             [ TOOLTIP <ctoolt> ]       ;
             [ STYLE <nStyle> ]         ;
          => ;
          [<oBmp> := ] HSayBmp():New( <oWnd>,<nId>,<x>,<y>,<width>, ;
             <height>,<bitmap>,<.res.>,<bInit>,<bSize>,<ctoolt>,<bClick>,<bDblClick>, <.lTransp.>,<nStretch>, <nStyle> );;
          [ <oBmp>:name := <(oBmp)> ]

#xcommand REDEFINE BITMAP [ <oBmp> SHOW ] <bitmap> ;
             [<res: FROM RESOURCE>]     ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [<lTransp: TRANSPARENT>]   ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ TOOLTIP <ctoolt> ]       ;
          => ;
          [<oBmp> := ] HSayBmp():Redefine( <oWnd>,<nId>,<bitmap>,<.res.>, ;
             <bInit>,<bSize>,<ctoolt>,<.lTransp.>)
