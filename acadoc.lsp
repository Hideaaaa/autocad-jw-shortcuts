; =============================================================================
; acadoc.lsp - AutoCAD Jw風カスタムLISPルーチン集
; =============================================================================
; 動作確認環境:
;   - Windows AutoCAD 2027
;   - Mac AutoCAD 2026
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
(setvar "FILEDIA" 1)	;保存ダイヤログを表示
(setvar "LWDISPLAY" 1)	;線幅を設定

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

; BWGT 面積、板厚から重量（BWGTレイヤへCSV形式記録）
; BWGT: 通常板（複数可）  BWGTH: 穴あき板
; BWGTC: CSV出力         BWGTCHK: 計算検証

(defun bwgt:ensure-layer (/)
  (if (not (tblsearch "LAYER" "BWGT"))
    (entmake
      (list
        '(0 . "LAYER")
        '(100 . "AcDbSymbolTableRecord")
        '(100 . "AcDbLayerTableRecord")
        '(70 . 0)
        '(62 . 8)
        '(6 . "Continuous")
        '(2 . "BWGT"))))
  (bwgt:set-layer-color "BWGT" 8)
  (princ))

(defun bwgt:unlock-layer (/)
  (bwgt:set-layer-lock "BWGT" nil)
  (princ))

(defun bwgt:lock-layer (/)
  (bwgt:set-layer-lock "BWGT" T)
  (princ))

(defun bwgt:put-or-add (code val ed / pair)
  (if (setq pair (assoc code ed))
    (subst (cons code val) pair ed)
    (append ed (list (cons code val)))))

(defun bwgt:set-layer-color (lay col / e ed)
  (if (setq e (tblobjname "LAYER" lay))
    (progn
      (setq ed (entget e))
      (setq ed (bwgt:put-or-add 62 col ed))
      (entmod ed)
      (entupd e))))

(defun bwgt:set-layer-lock (lay lockp / e ed f70)
  (if (setq e (tblobjname "LAYER" lay))
    (progn
      (setq ed (entget e))
      (setq f70 (cdr (assoc 70 ed)))
      (if (null f70) (setq f70 0))
      (if lockp
        (if (= 0 (logand f70 4)) (setq f70 (+ f70 4)))
        (if (/= 0 (logand f70 4)) (setq f70 (- f70 4))))
      (setq ed (bwgt:put-or-add 70 f70 ed))
      (entmod ed)
      (entupd e))))

(defun bwgt:pt2d (pt)
  (list (car pt) (cadr pt) 0.0))

; ---- 純 AutoLISP 面積計算（AREA コマンド不使用） ----

(defun bwgt:shoelace (pts / n i j area)
  (setq n (length pts))
  (if (< n 3)
    0.0
    (progn
      (setq area 0.0 i 0)
      (while (< i n)
        (setq j (rem (+ i 1) n))
        (setq area (+ area
          (- (* (car  (nth i pts)) (cadr (nth j pts)))
             (* (car  (nth j pts)) (cadr (nth i pts))))))
        (setq i (1+ i)))
      (abs (/ area 2.0)))))

(defun bwgt:calc-area-mm2 (ent / ed typ pts e vdata)
  (setq ed (entget ent))
  (setq typ (cdr (assoc 0 ed)))
  (cond
    ((= typ "CIRCLE")
     (* pi (expt (cdr (assoc 40 ed)) 2.0)))
    ((= typ "LWPOLYLINE")
     (setq pts '())
     (foreach pair ed
       (if (= (car pair) 10)
         (setq pts (append pts (list (cdr pair))))))
     (bwgt:shoelace pts))
    ((= typ "POLYLINE")
     (setq pts '())
     (setq e (entnext ent))
     (while (and e (= (cdr (assoc 0 (entget e))) "VERTEX"))
       (setq vdata (entget e))
       (setq pts (append pts (list (cdr (assoc 10 vdata)))))
       (setq e (entnext e)))
     (bwgt:shoelace pts))
    (T nil)))

(defun bwgt:calc-weight-kg (area-mm2 thk-mm dens-tm3)
  (* (/ area-mm2 1000000.0) (/ thk-mm 1000.0) dens-tm3 1000.0))

(defun bwgt:anno-scale (/ s)
  (setq s (getvar "CANNOSCALEVALUE"))
  (if (and (numberp s) (> s 0.0)) s 1.0))

; ---- 幾何ヘルパー ----

(defun bwgt:bbox-center (pts / p xmin xmax ymin ymax)
  (if (null pts)
    nil
    (progn
      (setq p (car pts)
            xmin (car p) xmax (car p) ymin (cadr p) ymax (cadr p))
      (foreach p (cdr pts)
        (if (< (car p) xmin) (setq xmin (car p)))
        (if (> (car p) xmax) (setq xmax (car p)))
        (if (< (cadr p) ymin) (setq ymin (cadr p)))
        (if (> (cadr p) ymax) (setq ymax (cadr p))))
      (list (/ (+ xmin xmax) 2.0) (/ (+ ymin ymax) 2.0) 0.0))))

(defun bwgt:lwpoly-pts (ed / pts)
  (setq pts '())
  (foreach pair ed
    (if (= (car pair) 10)
      (setq pts (append pts (list (cdr pair))))))
  pts)

(defun bwgt:poly-pts (ent / e ed pts)
  (setq pts '())
  (setq e (entnext ent))
  (while (and e (= (cdr (assoc 0 (entget e))) "VERTEX"))
    (setq ed (entget e))
    (setq pts (append pts (list (cdr (assoc 10 ed)))))
    (setq e (entnext e)))
  pts)

(defun bwgt:entity-center (ent / ed typ)
  (setq ed (entget ent))
  (setq typ (cdr (assoc 0 ed)))
  (cond
    ((member typ '("CIRCLE" "ARC" "ELLIPSE" "INSERT" "TEXT" "MTEXT"))
     (bwgt:pt2d (cdr (assoc 10 ed))))
    ((= typ "LWPOLYLINE")
     (bwgt:bbox-center (bwgt:lwpoly-pts ed)))
    ((= typ "POLYLINE")
     (bwgt:bbox-center (bwgt:poly-pts ent)))
    (T
     (if (assoc 10 ed)
       (bwgt:pt2d (cdr (assoc 10 ed)))
       nil))))

(defun bwgt:nearest-point (base pts / p best bestd d)
  (setq best nil bestd 1.0e99)
  (foreach p pts
    (setq d (distance base p))
    (if (< d bestd) (progn (setq best p) (setq bestd d))))
  best)

(defun bwgt:entity-anchor (ent ref-pt / ed typ center rad)
  (setq ed (entget ent))
  (setq typ (cdr (assoc 0 ed)))
  (cond
    ((= typ "LINE")
     (list
       (/ (+ (car  (cdr (assoc 10 ed))) (car  (cdr (assoc 11 ed)))) 2.0)
       (/ (+ (cadr (cdr (assoc 10 ed))) (cadr (cdr (assoc 11 ed)))) 2.0)
       0.0))
    ((= typ "LWPOLYLINE")
     (bwgt:nearest-point ref-pt (bwgt:lwpoly-pts ed)))
    ((= typ "POLYLINE")
     (bwgt:nearest-point ref-pt (bwgt:poly-pts ent)))
    ((= typ "CIRCLE")
     (setq center (bwgt:pt2d (cdr (assoc 10 ed))))
     (setq rad (cdr (assoc 40 ed)))
     (polar center (angle center ref-pt) rad))
    ((= typ "ARC")
     (setq center (bwgt:pt2d (cdr (assoc 10 ed))))
     (setq rad (cdr (assoc 40 ed)))
     (polar center (angle center ref-pt) rad))
    (T (bwgt:entity-center ent))))

(defun bwgt:auto-text-point (center idx th)
  (list
    (+ (car  center) (* 8.0 th))
    (+ (cadr center) (* th (+ 3.0 (* 2.0 idx))))
    0.0))

(defun bwgt:starts-with (s prefix)
  (and s prefix
       (>= (strlen s) (strlen prefix))
       (= (substr s 1 (strlen prefix)) prefix)))

(defun bwgt:csv-text (txt / pos)
  (cond
    ((null txt) nil)
    (T
     (setq pos (vl-string-search "| BWGT," txt))
     (if pos (substr txt (+ pos 4)) nil))))

(defun bwgt:split (s sep / pos out token)
  (setq out '())
  (while (setq pos (vl-string-search sep s))
    (setq token (substr s 1 pos))
    (setq out (append out (list token)))
    (setq s (substr s (+ pos (strlen sep) 1))))
  (append out (list s)))

(defun bwgt:next-id (/ ss i ent ed txt cols maxid idval)
  (setq maxid 0)
  (if (setq ss (ssget "X" '((8 . "BWGT") (0 . "TEXT"))))
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq ed (entget ent))
        (setq txt (bwgt:csv-text (cdr (assoc 1 ed))))
        (if txt
          (progn
            (setq cols (bwgt:split txt ","))
            (if (>= (length cols) 2)
              (progn
                (setq idval (atoi (nth 1 cols)))
                (if (> idval maxid) (setq maxid idval))))))
        (setq i (1+ i)))))
  (1+ maxid))

(defun bwgt:ask-params (/)
  (if (not (numberp *bwgt-last-thk*))  (setq *bwgt-last-thk*  9.0))
  (if (not (numberp *bwgt-last-dens*)) (setq *bwgt-last-dens* 7.85))
  (setq bwgt:tmp (getreal (strcat "\n板厚 t(mm) [Enter=" (rtos *bwgt-last-thk* 2 2) "]: ")))
  (if (numberp bwgt:tmp)
    (setq *bwgt-last-thk* bwgt:tmp))
  (setq bwgt:tmp (getreal (strcat "\n密度 t/m3 [Enter=" (rtos *bwgt-last-dens* 2 2) "]: ")))
  (if (numberp bwgt:tmp)
    (setq *bwgt-last-dens* bwgt:tmp))
  T)

(defun bwgt:make-group (name ss /)
  (if (and ss (> (sslength ss) 0))
    (progn
      (setq bwgt:nod (namedobjdict))
      (setq bwgt:gd (dictsearch bwgt:nod "ACAD_GROUP"))
      (if bwgt:gd
        (setq bwgt:gdict (cdr (assoc -1 bwgt:gd)))
        (setq bwgt:gdict
          (dictadd bwgt:nod "ACAD_GROUP"
            (entmakex '((0 . "DICTIONARY") (100 . "AcDbDictionary") (280 . 0) (281 . 1))))))
      (setq bwgt:i 0)
      (setq bwgt:data
        (list
          '(0 . "GROUP")
          '(100 . "AcDbGroup")
          '(300 . "BWGT")
          '(70 . 0)
          '(71 . 1)))
      (while (< bwgt:i (sslength ss))
        (setq bwgt:data (append bwgt:data (list (cons 340 (ssname ss bwgt:i)))))
        (setq bwgt:i (1+ bwgt:i)))
      (setq bwgt:grp (entmakex bwgt:data))
      (if bwgt:grp
        (vl-catch-all-apply 'dictadd (list bwgt:gdict name bwgt:grp)))))
  (princ))

(defun bwgt:number-text-p (s / n)
  (setq n (distof s 2))
  (numberp n))

(defun bwgt:valid-csv-cols (cols)
  (and (>= (length cols) 6)
       (> (atoi (nth 1 cols)) 0)
       (bwgt:number-text-p (nth 3 cols))
       (bwgt:number-text-p (nth 4 cols))
       (bwgt:number-text-p (nth 5 cols))))

; 1 件の注記＋矢印を作成してグループ化、成功なら T を返す
(defun bwgt:draw-record (id area-mm2 thk-mm dens w ent idx th
                         / center txtpt anchor csvline label grp-ss ang wing p1 p2)
  (setq center (bwgt:entity-center ent))
  (if (null center)
    nil
    (progn
      (setq txtpt (bwgt:auto-text-point center idx th))
      (setq anchor (bwgt:entity-anchor ent txtpt))
      (setq csvline
        (strcat "BWGT," (itoa id)
          "," (rtos (/ area-mm2 1000000.0) 2 6)
          "," (rtos thk-mm 2 3)
          "," (rtos dens 2 4)
          "," (rtos w 2 3)))
      (setq label
        (strcat "ID" (itoa id)
          "  t=" (rtos thk-mm 2 1) "mm"
          "  W=" (rtos w 2 2) "kg"
          "  | " csvline))
      (entmakex
        (list '(0 . "TEXT")
          (cons 8 "BWGT")
          (cons 10 txtpt)
          (cons 40 th)
          (cons 1 label)))
      (setq grp-ss (ssadd))
      (ssadd (entlast) grp-ss)
      (if (and anchor (> (distance txtpt anchor) 0.001))
        (progn
          (setq ang  (angle txtpt anchor))
          (setq wing (* th 1.2))
          (entmakex (list '(0 . "LINE") (cons 8 "BWGT")
            (cons 10 txtpt) (cons 11 anchor)))
          (ssadd (entlast) grp-ss)
          (setq p1 (polar anchor (+ ang 2.7) wing))
          (setq p2 (polar anchor (- ang 2.7) wing))
          (entmakex (list '(0 . "LINE") (cons 8 "BWGT")
            (cons 10 anchor) (cons 11 p1)))
          (ssadd (entlast) grp-ss)
          (entmakex (list '(0 . "LINE") (cons 8 "BWGT")
            (cons 10 anchor) (cons 11 p2)))
          (ssadd (entlast) grp-ss)))
      (bwgt:make-group (strcat "BW" (itoa id)) grp-ss)
      T)))

(defun c:BWGT (/ ss i ent area-mm2 w id th ok)
  (if (not (numberp *bwgt-last-thk*))  (setq *bwgt-last-thk*  9.0))
  (if (not (numberp *bwgt-last-dens*)) (setq *bwgt-last-dens* 7.85))
  (setq ss (ssget "_I"))
  (if (not ss)
    (progn
      (princ "\n板を選択してください（窓選択可）: ")
      (setq ss (ssget))))
  (if (not ss)
    (princ "\n選択されていません。")
    (progn
      (bwgt:ask-params)
      (bwgt:ensure-layer)
      (bwgt:unlock-layer)
      (setq id (bwgt:next-id))
      (setq th (max 1.0 (* 2.0 (getvar "TEXTSIZE") (bwgt:anno-scale))))
      (setq i 0 ok 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq area-mm2 (bwgt:calc-area-mm2 ent))
        (if (and area-mm2 (> area-mm2 0.0))
          (progn
            (setq w (bwgt:calc-weight-kg area-mm2 *bwgt-last-thk* *bwgt-last-dens*))
            (if (bwgt:draw-record id area-mm2 *bwgt-last-thk* *bwgt-last-dens* w ent ok th)
              (progn
                (setq id (1+ id))
                (setq ok (1+ ok))))))
        (setq i (1+ i)))
      (bwgt:lock-layer)
      (princ (strcat "\nBWGT記録: " (itoa ok) " 件"))))
  (princ))

(defun c:BWGTH (/ outer area-mm2 holes i ent hs hole-sum net-mm2 w id th)
  (if (not (numberp *bwgt-last-thk*))  (setq *bwgt-last-thk*  9.0))
  (if (not (numberp *bwgt-last-dens*)) (setq *bwgt-last-dens* 7.85))
  (setq outer (car (entsel "\n外形を選択: ")))
  (if (null outer)
    (princ "\nキャンセルされました。")
    (progn
      (setq area-mm2 (bwgt:calc-area-mm2 outer))
      (if (or (null area-mm2) (<= area-mm2 0.0))
        (princ "\n面積取得できません。閉じたポリライン/円を使用してください。")
        (progn
          (princ "\n穴境界を選択（なければ Enter）: ")
          (setq holes (ssget))
          (setq hole-sum 0.0)
          (if holes
            (progn
              (setq i 0)
              (while (< i (sslength holes))
                (setq ent (ssname holes i))
                (setq hs (bwgt:calc-area-mm2 ent))
                (if (and hs (> hs 0.0))
                  (setq hole-sum (+ hole-sum hs)))
                (setq i (1+ i)))))
          (setq net-mm2 (- area-mm2 hole-sum))
          (if (<= net-mm2 0.0)
            (princ "\n正味面積が0以下です。")
            (progn
              (princ
                (strcat "\n外形=" (rtos (/ area-mm2 1e6) 2 4)
                  "m2  穴=" (rtos (/ hole-sum 1e6) 2 4)
                  "m2  正味=" (rtos (/ net-mm2 1e6) 2 4) "m2"))
              (bwgt:ask-params)
              (setq w (bwgt:calc-weight-kg net-mm2 *bwgt-last-thk* *bwgt-last-dens*))
              (bwgt:ensure-layer)
              (bwgt:unlock-layer)
              (setq id (bwgt:next-id))
              (setq th (max 1.0 (* 2.0 (getvar "TEXTSIZE") (bwgt:anno-scale))))
              (bwgt:draw-record id net-mm2 *bwgt-last-thk* *bwgt-last-dens* w outer 0 th)
              (bwgt:lock-layer)
              (princ (strcat "\nBWGTH記録: ID=" (itoa id) "  重量=" (rtos w 2 2) "kg"))))))))
  (princ))

(defun c:BWGTCHK (/ area thk dens actual)
  ; 検証: 1m x 1m x 1mm x 7.85t/m3 = 7.85kg
  (setq area 1000000.0 thk 1.0 dens 7.85)
  (setq actual (bwgt:calc-weight-kg area thk dens))
  (princ (strcat "\nBWGTCHK: 1m2 x 1mm x 7.85t/m3 = "
    (rtos actual 2 6) "kg (期待値 7.85)"))
  (if (< (abs (- actual 7.85)) 1e-9)
    (princ " [OK]")
    (princ " [NG]"))
  (princ))

(defun c:BWGTC (/ ss i ent ed txt cols records rec path fp count total-w total-q w row)
  (setq ss (ssget "X" '((8 . "BWGT") (0 . "TEXT"))))
  (if (null ss)
    (princ "\nBWGT記録がありません。")
    (progn
      ; レコード収集
      (setq records '() i 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq ed (entget ent))
        (setq txt (bwgt:csv-text (cdr (assoc 1 ed))))
        (if txt
          (progn
            (setq cols (bwgt:split txt ","))
            (if (bwgt:valid-csv-cols cols)
              (setq records
                (cons (list (atoi (nth 1 cols)) cols) records)))))
        (setq i (1+ i)))
      ; ID 降順ソート
      (setq records
        (vl-sort records '(lambda (a b) (> (car a) (car b)))))
      ; 保存先
      (setq path
        (getfiled "CSV保存先"
          (strcat (getvar "DWGPREFIX")
                  (vl-filename-base (getvar "DWGNAME")) "_bwgt.csv")
          "csv" 1))
      (if (null path)
        (princ "\nキャンセルされました。")
        (progn
          (setq fp (open path "w"))
          ; タイトル（図面ファイル名）
          (write-line (strcat (chr 239) (chr 187) (chr 191) (getvar "DWGNAME")) fp)
          ; Header (English)
          (write-line "ID,DENSITY_t_m3,THICKNESS_mm,WEIGHT_kg,QTY,TOTAL_kg" fp)
          (setq count 0 total-w 0.0 total-q 0 row 3)
          (foreach rec records
            (setq cols (cadr rec))
            (setq w (atof (nth 5 cols)))
            (write-line
              (strcat
                (nth 1 cols) ","                 ; ID
                (nth 4 cols) ","                 ; 密度
                (nth 3 cols) ","                 ; 板厚
                (nth 5 cols) ","                 ; 重量
                "1,"                              ; 数量(編集可)
                "=D" (itoa row) "*E" (itoa row)) ; 合計重量(式)
              fp)
            (setq total-w (+ total-w w))
            (setq total-q (1+ total-q))
            (setq row (1+ row))
            (setq count (1+ count)))
          ; 合計行
          (write-line
            (strcat "TOTAL,,,,=SUM(E3:E" (itoa (1- row)) "),=SUM(F3:F" (itoa (1- row)) ")")
            fp)
          (close fp)
          (princ (strcat "\nCSV出力: " (itoa count)
            " 件 -> " path))))))
  (princ))


; -------------------------------------------------------------------------
; Z系 - 補助線（HJ画層）管理
; ロック基本運用版
; -------------------------------------------------------------------------

; Z - 補助線を引く（2点で自動判定→オリジナル無限長）
;     1点目を指定→2点目を指定→距離から水平/垂直を自動判定
;     十分に長い線を両方向に引く
;     実行前のロック状態を記憶して復帰
;     非表示なら自動表示
(defun c:Z (/ prev pt1 pt2 dx dy large laydata islocked islayer_off)
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
  
  ; HJ画層のロック状態を記憶（ビット4がロック）
  (setq laydata (tblsearch "LAYER" "HJ"))
  (setq islocked (= (logand (cdr (assoc 70 laydata)) 4) 4))
  
  ; HJ画層の非表示状態をチェック（ビット1がOFF/非表示）
  (setq islayer_off (= (logand (cdr (assoc 70 laydata)) 2) 0))
  
  ; 非表示なら表示ON
  (if islayer_off
    (progn
      (command "._LAYER" "_ON" "HJ" "")
      (command nil)  ; コマンド終了
    )
  )
  
  (command "._LAYER" "_U" "HJ" "")
  (command nil)  ; コマンド終了
  (setq prev (getvar "CLAYER"))
  (setvar "CLAYER" "HJ")
  
  ; 無限長として使う大きな値
  (setq large 100000)
  
  (while (setq pt1 (getpoint "\n最初の点を指定（Esc終了）: "))
    (setq pt2 (getpoint pt1 "\n2番目の点を指定: "))
    
    ; X方向とY方向の距離を計算
    (setq dx (abs (- (car pt2) (car pt1))))
    (setq dy (abs (- (cadr pt2) (cadr pt1))))
    
    ; どちらが大きいかで水平/垂直を判定して線を引く
    (if (>= dx dy)
      ; 水平線：Y座標は固定、X方向に十分長い線
      (command "._LINE" 
        (list (- (car pt1) large) (cadr pt1)) 
        (list (+ (car pt1) large) (cadr pt1)) 
        "")
      ; 垂直線：X座標は固定、Y方向に十分長い線
      (command "._LINE" 
        (list (car pt1) (- (cadr pt1) large)) 
        (list (car pt1) (+ (cadr pt1) large)) 
        "")
    )
  )
  
  (setvar "CLAYER" prev)
  ; 元のロック状態に復帰
  (if islocked
    (progn
      (command "._LAYER" "_LO" "HJ" "")
      (command nil)  ; コマンド終了
    )
  )
  (princ)
)

; ZD - 補助線を選択して削除（ロック自動管理）
;      ロック状態でも削除可能。ロックされていたら復帰
(defun c:ZD (/ ss laydata islocked)
  (setq laydata (tblsearch "LAYER" "HJ"))
  ; ロック状態をチェック（ビット4がロック）
  (setq islocked (= (logand (cdr (assoc 70 laydata)) 4) 4))
  
  ; ロックされていたら解除
  (if islocked
    (progn
      (command "._LAYER" "_U" "HJ" "")
      (command nil)  ; バッファクリア
    )
  )
  
  (princ "\n削除する補助線を選択 > ")
  ; ユーザーに選択させる
  (setq ss (ssget '((8 . "HJ"))))
  
  (if ss
    (progn
      (command "._ERASE" ss "")
      (princ "\n選択したHJ画層の補助線を削除しました。")
    )
    (princ "\n選択がキャンセルされました。")
  )
  
  ; ロックされていたら再びロック状態に戻す
  (if islocked
    (progn
      (command "._LAYER" "_LO" "HJ" "")
      (command nil)  ; バッファクリア
    )
  )
  (princ)
)

; ZDD - 補助線を全削除（ロック自動管理）
;       ロック状態でも削除可能。ロックされていたら復帰
(defun c:ZDD (/ ss laydata islocked)
  (setq laydata (tblsearch "LAYER" "HJ"))
  ; ロック状態をチェック（ビット4がロック）
  (setq islocked (= (logand (cdr (assoc 70 laydata)) 4) 4))
  
  (if (setq ss (ssget "X" '((8 . "HJ"))))
    (progn
      ; ロックされていたら解除
      (if islocked
        (progn
          (command "._LAYER" "_U" "HJ" "")
          (command nil)  ; バッファクリア
        )
      )
      
      (princ "\nHJ画層の全補助線を削除します...")
      (command "._ERASE" ss "")
      (princ "\nHJ画層のオブジェクトをすべて削除しました。")
      
      ; ロックされていたら再びロック状態に戻す
      (if islocked
        (progn
          (command "._LAYER" "_LO" "HJ" "")
          (command nil)  ; バッファクリア
        )
      )
    )
    (princ "\nHJ画層にオブジェクトはありません。")
  )
  (princ)
)

; ZZ - 補助線非表示
(defun c:ZZ ()
  ; 現在の画層を記憶
  (setq prev (getvar "CLAYER"))
  ; デフォルト画層に切り替え（確認プロンプト回避）
  (setvar "CLAYER" "0")
  ; LAYER _OFF を実行
  (command "._LAYER" "_OFF" "HJ" "")
  (command nil)  ; コマンド終了
  ; 元の画層に戻す
  (setvar "CLAYER" prev)
  (command "._REGEN")
  (princ)
)

; ZF - 補助線フリーズ
(defun c:ZF ()
  (command "._LAYER" "_F" "HJ" "")
  (command nil)  ; コマンド終了
  (princ)
)

; ZFF - 補助線フリーズ解除
(defun c:ZFF ()
  (command "._LAYER" "_T" "HJ" "")
  (command nil)  ; コマンド終了
  (princ)
)

; ZR - 補助線ロック（編集禁止）
(defun c:ZR ()
  (command "._LAYER" "_LO" "HJ" "")
  (command nil)  ; コマンド終了
  (princ)
)

; ZRR - 補助線ロック解除
(defun c:ZRR ()
  (command "._LAYER" "_U" "HJ" "")
  (command nil)  ; コマンド終了
  (princ)
)

; ZN - 補助線ノープロット設定（印刷前に実行）
(defun c:ZN ()
  (command "._LAYER" "_P" "_N" "HJ" "")
  (command nil)  ; コマンド終了
  (princ "\nHJ画層をノープロットに設定。印刷後にZNNで元に戻します。")
  (princ)
)

; ZNN - 補助線ノープロット解除（印刷後に実行）
(defun c:ZNN ()
  (command "._LAYER" "_P" "_P" "HJ" "")
  (command nil)  ; コマンド終了
  (princ "\nHJ画層を印刷設定に戻しました。")
  (princ)
)


;; ============================================================
;; PARTIAL-OFFSET.LSP  v6
;; ポリラインの一部セグメントを選択してオフセットするコマンド
;;
;; コマンド:
;;   POFFSET  - 元のレイヤに生成
;;   POFFSETC - カレントレイヤに生成
;; ============================================================


(defun poffset-main (use-current-layer
                     / pl-ent pl-data lay dist side-pt global-side
                       tmp-ents seg-data-list result-ents poly-vlist)

  (setq pl-ent (car (entsel "\nポリラインを選択: ")))
  (if (null pl-ent) (exit))
  (setq pl-data (entget pl-ent))
  (princ (strcat "\n[DBG] 選択エンティティタイプ: [" (cdr (assoc 0 pl-data)) "]"))
  (if (not (member (cdr (assoc 0 pl-data)) '("LWPOLYLINE" "POLYLINE")))
    (progn (princ "\nLWPOLYLINEを選択してください") (exit))
  )
  (setq lay (cdr (assoc 8 pl-data)))

  ;; UNDO前に頂点リストを保存（内外判定用）
  (setq poly-vlist (poffset-get-vertices pl-ent))

  (setq dist (getdist "\nオフセット距離を入力: "))
  (if (null dist) (exit))

  (setq tmp-ents (poffset-explode pl-ent))
  (if (null tmp-ents) (progn (princ "\n分解失敗") (exit)))
  (princ (strcat "\n" (itoa (length tmp-ents)) " セグメントに分解。選択 [Enter で確定]: "))

  (setq seg-data-list (poffset-select-and-copy tmp-ents))

  (command "_.UNDO" 1)

  (if (null seg-data-list) (progn (princ "\nキャンセル") (exit)))

  (setq side-pt (getpoint "\nオフセット方向を点で指示: "))
  (if (null side-pt) (exit))

  ;; ポリゴンの内外判定でglobal-sideを決定
  (setq global-side (poffset-calc-side-inout poly-vlist (car seg-data-list) side-pt))
  (princ (strcat "\n[DBG] global-side=" (rtos global-side 2 1)))

  (if (not use-current-layer)
    (progn (setq *poff-prev-lay* (getvar "CLAYER")) (setvar "CLAYER" lay))
  )

  (setq result-ents (poffset-draw-all seg-data-list dist global-side))
  (princ (strcat "\n[DBG] 生成エンティティ数: " (itoa (length result-ents))))

  (poffset-join-lines result-ents)

  (if (not use-current-layer) (setvar "CLAYER" *poff-prev-lay*))

  (princ (strcat "\n完了: " (itoa (length result-ents)) " オブジェクト生成"))
  (princ)
)


(defun poffset-explode (ent / before after new-ents)
  (setq before (entlast))
  (command "_.EXPLODE" ent "")
  (setq new-ents '())
  (setq after (if before (entnext before) (entnext)))
  (while after
    (setq new-ents (append new-ents (list after)))
    (setq after (entnext after))
  )
  new-ents
)


(defun poffset-select-and-copy (tmp-ents / data-list picked ent data etype already idx)
  (setq data-list '())
  (while
    (progn (setq picked (entsel)) (not (null picked)))
    (setq ent (car picked))
    (setq already (vl-some '(lambda (x) (equal (cdr (assoc -1 x)) ent)) data-list))
    (cond
      ((not (member ent tmp-ents)) (princ "\n分解されたセグメントを選択"))
      (already (princ "\n既に選択済み"))
      (T
       (setq data (entget ent))
       (setq etype (cdr (assoc 0 data)))
       (if (member etype '("LINE" "ARC"))
         (progn
           ;; tmp-ents内のインデックス（元ポリラインでの位置）を記録
           (setq idx (poffset-find-index ent tmp-ents 0))
           (setq data (append data (list (cons -100 idx))))  ; -100にインデックス保存
           (setq data-list (append data-list (list data)))
           (princ (strcat "\n" etype " 選択 (元位置" (itoa idx) ", 計" (itoa (length data-list)) "本)"))
         )
         (princ "\nLINEまたはARCを選択してください")
       )
      )
    )
  )
  ;; tmp-entsインデックス順にソート（元ポリラインの順序に揃える）
  (if data-list
    (setq data-list (vl-sort data-list
      '(lambda (a b) (< (cdr (assoc -100 a)) (cdr (assoc -100 b))))))
  )
  (if data-list data-list nil)
)


;;------------------------------------------------------------
;; LWPOLYLINE/POLYLINEの頂点リストを取得
;;------------------------------------------------------------
(defun poffset-get-vertices (ent / data etype vlist e vdata)
  (setq data (entget ent))
  (setq etype (cdr (assoc 0 data)))
  (setq vlist '())
  (cond
    ((= etype "LWPOLYLINE")
     (foreach pair data
       (if (= (car pair) 10)
         (setq vlist (append vlist (list (cdr pair))))
       )
     )
    )
    ((= etype "POLYLINE")
     (setq e (entnext ent))
     (while (and e (= (cdr (assoc 0 (entget e))) "VERTEX"))
       (setq vdata (entget e))
       (setq vlist (append vlist (list (cdr (assoc 10 vdata)))))
       (setq e (entnext e))
     )
    )
  )
  vlist
)


;;------------------------------------------------------------
;; 点がポリゴンの内側にあるか判定（crossing number法）
;;------------------------------------------------------------
(defun poffset-point-in-polygon (pt vlist / n i j px py vix viy vjx vjy inside)
  (setq n (length vlist))
  (setq px (car pt))
  (setq py (cadr pt))
  (setq inside nil)
  (setq i 0)
  (repeat n
    (setq j (if (= i (1- n)) 0 (1+ i)))
    (setq vix (car  (nth i vlist)))
    (setq viy (cadr (nth i vlist)))
    (setq vjx (car  (nth j vlist)))
    (setq vjy (cadr (nth j vlist)))
    (if (and (not (eq (>= py viy) (>= py vjy)))
             (< px (+ vix (* (/ (- py viy) (- vjy viy)) (- vjx vix)))))
      (setq inside (not inside))
    )
    (setq i (1+ i))
  )
  inside
)


;;------------------------------------------------------------
;; ポリゴンの内外判定でglobal-sideを決定
;;------------------------------------------------------------
(defun poffset-calc-side-inout (poly-vlist data side-pt
                                 / etype p1 p2 cx cy dx dy len nx ny test-pt
                                   inside-test outside-want)
  (setq outside-want (not (poffset-point-in-polygon side-pt poly-vlist)))
  (princ (strcat "\n[DBG] side-pt は " (if outside-want "外側" "内側")))

  (setq etype (cdr (assoc 0 data)))
  (cond
    ((= etype "LINE")
     (setq p1 (cdr (assoc 10 data)))
     (setq p2 (cdr (assoc 11 data)))
     (setq dx (- (car p2) (car p1)))
     (setq dy (- (cadr p2) (cadr p1)))
     (setq len (sqrt (+ (* dx dx) (* dy dy))))
     (setq nx (/ (- dy) len))
     (setq ny (/ dx len))
     (setq cx (* 0.5 (+ (car p1) (car p2))))
     (setq cy (* 0.5 (+ (cadr p1) (cadr p2))))
     (setq test-pt (list (+ cx (* nx 0.1)) (+ cy (* ny 0.1)) 0.0))
     (setq inside-test (poffset-point-in-polygon test-pt poly-vlist))
     (princ (strcat "\n[DBG] 左法線方向は " (if inside-test "内側" "外側")))
     (if (eq outside-want (not inside-test))
       1.0
       -1.0
     )
    )
    ((= etype "ARC")
     (if outside-want 1.0 -1.0)
    )
    (T 1.0)
  )
)


;;------------------------------------------------------------
;; リスト中のエンティティのインデックスを返す
;;------------------------------------------------------------
(defun poffset-find-index (ent lst idx)
  (cond
    ((null lst) -1)
    ((equal (car lst) ent) idx)
    (T (poffset-find-index ent (cdr lst) (1+ idx)))
  )
)


(defun poffset-draw-all (seg-data-list dist global-side / result ent orig-idx)
  (setq result '())
  (foreach data seg-data-list
    (setq ent (poffset-draw-one data dist global-side))
    (setq orig-idx (cdr (assoc -100 data)))
    (if ent (setq result (append result (list (cons ent orig-idx)))))
  )
  result
)


(defun poffset-draw-one (data dist global-side / etype)
  (setq etype (cdr (assoc 0 data)))
  (cond
    ((= etype "LINE") (poffset-draw-line data dist global-side))
    ((= etype "ARC")  (poffset-draw-arc  data dist global-side))
    (T nil)
  )
)


(defun poffset-draw-line (data dist global-side / p1 p2 dx dy len nx ny op1 op2)
  (setq p1 (cdr (assoc 10 data)))
  (setq p2 (cdr (assoc 11 data)))
  (setq dx (- (car p2) (car p1)))
  (setq dy (- (cadr p2) (cadr p1)))
  (setq len (sqrt (+ (* dx dx) (* dy dy))))
  (if (< len 1e-10) (return nil))
  (setq nx (* (/ (- dy) len) dist global-side))
  (setq ny (* (/ dx  len) dist global-side))
  (setq op1 (list (+ (car p1) nx) (+ (cadr p1) ny) 0.0))
  (setq op2 (list (+ (car p2) nx) (+ (cadr p2) ny) 0.0))
  (princ (strcat "\n[DBG] LINE offset op1=" (rtos (car op1) 2 2) "," (rtos (cadr op1) 2 2)
    " op2=" (rtos (car op2) 2 2) "," (rtos (cadr op2) 2 2)))
  (entmake (list '(0 . "LINE") (cons 10 op1) (cons 11 op2)))
  (entlast)
)


(defun poffset-draw-arc (data dist global-side / cx cy cz radius ang-s ang-e new-r)
  (setq cx     (car   (cdr (assoc 10 data))))
  (setq cy     (cadr  (cdr (assoc 10 data))))
  (setq cz     (caddr (cdr (assoc 10 data))))
  (setq radius (cdr (assoc 40 data)))
  (setq ang-s  (cdr (assoc 50 data)))
  (setq ang-e  (cdr (assoc 51 data)))
  (setq new-r  (+ radius (* dist global-side)))
  (princ (strcat "\n[DBG] ARC center=" (rtos cx 2 2) "," (rtos cy 2 2)
    " r=" (rtos radius 2 2) " -> " (rtos new-r 2 2)
    " ang=" (rtos (/ (* ang-s 180) pi) 2 1) "-" (rtos (/ (* ang-e 180) pi) 2 1)))
  (if (<= new-r 1e-10)
    (progn (princ "\nARC消滅スキップ") nil)
    (progn
      (entmake (list '(0 . "ARC")
                     (cons 10 (list cx cy cz))
                     (cons 40 new-r)
                     (cons 50 ang-s)
                     (cons 51 ang-e)))
      (entlast)
    )
  )
)


;;------------------------------------------------------------
;; 連続するLINEグループを交点で結合してポリラインに変換
;; entidx-list: ((entity . orig-idx) ...) 元ポリラインでの位置順
;;------------------------------------------------------------
(defun poffset-join-lines (entidx-list / n i groups grp e1 e2 t1 t2 idx1 idx2)
  (setq n (length entidx-list))
  (if (< n 2) (return))

  (setq groups '())
  (setq grp (list (car entidx-list)))
  (setq i 1)
  (repeat (1- n)
    (setq e1 (nth (1- i) entidx-list))
    (setq e2 (nth i entidx-list))
    (setq t1 (cdr (assoc 0 (entget (car e1)))))
    (setq t2 (cdr (assoc 0 (entget (car e2)))))
    (setq idx1 (cdr e1))
    (setq idx2 (cdr e2))
    (princ (strcat "\n[DBG] idx" (itoa idx1) "(" t1 ") - idx" (itoa idx2) "(" t2 ") 差=" (itoa (- idx2 idx1))))
    (if (and (= t1 "LINE") (= t2 "LINE") (= (- idx2 idx1) 1))
      (setq grp (append grp (list e2)))
      (progn
        (setq groups (append groups (list grp)))
        (setq grp (list e2))
      )
    )
    (setq i (1+ i))
  )
  (setq groups (append groups (list grp)))

  (princ (strcat "\n[DBG] グループ数: " (itoa (length groups)) " (単独含む)"))
  (foreach grp groups
    (if (and (> (length grp) 1)
             (= (cdr (assoc 0 (entget (car (car grp))))) "LINE"))
      (poffset-make-lwpoly (mapcar 'car grp))
    )
  )
)


;;------------------------------------------------------------
;; LINEグループ→交点計算→LWPOLYLINE生成
;;------------------------------------------------------------
(defun poffset-make-lwpoly (grp
                             / n i d1 d2 p1s p1e p2s p2e isect pts clean-pts
                               pline-data result result2 vresult sresult)
  (setq n (length grp))

  ;; 最初のLINEの始点
  (setq d1 (entget (car grp)))
  (setq pts (list (cdr (assoc 10 d1))))

  ;; 隣接ペアの交点を頂点として追加
  (setq i 0)
  (repeat (1- n)
    (setq d1 (entget (nth i grp)))
    (setq d2 (entget (nth (1+ i) grp)))
    (setq p1s (cdr (assoc 10 d1)))
    (setq p1e (cdr (assoc 11 d1)))
    (setq p2s (cdr (assoc 10 d2)))
    (setq p2e (cdr (assoc 11 d2)))
    (setq isect (poffset-isect p1s p1e p2s p2e))
    (princ (strcat "\n[DBG] 交点" (itoa i) ": "
      (if isect (strcat (rtos (car isect) 2 2) "," (rtos (cadr isect) 2 2)) "なし")))
    (setq pts (append pts (list (if isect isect p1e))))
    (setq i (1+ i))
  )

  ;; 最後のLINEの終点
  (setq d2 (entget (last grp)))
  (setq pts (append pts (list (cdr (assoc 11 d2)))))

  ;; 重複頂点除去
  (setq clean-pts (list (car pts)))
  (foreach pt (cdr pts)
    (if (> (distance (last clean-pts) pt) 1e-4)
      (setq clean-pts (append clean-pts (list pt)))
    )
  )
  (princ (strcat "\n[DBG] 頂点(" (itoa (length clean-pts)) "):"))
  (foreach pt clean-pts
    (princ (strcat "\n[DBG]  " (rtos (car pt) 2 2) "," (rtos (cadr pt) 2 2)))
  )

  (if (< (length clean-pts) 2) (progn (princ "\n頂点不足スキップ") (return)))

  ;; LWPOLYLINE entmake（2D点 X Y で試行）
  (setq pline-data
    (append
      (list '(0 . "LWPOLYLINE") (cons 90 (length clean-pts)) '(70 . 0))
      (mapcar '(lambda (pt) (cons 10 (list (car pt) (cadr pt)))) clean-pts)
    )
  )
  (princ (strcat "\n[DBG] LWPOLYLINE entmake試行(2D点, " (itoa (length pline-data)) "要素): "))
  (foreach d pline-data (princ (strcat "\n[DBG]   " (vl-prin1-to-string d))))

  (setq result (entmake pline-data))
  (princ (strcat "\n[DBG] entmake結果: " (if result "成功" "nil")))

  (if result
    (progn
      (foreach e grp (entdel e))
      (princ (strcat "\n✓ " (itoa n) " 本→LWPOLYLINE(" (itoa (length clean-pts)) "頂点)"))
    )
    (progn
      ;; POLYLINE + VERTEX 形式で再試行
      (princ "\n[DBG] LWPOLYLINE失敗。POLYLINE形式で再試行")
      (setq result2 (entmake (list '(0 . "POLYLINE")
                                     '(66 . 1)
                                     '(70 . 0)
                                     (cons 10 (list 0.0 0.0 0.0)))))
      (princ (strcat "\n[DBG] POLYLINEヘッダentmake結果: " (if result2 "成功" "nil")))
      (if result2
        (progn
          (foreach pt clean-pts
            (setq vresult (entmake (list '(0 . "VERTEX")
                                          '(70 . 0)
                                          (cons 10 (list (car pt) (cadr pt) 0.0)))))
            (princ (strcat "\n[DBG] VERTEX " (rtos (car pt) 2 2) "," (rtos (cadr pt) 2 2)
              " entmake結果: " (if vresult "成功" "nil")))
          )
          (setq sresult (entmake '((0 . "SEQEND"))))
          (princ (strcat "\n[DBG] SEQEND entmake結果: " (if sresult "成功" "nil")))
          (if sresult
            (progn
              (foreach e grp (entdel e))
              (princ (strcat "\n✓ " (itoa n) " 本→POLYLINE(" (itoa (length clean-pts)) "頂点)"))
            )
            (princ "\n✗ SEQEND失敗 LINEはそのまま")
          )
        )
        (princ "\n✗ POLYLINEヘッダ失敗 LINEはそのまま")
      )
    )
  )
)


;;------------------------------------------------------------
;; ARCの指定角度における円周上の点
;;------------------------------------------------------------
(defun poffset-arc-pt (arc-data angle / cx cy r pt)
  (setq cx (car  (cdr (assoc 10 arc-data))))
  (setq cy (cadr (cdr (assoc 10 arc-data))))
  (setq r  (cdr (assoc 40 arc-data)))
  (setq pt (list (+ cx (* r (cos angle))) (+ cy (* r (sin angle))) 0.0))
  (princ (strcat "\n[DBG] arc-pt: center=" (rtos cx 2 2) "," (rtos cy 2 2)
    " r=" (rtos r 2 2) " angle=" (rtos (/ (* angle 180) pi) 2 1)
    " -> " (rtos (car pt) 2 2) "," (rtos (cadr pt) 2 2)))
  pt
)


;;------------------------------------------------------------
;; 2直線の交点（無限延長）
;;------------------------------------------------------------
(defun poffset-isect (p1 p2 p3 p4 / dx1 dy1 dx2 dy2 denom t-val)
  (setq dx1 (- (car p2)  (car p1)))
  (setq dy1 (- (cadr p2) (cadr p1)))
  (setq dx2 (- (car p4)  (car p3)))
  (setq dy2 (- (cadr p4) (cadr p3)))
  (setq denom (- (* dx1 dy2) (* dy1 dx2)))
  (if (< (abs denom) 1e-10) nil
    (progn
      (setq t-val (/ (+ (* (- (car p3) (car p1)) dy2)
                        (* (- (cadr p1) (cadr p3)) dx2))
                     denom))
      (list (+ (car p1)  (* t-val dx1))
            (+ (cadr p1) (* t-val dy1))
            0.0)
    )
  )
)


(defun c:POFFSET  () (poffset-main nil))
(defun c:POFFSETC () (poffset-main T))

(princ "\nPOFFSET / POFFSETC 読み込み完了 (v6)")
(princ)

;;; ===================================================
;;; FILLET0.LSP
;;; フィレット半径0専用・連続実行コマンド
;;; コマンド名: F0
;;; ===================================================
;;;
;;; 説明：
;;;   FILLETコマンドの半径を常に0に固定し、
;;;   2辺を選択し続ける限り連続して角を作成（突き合わせ・角落とし）できる。
;;;   半径入力やオプション選択の手間を省略。
;;;
;;; 使い方：
;;;   コマンドラインで F0 と入力
;;;   1本目の線（または辺）をクリック
;;;   2本目の線（または辺）をクリック
;;;   → 角が作成される
;;;   そのまま次の1本目をクリック → 2本目をクリック…と繰り返せる
;;;   Enter または ESC で終了
;;;
;;; ===================================================

(defun c:F0 ( / e1 e2 cmdold)
  (setq cmdold (getvar "CMDECHO"))
  (setvar "CMDECHO" 1)
  (setvar "FILLETRAD" 0.0)  ; 半径を0に固定
  (while
    (progn
      (setq e1 (entsel "\n1本目の線を選択: "))
      (if e1
        (progn
          (setq e2 (entsel "\n2本目の線を選択: "))
          (if (and e2 (not (equal (car e1) (car e2))))
            (progn
              ;; エンティティ名ではなく、ピックした座標(点)を渡す方式
              ;; FILLETの対話プロンプトとの相性が良く安定する
              (command "_.FILLET")
              (command (cadr e1))
              (command (cadr e2))
              T  ; 続行
            )
            nil  ; 2本目が選択されなければ、または同一オブジェクトなら終了
          )
        )
        nil  ; 1本目が選択されなければ終了
      )
    )
  )
  (setvar "CMDECHO" cmdold)
  (princ "\nF0 終了")
  (princ)
)

(princ "\nF0 コマンドをロードしました。(半径0固定フィレット・連続実行)")
(princ)

;;; ===================================================
;;; OFFSET-LAYER.LSP
;;; オフセット・レイヤ制御コマンド
;;; コマンド名: F  （元のレイヤを保持）
;;;            FC （カレントレイヤに強制）
;;; ===================================================
;;;
;;; 説明：
;;;   OFFSETコマンドには「レイヤ(L)」オプションがあり、
;;;   オフセット結果を「元のオブジェクト」「現在の画層」のどちらに
;;;   するか、コマンド内から直接指定できる。
;;;   （システム変数OFFSETLAYERをSETVARで直接書き換える方式は
;;;     環境によって型エラーになることがあるため、
;;;     コマンドオプション経由の指定に変更した。）
;;;
;;;   F  ：OFFSETコマンドを起動し、レイヤ(L)オプションを
;;;        自動で「元のオブジェクト(S)」に設定
;;;   FC ：OFFSETコマンドを起動し、レイヤ(L)オプションを
;;;        自動で「現在の画層(C)」に設定
;;;
;;;   どちらもオプション設定後はOFFSETコマンドの通常の対話
;;;   （距離指定→選択→側を指定）が続き、連続実行できる。
;;;
;;; 使い方：
;;;   コマンドラインで F または FC と入力
;;;   オフセット距離を指定（数値入力 or 2点指定 or T:通過点 など）
;;;   オフセットしたいオブジェクトを選択
;;;   オフセットする側をクリック
;;;   そのまま続けて選択→クリックを繰り返せる
;;;   Enter または ESC で終了
;;;
;;; ===================================================

;; ---------------------------------------------------
;; F ： 元のレイヤを保持してオフセット
;;      OFFSETの「レイヤ(L)」オプション→「元のオブジェクト(S)」を自動選択
;; ---------------------------------------------------
(defun c:F ( )
  (command "_.OFFSET" "_L" "_S")
  (princ)
)

;; ---------------------------------------------------
;; FC ： カレントレイヤに強制してオフセット
;;      OFFSETの「レイヤ(L)」オプション→「現在の画層(C)」を自動選択
;; ---------------------------------------------------
(defun c:FC ( )
  (command "_.OFFSET" "_L" "_C")
  (princ)
)

(princ "\nF / FC コマンドをロードしました。(F=元レイヤ保持オフセット, FC=カレントレイヤ強制オフセット)")
(princ)

; =============================================================================
(princ "\n【acadoc.lsp ロード完了】\n")
(princ)
; =============================================================================
