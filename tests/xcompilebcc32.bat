rem Batch to compile tests using xHarbour and BCC 32-bit.
rem How to use:
rem xcompile filename <ENTER>
rem Require HB_PATH pointing to xHarbour dir.

del %1.exe

set HB_BIN_DIR=%HB_PATH%\bin
set HB_LIB_DIR=%HB_PATH%\lib
set HB_INC_DIR=%HB_PATH%\include

set HB_LIBS=rtl.lib vm.lib gtwin.lib lang.lib codepage.lib macro.lib rdd.lib dbfntx.lib dbfcdx.lib dbffpt.lib hbsix.lib common.lib debug.lib pp.lib pcrepos.lib
set HWG_LIBS=hwgui.lib procmisc.lib hbxml.lib hwg_qhtm.lib

rem prg -> c

%HB_BIN_DIR%\harbour %1.prg -i..\include -i%HB_INC_DIR% -n -es2

rem c -> obj

bcc32 -c -O2 -tW -M -I..\include -I%HB_INC_DIR% %1.c

rem obj -> exe

ilink32 -Gn -Tpe -aa -L..\lib\b32 -L%HB_LIB_DIR% c0w32.obj %1.obj, %1.exe, %1.map, %HWG_LIBS% %HB_LIBS% cw32.lib import32.lib

rem exclusão dos arquivo temporários

del %1.c
del %1.obj
del %1.map
del %1.tds

rem limpeza das variáveis de ambiente

set HB_BIN_DIR=
set HB_LIB_DIR=
set HB_INC_DIR=
set HB_LIBS=
set HWG_LIBS=
