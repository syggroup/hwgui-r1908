rem Batch to compile tests using xHarbour and Clang 32-bit.
rem How to use:
rem xcompileclang32 filename <ENTER>
rem Require HB_PATH pointing to xHarbour dir and CLANG_PATH pointing to Clang dir.

del %1.exe

set HB_BIN_DIR=%HB_PATH%\bin
set HB_LIB_DIR=%HB_PATH%\lib
set HB_INC_DIR=%HB_PATH%\include

set HB_LIBS=-lrtl -lvm -lgtwin -llang -lcodepage -lmacro -lrdd -ldbfntx -ldbfcdx -ldbffpt -lhbsix -lcommon -ldebug -lpp -lpcrepos
set HWG_LIBS=-lhwgui -lprocmisc -lhbxml -lhwg_qhtm
set SYS_LIBS=-lwinmm -lkernel32 -luser32 -lgdi32 -ladvapi32 -lws2_32 -liphlpapi -lwinspool -lcomctl32 -lcomdlg32 -lshell32 -luuid -lole32 -loleaut32 -lmpr -lmapi32 -limm32 -lmsimg32 -lwininet -lrpcrt4 -lwinhttp -lsecur32 -lopengl32 -lgdiplus

rem prg -> c

%HB_BIN_DIR%\harbour %1.prg -i..\include -i%HB_INC_DIR% -n -es2

rem c -> o

clang -c -I..\include -I%HB_INC_DIR% %1.c

rem o -> exe

clang -o %1.exe %1.o %HB_PATH%\obj\clngw32\mainwin.o -L..\lib\cl -L%HB_LIB_DIR% -L%CLANG_PATH%\i686-w64-mingw32\lib -Wl,--start-group %HWG_LIBS% %HB_LIBS% %SYS_LIBS%  -Wl,--end-group -mwindows

rem exclusão dos arquivo temporários

del %1.c
del %1.o

rem limpeza das variáveis de ambiente

set HB_BIN_DIR=
set HB_LIB_DIR=
set HB_INC_DIR=
set HB_LIBS=
set HWG_LIBS=
set SYS_LIBS=
