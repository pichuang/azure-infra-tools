# Changelog

## 2026-08-05

- 將 HTTP response、`ssrf.log` 與 console log 統一為共用鑑識 event。
- Response 新增 raw headers、最多 64 KiB request body、query、server 與 handler timing。
- 明確區分可信任 socket IP 與未驗證的 forwarding headers 宣告。
- 擴充 audit log 的 request ID、server、request size/time 欄位並啟用 JSON escaping。

## 2026-07-24

- 新增 `/return` 專用 JSON 請求反射日誌。
- 記錄完整反射 headers、`Authorization` 與最多 64 KiB request body。
- request body 超過上限時記錄原始 byte 長度與截斷標記。
- 將服務擴充為 SSRF catcher，僅保留 `/healthz`，其他 path/method 全部反射。
- 新增 request ID correlation、所有 headers 與重複 raw headers 記錄。
- 專用持久化日誌改為 `/var/log/nginx/ssrf.log`。
- 將 stdout 改為人類易讀的多行 SSRF request block。
- 成功 health check 不再輸出 stdout，4xx/5xx 改用單行錯誤摘要。
- JSON audit 與 SSRF events 僅寫入持久化檔案，避免 compose logs 重複。
