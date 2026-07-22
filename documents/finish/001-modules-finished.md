# 001 - 文章模組（Markdown 儲存與 WYSIWYG 渲染）階段完成報告

> 對應計畫文件：`documents/001-modules-plans.md`
> 本文件提供給下一個任務的 Agent 作為交接參考，說明目前已完成的狀態、實際實作與原計畫的差異、已知問題與建議後續事項。

## 1. 完成狀態

計畫中「3. 實作步驟流程」10 個步驟已全部完成並手動驗證通過：

1. 套件安裝完成，`.venv` 已建立
2. `DjangoBlog/settings.py`：加入 `markdownx` app、`MEDIA_URL`/`MEDIA_ROOT`、`MARKDOWNX_MEDIA_PATH`
3. `DjangoBlog/urls.py`：加入 `markdownx.urls`、`DEBUG` 下的 media 靜態路由
4. `article/models.py`：`Post.content` 改為 `MarkdownxField`
5. Migration 已產生並套用（`article/migrations/0002_alter_post_content.py`）
6. `article/admin.py`：`Post` 改用 `MarkdownxModelAdmin` 註冊
7. `article/urls.py`：新增 `list`（首頁）、`detail`（`/<pk>/`）路由，並在專案 urls 中 `include`
8. `article/views.py`：新增 `detail` view
9. 樣板：新增 `TEMPLATES/article/list.html`、`TEMPLATES/article/detail.html`；移除舊 `TEMPLATES/index.html`
10. 手動驗證：建立測試 superuser、啟動開發伺服器、建立一篇含 Markdown 語法的測試文章，確認前台列表／詳細頁渲染正確、`manage.py check` 無誤

## 2. 與原計畫的差異（重要）

- **`django-markdownx` 4.0.11 實際上沒有內建 `{% load markdownx %}` 樣板標籤／`markdownify` filter**（原計畫書中假設有，經安裝後實測發現該版本已移除 templatetags 模組，只保留 `markdownx.utils.markdownify()` 這個純函式）。
  - 因應做法：新增 `article/templatetags/article_markdown.py`，自訂 `markdownify` filter（呼叫 `markdownx.utils.markdownify` 並 `mark_safe`），前台改用 `{% load article_markdown %}`。
  - **若下一階段升級或更換 `django-markdownx` 版本，需重新確認此相容性假設是否仍成立。**

## 3. 檔案異動清單

新增：
- `documents/001-modules-plans.md`（計畫文件）
- `article/urls.py`
- `article/templatetags/__init__.py`
- `article/templatetags/article_markdown.py`
- `TEMPLATES/article/list.html`
- `TEMPLATES/article/detail.html`
- `article/migrations/0002_alter_post_content.py`
- `.venv/`（虛擬環境，未納入版控，見 `.gitignore`）

修改：
- `requirement.txt`（新增 `Markdown==3.10.2`、`django-markdownx==4.0.11`、`Pillow==12.3.0`）
- `DjangoBlog/settings.py`（`INSTALLED_APPS`、`MEDIA_URL`、`MEDIA_ROOT`、`MARKDOWNX_MEDIA_PATH`）
- `DjangoBlog/urls.py`（改用 `include('article.urls')`、加入 `markdownx.urls`、media 路由）
- `article/models.py`（`content` 改為 `MarkdownxField`）
- `article/admin.py`（改用 `MarkdownxModelAdmin`）
- `article/views.py`（新增 `detail` view，`index` 改渲染 `article/list.html`）

刪除：
- `TEMPLATES/index.html`（邏輯已搬移至 `TEMPLATES/article/list.html`）

## 4. 已知問題（超出本階段範圍，未修改）

- **`TEMPLATES/components/header.html` 本身包含一份完整的 `<html><body>...</html>` 舊版除錯用內容**（含 `{{ now }}`、逐篇文章迴圈等），與 `base.html` 疊在一起會造成頁面巢狀重複輸出。這是專案初始化時遺留的既有問題，非本次 Markdown 模組修改造成，但會影響實際頁面外觀。**建議下一階段優先處理**，將 `header.html` 精簡為單純的 `<meta>`/`<title>` 等 head 內容。

## 5. 測試資料與帳號（部署前請留意清理）

- 已建立本機測試用 superuser：`blogadmin` / `TestPass2026!`（僅寫入本機 SQLite，未提交版控）。
- 已建立一筆測試文章（`slug=markdown-test`）用於驗證 Markdown 渲染。
- 開發伺服器目前於背景執行中（`127.0.0.1:8000`），供人工瀏覽器驗證使用。

## 6. 建議後續工作

- 修復 `header.html` 的巢狀內容問題（見第 4 節）。
- 前台目前沒有公開的文章新增／編輯表單，僅能透過 Django Admin 建立文章；如需求包含前台作者介面，需另立計畫。
- `Post.slug` 目前為一般 `CharField` 且未強制唯一／未自動產生，如需 SEO 友善網址可評估改為 `SlugField(unique=True)` 並在 view 改用 slug 查詢。
- 部署前移除或更換測試 superuser 帳號密碼。
