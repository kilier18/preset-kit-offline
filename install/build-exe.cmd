@echo off
setlocal
cd /d "%~dp0.."
set "CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
rem 1.1.92: payload is the dsh-purge mainline build (97 files), installer exe keeps the public name.
"%CSC%" /nologo /target:exe /codepage:65001 /optimize+ ^
 /out:dist\dsh-preset-kit-setup-1.1.92.exe ^
 /resource:dist\dsh-preset-kit-1.1.92.tgz,presetkitctl.payload.tgz ^
 /resource:tools\calibrate.mjs,presetkitctl.tools.calibrate.mjs ^
 /resource:tools\calibrate.cmd,presetkitctl.tools.calibrate.cmd ^
 /r:System.Web.Extensions.dll ^
 src\Program.cs
echo build rc=%ERRORLEVEL%
