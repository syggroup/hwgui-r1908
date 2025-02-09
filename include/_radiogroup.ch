// DO NOT USE THIS FILE DIRECTLY - USED BY GUILIB.CH

#xcommand RADIOGROUP => HRadioGroup():New()

#xcommand GET RADIOGROUP [ <ogr> VAR ] <vari>  ;
             [ ON INIT <bInit> ]        ;
             [ STYLE <nStyle> ]         ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bWhen> ]           ;
          => [<ogr> := ] HRadioGroup():New( <vari>, {|v|Iif(v==Nil,<vari>,<vari>:=v)}, ;
					     <bInit>,<bClick>,<bWhen>, <nStyle> )

          //nando
#xcommand @ <x>,<y> GET RADIOGROUP [ <ogr> VAR ] <vari>  ;
             [ CAPTION  <caption> ];
             [ OF <oWnd> ]              ;
             [ ID <nId> ]               ;
             [ SIZE <width>, <height> ] ;
             [ COLOR <color> ]          ;
             [ BACKCOLOR <bcolor> ]     ;
             [<lTransp: TRANSPARENT>]   ;
             [ FONT <oFont> ]           ;
             [ ON INIT <bInit> ]        ;
             [ ON SIZE <bSize> ]        ;
             [ STYLE <nStyle> ]         ;
             [ ON CLICK <bClick> ]      ;
             [ ON GETFOCUS <bWhen> ]           ;
          => [<ogr> := ] HRadioGroup():NewRG( <oWnd>,<nId>,<nStyle>,<vari>,;
                  {|v|Iif(v==Nil,<vari>,<vari>:=v)},<x>,<y>,<width>,<height>,<caption>,<oFont>,;
                  <bInit>,<bSize>,<color>,<bcolor>,<bClick>,<bWhen>,<.lTransp.>);;
          [ <ogr>:name := <(ogr)> ]


#xcommand END RADIOGROUP [ SELECTED <nSel> ] ;
          => ;
          HRadioGroup():EndGroup( <nSel> )

#xcommand END RADIOGROUP <oGr> [ SELECTED <nSel> ]  ;
          => ;
          <oGr>:EndGroup( <nSel> );;
          [ <oGr>:name := <(oGr)> ]
