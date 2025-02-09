// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand @ <x>,<y>  ANIMATION [ <oAnimation> ] ;
             [ OF <oWnd> ]                       ;
             [ ID <nId> ]                        ;
             [ FROM RESOURCE <xResID> ]          ;
             [ STYLE <nStyle> ]                  ;
             [ SIZE <nWidth>, <nHeight> ]        ;
             [ FILE <cFile> ]                    ;
             [ < autoplay: AUTOPLAY > ]          ;
             [ < center : CENTER > ]             ;
             [ < transparent: TRANSPARENT > ]    ;
          => ;
          [<oAnimation> :=] HAnimation():New( <oWnd>,<nId>,<nStyle>,<x>,<y>, ;
             <nWidth>,<nHeight>,<cFile>,<.autoplay.>,<.center.>,<.transparent.>,<xResID>);;
          [ <oAnimation>:name := <(oAnimation)> ]

