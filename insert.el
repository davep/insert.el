;;; insert.el --- Insert stuff.
;; Copyright 2017-2018 by Dave Pearson <davep@davep.org>

;; Author: Dave Pearson <davep@davep.org>
;; Version: 1.16
;; Keywords: convenience
;; URL: https://github.com/davep/insert.el

;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; insert.el contains commands for quickly and easily inserting useful
;; things into the current buffer.

;;; Code:

(require 'thingatpt)

;;;###autoload
(defun insert-filename (file)
  "Insert a name of FILE allowing for interactive browsing to the name."
  (interactive "*fFile: ")
  (insert file))

;;;###autoload
(defun insert-buffer-filename (&optional name-only)
  "Insert the filename of the current buffer.

NAME-ONLY is a prefix argument, nil means insert the full name of the file,
any other value means insert the name without the directory."
  (interactive "*P")
  (let ((filename (buffer-file-name)))
    (if (null filename)
        (error "Buffer has no filename")
      (insert (if name-only
                  (file-name-nondirectory filename)
                filename)))))

;;;###autoload
(defun insert-sexp-link (&optional no-move)
  "Place \"link quotes\" around the `sexp-at-point'.

As a side-effect `point' is placed after the sexp unless NO-MOVE
is t."
  (interactive "*P")
  (when (sexp-at-point)
    (let* ((bounds (bounds-of-thing-at-point 'sexp))
           (move-to (save-excursion
                      (setf (point) (car bounds))
                      (insert "`")
                      (setf (point) (1+ (cdr bounds)))
                      (insert "'")
                      (point))))
      (unless no-move
        (setf (point) move-to)))))

;;;###autoload
(defun insert-snip (start end)
  "Call `kill-region' on region bounding START and END and then insert \"[SNIP]\"."
  (interactive "*r")
  (kill-region start end)
  (insert "[SNIP]")
  (forward-char -1))

;;;###autoload
(defun insert-tags (tag start end)
  "Place xml/sglm/html TAG around region bounded by START and END."
  (interactive "*sTag: \nr")
  (let ((text (buffer-substring start end)))
    (setf (buffer-substring start end)
          (concat "<" tag ">" text "</" tag ">"))))

;;;###autoload
(defun insert-line-split-keeping-fill-prefix ()
  "Like `split-line' but trys to keep the `fill-prefix'.

Also adds an extra blank line to the split because it's mostly
intended for use with editing quoted text."
  (interactive "*")
  (let* ((fill-prefix (fill-context-prefix (save-excursion
                                             (backward-paragraph)
                                             (point))
                                           (save-excursion
                                             (forward-paragraph)
                                             (point))))
         (spaces (- (point)
                    (line-beginning-position)
                    (length fill-prefix))))
    (if (wholenump spaces)
        (save-excursion
          (insert (format "\n\n%s%s" fill-prefix (make-string spaces ? ))))
      (error "Can't split within the fill prefix"))))

;;;###autoload
(defun insert-cut-here (&optional say-cut)
  "Insert \"cut here\" delimiters.

Just use dashes unless SAY-CUT is non-nil, then include \"cut
here\" in the cut marks."
  (interactive "*P")
  (let ((cut-line (if say-cut
                      (concat "-- cut here " (make-string 64 ?-))
                    (make-string 76 ?-))))
    (insert (format "%s\n%s\n" cut-line cut-line))
    (forward-line -1)))

;;;###autoload
(defun insert-file-cut-here (file)
  "Insert contents of FILE with a \"cut here\" delimiter."
  (interactive "*fFilename: ")
  (insert-cut-here t)
  (insert-file-contents-literally file))

(defconst insert--melpa-badge-types
  `((markdown .
              ,(concat
                "[![MELPA Stable](https://stable.melpa.org/packages/{{p}}-badge.svg)](https://stable.melpa.org/#/{{p}})"
                "\n"
                "[![MELPA](https://melpa.org/packages/{{p}}-badge.svg)](https://melpa.org/#/{{p}})"))
    (html .
          ,(concat
            "<a href=\"https://stable.melpa.org/#/{{p}}\"><img alt=\"MELPA Stable\" src=\"https://stable.melpa.org/packages/{{p}}-badge.svg\"/></a>"
            "\n"
            "<a href=\"https://melpa.org/#/{{p}}\"><img alt=\"MELPA\" src=\"https://melpa.org/packages/{{p}}-badge.svg\"/></a>")))
  "Types of output for `insert-melpa-badge'.")

;;;###autoload
(defun insert-melpa-badge (package type)
  "Insert melpa badge code for PACKAGE.

TYPE specifies what type of code to insert. Options are \"markdown\" and \"html\"."
  (interactive
   (unless (barf-if-buffer-read-only)
     (list
      (read-file-name "Package: ")
      (completing-read "Type: " insert--melpa-badge-types))))
  (let ((fmt (cdr (assoc (intern type) insert--melpa-badge-types))))
    (when fmt
      (insert (replace-regexp-in-string "{{p}}" (file-name-nondirectory (file-name-sans-extension package)) fmt)))))

;;;###autoload
(defun insert-autoload-cookie ()
  "Insert an autoload cookie before the current top level form.

What constitutes the top level form depends on where
`beginning-of-defun' takes us and its return value.

At some point I should probably extend this so that it goes to
the start of the form and then checks to see if it's anything
that can actually be autoloaded."
  (interactive "*")
  (save-excursion
    (when (beginning-of-defun)
      (insert ";;;###autoload\n"))))

;;;###autoload
(defun insert-break-comment ()
  "Insert a break comment at the current `point'.

If `bolp' is nil at the start of the comment, a new line is
created first. If `eolp' is nil at the end of the command a new
line is inserted and `point' is returned to where it was before
the new line is inserted."
  (interactive "*")
  (unless (bolp)
    (setf (point) (line-beginning-position)))
  (insert (make-string fill-column (aref ";" 0)) "\n;; ")
  (unless (eolp)
    (save-excursion
      (insert "\n"))))

;;;###autoload
(defun insert-youtube-markdown (url)
  "Insert markdown for embedding video at URL.

Note that it doesn't really embed the video because markdown
doesn't support that, but it does embed a thumbnail for the video
and make it a link to the video on YouTube."
  (interactive "*sURL: ")
  (let ((id (progn
              (string-match "^.*?v=\\([^&]+\\)" url)
              (match-string 1 url))))
    (if id
        (progn
          (save-excursion
            (insert
             (format
              "[![](https://img.youtube.com/vi/%s/0.jpg)](%s)" id url)))
          (setf (point) (+ (point) 3)))
      (error "Could not parse that URL for a YouTube video ID"))))

;;;###autoload
(defun insert-default-html5 ()
  "Insert a minimal boilerplate HTML5 page."
  (interactive "*")
  (save-excursion
    (insert "<!doctype html>
<html lang=\"en\">
  <head>
    <title></title>
    <meta charset=\"utf-8\">
    <meta http-equiv=\"X-UA-Compatible\" content=\"IE=edge\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
    <link rel=\"shortcut icon\" href=\"/favicon.ico\" />
    <link rel=\"apple-touch-icon\" href=\"/icon.png\" />
  </head>

  <body>
  </body>

</html>
")))

(provide 'insert)

;;; insert.el ends here
