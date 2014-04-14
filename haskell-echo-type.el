(require 'dash)
(require 'haskell-mode)
(require 's)
(require 'thingatpt)

(defvar-local haskell-echo-type/process nil)
(defvar-local haskell-echo-type/queue "")

(defun turn-on-haskell-echo-type ()
  (interactive)
  (haskell-echo-type/setup)
  (add-hook 'after-save-hook 'haskell-echo-type/reload nil t)
  (add-hook 'post-command-hook 'haskell-echo-type nil t))

(defun haskell-echo-type/setup ()
  (setq haskell-echo-type/process (start-process "haskell-echo-type" nil "ghci" (buffer-file-name)))
  (process-send-string haskell-echo-type/process ":set prompt \" \"")
  (process-send-string haskell-echo-type/process "\n")
  (set-process-filter haskell-echo-type/process 'haskell-echo-type/output-filter)
  (set-process-query-on-exit-flag haskell-echo-type/process nil))

(defun haskell-echo-type/reload ()
  (process-send-string haskell-echo-type/process (concat ":reload " (buffer-file-name)))
  (process-send-string haskell-echo-type/process "\n"))

(defun haskell-echo-type ()
  (interactive)
  (setq haskell-echo-type/queue "")
  (let ((source (thing-at-point 'word)))
    (process-send-string haskell-echo-type/process (concat ":t " (add-bracket-symbol source)))
    (process-send-string haskell-echo-type/process "\n")
    (accept-process-output haskell-echo-type/process 0 500 t)))

(defun add-bracket-symbol (source)
  (if (stringp source)
      (if (string-match "[A-z]" source)
          source
        (concat "(" source ")"))))

(defun haskell-echo-type/output-filter (process source)
  (setq haskell-echo-type/queue (concat haskell-echo-type/queue source))
  (let ((source-list (split-string haskell-echo-type/queue "\n")))
    (when (and (haskell-echo-type/success? source-list))
      (haskell-echo-type/success-output source-list))))

(defun haskell-echo-type/success? (source-list)
  (and (string= (car (last source-list)) " ")
       (string-match "^[^\W].+ :: .*[A-Z].*" (car (last source-list 2)))))

(defun haskell-echo-type/success-output (source-list)
  (let ((message (s-trim (car (last source-list 2)))))
    (minibuffer-message message)))

(provide 'haskell-echo-type)
