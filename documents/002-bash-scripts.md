# 002 - 部署腳本 Windows → Linux 轉換計畫

> 對應現況分析：`documents/project-arc.md`
> 本文件僅為規劃，尚未進行任何程式碼修改。

## 1. 目標與範圍

- 將 `build_venv.bat`、`config.bat`、`download_db.bat` 三支 Windows 批次檔，轉換為可在 Linux 遠端部署環境執行的 Shell 腳本（`.sh`）。
- 維持三者原本的呼叫關係與職責劃分：`config.sh` 提供共用參數，被 `download_db.sh` 讀取；`build_venv.sh` 為獨立腳本。
- 範圍不包含：`setup_git.bat`（依賴 `config.bat` 但本次未列入轉換）、`DjangoBlog/settings.py` 的部署設定（`DEBUG`/`ALLOWED_HOSTS`/`SECRET_KEY`）、CI/CD 或容器化設定。這些在 `project-arc.md` 第 4 節已列為後續待辦，如需納入請另立計畫。

## 2. 決策點（已確認）

- **是否保留原本的 `.bat` 檔案？** → **保留並存**。新增對應的 `.sh` 檔案（`config.sh`、`build_venv.sh`、`download_db.sh`），Windows 本機開發沿用 `.bat`，Linux 遠端部署改用 `.sh`，兩者內容需保持一致。
- **Google Drive 大檔案下載限制**：原 Windows 版 `download_db.bat` 對於超過掃描門檻的大檔案會下載到警告頁面而非實際檔案，這是既有問題。→ **先維持原邏輯**，本次僅做語法轉換（bat→sh），不引入 `gdown` 或 HTML 偵測等新行為，維持與現有 Windows 版本一致的行為。

## 3. 轉換對照表

| 項目 | Windows (`.bat`) | Linux (`.sh`) |
| --- | --- | --- |
| 腳本所在目錄 | `%~dp0` | `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` |
| 變數設定 | `set "VAR=value"` | `VAR="value"` |
| 載入共用參數 | `call config.bat` | `source "$SCRIPT_DIR/config.sh"` |
| 延遲展開 | `setlocal enabledelayedexpansion` + `!VAR!` | 不需要，Shell 變數即時展開 |
| venv 直譯器路徑 | `.venv\Scripts\python.exe` | `.venv/bin/python` |
| 判斷指令是否存在 | `where curl.exe` | `command -v curl` |
| 錯誤碼判斷 | `if %errorlevel% neq 0` | `if [ $? -ne 0 ]` 或直接 `set -e` |
| 互動暫停 | `pause` | 移除（部署腳本應可無人值守執行），或改為僅在偵測到互動終端機時才暫停 |
| PowerShell fallback 下載 | `Invoke-WebRequest` | `wget`（`curl` 幾乎必然存在於 Linux，仍可保留 `wget` 作為 fallback） |

## 4. 實作步驟流程

> 每個步驟完成後會先暫停，待確認修改內容無誤後再進行下一步（沿用本專案既有工作模式）。

1. **建立 `config.sh`**
   - 移植 `FILE_ID`、`DB_PATH`、`DOWNLOAD_URL`、`GIT_USER_NAME`、`GIT_USER_EMAIL` 等參數。
   - `DB_PATH` 改用 `$SCRIPT_DIR/db.sqlite3`。
2. **建立 `build_venv.sh`**
   - 檢查 `python3` 是否存在（若無則印出錯誤並 `exit 1`）。
   - 若 `.venv` 不存在則 `python3 -m venv .venv`。
   - 升級 pip、安裝 `requirement.txt`，錯誤時明確 `exit` 非 0。
3. **建立 `download_db.sh`**
   - `source config.sh`。
   - 優先用 `curl -L`，找不到則 fallback 用 `wget`；皆無則報錯。
   - 下載後檢查檔案是否存在／是否為有效檔案（依第 2 節決策決定是否加上 HTML 警告頁偵測）。
4. **設定執行權限**
   - `chmod +x config.sh build_venv.sh download_db.sh`。
   - 提醒：由 Windows 建立並以 Git 提交的檔案，`clone` 到 Linux 後預設不會有執行位元，需另外用 `git update-index --chmod=+x <file>` 記錄執行權限到版控中，否則遠端第一次拉下來仍需手動 `chmod +x`。
5. **（依決策點）處理／保留原 `.bat` 檔案**
   - 依步驟 2 決策點的結論，決定是否保留 `.bat` 並列出兩者對應關係於 README 或註解中，避免日後修改其中一份卻忘了同步另一份。
6. **手動測試與驗收**
   - 在 Linux 環境（WSL、Docker 容器或實際遠端主機）依序執行 `build_venv.sh`、`download_db.sh`，確認：
     - `.venv` 建立成功且套件安裝完成
     - `db.sqlite3` 下載成功且可被 Django 讀取（`manage.py check`／`runserver` 正常）
   - 確認腳本在非互動式（無 TTY，例如 CI/部署流程直接呼叫）環境下也能順利執行到底，不會卡在等待輸入的地方。

## 5. 驗收標準

- [ ] `config.sh`／`build_venv.sh`／`download_db.sh` 三支腳本可在乾淨的 Linux 環境從零執行成功。
- [ ] 腳本行為（成功/失敗訊息、結束碼）與原 Windows 版本邏輯對應一致（除第 2 節決策點註明的差異外）。
- [ ] 腳本具備執行權限，且該權限有被版控記錄（或部署流程中有對應的 `chmod` 步驟）。
- [ ] 不需要人工互動（無 `pause` 等待）即可在無 TTY 的部署流程中完整執行。
