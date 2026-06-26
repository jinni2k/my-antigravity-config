# oh-my-agent 설정 백업 스크립트 (Push)
# 이 스크립트는 로컬의 변경된 핵심 설정 파일들을 Git에 커밋하고 GitHub 원격 저장소에 업로드합니다.

# 1. 실행 정책 확인 및 작업 디렉토리 설정
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptDir

Write-Host "🛸 [OMA SYNC] 설정 백업 및 동기화 프로세스를 시작합니다..." -ForegroundColor Cyan

# 2. Git 저장소 여부 확인
if (-not (Test-Path ".git")) {
    Write-Host "⚠️  로컬 .git 저장소가 초기화되지 않았습니다." -ForegroundColor Yellow
    Write-Host "먼저 'git init'을 실행하고 원격 저장소를 연결해 주세요." -ForegroundColor Yellow
    Exit 1
}

# 3. GitHub 원격 저장소(Remote) 설정 여부 확인
$RemoteCheck = git remote
if (-not $RemoteCheck) {
    Write-Host "⚠️  연결된 GitHub 원격 저장소가 없습니다." -ForegroundColor Yellow
    Write-Host "예: git remote add origin <GitHub_레포지토리_주소>" -ForegroundColor Yellow
    Exit 1
}

# 4. 파일 추가 단계 (규칙상 'git add -A' 대신 개별 파일/경로 명시)
Write-Host "📦 변경된 설정 파일들을 추가하는 중..." -ForegroundColor Gray
git add mcp.json
git add oma-config.yaml
git add .gitignore
git add README.md
git add sync-push.ps1
git add sync-pull.ps1
if (Test-Path "rules") { git add rules/ }
if (Test-Path "workflows") { git add workflows/ }

# 5. 커밋 수행 (현재 날짜/시간 스탬프 활용)
$CurrentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$CommitMessage = "chore(config): Sync settings on $CurrentDate"

Write-Host "💾 커밋 생성 중: $CommitMessage" -ForegroundColor Gray
$CommitResult = git commit -m $CommitMessage 2>&1

if ($CommitResult -match "nothing to commit, working tree clean") {
    Write-Host "✅ 변경 사항이 없습니다. 작업 트리가 깨끗합니다." -ForegroundColor Green
} else {
    Write-Host "🚀 GitHub 원격 저장소로 업로드(Push) 중..." -ForegroundColor Gray
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        # main 브랜치가 아닐 경우 master 브랜치로 백업 시도
        Write-Host "⚠️  main 브랜치 푸시 실패. master 브랜치로 재시도합니다..." -ForegroundColor Yellow
        git push origin master
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 설정 백업 및 동기화가 성공적으로 완료되었습니다!" -ForegroundColor Green
    } else {
        Write-Host "❌ GitHub 푸시 과정에서 에러가 발생했습니다. 네트워크 및 SSH/자격증명 설정을 확인해 주세요." -ForegroundColor Red
    }
}
