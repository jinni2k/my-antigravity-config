# oh-my-agent 설정 복원 및 동기화 스크립트 (Pull)
# 이 스크립트는 GitHub의 최신 설정들을 가져오고, 누락된 스킬 및 연동 설정을 복원합니다.

# 1. 작업 디렉토리 설정 및 에러 정책
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptDir

Write-Host "🛸 [OMA SYNC] 설정 복원 및 동기화를 시작합니다..." -ForegroundColor Cyan

# 2. Git 저장소 여부 확인
if (-not (Test-Path ".git")) {
    Write-Host "❌ .git 저장소 정보를 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "먼저 GitHub 원격 저장소를 이 폴더에 Clone 받으신 뒤 실행해 주세요." -ForegroundColor Yellow
    Exit 1
}

# 3. 원격 저장소로부터 변경 내용 가져오기 (Pull)
Write-Host "📥 GitHub 원격 저장소로부터 최신 설정을 내려받는 중(Git Pull)..." -ForegroundColor Gray
git pull origin main
if ($LASTEXITCODE -ne 0) {
    # main 브랜치 실패 시 master 재시도
    git pull origin master
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 원격 설정 가져오기 성공!" -ForegroundColor Green
} else {
    Write-Host "⚠️  원격 업데이트를 가져오지 못했습니다. 로컬 변경 사항과 충돌이 있는지 확인해 주세요." -ForegroundColor Yellow
}

# 4. oh-my-agent doctor 구동을 통한 스킬 복구
Write-Host ""
Write-Host "🩺 oh-my-agent 진단 및 스킬 복원을 시작합니다..." -ForegroundColor Cyan
Write-Host "💡 안내: 누락된 32개 스킬 복원 질문이 나오면 엔터(Enter)를 입력해 주시면 됩니다." -ForegroundColor Yellow
Write-Host "------------------------------------------------------------" -ForegroundColor Gray

# 사용자 환경에서 직접 doctor 명령을 인터랙티브하게 제어할 수 있도록 프로세스를 띄웁니다.
# (스크립트 실행 중 터미널 입출력을 직접 전달받기 위해 Start-Process 대신 Call operator '&' 사용)
$ErrorActionPreference = "Continue" # doctor는 인터랙티브 중지 시 에러를 던질 수 있으므로 예외완화
& oh-my-agent doctor

Write-Host "------------------------------------------------------------" -ForegroundColor Gray
Write-Host "✅ 모든 글로벌 동기화 절차가 끝났습니다." -ForegroundColor Green
Write-Host "개별 개발 프로젝트 폴더에서 동일한 지침을 활성화하려면, 프로젝트 폴더를 열고 다음 명령을 실행해 주세요:" -ForegroundColor Gray
Write-Host "👉   oh-my-agent link" -ForegroundColor Cyan
