;;; insert.el --- Insert stuff.
;; Copyright 2017 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.0
;; Keywords: convenience
;; URL: https://github.com/davep/insert.el

;;; Commentary:
;;
;; insert.el contains commands for quickly and easily inserting useful
;; things into the current buffer.

;;; Code:

(require 'thingatpt)

;;;###autoload
(defun insert-filename (file)
  "Insert a name of FILE allowing for interactive browsing to the name."
  (interactive "fFile: ")
  (insert file))

;;;###autoload
(defun insert-buffer-filename (&optional name-only)
  "Insert the filename of the current buffer.

NAME-ONLY is a prefix argument, nil means insert the full name of the file,
any other value means insert the name without the directory."
  (interactive "P")
  (let ((filename (buffer-file-name)))
    (if (null filename)
        (error "Buffer has no filename")
      (insert (if name-only
                  (file-name-nondirectory filename)
                filename)))))

;;;###autoload
(defun insert-sexp-link ()
  "Place \"link quotes\" around the `sexp-at-point'."
  (interactive)
  (when (sexp-at-point)
    (let ((bounds (bounds-of-thing-at-point 'sexp)))
      (save-excursion
        (setf (point) (car bounds))
        (insert "`")
        (setf (point) (1+ (cdr bounds)))
        (insert "'")))))

(provide 'insert)

;;; insert.el ends here
