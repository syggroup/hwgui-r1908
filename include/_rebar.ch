// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand @ <x>,<y> REBAR [ <oTool> ] ;
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ STYLE <nStyle> ]         ;
          => ;
          [<oTool> := ]        HREBAR():New( <oWnd>,<nId>,<nStyle>,<x>,<y>,<width>, <height>,,,,,,,,);;
          [ <oTool>:name := <(oTool)> ]
