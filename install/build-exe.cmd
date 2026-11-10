@echo off
setlocal
rem cd to repo root (this file lives in install\, artifacts go to dist\)
cd /d "%~dp0.."
set "CSC=C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
rem 1.1.94: payload is the dsh-purge mainline build (97 files), installer unpacks
rem resources\app.asar on a clean machine and switches the host to resources\app.
"%CSC%" /nologo /target:exe /codepage:65001 /optimize+ ^
 /out:dist\dsh-preset-kit-setup-1.1.94.exe ^
 /resource:dist\dsh-preset-kit-1.1.94.tgz,presetkitctl.payload.tgz ^
 /resource:tools\calibrate.mjs,presetkitctl.tools.calibrate.mjs ^
 /resource:tools\calibrate.cmd,presetkitctl.tools.calibrate.cmd ^
 /r:System.Web.Extensions.dll ^
 src\Program.cs
echo build rc=%ERRORLEVEL%
