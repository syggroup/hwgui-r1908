// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand @ <x>,<y> PAGER [ <oTool> ] ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ STYLE <nStyle> ]         ;
             [ <lVert: VERTICAL> ] ;
          => ;
          [<oTool> := ] HPager():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, <height>,,,,,,,,,<.lVert.>);;
          [ <oTool>:name := <(oTool)> ]
