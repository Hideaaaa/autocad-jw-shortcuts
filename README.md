# AutoCAD Jw風ショートカット設定

Jw_cadユーザーがAutoCADを高速操作するための`acad.pgp`設定ファイルとLISPルーチン集です。

## 設計思想

- **左手のみで完結**する配置を優先
- **打鍵数 = 使用頻度の逆数**（よく使うほど少ない打鍵数）
- 同キー繰り返しで上位コマンドへ（例: `E`=円、`EE`=円弧、`EEE`=円柱）
- `Space` = コマンド繰り返し（Jwの右クリック相当）

## ファイル構成

```
autocad-jw-shortcuts/
├── README.md       このファイル
├── acad.pgp        コマンドエイリアス本体
├── acadoc.lsp      カスタムLISPルーチン集
└── cheatsheet.pdf  キーボード配列チートシート
```

## 動作環境

| ファイル | Windows | Mac |
|---|---|---|
| acad.pgp | ✓ 動作確認済み | ✓ 動作確認済み |
| FC / AC / AD / AS | ✓ | ✓ |
| W（属性取得）| ✓ | 未検証 |
| 数字トグル系 | ✓ | 一部非対応の可能性あり |
| DS100 / DS50 / DS30 / DS1 | ✓ | 未検証 |

Mac版AutoCADはWindows版と内部実装が異なるため、`command`関数経由のダイアログ系（SAVEAS等）は動作しない場合があります。Mac対応情報はIssueで歓迎します。

## インストール方法

### acad.pgp

1. 既存の`acad.pgp`のバックアップを取る
2. このリポジトリの`acad.pgp`を所定のフォルダにコピー
3. AutoCADのコマンドラインで`REINIT`→「PGPファイル」にチェックして再読み込み

pgpファイルの場所:
- Windows: `C:\Users\ユーザー名\AppData\Roaming\Autodesk\AutoCAD 20xx\Rxx.x\ja-JP\Support\acad.pgp`
- Mac: `/Users/ユーザー名/Library/Application Support/Autodesk/AutoCAD 20xx/Rxx.x\ja-JP/Support/acad.pgp`

### acadoc.lsp

AutoCADのサポートファイル検索パスにこのフォルダを追加するか、`acaddoc.lsp`から呼び出す:

```lisp
(load "acadoc.lsp")
```

## キー配置一覧

### 数字キー（トグル系）

| キー | コマンド | 説明 |
|---|---|---|
| 1 | ORTHOTOGGLE | 直交モード ON/OFF |
| 11 | AI_DRAWORDER | 表示順序 |
| 2 | MODELPAPERTOGGLE | モデル/ペーパー切替 |
| 22 | AI_DRAWORDER_FRONT | 最前面に移動 |
| 3 | GRIDTOGGLE | グリッド ON/OFF |
| 33 | HATCHBACK | ハッチ背面へ |
| 4 | SNAPTOGGLE | スナップ ON/OFF |
| 44 | QSELECT | クイック選択 |
| 5 | POLARTOGGLE | 極トラッキング ON/OFF |
| 55 | SAVEAS | 名前を付けて保存 |

### A — 文字・注釈系

| キー | コマンド | 説明 |
|---|---|---|
| A | DTEXT | 1行文字 |
| AA | ALIGN | 位置合わせ |
| AAA | MTEXT | マルチテキスト |
| AC | AC (LISP) | 丸囲み文字 |
| AD | AD (LISP) | 下線付き文字 |
| AF | FIND | 文字検索 |
| AFF | FIELD | フィールド |
| AR | MLEADER | マルチ引出線 |
| ART | MLEADERSTYLE | 引出線スタイル |
| AS | AS (LISP) | 角囲み文字 |
| AT | STYLE | 文字スタイル |
| AU | — | 未実装（各自追加） |

### B — ブロック系

| キー | コマンド | 説明 |
|---|---|---|
| B | -INSERT | ブロック挿入（コマンドライン） |
| BB | BLOCK | ブロック定義 |
| BC | BCOUNT | ブロック数カウント |
| BD | BOUNDARY | 境界線 |
| BE | BEDIT | ブロック編集 |
| BR | REFEDIT | 参照編集 |
| BW | BCLOSE | ブロック編集終了 |
| BX | BURST | ブロック展開（属性保持） |

### C — コピー系

| キー | コマンド | 説明 |
|---|---|---|
| C | COPY | コピー |
| CC | CHAMFER | 面取り |
| CS | CHSPACE | 空間変換 |
| CV | NCOPY | ネスト内コピー |
| CX | COPYBASE | 基点コピー |

### D — 消去・計測系

| キー | コマンド | 説明 |
|---|---|---|
| D | ERASE | 消去 |
| DD | DIST | 距離計測 |
| DF | POINT | 点 |
| DM | MEASURE | 等間隔測定 |
| DR | DIMREASSOCIATE | 寸法再関連付け |
| DT | PTYPE | 点スタイル |
| DV | DIVIDE | 等分割 |

### E — 円・曲線系

| キー | コマンド | 説明 |
|---|---|---|
| E | CIRCLE | 円 |
| EE | ARC | 円弧 |
| EEE | ELLIPSE | 楕円 |
| EX | EXTRUDE | 押し出し（3D） |

### F — オフセット系

| キー | コマンド | 説明 |
|---|---|---|
| F | OFFSET | オフセット |
| FC | FC (LISP) | オフセット→現在画層 |
| FF | PROPERTIES | プロパティ |
| FFF | PLAN | 平面図表示（3D用） |
| FT | FLATTEN | 2D平坦化 |

### G — 線分系

| キー | コマンド | 説明 |
|---|---|---|
| G | LINE | 直線 |
| GC | CENTERLINE | 中心線 |
| GE | PEDIT | ポリライン編集 |
| GG | PLINE | ポリライン |
| GGG | GROUP | グループ |
| GT | LINETYPE | 線種管理 |
| GX | XLINE | 無限線 |

### H — ハッチング系

| キー | コマンド | 説明 |
|---|---|---|
| H | HATCH | ハッチング |
| HH | HATCHEDIT | ハッチング編集 |
| HHH | HATCHGENERATEBOUNDARY | ハッチ境界生成 |

### N — 配列複写系

| キー | コマンド | 説明 |
|---|---|---|
| N | ARRAY | 配列複写（種類選択） |
| NN | ARRAYRECT | 矩形配列 |
| NNN | ARRAYPOLAR | 円形配列 |
| NP | ARRAYPATH | パス配列 |
| NX | ARRAYEDIT | 配列編集 |

### P — 印刷・出力系

| キー | コマンド | 説明 |
|---|---|---|
| P | PLOT | 印刷 |
| PA | PUBLISH | パブリッシュ |
| PP | PAGESETUP | ページ設定 |
| PS | PSLTSCALE | ペーパー線種尺度 |

### Q — 元に戻す・矩形系

| キー | コマンド | 説明 |
|---|---|---|
| Q | U | 元に戻す |
| QQ | RECTANGLE | 長方形 |
| QX | OOPS | 直前消去を元に戻す |

### R — フィレット・画層系

| キー | コマンド | 説明 |
|---|---|---|
| R | FILLET | フィレット |
| RA | LAYER | 画層管理 |
| RC | LAYCUR | 現在の画層に変更 |
| RG | LAYON | 画層表示 ON |
| RGG | -LAYER U * (LISP) | 全レイヤーアンロック |
| RH | LAYOFF | 画層表示 OFF |
| RM | LAYMRG | 画層マージ |
| RR | ROTATE | 回転 |
| RS | LAYISO | 画層アイソレート |
| RSS | LAYUNISO | アイソレート解除 |
| RT | LAYFRZ | 画層フリーズ |
| RV | AI_MOLC | オブジェクトの画層を現在に |
| RW | LAYMCH | 画層一致 |
| RWW | LAYWALK | 画層ウォーク |
| RX | LAYERCLOSE | 画層パネルを閉じる |

### S — 寸法系（Sunpou）

| キー | コマンド | 説明 |
|---|---|---|
| S | DIM | 寸法（自動判定） |
| SA | DIMALIGNED | 平行寸法 |
| SAR | DIMARC | 弧長寸法 |
| SB | DIMBASELINE | 基線寸法 |
| SC | DIMCONTINUE | 連続寸法 |
| SD | DIMDIAMETER | 直径寸法 |
| SE | DIMEDIT | 寸法編集 |
| SF | DIMBREAK | 寸法中断 |
| SG | DIMANGULAR | 角度寸法 |
| SQ | QDIM | クイック寸法 |
| SR | DIMRADIUS | 半径寸法 |
| SS | DIMLINEAR | 水平/垂直寸法 |
| SSS | STRETCH | ストレッチ |
| ST | DIMTEDIT | 寸法文字編集 |
| STT | DIMSTYLE | 寸法スタイル |
| SU | DIMUPDATE | 寸法更新 |
| SX | DIMSPACE | 寸法間隔調整 |

### T — トリム・編集系

| キー | コマンド | 説明 |
|---|---|---|
| T | TRIM | トリム |
| TA | JOIN | 結合 |
| TT | EXTEND | 延長 |
| TTT | PRESSPULL | プッシュプル（3D） |
| TTTT | LENGTHEN | 長さ変更 |

### V — 移動・貼り付け系

| キー | コマンド | 説明 |
|---|---|---|
| V | MOVE | 移動 |
| VB | PASTECLIPBLOCK | ブロックとして貼り付け |
| VC | PASTECLIP | 貼り付け |
| VV | BREAKATPOINT | 点でブレーク |
| VVV | 3DMOVE | 3D移動 |
| VX | PASTEORIG | 元座標に貼り付け |

### W — LISP・ユーティリティ系

| キー | コマンド | 説明 |
|---|---|---|
| W | JWGET (LISP) | 属性一括取得 |
| WQ | WIPEOUT | ワイプアウト |
| WS | BWGT (LISP) | 未実装（各自追加） |
| WW | MATCHPROP | プロパティコピー |
| WWW | SELECTSIMILAR | 類似オブジェクト選択 |

### X — 鏡像・分解系

| キー | コマンド | 説明 |
|---|---|---|
| X | MIRROR | 鏡像 |
| XC | XCLIP | 外部参照クリップ |
| XR | XREF | 外部参照管理 |
| XS | UCS | UCS設定 |
| XX | EXPLODE | 分解 |
| XXX | 3DMIRROR | 3D鏡像 |

### Z — 補助線

| キー | コマンド | 説明 |
|---|---|---|
|

| コマンド | DIMSCALE | TEXTSIZE |
|---|---|---|
| DS100 | 100 | 250 |
| DS50 | 50 | 125 |
| DS30 | 30 | 75 |
| DS1 | 1 | 2.5 |

## LISPについて

`W`（属性一括取得）は画層・色・線種・文字スタイル・寸法スタイル・ハッチスケールをオブジェクトから一括取得します。Jwの「属性取得」相当の最重要LISPです。


## Z補助線系の強化

Z:HJレイヤを作りそこへ補助線作成
ZH:HJレイヤを非表示
ZG:HJレイヤを表示
ZF:フリーズ
ZFF:解除
ZN:HJレイヤを印刷しない設定に
ZNN:HJレイヤを印刷する設定に
ZR:ロック
ZRR:解除
ZZ:HJレイヤを非表示

## レイヤロック、フリーズ、レイヤーウォークの見直し

## W:属性取得コマンドにロック解除機能を追加！

## poffset,poffsetcベータ版追加
## ポリラインの一部のみをオフセットするコマンド

## 常にR=0でフィレットする繰り返しコマンドR0を追加
## Rに割り当て、オリジナルのフィレットはRDに割り当て

## 常に元レイヤへ書き込みするオフセットF,常にカレントレイヤに書き込みするFCを追加

## 面積、板厚から重量を出すコマンドBWGTを更新
## BWGT:閉じた面を選択して板厚、比重を入力＞BWGTレイヤに重量書き込み
## BWGTH:開口対応
## BWGTC:BWGTレイヤに書き出された重量を集計する表をCSVで出力

## 貢献・フィードバック

Issue・Pull Request歓迎します。特にMac対応LISPの情報をお待ちしています。
