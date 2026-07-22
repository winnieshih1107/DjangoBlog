# 專案結構分析（Project Architecture）

> 本文件為現況分析，未修改任何程式碼。目的是為了後續將 `build_venv.bat`、`config.bat`、`download_db.bat` 轉換為 Linux 用腳本（遠端部署）提供依據，詳細轉換步驟另見 `documents/002-bash-scripts.md`。

## 1. 專案概述

- 框架：Django 6.0，專案名稱 `DjangoBlog`
- 目前只有一個 app：`article`（文章模組，內容以 Markdown 儲存，透過 `django-markdownx` 提供後台 WYSIWYG 編輯與前台渲染，詳見 `documents/001-modules-plans.md` 與 `documents/finish/001-modules-finished.md`）
- 資料庫：SQLite（`db.sqlite3`，已被 `.gitignore` 排除，不進版控）
- 目前開發環境為 **Windows**：虛擬環境建置、資料庫下載、Git 設定皆以 `.bat`（Windows Batch）腳本撰寫，且 `.vscode/settings.json` 寫死 Windows 路徑

## 2. 目錄結構

```
DjangoBlog/
├── article/                      # 文章模組 app
│   ├── migrations/
│   │   ├── 0001_initial.py
│   │   └── 0002_alter_post_content.py
│   ├── templatetags/
│   │   ├── __init__.py
│   │   └── article_markdown.py   # 自訂 markdownify filter
│   ├── admin.py                  # MarkdownxModelAdmin 註冊 Post
│   ├── apps.py
│   ├── models.py                 # Post model（content 為 MarkdownxField）
│   ├── tests.py                  # 空白，尚無測試
│   ├── urls.py                   # list / detail 路由
│   └── views.py                  # index(list) / detail view
├── DjangoBlog/                   # 專案設定
│   ├── asgi.py
│   ├── settings.py               # DEBUG=True, ALLOWED_HOSTS=['*'], SECRET_KEY 明碼寫死
│   ├── urls.py
│   └── wsgi.py
├── TEMPLATES/                    # 樣板根目錄（settings.py 指定 BASE_DIR/'templates'，實際資料夾名稱大小寫需留意，見第 4 節風險）
│   ├── article/
│   │   ├── detail.html
│   │   └── list.html
│   ├── components/
│   │   ├── footer.html
│   │   └── header.html           # 已知含舊版除錯內容，見 finish 文件
│   └── base.html
├── documents/                    # 規劃／交接文件
│   ├── 001-modules-plans.md
│   └── finish/001-modules-finished.md
├── .vscode/settings.json         # 寫死 Windows 路徑 D:\DjangoBlog\.venv\Scripts\python.exe
├── build_venv.bat                # 【待轉換】建立 .venv 並安裝 requirement.txt
├── config.bat                    # 【待轉換】共用參數（Google Drive 檔案 ID、Git 使用者資訊）
├── download_db.bat               # 【待轉換】從 Google Drive 下載 db.sqlite3
├── setup_git.bat                 # 讀取 config.bat 設定本地 git user.name/email（本次未列入轉換範圍，但邏輯與 download_db.bat 高度相依 config.bat，需注意結尾有異常內容，見第 4 節）
├── manage.py
├── requirement.txt               # Django, Markdown, django-markdownx, Pillow
└── .gitignore
```

## 3. 三個待轉換腳本的現況分析

### 3.1 `config.bat`
- 純參數設定檔，供其他 `.bat` 用 `call` 方式載入（等同 shell 的 `source`）
- 內容：Google Drive 檔案 ID／下載網址／目標路徑（用 `%~dp0` 取得腳本所在目錄）、Git 使用者名稱與 email
- Windows 專屬語法：`set "VAR=value"`、`%~dp0`（取得批次檔所在目錄，含結尾反斜線）

### 3.2 `build_venv.bat`
- 檢查 `python` 指令是否存在
- 若 `.venv` 不存在則建立（`python -m venv .venv`）
- 升級 pip、安裝 `requirement.txt`
- Windows 專屬語法／路徑：`.venv\Scripts\python.exe`（Linux 對應為 `.venv/bin/python`）、`%errorlevel%` 錯誤碼判斷、`pause`（互動暫停，Linux 無對應且部署腳本通常不需要）

### 3.3 `download_db.bat`
- 透過 `call config.bat` 載入參數
- 優先使用 `curl.exe` 下載，否則 fallback 用 PowerShell 的 `Invoke-WebRequest`
- 檢查下載結果是否成功、檔案是否存在
- Windows 專屬語法：`setlocal enabledelayedexpansion` + `!VAR!` 延遲展開、`where curl.exe`、PowerShell fallback、`pause`

## 4. 需要注意的風險與相依關係

- **Google Drive 直接下載連結對大檔案不可靠**：`https://drive.google.com/uc?export=download&id=...` 對超過一定大小的檔案會回傳「病毒掃描警告」的 HTML 中介頁面而非檔案本體，用 `curl -L` 直接下載可能只會存下一份 HTML。轉換為 Linux 腳本時需一併評估是否要處理此情況（例如改用 `gdown` 或加上 confirm token），此問題在 Windows 版腳本中也同樣存在，不是本次轉換才產生的新風險，但轉換時值得一併提出。
- **`setup_git.bat` 與 `config.bat` 高度耦合**：雖然本次只要求轉換 `build_venv.bat`／`config.bat`／`download_db.bat` 三支，但 `setup_git.bat` 也讀取 `config.bat` 的 `GIT_USER_NAME`／`GIT_USER_EMAIL`。若之後 `config.bat` 被下線或改名，`setup_git.bat` 會失效——目前先不動它，但列入待辦。另外 `setup_git.bat` 檔案結尾有 `@winnieshih1107` / `Comment` 兩行非批次語法內容，疑似貼上時殘留的雜訊，不影響 `pause` 之前的執行，但屬既有問題。
- **`.vscode/settings.json` 寫死 Windows 路徑**（`D:\\DjangoBlog\\.venv\\Scripts\\python.exe`），遠端 Linux 環境不會用到這個檔案，但如果之後也想讓 VS Code Remote 開發一致可用，需要另外處理（不在本次轉換範圍內）。
- **`DjangoBlog/settings.py` 目前非部署就緒**：`DEBUG = True`、`ALLOWED_HOSTS = ['*']`、`SECRET_KEY` 明碼寫在原始碼中。這些與本次「轉換三個 bat 檔」的需求無直接關係，但既然目標是「部署到遠端」，建議列為後續待辦（不在本次分析要求的修改範圍內，僅提醒）。
- **`db.sqlite3` 已被 `.gitignore` 排除**：遠端環境需要靠 `download_db.bat`（轉換後的等效腳本）另外取得資料庫檔案，或改用其他資料庫佈署方式。

## 5. 與本次任務的關聯

三個待轉換檔案彼此的呼叫關係：

```
build_venv.bat      （獨立，不依賴 config.bat）
config.bat           →  被 download_db.bat、setup_git.bat 用 call 讀取
download_db.bat      →  依賴 config.bat 取得 FILE_ID / DB_PATH / DOWNLOAD_URL
```

轉換為 Linux 版本時，建議維持相同的呼叫關係與職責劃分（例如 `config.sh` 被其他腳本 `source`），以降低轉換風險並維持現有的使用習慣。具體轉換步驟規劃於 `documents/002-bash-scripts.md`。
