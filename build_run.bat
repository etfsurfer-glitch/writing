@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

set SRC_DIR=%~dp0
set OBF_DIR=%SRC_DIR%obf_src
set BUILD_DIR=%SRC_DIR%build_out
set RELEASE_DIR=%SRC_DIR%release
set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
set LOG=%SRC_DIR%build_log.txt

:: Python Scripts 디렉토리(pyarmor.exe / pyinstaller.exe 위치) 를 PATH 앞에 prepend.
:: PEP 514 layout (pythoncore-*) 자동 감지 — 버전 업그레이드해도 동작.
for /d %%D in ("%LOCALAPPDATA%\Python\pythoncore-*") do set "PY_SCRIPTS=%%D\Scripts"
if defined PY_SCRIPTS set "PATH=%PY_SCRIPTS%;%PATH%"

echo Build started > "%LOG%"
if defined PY_SCRIPTS echo PY_SCRIPTS=%PY_SCRIPTS% >> "%LOG%"

echo [1/5] Cleaning... >> "%LOG%"
if exist "%OBF_DIR%"   rmdir /s /q "%OBF_DIR%"
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%SRC_DIR%dist" rmdir /s /q "%SRC_DIR%dist"
if exist "%SRC_DIR%__pycache__" rmdir /s /q "%SRC_DIR%__pycache__"
echo Done >> "%LOG%"

echo [2/5] PyArmor obfuscation... >> "%LOG%"
cd /d "%SRC_DIR%"
pyarmor gen --recursive --output "%OBF_DIR%" ^
    app.py stealth_utils.py auth.py tracker.py login_ui.py updater.py ^
    blog_collector.py blog_scraper.py blog_writer.py gemini_writer.py ^
    gemini_mamul_writer.py celebrity_gemini_writer.py celebrity_image_filter.py ^
    image_laundry.py naver_writing_rules.py ^
    add_text_to_image.py compress.py compress2.py mamul_writer.py naver_land_core.py >> "%LOG%" 2>&1
if errorlevel 1 (
    echo FAILED: PyArmor >> "%LOG%"
    exit /b 1
)
echo PyArmor done >> "%LOG%"

set RUNTIME_PKG=
for /d %%d in ("%OBF_DIR%\pyarmor_runtime_*") do (
    set RUNTIME_PKG=%%~nxd
)
if "%RUNTIME_PKG%"=="" (
    echo FAILED: no pyarmor_runtime folder >> "%LOG%"
    exit /b 1
)
echo Runtime: %RUNTIME_PKG% >> "%LOG%"

echo [3/5] Copying assets... >> "%LOG%"
xcopy /e /i /q "%SRC_DIR%prompts"           "%OBF_DIR%\prompts\" >> "%LOG%" 2>&1
xcopy /e /i /q "%SRC_DIR%background"        "%OBF_DIR%\background\" >> "%LOG%" 2>&1
xcopy /e /i /q "%SRC_DIR%cardnews_templates" "%OBF_DIR%\cardnews_templates\" >> "%LOG%" 2>&1
copy /y "%SRC_DIR%version.txt"              "%OBF_DIR%\version.txt" >> "%LOG%" 2>&1
copy /y "%SRC_DIR%common.jpg"                "%OBF_DIR%\common.jpg" >> "%LOG%" 2>&1
echo Assets done >> "%LOG%"

echo [4/5] PyInstaller... >> "%LOG%"
:: PyArmor 로 난독화된 본 프로젝트 .py 들은 --add-data 로 _internal/ 루트에
:: 강제 복사한다. --hidden-import 만으로는 정적 분석이 실패해 누락된다.
pyinstaller ^
    --noconfirm ^
    --onedir ^
    --windowed ^
    --name NWriting ^
    --uac-admin ^
    --distpath "%BUILD_DIR%" ^
    --workpath "%SRC_DIR%build_tmp" ^
    --paths "%OBF_DIR%" ^
    --add-data "%OBF_DIR%\%RUNTIME_PKG%;%RUNTIME_PKG%" ^
    --add-data "%OBF_DIR%\prompts;prompts" ^
    --add-data "%OBF_DIR%\background;background" ^
    --add-data "%OBF_DIR%\cardnews_templates;cardnews_templates" ^
    --add-data "%OBF_DIR%\version.txt;." ^
    --add-data "%OBF_DIR%\common.jpg;." ^
    --add-data "%OBF_DIR%\stealth_utils.py;." ^
    --add-data "%OBF_DIR%\auth.py;." ^
    --add-data "%OBF_DIR%\tracker.py;." ^
    --add-data "%OBF_DIR%\login_ui.py;." ^
    --add-data "%OBF_DIR%\updater.py;." ^
    --add-data "%OBF_DIR%\blog_collector.py;." ^
    --add-data "%OBF_DIR%\blog_scraper.py;." ^
    --add-data "%OBF_DIR%\blog_writer.py;." ^
    --add-data "%OBF_DIR%\gemini_writer.py;." ^
    --add-data "%OBF_DIR%\gemini_mamul_writer.py;." ^
    --add-data "%OBF_DIR%\celebrity_gemini_writer.py;." ^
    --add-data "%OBF_DIR%\celebrity_image_filter.py;." ^
    --add-data "%OBF_DIR%\image_laundry.py;." ^
    --add-data "%OBF_DIR%\naver_writing_rules.py;." ^
    --add-data "%OBF_DIR%\add_text_to_image.py;." ^
    --add-data "%OBF_DIR%\compress.py;." ^
    --add-data "%OBF_DIR%\compress2.py;." ^
    --add-data "%OBF_DIR%\mamul_writer.py;." ^
    --add-data "%OBF_DIR%\naver_land_core.py;." ^
    --hidden-import _tkinter ^
    --collect-submodules tkinter ^
    --collect-submodules PIL ^
    --hidden-import supabase ^
    --hidden-import google.genai ^
    --hidden-import playwright ^
    --hidden-import numpy ^
    --hidden-import win32clipboard ^
    --hidden-import win32con ^
    --hidden-import win32api ^
    --hidden-import aiohttp ^
    --hidden-import bs4 ^
    --collect-all playwright ^
    --collect-all openpyxl ^
    --collect-all certifi ^
    --collect-all truststore ^
    "%OBF_DIR%\app.py" >> "%LOG%" 2>&1

if errorlevel 1 (
    echo FAILED: PyInstaller >> "%LOG%"
    exit /b 1
)
echo PyInstaller done >> "%LOG%"

if exist "%SRC_DIR%build_tmp" rmdir /s /q "%SRC_DIR%build_tmp"
if exist "%SRC_DIR%NWriting.spec" del /q "%SRC_DIR%NWriting.spec"

echo [5/5] Inno Setup... >> "%LOG%"
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"
%ISCC% "%SRC_DIR%setup.iss" >> "%LOG%" 2>&1
if errorlevel 1 (
    echo FAILED: Inno Setup >> "%LOG%"
    exit /b 1
)

echo BUILD COMPLETE >> "%LOG%"
exit /b 0
