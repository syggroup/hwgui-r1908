// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand @ <x>,<y> MONTHCALENDAR [ <oMonthCalendar> ] ;
             [ OF <oWnd> ]                              ;
             [ ID <nId> ]                               ;
             [ SIZE <nWidth>,<nHeight> ]                ;
             [ INIT <dInit> ]                           ;
             [ ON INIT <bInit> ]                        ;
             [ ON CHANGE <bChange> ]                    ;
             [ ON SELECT <bSelect> ]                   ;
             [ STYLE <nStyle> ]                         ;
             [ FONT <oFont> ]                           ;
             [ TOOLTIP <cTooltip> ]                     ;
             [ < notoday : NOTODAY > ]                  ;
             [ < notodaycircle : NOTODAYCIRCLE > ]      ;
             [ < weeknumbers : WEEKNUMBERS > ]          ;
          => ;
          [<oMonthCalendar> :=] HMonthCalendar():New( <oWnd>,<nId>,<dInit>,<nStyle>,;
             <x>,<y>,<nWidth>,<nHeight>,<oFont>,<bInit>,<bChange>,<cTooltip>,;
             <.notoday.>,<.notodaycircle.>,<.weeknumbers.>,<bSelect> );;
          [ <oMonthCalendar>:name := <(oMonthCalendar)> ]
