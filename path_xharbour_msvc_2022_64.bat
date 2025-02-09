REM SET CL=-c -MD -MP -O1 -W4 -WX -EHsc -wd4201 -wd4457 -wd4459 -D_CRT_SECURE_NO_WARNINGS
REM SET LINK=-nologo -noimplib -noexp -subsystem:console
REM SET HARBOURCMD=-a -es2 -gc0 -n -q -w3

SET PATH=D:\devel\msvc_2022_64\bin;d:\devel\xharbour_msvc_2022_64\bin;%PATH%
SET INCLUDE=%INCLUDE%;d:\devel\xharbour_msvc_2022_64\include;D:\devel\msvc_2022_64\include;D:\devel\msvc_2022_64\include\ucrt;D:\devel\msvc_2022_64\include;D:\devel\msvc_2022_64\include\sdk
SET LIB=%LIB%;D:\devel\msvc_2022_64\lib;d:\devel\xharbour_msvc_2022_64\lib;D:\devel\msvc_2022_64\lib\SDK
SET HB_WITH_PGSQL=D:\pg13\include
SET HB_COMPILER=msvc64
SET HB_CPU=x86_64
%SystemRoot%\system32\cmd.exe
