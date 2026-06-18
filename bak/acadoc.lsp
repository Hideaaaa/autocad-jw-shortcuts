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
; 【6. W - 属性取得（JWGET）】
; オブジェクトの画層・色・線種・文字スタイル・寸法スタイル・ハッチを一括取得
; Windows 動作確認済み / Mac 未検証
; -------------------------------------------------------------------------
(defun c:W (/ e ed ds)
  (setq e (car (entsel "\n属性取得: ")))
  (if e
    (progn
      (setq ed (entget e))
      (if (assoc 8   ed) (setvar "CLAYER"    (cdr (assoc 8   ed))))
      (if (assoc 62  ed) (command "_.-COLOR" (itoa (cdr (assoc 62 ed)))) (command "_.-COLOR" "_BYLAYER"))
      (if (assoc 6   ed) (setvar "CELTYPE"   (cdr (assoc 6   ed))))
      (if (assoc 370 ed) (setvar "CELWEIGHT" (cdr (assoc 370 ed))))
      (if (member (cdr (assoc 0 ed)) '("TEXT" "MTEXT"))
        (progn
          (if (assoc 7  ed) (setvar "TEXTSTYLE" (cdr (assoc 7  ed))))
          (if (assoc 40 ed) (setvar "TEXTSIZE"  (cdr (assoc 40 ed))))))
      (if (member (cdr (assoc 0 ed)) '("DIMENSION"))
        (progn
          (setq ds (cdr (assoc 3 ed)))
          (if ds (command "_.DIMSTYLE" "_R" ds))))
      (if (assoc 48 ed) (setvar "CELTSCALE" (cdr (assoc 48 ed))))
      (if (= (cdr (assoc 0 ed)) "HATCH")
        (progn
          (if (assoc 41 ed) (setvar "HPSCALE" (cdr (assoc 41 ed))))
          (if (assoc 52 ed) (setvar "HPANG"   (cdr (assoc 52 ed))))))
      (princ "\n現在属性を取得しました")))
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

; BWGT - 未実装（各自追加してください）
(defun c:BWGT ()
  (princ "\nBWGT: 未実装")
  (princ)
)

;フィレットを繰り返しコマンドに
(defun c:R ()
  (vl-cmdf "._FILLET" "_M")
  (princ)
)

; =============================================================================
(princ "\n【acadoc.lsp ロード完了】\n")
(princ)
; =============================================================================
