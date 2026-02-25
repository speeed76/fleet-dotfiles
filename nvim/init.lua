-- ── Fleet Dotfiles — nvim/init.lua ──────────────────────────────────────────
-- Repo: https://github.com/speeed76/fleet-dotfiles

-- ── Bootstrap lazy.nvim ──────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- ── Options ──────────────────────────────────────────────────────────────────
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number          = true
opt.relativenumber  = true
opt.cursorline      = true
opt.signcolumn      = "yes"
opt.scrolloff       = 8
opt.sidescrolloff   = 8
opt.wrap            = true
opt.linebreak       = true
opt.breakindent     = true
opt.expandtab       = true
opt.tabstop         = 2
opt.softtabstop     = 2
opt.shiftwidth      = 2
opt.smartindent     = true
opt.ignorecase      = true
opt.smartcase       = true
opt.hlsearch        = true
opt.incsearch       = true
opt.splitright      = true
opt.splitbelow      = true
opt.termguicolors   = true
opt.laststatus      = 3       -- global statusline
opt.showmode        = false
opt.updatetime      = 250
opt.timeoutlen      = 500
opt.completeopt     = { "menu", "menuone", "noselect" }
opt.undofile        = true
opt.swapfile        = false
opt.backup          = false
opt.hidden          = true
opt.encoding        = "utf-8"
opt.clipboard       = "unnamedplus"

-- ── Plugins (lazy.nvim) ──────────────────────────────────────────────────────
require("lazy").setup({

  -- Colorscheme
  { "catppuccin/nvim", name = "catppuccin", priority = 1000,
    config = function()
      require("catppuccin").setup({ flavour = "mocha", integrations = {
        nvim_tree = true, telescope = true, gitsigns = true, cmp = true,
        treesitter = true,
      }})
      vim.cmd.colorscheme("catppuccin-mocha")
    end },

  -- File explorer
  { "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        filters = { dotfiles = false },
        renderer = { group_empty = true,
          icons = { glyphs = { git = { unstaged="▎", staged="▎", untracked="?" }}}},
      })
    end },

  -- Statusline
  { "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({ options = { theme = "catppuccin" },
        sections = {
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
        }})
    end },

  -- Fuzzy finder
  { "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
    config = function()
      local t = require("telescope")
      t.setup({ defaults = { layout_strategy = "horizontal",
        layout_config = { preview_width = 0.55 } }})
      pcall(t.load_extension, "fzf")
    end },

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "python", "javascript", "typescript",
          "bash", "json", "yaml", "toml", "markdown", "vim", "vimdoc" },
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end },

  -- LSP
  { "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "ts_ls", "bashls" },
        automatic_installation = true,
      })
      local caps = require("cmp_nvim_lsp").default_capabilities()
      local lsp  = require("lspconfig")
      local servers = { "lua_ls", "pyright", "ts_ls", "bashls" }
      for _, s in ipairs(servers) do
        lsp[s].setup({ capabilities = caps })
      end
      -- Completion
      local cmp = require("cmp")
      local snip = require("luasnip")
      cmp.setup({
        snippet = { expand = function(a) snip.lsp_expand(a.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping(function(fb)
            if cmp.visible() then cmp.select_next_item()
            elseif snip.expand_or_jumpable() then snip.expand_or_jump()
            else fb() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({{ name="nvim_lsp"},{name="luasnip"}},
          {{ name="buffer" },{ name="path" }}),
      })
    end },

  -- Git
  { "lewis6991/gitsigns.nvim", config = function()
      require("gitsigns").setup({ signs = {
        add = { text = "▎" }, change = { text = "▎" }, delete = { text = "▁" },
      }})
    end },
  { "tpope/vim-fugitive" },

  -- Editor enhancement
  { "tpope/vim-surround" },
  { "tpope/vim-commentary" },
  { "tpope/vim-repeat" },
  { "tpope/vim-sleuth" },
  { "windwp/nvim-autopairs", event = "InsertEnter",
    config = function() require("nvim-autopairs").setup() end },
  { "mbbill/undotree" },
  { "editorconfig/editorconfig-vim" },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl",
    config = function() require("ibl").setup() end },

  -- Which-key (discover mappings)
  { "folke/which-key.nvim", event = "VeryLazy",
    config = function() require("which-key").setup() end },

}, { ui = { border = "rounded" } })

-- ── Keymaps ───────────────────────────────────────────────────────────────────
local map = function(m, k, v, d)
  vim.keymap.set(m, k, v, { noremap=true, silent=true, desc=d })
end

-- Escape
map("i", "jk", "<Esc>",         "Escape insert mode")
map("i", "jj", "<Esc>",         "Escape insert mode")

-- Clear search
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Window navigation
map("n", "<C-h>", "<C-w>h", "Window left")
map("n", "<C-j>", "<C-w>j", "Window down")
map("n", "<C-k>", "<C-w>k", "Window up")
map("n", "<C-l>", "<C-w>l", "Window right")

-- Resize
map("n", "<C-Up>",    "<cmd>resize +2<CR>")
map("n", "<C-Down>",  "<cmd>resize -2<CR>")
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>")

-- Move lines
map("v", "J", ":m '>+1<CR>gv=gv", "Move line down")
map("v", "K", ":m '<-2<CR>gv=gv", "Move line up")

-- Centred jumps
map("n", "n",     "nzzzv")
map("n", "N",     "Nzzzv")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Indent without deselect
map("v", "<",  "<gv")
map("v", ">",  ">gv")

-- Paste without yanking
map("v", "p",  '"_dP')

-- Buffers
map("n", "<S-h>",      "<cmd>bprevious<CR>",      "Prev buffer")
map("n", "<S-l>",      "<cmd>bnext<CR>",           "Next buffer")
map("n", "<leader>bd", "<cmd>bdelete<CR>",         "Delete buffer")

-- File tree
map("n", "<leader>e",  "<cmd>NvimTreeToggle<CR>",  "Explorer toggle")
map("n", "<leader>ef", "<cmd>NvimTreeFindFile<CR>","Explorer find file")

-- Telescope
local tb = require("telescope.builtin")
map("n", "<leader>ff", function() tb.find_files() end,   "Find files")
map("n", "<leader>fg", function() tb.live_grep() end,    "Live grep")
map("n", "<leader>fb", function() tb.buffers() end,      "Buffers")
map("n", "<leader>fh", function() tb.help_tags() end,    "Help tags")
map("n", "<leader>fr", function() tb.oldfiles() end,     "Recent files")
map("n", "<leader>fc", function() tb.git_commits() end,  "Git commits")

-- Git
map("n", "<leader>gs", "<cmd>Git status<CR>",     "Git status")
map("n", "<leader>gd", "<cmd>Gdiffsplit<CR>",     "Git diff")
map("n", "<leader>gb", "<cmd>Git blame<CR>",      "Git blame")
map("n", "<leader>gl", "<cmd>Git log --oneline<CR>", "Git log")

-- Undo tree
map("n", "<leader>u", "<cmd>UndotreeToggle<CR>",  "Undo tree")

-- Config
map("n", "<leader>ce", "<cmd>edit $MYVIMRC<CR>",  "Edit config")

-- ── Autocmds ─────────────────────────────────────────────────────────────────
local ag = vim.api.nvim_create_augroup
local au = vim.api.nvim_create_autocmd

-- Strip trailing whitespace on save
au("BufWritePre", { pattern = "*", command = [[%s/\s\+$//e]] })

-- Markdown/text: spell + wrap
au("FileType", { pattern = { "markdown", "text" },
  callback = function() vim.opt_local.spell = true end })

-- Python: 4-space indent
au("FileType", { pattern = "python",
  callback = function()
    vim.opt_local.tabstop     = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth  = 4
  end })

-- Highlight on yank
au("TextYankPost", { callback = function()
  vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
end })
-- ────────────────────────────────────────────────────────────────────────────
