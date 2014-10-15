;; -*- lexical-binding: t -*-

(require 'haskell-mode-autoloads)

(require 'dash)
(require 's)
(require 'thingatpt)

(defvar-local haskell-echo-info-mode nil)
(add-to-list 'minor-mode-alist '(haskell-echo-info-mode " het"))

;;;###autoload
(defun haskell-echo-info-mode (&optional arg)
  "echo haskell function type on minibuffer"
  (interactive)
  (cond
   ((and (null arg) (not haskell-echo-info-mode))
    (turn-on-haskell-echo-info-mode))
   ((and (not (null arg)) (< 0 arg))
    (turn-on-haskell-echo-info-mode))
   (t
    (turn-off-haskell-echo-info-mode))
   )
  (force-mode-line-update))

(defvar-local haskell-echo-info/process nil)
(defvar-local haskell-echo-info/queue "")

;;;###autoload
(defun turn-on-haskell-echo-info-mode ()
  (interactive)
  (setq haskell-echo-info-mode t)
  (haskell-echo-info/setup)
  (add-hook 'after-save-hook 'haskell-echo-info/reload nil t)
  (add-hook 'kill-buffer-hook 'haskell-echo-info/kill nil t)
  (add-hook 'post-command-hook 'haskell-echo-info nil t))

;;;###autoload
(defun turn-off-haskell-echo-info-mode ()
  (interactive)
  (setq haskell-echo-info-mode nil)
  (if haskell-echo-info/process
      (haskell-echo-info/kill))
  (remove-hook 'after-save-hook 'haskell-echo-info/reload t)
  (remove-hook 'kill-buffer-hook 'haskell-echo-info/kill t)
  (remove-hook 'post-command-hook 'haskell-echo-info t)
  (setq haskell-echo-info/process nil)
  (setq haskell-echo-info/queue ""))

(defun haskell-echo-info/setup ()
  (setq haskell-echo-info/process (start-process "haskell-echo-info" nil "ghci" (buffer-file-name)))
  (process-send-string haskell-echo-info/process ":set prompt \" \"")
  (process-send-string haskell-echo-info/process "\n")
  (set-process-filter haskell-echo-info/process 'haskell-echo-info/output-filter)
  (set-process-query-on-exit-flag haskell-echo-info/process nil))

(defun haskell-echo-info/reload ()
  (process-send-string haskell-echo-info/process (concat ":reload " (buffer-file-name)))
  (process-send-string haskell-echo-info/process "\n"))

(defun haskell-echo-info/kill ()
  (process-send-string haskell-echo-info/process ":quit")
  (process-send-string haskell-echo-info/process "\n"))

(defun haskell-echo-info ()
  (interactive)
  (setq haskell-echo-info/queue "")
  (let ((source (thing-at-point 'sexp)))
    (process-send-string haskell-echo-info/process (concat ":i " (add-bracket-operator source) "\n"))
    (accept-process-output haskell-echo-info/process 0 500 t)))

(defun add-bracket-operator (function-or-operator)
  (if (stringp function-or-operator)
      (if (string-match "^[A-z]+$" function-or-operator)
          function-or-operator
        (concat "(" function-or-operator ")"))))

(defun haskell-echo-info/output-filter (_ stream)
  (setq haskell-echo-info/queue (concat haskell-echo-info/queue (replace-regexp-in-string "\n" " " stream)))
  (if (haskell-echo-info/success? haskell-echo-info/queue)
      (haskell-echo-info/success-output haskell-echo-info/queue))
  ())

(defun haskell-echo-info/success? (stdout)
  (string-match "-- Defined " stdout))

(defun haskell-echo-info/success-output (output)
  (let ((message-log-max nil))          ;messageバッファに記録させない
    (message "%s" output)))

(provide 'haskell-echo-info)
