// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand @ <x>,<y> LINE [ <oLine> ]   ;
             [ LENGTH <length> ]       ;
             [ HEIGHT <nHeight> ]      ;
             [ OF <oWnd> ]             ;
             [ ID <nId> ]              ;
             [ COLOR <color> ]         ;
             [ LINESLANT <cSlant> ]    ;
             [ BORDERWIDTH <nBorder> ] ;
             [<lVert: VERTICAL>]       ;
             [ ON INIT <bInit> ]       ;
             [ ON SIZE <bSize> ]       ;
          => ;
          [<oLine> := ] HLine():New( <oWnd>,<nId>,<.lVert.>,<x>,<y>,<length>,<bSize>, <bInit>,;
					              <color>, <nHeight>, <cSlant>,<nBorder>  );;
          [ <oLine>:name := <(oLine)> ]

