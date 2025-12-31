# README


## Raw data (CWA-GDMSN)
Referring: [Appendix C (附錄C 地震目錄欄位說明)](https://gdms.cwa.gov.tw/help.php#AppendixC)

Date: 年, 月, 日
Time: 時, 分, 秒
Lat.: 北緯度
Lon: 東經度
Depth: 震源深度
ML: 規模
nstn: 使用測站數量
Dmin: 最近站震央距(F5.1)
Gap: 相鄰測站之最大間隙角度
RMS: 時間殘值之方均根誤差值
ERH: 震央之(水平)標準差(公里)
ERZ: 震源深度之(垂直)標準差(公里)
Fixed: 深度控制(F: 未限制,X:限制深度)
nph: 到時相位數量
Quality: 品質

Q: 定位結果之品質共劃分為A, B, C, D 4種等級：
|   Q   | 測站數量 | 最大間隙角度 | 最小震央距          |
| :---: | :------- | :----------- | :------------------ |
|   A   | >= 6     | <= 90        | <= Depth or 5 Km    |
|   B   | >= 6     | <= 135       | <= 2 Depth or 10 Km |
|   C   | >= 6     | <= 180       | <= 50 Km            |
|   D   | others   | -            | -                   |

深度控制,F: 未限制，即採逆推收斂至最小誤差；X:限制深度，即依據經驗給定震源深度後，該參數不為變數進行逆推收斂至最小誤差。
