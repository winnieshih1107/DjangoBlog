# 001 - 文章模組（Article Module）：Markdown 儲存與 WYSIWYG 渲染

## 1. 目標與範圍

- 文章內容（`article.Post.content`）改以 **Markdown 格式**儲存純文字。
- 後台（Django Admin）編輯文章時，提供**所見即所得（WYSIWYG／即時預覽）介面**來編寫 Markdown。
- 前台頁面顯示文章時，將儲存的 Markdown 內容渲染為 HTML。
- 範圍不包含：前台公開的文章新增/編輯表單、使用者權限系統、留言功能（如需要另立計畫）。

## 2. 資料模型設計

- 沿用現有 `article/models.py` 的 `Post` model（`title`, `slug`, `content`, `pub_date`）。
- `content` 欄位型別由 `models.TextField()` 改為 `markdownx.models.MarkdownxField()`（為 `TextField` 的子類別，資料庫層級相容，不會遺失既有資料，僅需一次 migration）。
- 不新增資料表；渲染後的 HTML 不落地儲存，於顯示時即時轉換（使用 `markdownx` 提供的樣板標籤 `markdownify`）。

## 3. 實作步驟流程

> 每個步驟完成後會先暫停，待確認修改內容無誤後再進行下一步。

1. **安裝套件並更新 `requirement.txt`**
   - 新增 `Markdown`、`django-markdownx`、`Pillow`（圖片上傳處理用）三個套件與版本號。
2. **更新 `DjangoBlog/settings.py`**
   - `INSTALLED_APPS` 加入 `'markdownx'`。
   - 設定 `MEDIA_URL`、`MEDIA_ROOT`（Markdown 編輯器拖拉上傳圖片會用到）。
   - 視需要設定 `MARKDOWNX_MEDIA_PATH` 等 markdownx 相關參數。
3. **更新 `DjangoBlog/urls.py`**
   - `include('markdownx.urls')`：提供編輯器即時預覽所需的 AJAX 端點。
   - 開發模式（`DEBUG`）下加入 media 檔案的 URL 路由。
4. **修改 `article/models.py`**
   - 將 `Post.content` 欄位型別改為 `MarkdownxField`。
5. **產生並套用 migration**
   - `python manage.py makemigrations article`
   - `python manage.py migrate`
6. **修改 `article/admin.py`**
   - 改用 `markdownx.admin.MarkdownxModelAdmin` 註冊 `Post`，讓後台編輯頁提供 Markdown 即時預覽（WYSIWYG）介面。
7. **新增 `article/urls.py`**
   - 新增文章列表（沿用 index）與**文章詳細頁**路由，並在 `DjangoBlog/urls.py` 中 `include`。
8. **修改 `article/views.py`**
   - 新增文章詳細頁 view（依 `pk` 或 `slug` 查詢單篇文章）。
9. **新增／修改樣板**
   - `TEMPLATES/article/list.html`（取代 `index.html` 內容顯示邏輯，加上文章連結）。
   - `TEMPLATES/article/detail.html`：使用 `{% load markdownx %}` 及 `{{ post.content|markdownify }}` 將 Markdown 轉為 HTML 顯示。
10. **手動測試與驗收**
    - 建立／更新 `.venv` 並安裝套件、執行 migration、啟動開發伺服器。
    - 於 Django Admin 建立文章，確認編輯介面具備 Markdown 即時預覽。
    - 於前台列表與詳細頁確認 Markdown 內容正確渲染為 HTML。

## 4. 套件需求（新增至 `requirement.txt`）

| 套件 | 版本 | 用途 |
| --- | --- | --- |
| `Markdown` | `3.10.2` | Markdown → HTML 轉換核心引擎 |
| `django-markdownx` | `4.0.11` | 提供 Django Admin／表單的 Markdown WYSIWYG 編輯器與 `markdownify` 樣板標籤，官方已標示支援 Django 6.0 |
| `Pillow` | `12.3.0` | `django-markdownx` 處理編輯器圖片上傳所需依賴 |

## 5. 驗收標準

- [ ] `requirement.txt` 含新套件與版本，`.venv` 可成功安裝。
- [ ] Admin 編輯文章時可看到 Markdown 語法即時預覽渲染結果。
- [ ] 前台文章列表／詳細頁顯示的是渲染後的 HTML，而非原始 Markdown 語法。
- [ ] 既有文章資料在 migration 後未遺失。
