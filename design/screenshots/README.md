# App Store 截圖

README 使用的截圖，取自 App Store Connect 上實際上架的 en 版截圖（v1.2.0），
以 750px 寬下載自 App Store 的圖片 CDN。

| 檔案 | 畫面 |
|---|---|
| `home.png` | Home：到期環形圖、浪費統計、即將到期清單 |
| `widget.png` | 桌面 Widget（medium） |
| `settings.png` | Settings：移除廣告、iCloud 同步、通知 |

更新方式：截圖換版上架後，用 `https://itunes.apple.com/lookup?id=6793926521&country=us`
取得 `screenshotUrls`，把網址結尾的尺寸段改成 `750x0w.png` 後重新下載覆蓋。
