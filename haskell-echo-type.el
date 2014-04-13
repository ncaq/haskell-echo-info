(require 'haskell-mode)
(require 'thingatpt)

(defvar-local haskell-echo-type-process nil)
(defvar-local haskell-echo-type-output-string "")

(defun haskell-echo-type-setup ()
  (setq haskell-echo-type-process (start-process "haskell-echo-type" nil "ghci" (buffer-file-name)))
  (set-process-filter haskell-echo-type-process 'haskell-echo-type-output-filter)
  (set-process-query-on-exit-flag haskell-echo-type-process nil))

(defun haskell-echo-type-reload ()
  ())

(defun haskell-echo-type-kill ()
  (delete-process haskell-echo-type-process))

(defun haskell-echo-type-request-type (word)
  (process-send-string haskell-echo-type-process (concat ":t " word))
  (process-send-string haskell-echo-type-process "\n")
  (accept-process-output haskell-echo-type-process 0 500)
  haskell-echo-type-output-string)

(defun haskell-echo-type-output-filter (process output)
  (setq haskell-echo-type-output-string (car (split-string output "\n"))))

(defun haskell-echo-type ()
  (interactive)
  (message (haskell-echo-type-request-type (thing-at-point 'sexp))))

(defun turn-on-haskell-echo-type ()
  (interactive)
  (haskell-echo-type-setup)
  (add-hook 'after-save-hook 'haskell-echo-type-reload nil t)
  (add-hook 'post-command-hook 'haskell-echo-type nil t))

(provide 'haskell-echo-type)
