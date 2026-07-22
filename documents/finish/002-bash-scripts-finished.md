# 002 - 部署腳本 Windows → Linux 轉換 階段完成報告

> 對應計畫文件：`documents/002-bash-scripts.md`
> 對應現況分析：`documents/project-arc.md`
> 本文件提供給下一個任務的 Agent 作為交接參考。

## 1. 完成狀態

`documents/002-bash-scripts.md` 第 4 節「實作步驟流程」5 個步驟已全部完成：

1. 決策點已確認：`.bat` 與 `.sh` **並存**；Google Drive 大檔案下載問題**維持原邏輯**，不引入新套件/新行為
2. 新增 `config.sh`：移植 `FILE_ID`／`DB_PATH`／`DOWNLOAD_URL`／`GIT_USER_NAME`／`GIT_USER_EMAIL`，`%~dp0` 改用 `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
3. 新增 `build_venv.sh`：`python3` 存在性檢查、`.venv` 建立（`.venv/bin/python`）、pip 升級與 `requirement.txt` 安裝，移除 `pause`，錯誤時 `exit 1`
4. 新增 `download_db.sh`：`source config.sh`、`curl` 優先、無 `curl` 則 fallback `wget`，取代原本的 PowerShell fallback
5. 三個新 `.sh` 檔已 `chmod +x`（`rwxr-xr-x`），尚未 `git add`；由於執行位元已直接寫入檔案系統，之後正常 `git add` 即會保留該權限，不需額外跑 `git update-index --chmod=+x`

## 2. 檔案異動清單

新增：
- `config.sh`
- `build_venv.sh`
- `download_db.sh`
- `documents/project-arc.md`（現況分析）
- `documents/002-bash-scripts.md`（轉換計畫）

未異動（依決策點保留）：
- `config.bat`、`build_venv.bat`、`download_db.bat`（Windows 本機開發沿用，往後修改任一版本時需同步另一版本，目前沒有自動化機制確保兩者同步，屬於已知手動維運成本）
- `setup_git.bat`（本次範圍外，仍只有 Windows 版本，依賴 `config.bat` 而非 `config.sh`）

## 3. 測試方式與結果

在 WSL（Ubuntu，真正的 Linux 環境）驗證，而非僅在 Windows 上做語法檢查：

| 驗證項目 | 結果 |
| --- | --- |
| 三個腳本語法檢查（`bash -n`） | 通過 |
| `config.sh` 參數讀取／`SCRIPT_DIR` 解析 | 通過 |
| `download_db.sh` 端對端下載（curl、檔案檢查、成功訊息） | 通過 |
| `build_venv.sh` 存在性檢查與錯誤處理路徑 | 通過（`.venv` 建立失敗時正確印出錯誤並 `exit 1`） |
| `build_venv.sh` 完整 happy path（`pip install -r requirement.txt`） | **未驗證**——該台 WSL 缺少 `python3-venv` 套件，使用者選擇不安裝以避免異動其系統環境，因此沒有跑到 pip 安裝那段 |

**建議下一階段**：在一台已具備 `python3-venv`（或等效套件）的乾淨 Linux 環境（例如實際遠端主機、或另一台 Docker 容器）補做 `build_venv.sh` 完整 happy path 測試，確認套件安裝與版本符合 `requirement.txt`。

## 4. 意外事件與經驗教訓（重要，供下次測試參考）

測試 `download_db.sh` 時，原計畫是在 WSL 內一份隔離的暫存目錄（`/tmp/sh_test`）執行，避免影響專案實際的 `db.sqlite3`。但發生以下連鎖狀況：

1. 前一次 `wsl -e bash -lc` 呼叫結束後，WSL 的輕量 VM 被關閉，`/tmp`（tmpfs）內容被清空，導致 `/tmp/sh_test` 在下一次呼叫時已不存在。
2. 腳本中 `cd /tmp/sh_test` 失敗，但因為沒有搭配 `set -e` 或 `|| exit 1`，執行沒有中止。
3. `wsl.exe` 從 Windows 端某個目錄下呼叫時，會預設把工作目錄帶入對應的 `/mnt/...` 路徑；剛好那正是**專案的實際目錄**。
4. 於是 `./download_db.sh` 實際上是對著**真正的專案目錄**執行，讀取到真正的 `config.sh`，並把 Google Drive 下載下來的檔案寫進了**真正的 `db.sqlite3`**，覆蓋掉先前為了驗證 Markdown 模組所建立的測試 superuser（`blogadmin`）與測試文章。

**結果與處理**：`db.sqlite3` 已被 `.gitignore` 排除、原本就是可被 `download_db` 腳本重新產生的「種子資料」性質，使用者確認**保持現狀**（也就是現在資料庫內容為 Google Drive 上的種子資料庫），未做任何還原動作。

**經驗教訓（給下一個 Agent）**：
- 之後若要在 WSL / 容器等外部環境測試「會寫入檔案」的腳本，**每個目錄操作都要搭配 `set -e` 或明確檢查回傳碼**，一旦 `cd` 失敗就必須中止，不能讓後續指令在錯誤的目錄下繼續執行。
- 不要假設 `/tmp` 或其他暫存路徑會在多次 `wsl -e` 呼叫之間持續存在；每次呼叫前最好重新建立暫存目錄，或在同一個 `wsl` 呼叫（同一個 shell session）內一次做完「建立暫存目錄 → 複製 → 執行 → 驗證」，不要分成多次個別呼叫。
- 測試任何會下載/覆寫檔案的腳本前，建議先確認目標路徑，或先備份既有檔案（例如 `cp db.sqlite3 db.sqlite3.bak`），再執行測試。

## 5. 已知限制／後續待辦

- `build_venv.sh` 尚未在具備 `python3-venv` 的環境完整跑過 happy path（見第 3 節）。
- `.bat` 與 `.sh` 並存，內容需人工同步，目前沒有自動化檢查兩者是否一致。
- Google Drive 大檔案下載限制（可能下載到警告頁而非實際檔案）維持原狀未修正，日後若種子資料庫變大，`download_db.sh`／`download_db.bat` 可能都需要改用 `gdown` 或其他機制。
- `setup_git.bat` 仍只有 Windows 版本，若要在 Linux 遠端也自動設定 git 使用者資訊，需要另外規劃 `setup_git.sh`（本次範圍外）。
- `db.sqlite3` 目前內容為 Google Drive 種子資料庫（非測試資料），文字顯示有亂碼疑似編碼問題，若後續要在此資料上開發／展示功能，建議先確認資料庫的實際字元編碼設定。
