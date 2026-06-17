# Antigravity IDE 환경 동기화 (Environment Sync)

이 저장소는 Antigravity IDE의 글로벌 설정 파일, 에이전트 지침서, 그리고 MCP(Model Context Protocol) 서버 환경을 여러 컴퓨터 간에 동일하게 동기화하고 관리하기 위한 설정 저장소입니다.

## 📦 포함된 주요 파일

*   **`GEMINI.md`**: 전역 에이전트 지침, 컨벤션 및 순차적 사고(Sequential Thinking) 규칙이 정의된 파일입니다. (`$HOME\.gemini\GEMINI.md`에 위치)
*   **`setup.ps1`**: 윈도우 환경에서 설정을 자동으로 배포하고 MCP 서버를 복원해 주는 PowerShell 자동화 스크립트입니다.

---

## 🚀 1-클릭 환경 복원 및 단축 명령어 등록 (Restore & Alias)

새로운 Windows 컴퓨터에서 **PowerShell**을 열고 아래의 단축 명령어를 실행하면, 모든 패키지 설치와 MCP 설정이 완료되고, 다음부터 간편하게 쓸 수 있는 단축어 **`sync-ag`**가 자동으로 프로필에 등록됩니다.

```powershell
iex(irm "https://raw.githubusercontent.com/jinni2k/my-antigravity-config/master/setup.ps1?v=$(Get-Random)")
```

### ⚡ 이후 동기화 업데이트 방법 (매우 간편)
한 번 설치가 완료된 후에는 파워셸에서 단 **7글자**만 치면 즉시 최신 지침과 설정을 동기화합니다.
```powershell
sync-ag
```

### ⚙️ `setup.ps1` 스크립트가 수행하는 작업:
1.  시스템에 안티그래비티 CLI(`agy`)가 설치되어 있지 않다면 공식 권장 스크립트를 통해 자동으로 설치합니다.
2.  `C:\Users\[사용자명]\.gemini\` 디렉토리를 생성하고 `GEMINI.md` 파일을 배치합니다.
3.  글로벌 MCP 패키지(`@modelcontextprotocol/server-sequential-thinking` 및 `oh-my-agent`)를 글로벌 npm으로 자동 설치합니다.
4.  기존 설정을 유지하면서 전역 설정 파일(`%APPDATA%\Code\User\globalSettings.json`)의 `mcpServers`에 `sequential-thinking` 설정을 안전하게 등록/갱신합니다.

---

## 🔄 설정 업데이트 및 동기화 방법 (Sync)

`GEMINI.md` 규칙을 수정하거나 설정을 변경했을 때, 이를 깃허브에 반영하고 다른 컴퓨터로 가져오는 방법입니다.

### 1. 현재 컴퓨터에서 수정 후 업로드하기 (Push)
설정이 저장된 폴더(`antigravity-config`)에서 작업을 마친 후 아래 명령어를 실행하여 깃허브에 올립니다.
*(GitHub CLI(`gh`)가 설치되어 있다면 편리하게 인증할 수 있습니다.)*

```bash
# 변경된 설정 파일 추가 및 커밋
git add .
git commit -m "Update GEMINI.md rules & settings"

# 깃허브 원격 저장소로 업로드
git push origin master
```

### 2. 다른 컴퓨터에서 최신 설정으로 갱신하기 (Pull / Run)
*   **저장소를 Clone 해둔 경우**:
    ```bash
    git pull origin master
    # 로컬에서 setup 스크립트 실행 (PowerShell)
    .\setup.ps1
    ```
*   **저장소 없이 1-클릭 명령어로 갱신할 경우**:
    위의 **[1-클릭 환경 복원 및 단축 명령어 등록]**에 있는 단축 명령어를 재실행하거나, 프로필이 등록된 후라면 터미널에 단순히 `sync-ag`를 입력하여 최신 지침과 설정을 덮어쓸 수 있습니다.

---

## 🛠️ GitHub CLI (gh) 팁
GitHub 인증을 간편하게 처리하고 싶다면, 터미널에서 `gh auth login`을 실행하여 웹 브라우저를 통해 로그인하면 편리하게 원격 저장소 권한을 획득할 수 있습니다.
```bash
gh auth login
```

