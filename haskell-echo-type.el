;; -*- lexical-binding: t -*-
(require 'dash)
(require 'haskell-mode)
(require 's)
(require 'thingatpt)

(defvar-local haskell-echo-type/process nil)
(defvar-local haskell-echo-type/queue nil)

(defun turn-on-haskell-echo-type ()
  (interactive)
  (haskell-echo-type/setup)
  (add-hook 'after-save-hook 'haskell-echo-type/reload nil t)
  (add-hook 'kill-buffer-hook 'haskell-echo-type/kill nil t)
  (add-hook 'post-command-hook 'haskell-echo-type nil t))

(defun turn-off-haskell-echo-type ()
  (interactive)
  (if haskell-echo-type/process
      (haskell-echo-type/kill))
  (remove-hook 'after-save-hook 'haskell-echo-type/reload t)
  (remove-hook 'kill-buffer-hook 'haskell-echo-type/kill t)
  (remove-hook 'post-command-hook 'haskell-echo-type t)
  (setq haskell-echo-type/process nil)
  (setq haskell-echo-type/queue nil))

(defun haskell-echo-type/setup ()
  (setq haskell-echo-type/process (start-process "haskell-echo-type" nil "ghci" (buffer-file-name)))
  (process-send-string haskell-echo-type/process ":set prompt \" \"")
  (process-send-string haskell-echo-type/process "\n")
  (set-process-filter haskell-echo-type/process 'haskell-echo-type/output-filter)
  (set-process-query-on-exit-flag haskell-echo-type/process nil))

(defun haskell-echo-type/reload ()
  (process-send-string haskell-echo-type/process (concat ":reload " (buffer-file-name)))
  (process-send-string haskell-echo-type/process "\n"))

(defun haskell-echo-type/kill ()
  (process-send-string haskell-echo-type/process ":quit")
  (process-send-string haskell-echo-type/process "\n"))

(defun haskell-echo-type ()
  (interactive)
  (setq haskell-echo-type/queue "")
  (let ((source (thing-at-point 'sexp)))
    (process-send-string haskell-echo-type/process (concat ":t " (add-bracket-operator source)))
    (process-send-string haskell-echo-type/process "\n")
    (accept-process-output haskell-echo-type/process 0 500 t)))

(defun add-bracket-operator (function-or-operator)
  (if (stringp function-or-operator)
      (if (string-match "^[A-z]+$" function-or-operator)
          function-or-operator
        (concat "(" function-or-operator ")"))))

(defun haskell-echo-type/output-filter (_ source)
  (setq haskell-echo-type/queue (concat haskell-echo-type/queue source))
  (let ((source-list (split-string haskell-echo-type/queue "\n")))
    (if (haskell-echo-type/success? source-list)
        (let ((output (car (last source-list 2))))
          (haskell-echo-type/success-output output)))))

(defun haskell-echo-type/success? (source-list)
  (and (string= (car (last source-list)) " ")
       (string-match "^[^\W].+ :: .*[A-Z].*" (car (last source-list 2)))))

(defun haskell-echo-type/success-output (output)
  (let ((message-log-max nil))
    (message "%s" output)))

(provide 'haskell-echo-type)
