(require 'haskell-mode)
(require 'thingatpt)

(defvar-local haskell-echo-type/process nil)
(defvar-local haskell-echo-type/output-string "")

(defun haskell-echo-type/setup ()
  (setq haskell-echo-type/process (start-process "haskell-echo-type" nil "ghci" (buffer-file-name)))
  (set-process-filter haskell-echo-type/process 'haskell-echo-type/output-filter)
  (set-process-query-on-exit-flag haskell-echo-type/process nil))

(defun haskell-echo-type/reload ()
  (process-send-string haskell-echo-type/process (concat ":reload " (buffer-file-name)))
  (process-send-string haskell-echo-type/process "\n"))

(defun haskell-echo-type/kill ()
  (delete-process haskell-echo-type/process))

(defun haskell-echo-type/output-filter (process source)
  (setq haskell-echo-type/output-string (car (split-string source "\n"))))

(defun add-bracket-symbol (source)
  (if (stringp source)
      (if (string-match "[A-z]" source)
          source
        (concat "(" source ")"))))

(defun haskell-echo-type ()
  (interactive)
  (let ((source (add-bracket-symbol (thing-at-point 'sexp))))
    (if source
        (progn (process-send-string haskell-echo-type/process (concat ":t " source))
               (process-send-string haskell-echo-type/process "\n")
               (accept-process-output haskell-echo-type/process 0 500)
               (message haskell-echo-type/output-string))
      ())))

(defun turn-on-haskell-echo-type ()
  (interactive)
  (haskell-echo-type/setup)
  (add-hook 'after-save-hook 'haskell-echo-type/reload nil t)
  (add-hook 'post-command-hook 'haskell-echo-type nil t))

(provide 'haskell-echo-type)
