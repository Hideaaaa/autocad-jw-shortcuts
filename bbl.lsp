(defun c:BBLE ( / ss i ent elist bname pt sc-x sc-y sc-z rot doc blocks
               new-bname exploded-list j ent-type color linetype linewidth)
  (vl-load-com)
  (setq doc (vla-get-activedocument (vlax-get-acad-object)))
  (setq blocks (vla-get-blocks doc))
  
  (princ "\n========================================")
  (princ "\n[BBLE] ブロック爆発＋ByLayer化")
  (princ "\n========================================")
  
  (if (setq ss (ssget '((0 . "INSERT"))))
    (progn
      (vla-startundomark doc)
      
      (setq i 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq elist (entget ent))
        
        (setq bname (cdr (assoc 2 elist)))
        (setq pt (cdr (assoc 10 elist)))
        (setq sc-x (or (cdr (assoc 41 elist)) 1.0))
        (setq sc-y (or (cdr (assoc 42 elist)) 1.0))
        (setq sc-z (or (cdr (assoc 43 elist)) 1.0))
        (setq rot (or (cdr (assoc 50 elist)) 0.0))
        
        (princ (strcat "\n\n【処理】 " bname))
        
        ;; 1. 爆発
        (princ "\n  → EXPLODE...")
        (command-s "._EXPLODE" ent "")
        (princ " ✓")
        
        ;; 2. 爆発後のセット取得
        (setq exploded-list (ssget "_P"))
        
        (if exploded-list
          (progn
            (princ (strcat "\n  → 爆発後: " (itoa (sslength exploded-list)) "個"))
            
            ;; 3. ByLayer 化
            (setq j 0)
            (while (< j (sslength exploded-list))
              (setq ent (ssname exploded-list j))
              (setq elist (entget ent))
              (setq ent-type (cdr (assoc 0 elist)))
              (setq color (cdr (assoc 62 elist)))
              (setq linetype (cdr (assoc 6 elist)))
              (setq linewidth (cdr (assoc 370 elist)))
              
              (princ (strcat "\n    [" (itoa j) "] " ent-type))
              (if color (princ (strcat " [色:" (itoa color) "]")))
              (if linetype (princ (strcat " [線:" linetype "]")))
              (if linewidth (princ (strcat " [幅:" (itoa linewidth) "]")))
              
              ;; 修正
              (setq elist (vl-remove-if 
                '(lambda (x) (member (car x) '(6 39 62 370 440)))
                elist))
              (entmod elist)
              (entupd ent)
              (princ " → ✓")
              
              (setq j (1+ j))
            )
            
            ;; 4. 新ブロック作成
            (setq new-bname (strcat bname "_BL"))
            (princ (strcat "\n  → ブロック作成: " new-bname))
            
            (if (not (vl-catch-all-error-p
                       (vl-catch-all-apply 'vla-item (list blocks new-bname))))
              (vla-delete (vla-item blocks new-bname))
            )
            
            (command-s "._BLOCK" new-bname pt exploded-list "")
            (princ " ✓")
            
            ;; 5. 新ブロック挿入
            (princ (strcat "\n  → 挿入: " new-bname))
            (command-s "._-INSERT" new-bname pt sc-x (/ sc-y sc-x) rot)
            (princ " ✓")
            
            ;; 6. 属性同期
            (setq exploded-list (ssget "_L"))
            (if exploded-list
              (command-s "._ATTSYNC" "_S" exploded-list "")
            )
          )
          (princ "\n  ⚠ ssget \"_P\" 失敗")
        )
        
        (setq i (1+ i))
      )
      
      (vla-endundomark doc)
      (princ "\n\n========================================")
      (princ "\n【完了】")
      (princ "\n========================================\n")
    )
    (princ "\nブロック選択してください。\n")
  )
  (princ)
)