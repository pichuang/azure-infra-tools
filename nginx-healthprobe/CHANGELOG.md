# Changelog

## 2026-07-24

- 新增 `/return` 專用 JSON 請求反射日誌。
- 記錄完整反射 headers、`Authorization` 與最多 64 KiB request body。
- request body 超過上限時記錄原始 byte 長度與截斷標記。
- 將服務擴充為 SSRF catcher，僅保留 `/healthz`，其他 path/method 全部反射。
- 新增 request ID correlation、所有 headers 與重複 raw headers 記錄。
- 專用持久化日誌改為 `/var/log/nginx/ssrf.log`。
