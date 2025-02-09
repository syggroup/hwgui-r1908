// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand @ <x>,<y> SHADEBUTTON [ <oShBtn> ]  ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ EFFECT <shadeID>  [ PALETTE <palet> ]             ;
             [ GRANULARITY <granul> ] [ HIGHLIGHT <highl> ] ;
             [ COLORING <coloring> ] [ SHCOLOR <shcolor> ] ];
             [ ON INIT <bInit> ]     ;
             [ ON SIZE <bSize> ]     ;
             [ ON DRAW <bDraw> ]     ;
             [ ON CLICK <bClick> ]   ;
             [ STYLE <nStyle> ]      ;
             [ <flat: FLAT> ]        ;
             [ <enable: DISABLED> ]  ;
             [ TEXT <cText>          ;
             [ COLOR <color>] [ FONT <font> ] ;
             [ COORDINATES  <xt>, <yt> ] ;
             ] ;
             [ BITMAP <bmp>  [<res: FROM RESOURCE>] [<ltr: TRANSPARENT> [COLOR  <trcolor> ]] ;
             [ COORDINATES  <xb>, <yb>, <widthb>, <heightb> ] ;
             ] ;
             [ TOOLTIP <ctoolt> ]    ;
          => ;
          [<oShBtn> :=] HSHADEBUTTON():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<bInit>,<bSize>,<bDraw>,<bClick>,<.flat.>,<cText>,<color>, ;
             <font>,<xt>,<yt>,<bmp>,<.res.>,<xb>,<yb>,<widthb>,<heightb>,<.ltr.>, ;
             <trcolor>,<ctoolt>,!<.enable.>,<shadeID>,<palet>,<granul>,<highl>, ;
             <coloring>,<shcolor> );;
          [ <oShBtn>:name := <(oShBtn)> ]
