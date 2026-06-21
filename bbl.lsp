(defun bbl:strip-truecolor-data (elist /)
  (vl-remove-if
    '(lambda (pair) (member (car pair) '(420 430)))
    elist))

(defun bbl:put-or-add (code value elist / pair)
  (if (setq pair (assoc code elist))
    (subst (cons code value) pair elist)
    (append elist (list (cons code value)))))

(defun bbl:set-bylayer (ename / elist)
  (if ename
    (progn
      (setq elist (entget ename))
      (if elist
        (progn
          (setq elist (bbl:strip-truecolor-data elist))
          (setq elist (bbl:put-or-add 6 "BYLAYER" elist))
          (setq elist (bbl:put-or-add 62 256 elist))
          (setq elist (bbl:put-or-add 370 -1 elist))
          (entmod elist)
          (entupd ename)
          T)))))

(defun bbl:process-attributes (insert-ename / ent ed type)
  (setq ent (entnext insert-ename))
  (while (and ent
              (progn
                (setq ed (entget ent))
                (setq type (cdr (assoc 0 ed)))
                (/= type "SEQEND")))
    (if (= type "ATTRIB")
      (bbl:set-bylayer ent))
    (setq ent (entnext ent))))

(defun bbl:block-ename (bname)
  (if bname
    (tblobjname "BLOCK" bname)))

(defun bbl:process-block (bname visited / blk ent ed type nested)
  (if (and bname (not (member bname visited)))
    (progn
      (setq visited (cons bname visited))
      (setq blk (bbl:block-ename bname))
      (if blk
        (progn
          (setq ent (entnext blk))
          (while (and ent
                      (progn
                        (setq ed (entget ent))
                        (setq type (cdr (assoc 0 ed)))
                        (/= type "SEQEND")))
            (bbl:set-bylayer ent)
            (if (= type "INSERT")
              (progn
                (bbl:process-attributes ent)
                (setq nested (cdr (assoc 2 ed)))
                (bbl:process-block nested visited)))
            (setq ent (entnext ent))))))))

(defun c:BBLE ( / ss i ent elist objname bname)
  (princ "\n========================================")
  (princ "\n[BBLE] 選択物をByLayer化（ブロック内含む）")
  (princ "\n========================================")

  (if (setq ss (ssget))
    (progn
      (setq i 0)
      (while (< i (sslength ss))
        (setq ent (ssname ss i))
        (setq elist (entget ent))
        (setq objname (cdr (assoc 0 elist)))
        (princ (strcat "\n【処理】 " objname))
        (bbl:set-bylayer ent)
        (if (= objname "INSERT")
          (progn
            (setq bname (cdr (assoc 2 elist)))
            (princ (strcat "\n  → ブロック定義: " bname))
            (bbl:process-attributes ent)
            (bbl:process-block bname nil)
            (princ " ✓"))
          (princ " ✓"))
        (setq i (1+ i)))
      (princ "\n\n========================================")
      (princ "\n【完了】")
      (princ "\n========================================\n"))
    (princ "\n対象を選択してください。\n"))
  (princ))
