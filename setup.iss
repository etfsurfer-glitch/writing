; ============================================================
; N Writing 블로그 자동화  —  Inno Setup 설치 스크립트
; ============================================================

#define AppName      "N Writing 블로그 자동화"
#define AppVersion   "1.25"
#define AppPublisher "runto.online"
#define AppExeName   "NWriting.exe"
#define BuildDir     "build_out\NWriting"

[Setup]
AppId={{A3F2B1C4-9E7D-4F8A-B2C3-1D5E6F7A8B9C}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://runto.online/
DefaultDirName={autopf}\NWriting
DefaultGroupName={#AppName}
OutputDir=release
OutputBaseFilename=NWriting_v{#AppVersion}_Setup
VersionInfoVersion={#AppVersion}.0.0
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
; ── 관리자 권한 필수 ──────────────────────────────────────
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=
; ── 아이콘 ───────────────────────────────────────────────
; SetupIconFile=assets\icon.ico
; ── 기타 ─────────────────────────────────────────────────
DisableProgramGroupPage=yes
DisableWelcomePage=no
ShowLanguageDialog=no
LanguageDetectionMethod=none
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
CloseApplications=yes
RestartIfNeededByRun=no

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Files]
; PyInstaller --onedir 출력 폴더 전체 포함
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; 바탕화면 바로가기
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; \
      WorkingDir: "{app}"; Comment: "{#AppName} v{#AppVersion}"
; 시작 메뉴
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"; \
      WorkingDir: "{app}"
Name: "{group}\제거"; Filename: "{uninstallexe}"

[Run]
; ── Playwright Chromium 브라우저 설치 (최초 1회, 필수) ──────
; PLAYWRIGHT_BROWSERS_PATH 를 _internal 안으로 지정해야 앱이 찾을 수 있음
Filename: "cmd.exe"; \
    Parameters: "/C set ""PLAYWRIGHT_BROWSERS_PATH=0"" && ""{app}\_internal\playwright\driver\node.exe"" ""{app}\_internal\playwright\driver\package\cli.js"" install chromium"; \
    WorkingDir: "{app}\_internal\playwright\driver\package"; \
    StatusMsg: "Playwright 브라우저 설치 중... (시간이 걸릴 수 있습니다)"; \
    Flags: runhidden waituntilterminated

[Code]
{ 설치 완료(Finish) 페이지 문구 커스터마이징 }
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    WizardForm.FinishedHeadingLabel.Caption := '설치가 완료되었습니다!';
    WizardForm.FinishedLabel.Caption :=
      '{#AppName} v{#AppVersion} 설치가 성공적으로 완료되었습니다.' + #13#10 + #13#10 +
      '▶  바탕화면의 [N Writing 블로그 자동화] 아이콘을' + #13#10 +
      '   직접 클릭하여 프로그램을 실행해주세요.' + #13#10 + #13#10 +
      '※ 시작 메뉴에서도 실행하실 수 있습니다.' + #13#10 +
      '※ 처음 실행 시 관리자 권한 확인 창이 나타날 수 있습니다.';
  end;
end;
