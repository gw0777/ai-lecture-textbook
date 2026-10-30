# 손으로 배우는 AI — 교재 실행 도구
#
# 교재 폴더의 00~04 실행 파일(.bat)이 이 스크립트를 불러 씁니다.
# 직접 실행할 때: powershell -ExecutionPolicy Bypass -File scripts\textbook.ps1 menu
#
#   menu      시작 메뉴
#   preview   교재 미리보기 (내 컴퓨터에서 교재 사이트 열기)
#   offline   오프라인 교재 만들기 (바탕화면의 '손으로배우는AI_오프라인교재' 폴더, -OutDir 로 바꿀 수 있음)
#   tools     수업 도구 열기
#   prompts   프롬프트 모음(부록 B) 새로 만들기
#   github    GitHub에 올리기
#
# -NoPause 를 붙이면 끝날 때 Enter를 기다리지 않습니다 (자동 실행용).

param(
    [ValidateSet('menu', 'preview', 'offline', 'tools', 'prompts', 'github')]
    [string]$Action = 'menu',
    [switch]$NoPause,
    [string]$OutDir
)

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
$Host.UI.RawUI.WindowTitle = '손으로 배우는 AI'

# 도구(MkDocs)는 교재 폴더가 아니라 짧은 고정 위치에 설치합니다.
# 교재 폴더가 바탕화면·OneDrive 깊은 곳에 있어도 Windows 경로 길이 제한에 걸리지 않게 하기 위해서입니다.
# 지우고 다시 설치하려면 이 폴더를 지우면 됩니다.
$Venv = Join-Path $env:LOCALAPPDATA 'ai-lecture-textbook\venv'
$Py = Join-Path $Venv 'Scripts\python.exe'
$MkDocs = Join-Path $Venv 'Scripts\mkdocs.exe'

function Say([string]$Text, [string]$Color = 'Gray') {
    Write-Host $Text -ForegroundColor $Color
}

function Wait-Enter([string]$Message) {
    if ($NoPause) { return }
    Write-Host ''
    [void](Read-Host $Message)
}

function Find-Python {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        & py -3 --version *> $null
        if ($LASTEXITCODE -eq 0) { return , @('py', '-3') }
    }
    if (Get-Command python -ErrorAction SilentlyContinue) {
        & python --version *> $null
        if ($LASTEXITCODE -eq 0) { return , @('python') }
    }
    return $null
}

function Install-Tools {
    if (Test-Path $MkDocs) { return $true }
    Say ''
    Say '[준비] 처음 실행이라 필요한 도구를 설치합니다. (1~3분, 처음 한 번만)' Cyan
    $python = Find-Python
    if (-not $python) {
        Say '[오류] Python을 찾지 못했습니다.' Red
        Say '       https://www.python.org/downloads/ 에서 설치한 뒤 다시 실행하세요.'
        Say '       설치 첫 화면 아래쪽 "Add python.exe to PATH" 를 꼭 체크하세요.'
        return $false
    }
    $exe = $python[0]
    $pre = @($python | Select-Object -Skip 1)
    & $exe @pre -m venv $Venv | Out-Host
    if ($LASTEXITCODE -eq 0) {
        & $Py -m pip install --disable-pip-version-check -q -r requirements.txt | Out-Host
    }
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $MkDocs)) {
        Say '[오류] 설치 중 문제가 생겼습니다. 인터넷 연결을 확인하고 다시 실행하세요.' Red
        Say "       그래도 안 되면 이 폴더를 지운 뒤 다시 실행해 보세요: $Venv"
        return $false
    }
    Say '[준비] 설치가 끝났습니다.' Green
    return $true
}

function Update-Prompts {
    & $Py scripts\collect_prompts.py | Out-Host
}

function Start-Preview {
    if (-not (Install-Tools)) { return }
    Update-Prompts
    Say ''
    Say '============================================================' DarkCyan
    Say '  교재 미리보기를 시작합니다. 잠시 뒤 브라우저가 열립니다.' Cyan
    Say '  주소: http://127.0.0.1:8000'
    Say '  원고(.md)를 고쳐 저장하면 브라우저에 바로 반영됩니다.'
    Say '  끝내려면 이 창을 닫거나 Ctrl+C 를 누르세요.'
    Say '  (MkDocs 2.0 관련 노란 안내 문구는 무시해도 됩니다)' DarkGray
    Say '============================================================' DarkCyan
    & $MkDocs serve -a 127.0.0.1:8000 --open
    if ($LASTEXITCODE -ne 0) {
        Say '[오류] 미리보기를 시작하지 못했습니다. 이미 미리보기 창이 열려 있다면 그 창을 닫고 다시 실행하세요.' Red
    }
}

function New-OfflineBook {
    if (-not (Install-Tools)) { return }
    Update-Prompts
    # 바탕화면처럼 짧은 경로에 만들어야 Windows 경로 길이 제한에 걸리지 않고, 찾기도 쉽습니다.
    $out = $OutDir
    if (-not $out) { $out = Join-Path ([Environment]::GetFolderPath('Desktop')) '손으로배우는AI_오프라인교재' }
    Say ''
    Say "[만들기] 오프라인 교재를 만듭니다: $out" Cyan
    & $MkDocs build -f mkdocs.offline.yml -q -d $out
    if ($LASTEXITCODE -ne 0) {
        Say '[오류] 교재를 만드는 중 문제가 생겼습니다. 위에 적힌 WARNING 줄의 파일을 확인하세요.' Red
        return
    }
    Say ''
    Say "[완료] 오프라인 교재 폴더가 만들어졌습니다: $out" Green
    Say '       폴더를 통째로 압축하거나 USB에 담아 나눠 주면,'
    Say '       받은 사람은 index.html 을 더블클릭해 교재를 볼 수 있습니다.'
    Say '       (흐름도 그림은 인터넷이 연결되어 있을 때 표시됩니다)' DarkGray
    if (-not $NoPause) { Start-Process (Join-Path $out 'index.html') }
}

function Open-Tools {
    $examples = Join-Path $Root 'docs\examples'
    while ($true) {
        Clear-Host
        Say '============================================================' DarkCyan
        Say '  수업 도구 열기  (설치나 인터넷 없이도 열립니다)' Cyan
        Say '============================================================' DarkCyan
        Say '  1. 입구 쇼크 해부도              (01장)'
        Say '  2. Prompt Continuity Lab        (11장)'
        Say '  3. 모션그래픽 홍보영상 템플릿     (12장)'
        Say '  4. 예제 폴더 열기'
        Say '  0. 돌아가기'
        Say ''
        $sel = Read-Host '번호를 입력하고 Enter'
        if ($null -eq $sel) { return }   # 입력이 끝났으면(창 닫힘 등) 반복하지 않고 끝냅니다
        switch ($sel) {
            '1' { Start-Process (Join-Path $examples 'entry-shock-anatomy.html') }
            '2' { Start-Process (Join-Path $examples 'prompt-continuity-lab.html') }
            '3' { Start-Process (Join-Path $examples 'motion-promo-template.html') }
            '4' { Start-Process explorer.exe $examples }
            default { return }
        }
    }
}

function Publish-GitHub {
    Say '============================================================' DarkCyan
    Say '  교재를 GitHub에 올립니다.' Cyan
    Say '  먼저 github.com 에서 README 없이 빈 저장소를 만들어 두세요. (부록 F 6장)'
    Say '============================================================' DarkCyan
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Say '[오류] Git이 설치되어 있지 않습니다.' Red
        Say '       https://git-scm.com/download/win 에서 설치하거나, GitHub Desktop을 사용하세요. (부록 F 6장)'
        return
    }

    # 1. 수정 기록에 남길 이름·이메일 (처음 한 번)
    $email = git config user.email 2>$null
    if (-not $email) {
        Say ''
        Say '[설정] 수정 기록에 남길 이름과 이메일을 한 번만 등록합니다.' Cyan
        $name = Read-Host '이름'
        if (-not $name) { Say '[취소] 아무것도 올리지 않았습니다.' Yellow; return }
        $mail = Read-Host '이메일'
        if (-not $mail) { Say '[취소] 아무것도 올리지 않았습니다.' Yellow; return }
        git config user.name $name
        git config user.email $mail
    }

    # 2. GitHub 저장소 연결 (처음 한 번)
    $origin = git remote get-url origin 2>$null
    if (-not $origin) {
        Say ''
        Say '[연결] GitHub 저장소 주소를 붙여 넣으세요.' Cyan
        Say '       예: https://github.com/내아이디/ai-lecture-textbook.git'
        $url = "$(Read-Host '주소')".Trim()
        if (-not $url) { Say '[취소] 아무것도 올리지 않았습니다.' Yellow; return }
        git remote add origin $url
        if ($LASTEXITCODE -ne 0) { Say '[오류] 저장소를 연결하지 못했습니다.' Red; return }
        $origin = $url
    }

    # 3. 아직 기록하지 않은 수정이 있으면 기록(커밋)
    git add -A
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        Say ''
        Say '[기록] 아직 기록하지 않은 수정이 있습니다.' Cyan
        $msg = Read-Host '무엇을 고쳤는지 한 줄로 적어 주세요'
        if (-not $msg) { $msg = '교재 내용 수정' }
        git commit -q -m $msg
        if ($LASTEXITCODE -ne 0) { Say '[오류] 수정 내용을 기록하지 못했습니다.' Red; return }
    }

    # 4. 올리기
    Say ''
    Say "[확인] 이 저장소로 올립니다: $origin" Yellow
    $ok = Read-Host '계속할까요? Y 또는 N'
    if ($ok -notmatch '^[Yy]') { Say '[취소] 아무것도 올리지 않았습니다.' Yellow; return }
    Say '[올리기] GitHub 로그인 창이 뜨면 로그인해 주세요...' Cyan
    git push -u origin main
    if ($LASTEXITCODE -ne 0) {
        Say ''
        Say '[오류] 올리지 못했습니다. 자주 있는 원인:' Red
        Say '       - 저장소 주소가 틀렸다: 교재 폴더에서 git remote set-url origin 올바른주소 로 고칩니다.'
        Say '       - 저장소를 만들 때 README를 추가했다: README 없이 빈 저장소로 다시 만드세요.'
        Say '       - 로그인 창을 닫았다: 다시 실행해 로그인하세요.'
        return
    }
    Say ''
    Say '[완료] 올렸습니다.' Green
    Say '       처음 올렸다면 GitHub 저장소의 Settings - Pages - Source 를 "GitHub Actions" 로 바꿔 주세요.'
    Say '       몇 분 뒤 https://내아이디.github.io/ai-lecture-textbook/ 에서 교재가 열립니다.'
}

function Show-Menu {
    while ($true) {
        Clear-Host
        Say '============================================================' DarkCyan
        Say '  손으로 배우는 AI - 교재 시작 메뉴' Cyan
        Say '============================================================' DarkCyan
        Say '  1. 교재 미리보기             내 컴퓨터에서 교재 사이트 열기'
        Say '  2. 오프라인 교재 만들기       USB·압축으로 나눠 줄 교재'
        Say '  3. 수업 도구 열기             해부도 · 프롬프트 연출 · 모션그래픽'
        Say '  4. 프롬프트 모음 새로 만들기   부록 B를 각 장에서 다시 모으기'
        Say '  5. GitHub에 올리기'
        Say '  6. 교재 폴더 열기'
        Say '  0. 끝내기'
        Say ''
        Say '  처음 1·2·4번을 고르면 필요한 도구를 자동으로 설치합니다. (1~3분)' DarkGray
        Say ''
        $sel = Read-Host '번호를 입력하고 Enter'
        if ($null -eq $sel) { return }   # 입력이 끝났으면(창 닫힘 등) 반복하지 않고 끝냅니다
        switch ($sel) {
            '1' { Start-Preview; Wait-Enter 'Enter 키를 누르면 메뉴로 돌아갑니다' }
            '2' { New-OfflineBook; Wait-Enter 'Enter 키를 누르면 메뉴로 돌아갑니다' }
            '3' { Open-Tools }
            '4' { if (Install-Tools) { Update-Prompts }; Wait-Enter 'Enter 키를 누르면 메뉴로 돌아갑니다' }
            '5' { Publish-GitHub; Wait-Enter 'Enter 키를 누르면 메뉴로 돌아갑니다' }
            '6' { Start-Process explorer.exe $Root }
            default { return }
        }
    }
}

switch ($Action) {
    'menu'    { Show-Menu }
    'preview' { Start-Preview; Wait-Enter 'Enter 키를 누르면 창이 닫힙니다' }
    'offline' { New-OfflineBook; Wait-Enter 'Enter 키를 누르면 창이 닫힙니다' }
    'tools'   { Open-Tools }
    'prompts' { if (Install-Tools) { Update-Prompts }; Wait-Enter 'Enter 키를 누르면 창이 닫힙니다' }
    'github'  { Publish-GitHub; Wait-Enter 'Enter 키를 누르면 창이 닫힙니다' }
}
