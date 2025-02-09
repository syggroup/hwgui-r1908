// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand @ <x>,<y> OWNERBUTTON [ <oOwnBtn> ]  ;
             [ OF <oWnd> ]             ;
             [ ID <nId> ]              ;
             [ SIZE <width>, <height> ] ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]     ;
             [ ON SIZE <bSize> ]     ;
             [ ON DRAW <bDraw> ]     ;
             [ ON CLICK <bClick> ]   ;
             [ ON GETFOCUS <bGfocus> ]   ;
             [ ON LOSTFOCUS <bLfocus> ]  ;
             [ STYLE <nStyle> ]      ;
             [ <flat: FLAT> ]        ;
             [ <enable: DISABLED> ]        ;
             [ TEXT <cText>          ;
             [ COLOR <color>] [ FONT <font> ] ;
             [ COORDINATES  <xt>, <yt>, <widtht>, <heightt> ] ;
             ] ;
             [ BITMAP <bmp>  [<res: FROM RESOURCE>] [<ltr: TRANSPARENT> [COLOR  <trcolor> ]] ;
             [ COORDINATES  <xb>, <yb>, <widthb>, <heightb> ] ;
             ] ;
             [ TOOLTIP <ctoolt> ]    ;
             [ <lCheck: CHECK> ]     ;
             [ <lThemed: THEMED> ]     ;             
          => ;
          [<oOwnBtn> :=] HOWNBUTTON():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, ;
             <height>,<bInit>,<bSize>,<bDraw>,<bClick>,<.flat.>,<cText>,<color>, ;
             <font>,<xt>,<yt>,<widtht>,<heightt>,<bmp>,<.res.>,<xb>,<yb>,<widthb>, ;
             <heightb>,<.ltr.>,<trcolor>,<ctoolt>,!<.enable.>,<.lCheck.>,<bcolor>, <bGfocus>, <bLfocus>,<.lThemed.> );;
          [ <oOwnBtn>:name := <(oOwnBtn)> ]

#xcommand REDEFINE OWNERBUTTON [ <oOwnBtn> ]  ;
             [ OF <oWnd> ]                     ;
             ID <nId>                          ;
             [ ON INIT <bInit> ]     ;
             [ ON SIZE <bSize> ]     ;
             [ ON DRAW <bDraw> ]     ;
             [ ON CLICK <bClick> ]   ;
             [ <flat: FLAT> ]        ;
             [ TEXT <cText>          ;
             [ COLOR <color>] [ FONT <font> ] ;
             [ COORDINATES  <xt>, <yt>, <widtht>, <heightt> ] ;
             ] ;
             [ BITMAP <bmp>  [<res: FROM RESOURCE>] [<ltr: TRANSPARENT>] ;
             [ COORDINATES  <xb>, <yb>, <widthb>, <heightb> ] ;
             ] ;
             [ TOOLTIP <ctoolt> ]    ;
             [ <enable: DISABLED> ]  ;
             [ <lCheck: CHECK> ]      ;
          => ;
          [<oOwnBtn> :=] HOWNBUTTON():Redefine( <oWnd>,<nId>,<bInit>,<bSize>,;
             <bDraw>,<bClick>,<.flat.>,<cText>,<color>,<font>,<xt>,<yt>,;
             <widtht>,<heightt>,<bmp>,<.res.>,<xb>,<yb>,<widthb>,<heightb>,;
             <.ltr.>,<ctoolt>,!<.enable.>,<.lCheck.> )

