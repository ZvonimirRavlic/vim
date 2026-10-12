local opt = vim.opt

-- Leader must be set before lazy.nvim loads plugins
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- nvim-tree replaces netrw (NERDTree in IdeaVim)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- From .ideavimrc
opt.number = true -- set number
opt.relativenumber = true -- set relativenumber
opt.hlsearch = true -- set hlsearch
opt.incsearch = true -- set incsearch
opt.scrolloff = 10 -- set scrolloff=10
opt.showmode = true -- set showmode
opt.showcmd = true -- set showcmd
opt.belloff = "all" -- set visualbell (no beeping)
opt.clipboard = "unnamedplus" -- set clipboard+=unnamed
opt.timeout = false -- set notimeout (which-key shows the popup)
opt.ttimeout = true -- keep Alt/Option key codes fast
opt.ttimeoutlen = 10
opt.formatoptions:append("j") -- set ideajoin (J removes comment leaders)

-- IntelliJ-like behaviour
opt.splitright = true -- MoveTabRight opens on the right
opt.splitbelow = true -- MoveTabDown opens below
opt.autoread = true -- reload files changed outside (IntelliJ sync)
opt.undofile = true -- local history
opt.confirm = true
opt.mouse = "a"
opt.termguicolors = true
opt.signcolumn = "yes" -- gutter for breakpoints / git / diagnostics
opt.cursorline = true
opt.ignorecase = true
opt.smartcase = true
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.updatetime = 250
opt.laststatus = 3
opt.showtabline = 2
