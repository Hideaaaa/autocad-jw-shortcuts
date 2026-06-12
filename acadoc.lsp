; =============================================================================
; acadoc.lsp - AutoCAD Jw風カスタムLISPルーチン集
; =============================================================================
; 動作確認環境:
;   - Windows AutoCAD 2024/2025/2026 ✓
;   - Mac: FC・AC・AS・AD のみ動作確認済み、他は未検証
;
; ロード方法:
;   AutoCADのサポートファイル検索パスに
;   このファイルのフォルダを追加するか、
;   acad.lsp / acaddoc.lsp から (load "acadoc.lsp") で呼び出す
; =============================================================================

; -------------------------------------------------------------------------
; 【1. システム変数 & スタイル・寸法の自動生成】
; -------------------------------------------------------------------------
(setvar "CENTEREXE" 0)   ; 中心線の自動リンクを切る
(setvar "PICKFIRST" 1)   ; 選択セット初期化
(setvar "QPMODE" 0)      ; クイックプロパティOFF
(setvar "AUTOSNAP" (boole 7 (getvar "AUTOSNAP") 8))  ; 極トラッキングON
(setvar "ORTHOMODE" 0)  ; 直交OFF

; --- プロッター文字スタイル（SHX単線フォント）の自動作成 ---
(command "._-STYLE" "Standard"     "simplex.shx,extfont2.shx" "0" "1" "0" "_N" "_N" "_N")
(command "._-STYLE" "Plotter-Font" "simplex.shx,extfont2.shx" "0" "1" "0" "_N" "_N" "_N")

; -------------------------------------------------------------------------
; 【2. 縮尺一発変更コマンド】
; DS100 / DS50 / DS30 / DS1
; -------------------------------------------------------------------------
(defun c:DS100 () (setvar "DIMSCALE" 100) (setvar "TEXTSIZE" 250) (command "._DIMSTYLE" "_R" "MY-DIM") (princ "\n【縮尺 1:100】") (princ))
(defun c:DS50  () (setvar "DIMSCALE" 50)  (setvar "TEXTSIZE" 125) (command "._DIMSTYLE" "_R" "MY-DIM") (princ "\n【縮尺 1:50】")  (princ))
(defun c:DS30  () (setvar "DIMSCALE" 30)  (setvar "TEXTSIZE" 75)  (command "._DIMSTYLE" "_R" "MY-DIM") (princ "\n【縮尺 1:30】")  (princ))
(defun c:DS1   () (setvar "DIMSCALE" 1)   (setvar "TEXTSIZE" 2.5) (command "._DIMSTYLE" "_R" "MY-DIM") (princ "\n【現寸 1:1】")   (princ))

; -------------------------------------------------------------------------
; 【3. 数字・トグル系】
; Windows/Mac 動作確認済み（SAVEASなど一部Macで非対応の可能性あり）
; -------------------------------------------------------------------------
(defun c:1   () (command "._ORTHOMODE" (if (= (getvar "ORTHOMODE") 1) 0 1)) (princ))
(defun c:11  () (command "._AI_DRAWORDER") (princ))
(defun c:2   () (command "._TILEMODE" (if (= (getvar "TILEMODE") 1) 0 1)) (princ))
(defun c:22  () (command "._AI_DRAWORDER" "_FRONT") (princ))
(defun c:3   () (command "._GRIDMODE" (if (= (getvar "GRIDMODE") 1) 0 1)) (princ))
(defun c:33  () (command "._HATCHTOBACK") (princ))
(defun c:4   () (command "._SNAPMODE" (if (= (getvar "SNAPMODE") 1) 0 1)) (princ))
(defun c:44  () (command "._QSELECT") (princ))
(defun c:5   () (command "._SNAPTYPE" (if (= (getvar "SNAPTYPE") 1) 0 1)) (princ))
(defun c:55  () (command "._SAVEAS") (princ))

; -------------------------------------------------------------------------
; 【4. 文字装飾系】
; AC=丸囲み / AD=下線付き / AS=角囲み
; Windows/Mac 動作確認済み
; -------------------------------------------------------------------------

; AC - 丸囲み文字
(defun c:AC (/ txt pt th tw rad)
  (setq txt (getstring t "\n丸囲み文字: "))
  (setq pt  (getpoint "\n配置点: "))
  (setq th  (getvar "TEXTSIZE"))
  (command "._TEXT" "_C" pt th 0 txt)
  (setq tw (caadr (textbox (entget (entlast)))))
  (setq rad (* (if (> tw th) tw th) 0.75))
  (command "._CIRCLE" pt rad)
  (princ)
)

; AD - 下線付き文字
(defun c:AD (/ txt pt th tw off p1 p2)
  (setq txt (getstring t "\n下線付き文字: "))
  (setq pt  (getpoint "\n配置点: "))
  (setq th  (getvar "TEXTSIZE"))
  (command "._TEXT" "_C" pt th 0 txt)
  (setq tw  (caadr (textbox (entget (entlast)))))
  (setq off (* th 0.2))
  (setq p1  (list (- (car pt) (/ tw 2.0)) (- (cadr pt) off)))
  (setq p2  (list (+ (car pt) (/ tw 2.0)) (- (cadr pt) off)))
  (command "._LINE" p1 p2 "")
  (princ)
)

; AS - 角囲み文字
(defun c:AS (/ txt pt th tw off p1 p2)
  (setq txt (getstring t "\n角囲み文字: "))
  (setq pt  (getpoint "\n配置点: "))
  (setq th  (getvar "TEXTSIZE"))
  (command "._TEXT" "_C" pt th 0 txt)
  (setq tw  (caadr (textbox (entget (entlast)))))
  (setq off (* th 0.3))
  (setq p1  (list (- (car pt) (+ (/ tw 2.0) off)) (- (cadr pt) off)))
  (setq p2  (list (+ (car pt) (+ (/ tw 2.0) off)) (+ (cadr pt) (+ th off))))
  (command "._RECTANGLE" p1 p2)
  (princ)
)

; -------------------------------------------------------------------------
; 【5. FC - オフセット→現在の画層に作成】
; F = OFFSET の派生、FC = F + Current layer
; Windows/Mac 動作確認済み
; -------------------------------------------------------------------------
(defun c:FC (/ prev)
  (setq prev (getvar "OFFSETLAYERMODE"))
  (setvar "OFFSETLAYERMODE" 1)
  (command "OFFSET")
  (setvar "OFFSETLAYERMODE" prev)
  (princ)
)

; -------------------------------------------------------------------------
; W - 属性取得（JWGET）
; オブジェクトの画層・色・線種・文字スタイル・寸法スタイル・ハッチを一括取得
; ロックされた画層も1クリックで取得・自動ロック解除
; Windows,Mac 動作確認済み
; -------------------------------------------------------------------------
(defun c:W (/ e ed ds layname laydata colorval pt)
  ; まずentselで試みる、失敗したらnentselp（ロック画層対応）
  (setq e (car (entsel "\n属性取得: ")))
  (if (not e)
    (progn
      (setq pt (getpoint "\nロック画層を指定: "))
      (setq e (car (nentselp pt)))
    )
  )
  (if e
    (progn
      (setq ed (entget e))
      (setq layname (cdr (assoc 8 ed)))
      ; ロックされてたら解除
      (if layname
        (progn
          (setq laydata (tblsearch "LAYER" layname))
          (if (and laydata (= (logand (cdr (assoc 70 laydata)) 4) 4))
            (progn
              (command "._LAYER" "_U" layname "")
              (princ (strcat "\n" layname " 画層のロックを解除しました"))
            )
          )
        )
      )
      ; 画層
      (if (assoc 8 ed) (setvar "CLAYER" (cdr (assoc 8 ed))))
      ; 色（0や256は無効なのでBYLAYERにする）
      (setq colorval (cdr (assoc 62 ed)))
      (if (and colorval (> colorval 0) (< colorval 256))
        (command "_.-COLOR" (itoa colorval))
        (command "_.-COLOR" "_BYLAYER")
      )
      ; 線種
      (if (assoc 6 ed) (setvar "CELTYPE" (cdr (assoc 6 ed))))
      ; 線幅
      (if (assoc 370 ed) (setvar "CELWEIGHT" (cdr (assoc 370 ed))))
      ; 文字スタイル・サイズ
      (if (member (cdr (assoc 0 ed)) '("TEXT" "MTEXT"))
        (progn
          (if (assoc 7  ed) (setvar "TEXTSTYLE" (cdr (assoc 7  ed))))
          (if (assoc 40 ed) (setvar "TEXTSIZE"  (cdr (assoc 40 ed))))))
      ; 寸法スタイル
      (if (member (cdr (assoc 0 ed)) '("DIMENSION"))
        (progn
          (setq ds (cdr (assoc 3 ed)))
          (if ds (command "_.DIMSTYLE" "_R" ds))))
      ; 線種尺度
      (if (assoc 48 ed) (setvar "CELTSCALE" (cdr (assoc 48 ed))))
      ; ハッチ
      (if (= (cdr (assoc 0 ed)) "HATCH")
        (progn
          (if (assoc 41 ed) (setvar "HPSCALE" (cdr (assoc 41 ed))))
          (if (assoc 52 ed) (setvar "HPANG"   (cdr (assoc 52 ed))))))
      (princ "\n現在属性を取得しました"))
    (princ "\nオブジェクトが見つかりません")
  )
  (princ)
)

; -------------------------------------------------------------------------
; 【7. その他ユーティリティ】
; -------------------------------------------------------------------------

; RGG - 全レイヤーアンロック
(defun c:RGG () (command "-LAYER" "U" "*" "") (princ))

; ZZZ - 強制Z=0モードトグル（3D対策）
(defun c:ZZZ ()
  (if (= (getvar "OSNAPZ") 0)
    (progn (setvar "OSNAPZ" 1) (princ "\n--- 強制Z=0モード：[ON] ---"))
    (progn (setvar "OSNAPZ" 0) (princ "\n--- 強制Z=0モード：[OFF] ---"))
  )
  (princ)
)

; AU - 未実装（各自追加してください）
(defun c:AU ()
  (princ "\nAU: 未実装")
  (princ)
)

; BWGT 面積、板厚から重量
(defun c:BWGT ( / obj area-mm2 area-m2 thk-mm thk-m dens dens-kgm3 w pt)
  (vl-load-com)

  ;; 図形を1つ選択
  (setq obj (car (entsel "\n板を選択してください: ")))
  (if (null obj)
    (progn (princ "\n選択されていません。") (princ))
  )

  ;; 面積取得（mm² → m²）
  (setq area-mm2 (vla-get-area (vlax-ename->vla-object obj)))
  (setq area-m2 (/ area-mm2 1000000.0))

  ;; 板厚(mm → m)
  (setq thk-mm (getreal "\n板厚(mm)を入力: "))
  (if (null thk-mm) (setq thk-mm 0.0))
  (setq thk-m (/ thk-mm 1000.0))

  ;; 比重(t/m3 → kg/m3)
  (setq dens (getreal "\n比重(t/m3) [Enter=7.85]: "))
  (if (null dens) (setq dens 7.85))
  (setq dens-kgm3 (* dens 1000.0))

  ;; 重量計算（kg）
  (setq w (* area-m2 thk-m dens-kgm3))

  ;; 書き込む位置
  (setq pt (getpoint "\n書き込む位置を指示してください: "))

  ;; ★ 高さ20のTEXTを作成（異尺度対応なし）
  (entmakex
    (list
      '(0 . "TEXT")
      (cons 10 pt)
      (cons 40 20.0) ;; ← 高さ20固定
      (cons 1 (strcat "W:" (rtos w 2 2) "kg  T:" (rtos thk-mm 2 2) "mm"))
    )
  )

  (princ (strcat "\n書き込みました → W:" (rtos w 2 2) "kg  T:" (rtos thk-mm 2 2) "mm"))
  (princ)
)

(defun c:OC () (command "._OFFSET" "_Layer" "_Current") (princ))

; F:元のレイヤでオフセットFC:オフセットしたものを現在のレイヤに
;(defun c:FC ()
;  (setvar "OFFSETLAYERMODE" 1)
;  (command "OFFSET")
;  (princ)
;)

;(defun c:F ()
;  (setvar "OFFSETLAYERMODE" 0)
;  (command "OFFSET")
;  (princ)
;)

; -------------------------------------------------------------------------
; Z系 - 補助線（HJ画層）管理
; -------------------------------------------------------------------------

; Z - HJ画層に切り替えてXLINE起動
;     非表示・フリーズなら自動解除、なければ作成、終了後元の画層に戻る
(defun c:Z (/ prev olderr laydata)
  (setq prev (getvar "CLAYER"))
  (setq olderr *error*)
  (defun *error* (msg)
    (setvar "CLAYER" prev)
    (setq *error* olderr)
    (princ)
  )
  ; HJ画層がなければ作成（色=251暗めグレー、線種=DASHED2）
  (if (not (tblsearch "LAYER" "HJ"))
    (progn
      (command "._LAYER" "_N" "HJ" "")
      (command "._LAYER" "_C" 251 "HJ" "")
      (if (not (tblsearch "LTYPE" "DASHED2"))
        (command "._LINETYPE" "_L" "DASHED2" "acadiso.lin" "")
      )
      (command "._LAYER" "_L" "DASHED2" "HJ" "")
    )
  )
  (setq laydata (tblsearch "LAYER" "HJ"))
  ; フリーズされてたら解除
  (if (= (logand (cdr (assoc 70 laydata)) 1) 1)
    (command "._LAYER" "_T" "HJ" "")
  )
  ; OFFなら表示ON
  (if (= (logand (cdr (assoc 70 (tblsearch "LAYER" "HJ"))) 2) 0)
    (command "._LAYER" "_ON" "HJ" "")
  )
  ; ロックされてたら解除
  (if (= (logand (cdr (assoc 70 (tblsearch "LAYER" "HJ"))) 4) 4)
    (command "._LAYER" "_U" "HJ" "")
  )
  
  ; HJ画層に切り替え
  (setvar "CLAYER" "HJ")
  ; XLINE起動（完全終了まで待つ）
  (vl-cmdf "._XLINE" pause)
  ; 元の画層に戻す
  (setvar "CLAYER" prev)
  (setq *error* olderr)
  (princ)
)

; ZZ - 補助線非表示
(defun c:ZZ ()
  (command "._LAYER" "_OFF" "HJ" "")
  (command "._REGEN")
  (princ)
)

; ZD - 補助線全削除
(defun c:ZD (/ ss)
  (setq ss (ssget "X" '((8 . "HJ"))))
  (if ss
    (progn
      (command "._ERASE" ss "")
      (princ "\nHJ画層のオブジェクトをすべて削除しました。")
    )
    (princ "\nHJ画層にオブジェクトはありません。")
  )
  (princ)
)

; ZF - 補助線フリーズ
(defun c:ZF ()
  (command "._LAYER" "_F" "HJ" "")
  (princ)
)

; ZFF - 補助線フリーズ解除
(defun c:ZFF ()
  (command "._LAYER" "_T" "HJ" "")
  (princ)
)

; ZR - 補助線ロック（編集禁止）
(defun c:ZR ()
  (command "._LAYER" "_LO" "HJ" "")
  (princ)
)

; ZRR - 補助線ロック解除
(defun c:ZRR ()
  (command "._LAYER" "_U" "HJ" "")
  (princ)
)


; ZN - 補助線ノープロット設定（印刷前に実行）
(defun c:ZN ()
  (command "._LAYER" "_P" "_N" "HJ" "")
  (princ "\nHJ画層をノープロットに設定。印刷後にZNNで元に戻します。")
  (princ)
)

; ZNN - 補助線ノープロット解除（印刷後に実行）
(defun c:ZNN ()
  (command "._LAYER" "_P" "_P" "HJ" "")
  (princ "\nHJ画層を印刷設定に戻しました。")
  (princ)
)

;; test============================================================
;; PARTIAL-OFFSET.LSP
;; 
;; ポリラインの一部セグメントを選択してオフセットするコマンドのテスト
;; ============================================================
;;
;; コマンド:
;;   POFFSET  - オフセット結果を元のレイヤに作成
;;   POFFSETC - オフセット結果をカレントレイヤに作成
;;
;; 使い方:
;;   1. コマンド実行
;;   2. オフセット距離を入力
;;   3. セグメントをクリック（最初のクリックでポリライン自動特定）、Enterで確定
;;   4. オフセット方向を点で指示
;;   5. 繋がったセグメントはポリライン、バラバラはLINEで生成
;; ============================================================


;;------------------------------------------------------------
;; メイン処理（use-current-layer: T=カレント / nil=元レイヤ）
;;------------------------------------------------------------
(defun poffset-main (use-current-layer / pl-ent pl-data vlist n
                      dist side-pt side segs sel-segs
                      result-groups grp new-ent lay)

  ;; --- 1. オフセット距離 ---
  (setq dist (getdist "\nオフセット距離を入力: "))
  (if (null dist) (exit))

  ;; --- 2. セグメント選択（最初のクリックでポリライン自動特定）---
  (princ "\nセグメントをクリック [Enter で確定]: ")
  (setq sel-result (poffset-select-segments-auto))
  (if (null sel-result) (progn (princ "\nキャンセル") (exit)))

  (setq pl-ent   (car sel-result))
  (setq sel-segs (cadr sel-result))

  (setq pl-data (entget pl-ent))
  (setq vlist (poffset-get-vertices pl-ent))
  (setq n (length vlist))
  (if (< n 2) (progn (princ "\n頂点が不足しています") (exit)))

  ;; --- 3. オフセット方向 ---
  (setq side-pt (getpoint "\nオフセット方向を点で指示: "))
  (if (null side-pt) (exit))

  ;; --- 4. 方向判定 ---
  (setq side (poffset-side-sign vlist side-pt))

  ;; --- 5. 選択セグメントをオフセット計算 ---
  (setq segs (poffset-calc-offset-segs vlist sel-segs dist side))

  ;; --- 6. 連続グループに分割 ---
  (setq result-groups (poffset-group-consecutive sel-segs segs))

  ;; --- 7. 元レイヤ取得 ---
  (setq lay (cdr (assoc 8 pl-data)))

  ;; --- 8. 図形生成 ---
  (foreach grp result-groups
    (if use-current-layer
      (poffset-draw-group grp nil)       ; カレントレイヤ
      (poffset-draw-group grp lay)       ; 元のレイヤ
    )
  )

  (princ (strcat "\n完了: " (itoa (length result-groups)) " グループ生成"))
  (princ)
)


;;------------------------------------------------------------
;; 頂点リスト取得（LWPOLYLINE対応）
;;------------------------------------------------------------
(defun poffset-get-vertices (ent / data pt-list pair)
  (setq data (entget ent))
  (setq pt-list '())
  (foreach pair data
    (if (= (car pair) 10)
      (setq pt-list (append pt-list (list (cdr pair))))
    )
  )
  pt-list
)


;;------------------------------------------------------------
;; セグメント選択（最初のクリックでポリライン自動特定）
;; 戻り値: (pl-ent sel-idx-list) または nil
;;------------------------------------------------------------
(defun poffset-select-segments-auto (/ sel-idx pl-ent vlist inp idx result)
  (setq sel-idx '())
  (setq pl-ent nil)
  (setq vlist nil)

  (while
    (progn
      (setq inp (grread T 15 0))
      (not (and (= (car inp) 2) (= (cadr inp) 13)))  ; Enter で終了
    )

    (cond
      ((= (car inp) 5) nil)  ; マウス移動は無視

      ((= (car inp) 3)  ; 左クリック
       (if (null pl-ent)
         ;; --- 最初のクリック：ポリラインを自動特定 ---
         (progn
           (setq result (poffset-find-polyline-at (cadr inp)))
           (if result
             (progn
               (setq pl-ent (car result))
               (setq vlist  (cadr result))
               (setq idx    (caddr result))
               (setq sel-idx (list idx))
               (princ (strcat "\nポリライン特定、セグメント " (itoa (1+ idx)) " 選択"))
             )
             (princ "\nポリラインが見つかりません")
           )
         )
         ;; --- 2回目以降：同じポリラインのセグメントを追加 ---
         (progn
           (setq idx (poffset-nearest-seg (cadr inp) vlist))
           (if (not (member idx sel-idx))
             (progn
               (setq sel-idx (append sel-idx (list idx)))
               (princ (strcat "\nセグメント " (itoa (1+ idx)) " 選択"))
             )
           )
         )
       )
      )
    )
  )

  (if (and pl-ent sel-idx)
    (list pl-ent sel-idx)
    nil
  )
)


;;------------------------------------------------------------
;; クリック点付近のポリラインとセグメントを特定
;; 戻り値: (pl-ent vlist nearest-seg-idx) または nil
;;------------------------------------------------------------
(defun poffset-find-polyline-at (pt / snap-dist ss i ent data etype vlist idx best-ent best-vlist best-idx best-d d)
  (setq snap-dist (/ (getvar "VIEWSIZE") 50.0))  ; 画面サイズの2%を許容距離に
  (setq ss (ssget "_C"
             (list (- (car pt) snap-dist) (- (cadr pt) snap-dist) 0.0)
             (list (+ (car pt) snap-dist) (+ (cadr pt) snap-dist) 0.0)))
  (if (null ss) (setq ss (ssget "_C"
             (list (- (car pt) (* snap-dist 3)) (- (cadr pt) (* snap-dist 3)) 0.0)
             (list (+ (car pt) (* snap-dist 3)) (+ (cadr pt) (* snap-dist 3)) 0.0))))
  (if (null ss) (return nil))

  (setq best-ent nil best-d 1e38)
  (setq i 0)
  (repeat (sslength ss)
    (setq ent (ssname ss i))
    (setq data (entget ent))
    (setq etype (cdr (assoc 0 data)))
    (if (member etype '("LWPOLYLINE" "POLYLINE"))
      (progn
        (setq vlist (poffset-get-vertices ent))
        (setq idx (poffset-nearest-seg pt vlist))
        (setq d (distance pt (poffset-foot-on-seg pt (nth idx vlist) (nth (1+ idx) vlist))))
        (if (< d best-d)
          (progn
            (setq best-d d)
            (setq best-ent ent)
            (setq best-vlist vlist)
            (setq best-idx idx)
          )
        )
      )
    )
    (setq i (1+ i))
  )

  (if best-ent
    (list best-ent best-vlist best-idx)
    nil
  )
)


;;------------------------------------------------------------
;; クリック点に最も近いセグメントのインデックスを返す
;;------------------------------------------------------------
(defun poffset-nearest-seg (pt vlist / i n best-i best-d d p1 p2 foot)
  (setq n (1- (length vlist)))
  (setq i 0 best-i 0 best-d 1e38)
  (repeat n
    (setq p1 (nth i vlist))
    (setq p2 (nth (1+ i) vlist))
    (setq foot (poffset-foot-on-seg pt p1 p2))
    (setq d (distance pt foot))
    (if (< d best-d)
      (progn (setq best-d d) (setq best-i i))
    )
    (setq i (1+ i))
  )
  best-i
)


;;------------------------------------------------------------
;; 線分上の垂足を求める
;;------------------------------------------------------------
(defun poffset-foot-on-seg (pt p1 p2 / dx dy t-val len2 tx ty)
  (setq dx (- (car p2) (car p1)))
  (setq dy (- (cadr p2) (cadr p1)))
  (setq len2 (+ (* dx dx) (* dy dy)))
  (if (< len2 1e-10)
    p1
    (progn
      (setq t-val (/ (+ (* (- (car pt) (car p1)) dx)
                        (* (- (cadr pt) (cadr p1)) dy))
                     len2))
      (setq t-val (max 0.0 (min 1.0 t-val)))
      (list (+ (car p1) (* t-val dx))
            (+ (cadr p1) (* t-val dy))
            0.0)
    )
  )
)


;;------------------------------------------------------------
;; オフセット方向符号（+1 or -1）
;;------------------------------------------------------------
(defun poffset-side-sign (vlist side-pt / p1 p2 dx dy nx ny cx cy dot)
  ;; 最初のセグメントの法線方向と side-pt の関係で判定
  (setq p1 (nth 0 vlist))
  (setq p2 (nth 1 vlist))
  (setq dx (- (car p2) (car p1)))
  (setq dy (- (cadr p2) (cadr p1)))
  ;; 左法線
  (setq nx (- dy))
  (setq ny dx)
  ;; セグメント中点
  (setq cx (* 0.5 (+ (car p1) (car p2))))
  (setq cy (* 0.5 (+ (cadr p1) (cadr p2))))
  ;; side-pt との内積
  (setq dot (+ (* (- (car side-pt) cx) nx)
               (* (- (cadr side-pt) cy) ny)))
  (if (>= dot 0) 1.0 -1.0)
)


;;------------------------------------------------------------
;; 選択セグメントのオフセット線分リストを計算
;; 戻り値: ((p1 p2) (p1 p2) ...) インデックス対応
;;------------------------------------------------------------
(defun poffset-calc-offset-segs (vlist sel-segs dist side /
                                   result idx p1 p2 dx dy len nx ny op1 op2)
  (setq result '())
  (foreach idx sel-segs
    (setq p1 (nth idx vlist))
    (setq p2 (nth (1+ idx) vlist))
    (setq dx (- (car p2) (car p1)))
    (setq dy (- (cadr p2) (cadr p1)))
    (setq len (sqrt (+ (* dx dx) (* dy dy))))
    (if (> len 1e-10)
      (progn
        ;; 左法線を正規化してdist*side倍
        (setq nx (* (/ (- dy) len) dist side))
        (setq ny (* (/ dx len) dist side))
        (setq op1 (list (+ (car p1) nx) (+ (cadr p1) ny) 0.0))
        (setq op2 (list (+ (car p2) nx) (+ (cadr p2) ny) 0.0))
        (setq result (append result (list (list idx op1 op2))))
      )
    )
  )
  result
)


;;------------------------------------------------------------
;; 連続するセグメントをグループ化
;; 戻り値: グループのリスト、各グループは ((idx op1 op2) ...) の形
;;------------------------------------------------------------
(defun poffset-group-consecutive (sel-segs segs / sorted groups grp prev-idx item idx)
  (setq sorted (vl-sort segs '(lambda (a b) (< (car a) (car b)))))
  (setq groups '())
  (setq grp '())
  (setq prev-idx -999)

  (foreach item sorted
    (setq idx (car item))
    (if (or (null grp) (= idx (1+ prev-idx)))
      ;; 連続 → 同じグループに追加
      (setq grp (append grp (list item)))
      ;; 不連続 → グループ確定して新グループ開始
      (progn
        (setq groups (append groups (list grp)))
        (setq grp (list item))
      )
    )
    (setq prev-idx idx)
  )
  (if grp (setq groups (append groups (list grp))))
  groups
)


;;------------------------------------------------------------
;; グループを図形として描画
;; lay=nil のときカレントレイヤ、文字列のとき指定レイヤ
;;------------------------------------------------------------
(defun poffset-draw-group (grp lay / pts item op1 op2 prev-p2 connected)
  (setq pts '())
  (setq prev-p2 nil)
  (setq connected T)

  ;; 頂点をつなげられるか確認しながらリスト化
  (foreach item grp
    (setq op1 (cadr item))
    (setq op2 (caddr item))
    (if (null pts)
      (setq pts (list op1 op2))
      (progn
        ;; 前のセグメントの終点と今のセグメントの始点が近ければ連続
        (if (< (distance (last pts) op1) 1e-6)
          (setq pts (append pts (list op2)))
          (progn
            ;; 離れている → 連続とみなさずフラグを折る
            (setq connected nil)
            (setq pts (append pts (list op2)))
          )
        )
      )
    )
  )

  ;; レイヤ変更が必要な場合
  (if lay
    (progn
      (setq *prev-lay* (getvar "CLAYER"))
      (setvar "CLAYER" lay)
    )
  )

  ;; 2点以上連続 → LWPOLYLINE、それ以外 → LINE
  (if (and connected (> (length pts) 2))
    ;; ポリライン描画
    (progn
      (command "_.PLINE")
      (foreach p pts (command p))
      (command "")
    )
    ;; LINE描画（2点ずつ）
    (progn
      (setq item (car grp))
      (command "_.LINE" (cadr item) (caddr item) "")
    )
  )

  ;; レイヤを戻す
  (if lay
    (setvar "CLAYER" *prev-lay*)
  )
)


;;------------------------------------------------------------
;; 公開コマンド定義
;;------------------------------------------------------------

;; 元のレイヤに生成
(defun c:POFFSET ()
  (vl-load-com)
  (poffset-main nil)
)

;; カレントレイヤに生成
(defun c:POFFSETC ()
  (vl-load-com)
  (poffset-main T)
)

(princ "\nPOFFSET / POFFSETC コマンド読み込み完了")
(princ)

; =============================================================================
(princ "\n【acadoc.lsp ロード完了】\n")
(princ)
; =============================================================================
