;;; init.el --- Emacs Init: Initial file that emacs loads at startup.

;;; Commentary:
;; This file includes the basic setup necessary to get started with Emacs.

;;; Code:

;; Disable menu bar in Emacs.
(menu-bar-mode -1)

;; Change backup file directory for emacs.
(setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups"))))

;; This lists the directories first and ignores some files and directories in dired.
(setq dired-use-ls-dired t)
(setq dired-listing-switches "-aBhl --ignore=.git --ignore=.bundle --ignore=.byebug_history --group-directories-first")

;; Hide dired details on startup.
(add-hook 'dired-mode-hook
	  (lambda ()
	    (dired-hide-details-mode)))

;; Setup initial screen.
(setq initial-buffer-choice (expand-file-name "."))

;; Org mode key bindings.
(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

;; Display line numbers.
(when (version<= "26.0.50" emacs-version)
  (global-display-line-numbers-mode))

;; Highlight current line.
(global-hl-line-mode +1)

;; Revert buffers if they've changed on disk.
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil)

;; Exclude directories from grep.
(eval-after-load 'grep
  '(progn
     (add-to-list 'grep-find-ignored-directories "log")
     (add-to-list 'grep-find-ignored-directories "node_modules")
     (add-to-list 'grep-find-ignored-directories "public/packs")
     (add-to-list 'grep-find-ignored-directories "storage")
     (add-to-list 'grep-find-ignored-directories "tmp")
     (add-to-list 'grep-find-ignored-directories ".bundle")
     (add-to-list 'grep-find-ignored-directories "auto")
     (add-to-list 'grep-find-ignored-directories "elpa")))

;; Add melpa to package-archives list.
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/") t)

;; use-package
;; Ensure use-package is installed.
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
;; Configure and load use-package.
(setq use-package-always-ensure t)
(eval-when-compile
  (defvar use-package-verbose t)
  (require 'use-package))

(use-package logview)

(use-package dired-hacks-utils)

(use-package dired-narrow
  :bind (:map dired-mode-map
	      ("/" . dired-narrow)))

(use-package dired-subtree
  :after dired
  :bind (:map dired-mode-map
	      ("TAB" . dired-subtree-toggle)
	      ("<backtab>" . dired-subtree-remove))
  :config
  (setq dired-subtree-use-backgrounds nil))

(use-package dired-git-info
  :bind (:map dired-mode-map
	      (")" . dired-git-info-mode)))

;; Extra font lock rules for a more colourful dired.
(use-package diredfl
  :config
  (diredfl-global-mode))

(use-package clipetty
  :bind ("M-w" . clipetty-kill-ring-save))

(use-package undo-tree
  :config
  ;; Prevent undo tree files from polluting your git repo
  (setq undo-tree-history-directory-alist `(("." . ,(concat user-emacs-directory "backups/undotree"))))
  (global-undo-tree-mode))

(use-package indent-guide
  :config
  (setq indent-guide-delay 0.3)
  (indent-guide-global-mode))

(use-package rainbow-delimiters
  :config
  (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(use-package smartparens
  :config
  (require 'smartparens-config))
(add-hook 'prog-mode-hook #'smartparens-mode)

(use-package robe
  :config
  (eval-after-load 'company '(push 'company-robe company-backends))
  (global-robe-mode))

(use-package company
  :config
  (add-hook 'after-init-hook 'global-company-mode))

(use-package projectile
  :config
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(use-package projectile-rails
  :config
  (projectile-rails-global-mode)
  (define-key projectile-rails-mode-map (kbd "C-c r") 'projectile-rails-command-map))

(use-package diff-hl
  :custom-face
  ;; Change colors for insert, delete and change indicators in diff-hl
  (diff-hl-insert ((t (:foreground "#a1b56c" :background "#a1b56c"))))
  (diff-hl-delete ((t (:foreground "#ab4642" :background "#ab4642"))))
  (diff-hl-change ((t (:foreground "#f7ca88" :background "#f7ca88"))))

  :hook
  ;; To enable in all Dired buffers.
  (dired-mode         . diff-hl-dired-mode)
  ;; diff-hl integration with magit.
  (magit-pre-refresh  . diff-hl-magit-pre-refresh)
  (magit-post-refresh . diff-hl-magit-post-refresh)

  :config
  ;; it modifies 'diff-hl-mode' to use the margin instead of the fringe. The unless condition does this only for terminal.
  (unless (window-system) (diff-hl-margin-mode))
  ;; This mode enables diffing on-the-fly.
  (diff-hl-flydiff-mode)
  ;; Highlight uncommitted changes using VCHighlight uncommitted changes using VC.
  (global-diff-hl-mode))

;; A Git porcelain inside Emacs.
(use-package magit
  :commands (magit-add-section-hook magit-section-initial-visibility-alist)

  :init
  (setq magit-diff-refine-hunk 'all)
  (setq magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)

  :config
  ;; To list branches and tags directly in your Magit status buffer.
  (magit-add-section-hook 'magit-status-sections-hook 'magit-insert-local-branches nil t)
  (add-to-list 'magit-section-initial-visibility-alist '(local . hide))
  (magit-add-section-hook 'magit-status-sections-hook 'magit-insert-remote-branches nil t)
  (add-to-list 'magit-section-initial-visibility-alist '(remote . hide))
  (magit-add-section-hook 'magit-status-sections-hook 'magit-insert-tags nil t)
  (add-to-list 'magit-section-initial-visibility-alist '(tags . hide)))

;; Flycheck is a modern on-the-fly syntax checking extension for GNU Emacs.
(use-package flycheck
  :init
  (global-flycheck-mode))

;; Expand region increases the selected region by semantic units. Just keep pressing the key until it selects what you want.
(use-package expand-region
  :bind
  ("C-=" . er/expand-region))

;; ruby-mode - comes included in latest emacs.
(add-to-list 'auto-mode-alist
	     '("\\.\\(?:cap\\|gemspec\\|irbrc\\|gemrc\\|rake\\|rb\\|ru\\|thor\\|god\\)\\'" . ruby-mode))
(add-to-list 'auto-mode-alist
	     '("\\(?:Brewfile\\|Capfile\\|Gemfile\\(?:\\.[a-zA-Z0-9._-]+\\)?\\|[rR]akefile\\)\\'" . ruby-mode))
(use-package ruby-electric
  :config
  (eval-after-load "ruby-mode"
    '(add-hook 'ruby-mode-hook 'ruby-electric-mode)))

(use-package yaml-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
  (add-hook 'yaml-mode-hook '(lambda () (define-key yaml-mode-map "\C-m" 'newline-and-indent))))

(use-package typescript-mode)

(use-package web-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.phtml\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.tpl\\.php\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.[agj]sp\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.as[cp]x\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.erb\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.mustache\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.djhtml\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.js?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.jsx?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.css?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.scss?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.xml?\\'" . web-mode)))

(use-package dockerfile-mode)

;; Polymode is a framework for multiple major modes (MMM) inside a single Emacs buffer.
(use-package polymode
  :config
  (with-eval-after-load "polymode"
    (eieio-oset-default pm-inner-chunkmode :adjust-face -2))
  (define-innermode poly-dockerfile-innermode
    :mode 'dockerfile-mode
    :head-matcher "<<[~-]?\'?DOCKERFILE_?\'?.*\r?\n"
    :tail-matcher "[ \t]*DOCKERFILE_?.*\r?\n")
  (define-polymode poly-ruby-mode
    :hostmode 'poly-ruby-hostmode
    :innermodes '(poly-dockerfile-innermode))
  (add-to-list 'auto-mode-alist '("\\.rb" . poly-ruby-mode))

  :hook
  (poly-ruby-mode . (lambda ()
		      (setq dockerfile-enable-auto-indent nil))))

;;; init.el ends here
