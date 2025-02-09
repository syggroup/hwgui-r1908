// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand @ <x>,<y> PANEL [ <oPanel> ] ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ STYLE <nStyle> ]         ;
          => ;
          [<oPanel> :=] HPanel():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>,<height>,<bInit>,<bSize>,<bDraw>,<bcolor> );;
          [ <oPanel>:name := <(oPanel)> ]

#xcommand REDEFINE PANEL [ <oPanel> ]  ;
             [ OF <oWnd> ]              ;
             ID <nId>                   ;
             [ BACKCOLOR <bcolor> ]     ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ ON PAINT <bDraw> ]       ;
             [ HEIGHT <nHeight> ]       ;
             [ WIDTH <nWidth> ]         ;
          => ;
          [<oPanel> :=] HPanel():Redefine( <oWnd>,<nId>,<nWidth>,<nHeight>,<bInit>,<bSize>,<bDraw>, <bcolor> )
