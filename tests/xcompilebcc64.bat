rem Batch to compile tests using xHarbour and BCC 64-bit.
rem How to use:
rem xcompile64 filename <ENTER>
rem Require HB_PATH pointing to xHarbour dir and BCC_PATH pointing to BCC dir.

del %1.exe

set HB_BIN_DIR=%HB_PATH%\bin
set HB_LIB_DIR=%HB_PATH%\lib
set HB_INC_DIR=%HB_PATH%\include

set HB_LIBS=rtl.a vm.a gtwin.a lang.a codepage.a macro.a rdd.a dbfntx.a dbfcdx.a dbffpt.a hbsix.a common.a debug.a pp.a pcrepos.a
set HWG_LIBS=hwgui.a procmisc.a hbxml.a hwg_qhtm.a

rem prg -> c

%HB_BIN_DIR%\harbour %1.prg -i..\include -i%HB_INC_DIR% -n -es2

rem c -> o

bcc64 -c -tW -I..\include -I%HB_INC_DIR% %1.c %1.c

rem o -> exe

ilink64 %1.o -aa -L..\lib\b64 -L%HB_LIB_DIR% -L%BCC_PATH%\lib -L%BCC_PATH%\lib\psdk c0w64.o %HWG_LIBS% %HB_LIBS% cw64.a import64.a

rem exclusão dos arquivo temporários

del %1.c
del %1.il*
del %1.map
del %1.o

rem limpeza das variáveis de ambiente

set HB_BIN_DIR=
set HB_LIB_DIR=
set HB_INC_DIR=
set HB_LIBS=
set HWG_LIBS=
