(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(polymode ruby-electric ruby-electric-mode ruby-mode dockerfile-mode expand-region flycheck zenburn-theme multi-vterm vterm yaml-mode web-mode use-package undo-tree typescript-mode smartparens robe rbenv rainbow-delimiters projectile-rails osx-trash magit logview indent-guide diredfl dired-sidebar dired-narrow dired-git-info diff-hl company clipetty bundler)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(diff-hl-change ((t (:foreground "#f7ca88" :background "#f7ca88"))))
 '(diff-hl-delete ((t (:foreground "#ab4642" :background "#ab4642"))))
 '(diff-hl-insert ((t (:foreground "#a1b56c" :background "#a1b56c")))))

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

;; Disable menu bar in emacs.
(menu-bar-mode -1)

;; change backup file directory for emacs
(setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups"))))

;; Use gls instead of the default ls on darwain systems like Apple.
;; coreutils is needed to be installed for gls. You can get it with brew install coreutils.
;; This solves the --dired problem on macOS and lists the directories first in dired.
(when (string= system-type "darwin")
  (setq dired-use-ls-dired t
        insert-directory-program "/usr/local/bin/gls"
        dired-listing-switches "-aBhl --ignore=.DS_Store --ignore=.git --ignore=.bundle --ignore=.byebug_history --group-directories-first"))

;; Hide dired details on startup
(add-hook 'dired-mode-hook
	  (lambda ()
	    (dired-hide-details-mode)))

;; Setup initial screen
(setq initial-buffer-choice (expand-file-name "."))

;; Org mode key bindings
(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

;; Display line numbers.
(when (version<= "26.0.50" emacs-version)
  (global-display-line-numbers-mode))

;; Highlight current line.
(global-hl-line-mode +1)

;; Revert buffers if they've changed on disk
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

(use-package zenburn-theme
  :ensure t
  :config
  (load-theme 'zenburn t)
  (zenburn-with-color-variables
    (custom-theme-set-faces
     'zenburn
     `(hl-line-face ((t (:background ,zenburn-bg+05 ))))
     `(hl-line ((t (:background ,zenburn-bg+05 ))))
     `(region ((nil (:background ,zenburn-bg+2))))
     )))

(use-package logview
  :ensure t)

(use-package dired-hacks-utils
  :ensure t)

(use-package dired-narrow
  :ensure t
  :bind (:map dired-mode-map
	      ("/" . dired-narrow)))

(use-package dired-subtree
  :ensure t
  :after dired
  :bind (:map dired-mode-map
	      ("TAB" . dired-subtree-toggle)
	      ("<backtab>" . dired-subtree-remove))
  :config
  (setq dired-subtree-use-backgrounds nil))

(use-package dired-git-info
  :ensure t
  :bind (:map dired-mode-map
	      (")" . dired-git-info-mode)))

(use-package dired-sidebar
  :ensure t
  :commands (dired-sidebar-toggle-sidebar)
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :init
  (setq dired-sidebar-use-term-integration t)
  (setq dired-sidebar-use-custom-font t))

(use-package typescript-mode
  :ensure t)

(use-package clipetty
  :ensure t
  :bind ("M-w" . clipetty-kill-ring-save))

(use-package osx-trash
  :config
  (when (eq system-type 'darwin)
    (osx-trash-setup))
  (setq delete-by-moving-to-trash t))

(use-package undo-tree
  :config
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

(use-package ruby-mode
  :config
  (add-to-list 'auto-mode-alist
	       '("\\.\\(?:cap\\|gemspec\\|irbrc\\|gemrc\\|rake\\|rb\\|ru\\|thor\\)\\'" . ruby-mode))
  (add-to-list 'auto-mode-alist
	       '("\\(?:Brewfile\\|Capfile\\|Gemfile\\(?:\\.[a-zA-Z0-9._-]+\\)?\\|[rR]akefile\\)\\'" . ruby-mode)))

(use-package ruby-electric
  :config
  (add-hook 'ruby-mode-hook 'ruby-electric-mode))

(use-package robe
  :config
  (eval-after-load 'company '(push 'company-robe company-backends))
  (global-robe-mode))

(use-package company
  :config
  (add-hook 'after-init-hook 'global-company-mode))

(use-package bundler)

(use-package rbenv
  :config
  (global-rbenv-mode))

(use-package yaml-mode
  :config
  (add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
  (add-hook 'yaml-mode-hook '(lambda () (define-key yaml-mode-map "\C-m" 'newline-and-indent))))

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

(use-package projectile
  :config
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(use-package projectile-rails
  :config
  (projectile-rails-global-mode)
  (define-key projectile-rails-mode-map (kbd "C-c r") 'projectile-rails-command-map))

;; Extra font lock rules for a more colourful dired.
(use-package diredfl
  :ensure t
  :config
  (diredfl-global-mode))

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
  :ensure t

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

;; Emacs-libvterm (vterm) is fully-fledged terminal emulator inside GNU Emacs based on libvterm, a C library.
(use-package vterm
  :ensure t
  :config
  (define-key vterm-mode-map (kbd "C-q") #'vterm-send-next-key))
;; Managing multiple vterm buffers in Emacs.
(use-package multi-vterm
  :ensure t)

;; Flycheck is a modern on-the-fly syntax checking extension for GNU Emacs.
(use-package flycheck
  :ensure t
  :init
  (global-flycheck-mode))

;; Expand region increases the selected region by semantic units. Just keep pressing the key until it selects what you want.
(use-package expand-region
  :ensure t
  :bind
  ("C-=" . er/expand-region))

(use-package dockerfile-mode
  :ensure t)

;; Polymode is a framework for multiple major modes (MMM) inside a single Emacs buffer.
(use-package polymode
  :ensure t

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
