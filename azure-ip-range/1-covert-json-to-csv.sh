#!/bin/bash

# 1. 設定變數
# 注意：此下載連結會隨時間變動，建議搜尋 "Azure IP Ranges and Service Tags – Public Cloud" 取得最新連結
# https://www.microsoft.com/en-us/download/details.aspx?id=56519
INPUT_FILE="ServiceTags_Public.json"
OUTPUT_FILE="ServiceTags_Public.csv"

# 檢查輸入檔案是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo "錯誤: 找不到 $INPUT_FILE，請先下載 JSON 檔案。"
    exit 1
fi

echo "正在處理 $INPUT_FILE ..."

# 2. 建立 CSV 標頭 (Header)
# Sentinel Watchlist 需要欄位名稱
echo "ServiceTag,IPPrefix,Region,SystemService" > "$OUTPUT_FILE"

# 3. 使用 jq 進行轉換
# 邏輯說明：
# .values[] : 遍歷每個 Service Tag 物件
# select(...) : (可選) 你可以在這裡過濾掉不需要的 Tag，例如只留 AzureCloud
# 變數指派 : 將 name, region, systemService 存為變數
# .properties.addressPrefixes[] : 展開該 Tag 底下的所有 IP
# 輸出 : 組合變數與 IP，並用 @csv 格式化
jq -r '.values[] |
             select(
                 .properties.region == "japaneast" or
                 .properties.region == "japanwest" or
                 .properties.region == "westus3" or
                 .properties.region == "taiwannorth"
             ) |
             .name as $name |
             .properties.region as $region |
             .properties.systemService as $service |
             .properties.addressPrefixes[] |
             [$name, ., $region, $service] |
             @csv' "$INPUT_FILE" >> "$OUTPUT_FILE"

echo "轉換完成！檔案已儲存為: $OUTPUT_FILE"
# 顯示前 5 行檢查結果
head -n 5 "$OUTPUT_FILE"