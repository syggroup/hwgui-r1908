rem Batch to compile tests using xHarbour and Visual C++ 64-bit.
rem How to use:
rem xcompilemsvc64 filename <ENTER>
rem Require HB_PATH pointing to xHarbour dir.

del %1.exe

set HB_BIN_DIR=%HB_PATH%\bin
set HB_LIB_DIR=%HB_PATH%\lib
set HB_INC_DIR=%HB_PATH%\include

set HB_LIBS=rtl.lib vm.lib gtwin.lib lang.lib codepage.lib macro.lib rdd.lib dbfntx.lib dbfcdx.lib dbffpt.lib hbsix.lib common.lib debug.lib pp.lib pcrepos.lib
set HWG_LIBS=hwgui.lib procmisc.lib hbxml.lib hwg_qhtm.lib
set SYS_LIBS=winmm.lib kernel32.lib user32.lib gdi32.lib advapi32.lib ws2_32.lib iphlpapi.lib winspool.lib comctl32.lib comdlg32.lib shell32.lib uuid.lib ole32.lib oleaut32.lib mpr.lib mapi32.lib imm32.lib msimg32.lib wininet.lib rpcrt4.lib winhttp.lib secur32.lib opengl32.lib gdiplus.lib

rem prg -> c

%HB_BIN_DIR%\harbour %1.prg -i..\include -i%HB_INC_DIR% -n -es2

rem c -> o

cl -c -I..\include -I%HB_INC_DIR% %1.c

rem o -> exe

cl /EHsc %1.obj %HB_PATH%\obj\vcw64\mainwin.obj /link /out:%1.exe /LIBPATH:..\lib\vc64 /LIBPATH:%HB_LIB_DIR% %HWG_LIBS% %HB_LIBS% %SYS_LIBS% /NODEFAULTLIB:LIBC /NODEFAULTLIB:msvcrt /force:multiple /nxcompat:NO /subsystem:windows

rem exclusão dos arquivo temporários

del %1.c
del %1.obj

rem limpeza das variáveis de ambiente

set HB_BIN_DIR=
set HB_LIB_DIR=
set HB_INC_DIR=
set HB_LIBS=
set HWG_LIBS=
set SYS_LIBS=
