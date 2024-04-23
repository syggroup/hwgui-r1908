@echo off
if "%1" == "clean" goto CLEAN
if "%1" == "CLEAN" goto CLEAN

if not exist lib md lib
if not exist obj md obj
if not exist obj\b64 md obj\b64
if not exist obj\b64\mt md obj\b64\mt
:BUILD

rem   make -fmakefile.bc  > make_b32.log
rem   if errorlevel 1 goto BUILD_ERR
rem   set ACTIVEX_SUPPORT=ON
make -l EXE_OBJ_DIR=obj\b64\bin OBJ_DIR=obj\b64 -fmakefile.bc64 %1 %2 %3 > make_b64.log
if errorlevel 1 goto BUILD_ERR
make -l OBJ_DIR=obj\b64\mt -DHB_THREAD_SUPPORT -DHB_MT=mt -fmakefile.bc64 %2 %3 >> make_b64.log
if errorlevel 1 goto BUILD_ERR


:BUILD_OK

   goto EXIT

:BUILD_ERR

   notepad make_b64.log
   goto EXIT

:CLEAN
   del lib\*.lib
   del lib\*.bak
   del obj\b64\*.obj
   del obj\b64\*.c
   del obj\b64\mt\*.obj
   del obj\b64\mt\*.c

   del make_b64.log

   goto EXIT

:EXIT

