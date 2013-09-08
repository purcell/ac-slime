;;; ac-slime.el --- An auto-complete source using slime completions
;;
;;; Author: Steve Purcell <steve@sanityinc.com>
;;; URL: https://github.com/purcell/ac-slime
;;; Version: DEV
;;
;;; Commentary:
;; Usage:
;;     (require 'ac-slime)
;;     (add-hook 'slime-mode-hook 'set-up-slime-ac)
;;     (add-hook 'slime-repl-mode-hook 'set-up-slime-ac)
;;     (eval-after-load "auto-complete"
;;       '(add-to-list 'ac-modes 'slime-repl-mode))
;;

(eval-when-compile (require 'cl))
(require 'slime)
(require 'auto-complete)

(defvar ac-slime-last-ac-prefix "")
(defvar ac-slime-results nil)
(defvar ac-slime-current-doc nil "Holds slime docstring for current symbol")

(defun ac-slime-documentation (symbol-info)
  (ignore-errors
   (let ((symbol (substring-no-properties symbol-info)))
     (slime-eval `(swank:documentation-symbol ,symbol)))))

(defun ac-slime-init ()
  (setq ac-slime-current-doc nil))

;;;###autoload
(defface ac-slime-menu-face
    '((t (:inherit 'ac-candidate-face)))
  "Face for slime candidate menu."
  :group 'auto-complete)

;;;###autoload
(defface ac-slime-selection-face
    '((t (:inherit 'ac-selection-face)))
  "Face for the slime selected candidate."
  :group 'auto-complete)

(defun ac-source-slime-candidates (&optional flags)
  (update-results)
  (gethash flags ac-slime-table))

(defun update-results ()
  (cond ((not (string= ac-prefix ac-slime-last-ac-prefix))
	 (setq ac-slime-results (car 
				 (if ac-use-fuzzy 
				     (slime-fuzzy-completions (substring-no-properties ac-prefix))
				     (slime-simple-completions (substring-no-properties ac-prefix)))))
	 (setq ac-slime-last-ac-prefix ac-prefix)
	 (setf ac-slime-table (make-hash-table :test 'equal))
	 (mapcar #'(lambda (item)
		     (push (car item) (gethash (car (last item)) ac-slime-table))
		     (setq ac-sources (add-to-list 'ac-sources (make-ac-slime-source (car (last item))))))
		 ac-slime-results))))

(defun make-ac-slime-source (flags)
  `((init . ac-slime-init)
    (candidates . (lambda () (ac-source-slime-candidates ,flags)))
    (candidate-face . ac-slime-menu-face)
    (selection-face . ac-slime-selection-face)
    (prefix . slime-symbol-start-pos)
    (symbol . ,flags)
    (match . (lambda (prefix candidates) candidates))
    (document . ac-slime-documentation)))

(defun set-up-slime-ac (&optional fuzzy)
  "Add an optionally-fuzzy slime completion source to the
front of `ac-sources' for the current buffer."
  (interactive)
  (setq ac-sources (add-to-list 'ac-sources (make-ac-slime-source nil))))


(provide 'ac-slime)
;;; ac-slime.el ends here
