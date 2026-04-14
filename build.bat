@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo.
echo ============================================================
echo   N Writing 블로그 자동화  —  빌드 스크립트  v1.21
echo ============================================================
echo.

:: ── 경로 설정 ──────────────────────────────────────────────
set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
set SRC_DIR=%~dp0
set OBF_DIR=%SRC_DIR%obf_src
set BUILD_DIR=%SRC_DIR%build_out
set RELEASE_DIR=%SRC_DIR%release

:: ── 사전 청소 ──────────────────────────────────────────────
echo [1/5] 이전 빌드 정리 중...
if exist "%OBF_DIR%"   rmdir /s /q "%OBF_DIR%"
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%SRC_DIR%dist" rmdir /s /q "%SRC_DIR%dist"
if exist "%SRC_DIR%__pycache__" rmdir /s /q "%SRC_DIR%__pycache__"
echo     완료

:: ── PyArmor 난독화 ─────────────────────────────────────────
echo.
echo [2/5] PyArmor 난독화 중...
cd /d "%SRC_DIR%"
pyarmor gen --recursive --output "%OBF_DIR%" ^
    app.py stealth_utils.py auth.py tracker.py login_ui.py updater.py ^
    blog_collector.py blog_scraper.py blog_writer.py gemini_writer.py ^
    gemini_mamul_writer.py celebrity_gemini_writer.py celebrity_image_filter.py ^
    image_laundry.py ^
    add_text_to_image.py compress.py compress2.py mamul_writer.py naver_land_core.py
if errorlevel 1 (
    echo [오류] PyArmor 실패
    pause & exit /b 1
)
echo     완료

:: ── PyArmor 런타임 폴더 이름 확인 ────────────────────────
set RUNTIME_PKG=
for /d %%d in ("%OBF_DIR%\pyarmor_runtime_*") do (
    set RUNTIME_PKG=%%~nxd
)
if "%RUNTIME_PKG%"=="" (
    echo [오류] pyarmor_runtime 폴더를 찾을 수 없습니다.
    pause & exit /b 1
)
echo     런타임 패키지: %RUNTIME_PKG%

:: ── 비Python 에셋 복사 ────────────────────────────────────
echo.
echo [3/5] 에셋 복사 중...
xcopy /e /i /q "%SRC_DIR%prompts"           "%OBF_DIR%\prompts\"
xcopy /e /i /q "%SRC_DIR%background"        "%OBF_DIR%\background\"
xcopy /e /i /q "%SRC_DIR%cardnews_templates" "%OBF_DIR%\cardnews_templates\" 2>nul
copy /y "%SRC_DIR%version.txt"              "%OBF_DIR%\version.txt"
copy /y "%SRC_DIR%common.jpg"                "%OBF_DIR%\common.jpg"
echo     완료

:: ── PyInstaller 패키징 ────────────────────────────────────
echo.
echo [4/5] PyInstaller 패키징 중...
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
    --hidden-import stealth_utils ^
    --hidden-import auth ^
    --hidden-import tracker ^
    --hidden-import login_ui ^
    --hidden-import updater ^
    --hidden-import blog_collector ^
    --hidden-import blog_scraper ^
    --hidden-import blog_writer ^
    --hidden-import gemini_writer ^
    --hidden-import gemini_mamul_writer ^
    --hidden-import celebrity_gemini_writer ^
    --hidden-import celebrity_image_filter ^
    --hidden-import image_laundry ^
    --hidden-import add_text_to_image ^
    --hidden-import compress ^
    --hidden-import mamul_writer ^
    --hidden-import naver_land_core ^
    --hidden-import _tkinter ^
    --hidden-import tkinter ^
    --hidden-import tkinter.ttk ^
    --hidden-import tkinter.messagebox ^
    --hidden-import tkinter.filedialog ^
    --hidden-import tkinter.simpledialog ^
    --collect-all customtkinter ^
    --hidden-import requests ^
    --hidden-import playwright_stealth ^
    --hidden-import supabase ^
    --hidden-import google.genai ^
    --hidden-import PIL ^
    --hidden-import PIL.Image ^
    --hidden-import PIL.ImageDraw ^
    --hidden-import PIL.ImageFont ^
    --hidden-import PIL.ImageFilter ^
    --hidden-import PIL.ImageEnhance ^
    --hidden-import PIL.ImageTk ^
    --hidden-import compress2 ^
    --hidden-import openpyxl ^
    --hidden-import openpyxl.styles ^
    --hidden-import openpyxl.styles.fonts ^
    --hidden-import openpyxl.styles.fills ^
    --hidden-import numpy ^
    --hidden-import win32clipboard ^
    --hidden-import win32con ^
    --hidden-import win32api ^
    --hidden-import aiohttp ^
    --hidden-import bs4 ^
    --collect-all playwright ^
    --collect-all openpyxl ^
    "%OBF_DIR%\app.py"

if errorlevel 1 (
    echo [오류] PyInstaller 실패
    pause & exit /b 1
)
echo     완료

:: ── 빌드 임시파일 정리 ────────────────────────────────────
if exist "%SRC_DIR%build_tmp" rmdir /s /q "%SRC_DIR%build_tmp"
if exist "%SRC_DIR%NWriting.spec" del /q "%SRC_DIR%NWriting.spec"

:: ── Inno Setup 인스톨러 컴파일 ────────────────────────────
echo.
echo [5/5] Inno Setup 인스톨러 컴파일 중...
if not exist "%RELEASE_DIR%" mkdir "%RELEASE_DIR%"
%ISCC% "%SRC_DIR%setup.iss"
if errorlevel 1 (
    echo [오류] Inno Setup 컴파일 실패
    pause & exit /b 1
)

:: ── 완료 ──────────────────────────────────────────────────
echo.
echo ============================================================
echo   빌드 완료!
echo   인스톨러 위치: %RELEASE_DIR%\NWriting_v1.21_Setup.exe
echo ============================================================
echo.
echo   GitHub 릴리즈 업로드 절차:
echo   1. https://github.com/etfsurfer-glitch/writing/releases/new
echo   2. Tag: 1.21  /  Title: v1.21
echo   3. NWriting_v1.21_Setup.exe 첨부 후 Publish
echo.
pause
