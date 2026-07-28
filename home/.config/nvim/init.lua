-- init.lua — single-file config for nvim 0.12+.
-- Plugins via the built-in vim.pack; LSP servers/formatters installed by nix
-- (see home.nix), not mason. See README.md in this folder for usage.

-- ---------------------------------------------------------------- options ---
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.showbreak = "↪ "

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.swapfile = false
vim.opt.undofile = true                -- persistent undo across sessions
vim.opt.clipboard = "unnamedplus"      -- yank/paste through the system clipboard
vim.opt.signcolumn = "yes"             -- stable gutter; no shift when signs appear

vim.opt.ignorecase = true              -- search: case-insensitive...
vim.opt.smartcase = true               -- ...unless the query has capitals

-- visually minimal: no statusline, no mode indicator
vim.opt.laststatus = 0
vim.opt.showmode = false
vim.opt.cmdheight = 1

-- ---------------------------------------------------------------- keymaps ---
-- indent without losing the visual selection
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<", "<gv")

-- ctrl-hjkl to move between windows
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- keep the cursor centered while jumping
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "clear search highlight" })

-- ---------------------------------------------------------------- plugins ---
-- vim.pack clones anything missing on startup (first launch needs network).
-- Update everything with :lua vim.pack.update()
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/neovim/nvim-lspconfig" },  -- data only: server defaults for vim.lsp.enable
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
  { src = "https://github.com/ibhagwan/fzf-lua" },       -- uses the fzf + rg installed by nix
  { src = "https://github.com/folke/snacks.nvim" },          -- explorer (LazyVim's tree)
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/akinsho/bufferline.nvim" },
  { src = "https://github.com/zbirenbaum/copilot.lua" },
  { src = "https://github.com/fang2hou/blink-copilot" },     -- copilot as a blink source
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/ellisonleao/gruvbox.nvim", name = "gruvbox" },
  { src = "https://github.com/christoomey/vim-tmux-navigator" },  -- tmux half in home.nix
  { src = "https://github.com/nvim-mini/mini.ai" },  -- textobjects: iq/aq quotes, f, a, t…
  { src = "https://github.com/nvim-mini/mini.bufremove" },  -- close buffer, keep window layout
  { src = "https://github.com/folke/persistence.nvim" },    -- session per project dir
  { src = "https://github.com/folke/which-key.nvim" },  -- keymap hints after a pause
})

require("which-key").setup()
require("which-key").add({
  { "<leader>b", group = "buffers" },
  { "<leader>q", group = "session" },
})

require("mini.ai").setup()
require("mini.bufremove").setup()

-- sessions save on exit; nothing auto-restores — <leader>qs brings one back
require("persistence").setup()
vim.keymap.set("n", "<leader>qs", function() require("persistence").load() end, { desc = "restore session (this dir)" })
vim.keymap.set("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "restore last session" })
vim.keymap.set("n", "<leader>qd", function() require("persistence").stop() end, { desc = "don't save this session" })

-- hard = GruvboxDarkHard, matches wezterm; transparent lets wezterm's
-- opacity/blur show through (like the old gruvbox-baby transparent_mode)
require("gruvbox").setup({ contrast = "hard", transparent_mode = true })
vim.cmd.colorscheme("gruvbox")

-- ------------------------------------------------------------- treesitter ---
-- main-branch nvim-treesitter: install parsers, then start highlighting per
-- buffer (nothing is enabled automatically).
local parsers = {
  "rust", "python", "javascript", "typescript", "tsx", "swift",
  "lua", "nix", "bash", "json", "toml", "yaml", "html", "css", "markdown",
}
require("nvim-treesitter").install(parsers)
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)  -- no-op for filetypes without a parser
  end,
})

-- ------------------------------------------------------------------- lsp ----
-- Servers come from nix (home.nix), sourcekit from Xcode. nvim-lspconfig
-- provides each server's cmd/root-markers; vim.lsp.enable launches on filetype.
vim.lsp.enable({
  "rust_analyzer",
  "pyright",
  "ruff",       -- lints alongside pyright; also our python formatter
  "ts_ls",
  "lua_ls",
  "nixd",
  "sourcekit",  -- swift/objc, ships with Xcode
})

vim.lsp.config("lua_ls", {
  settings = { Lua = { diagnostics = { globals = { "vim", "Snacks" } } } },
})

-- 0.11+ ships LSP keymaps by default: grn rename, gra code action,
-- grr references, gri implementation, gO document symbols, K hover.
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "goto definition" })

vim.diagnostic.config({
  virtual_text = true,
  severity_sort = true,
})
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "line diagnostics" })

-- ------------------------------------------------------------- completion ---
-- Copilot feeds the blink menu (no ghost text), so Tab-to-accept stays unified.
require("copilot").setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
})

vim.g.copilot_enabled = true
vim.keymap.set("n", "<leader>c", function()
  vim.g.copilot_enabled = not vim.g.copilot_enabled
  vim.notify("copilot " .. (vim.g.copilot_enabled and "on" or "off"))
end, { desc = "toggle copilot" })

require("blink.cmp").setup({
  keymap = { preset = "super-tab" },   -- Tab accepts the completion
  fuzzy = { implementation = "lua" },  -- skip the optional rust matcher binary
  signature = { enabled = true },
  sources = {
    default = { "lsp", "path", "snippets", "buffer", "copilot" },
    providers = {
      copilot = {
        name = "copilot",
        module = "blink-copilot",
        async = true,
        score_offset = 100,  -- rank copilot suggestions above the rest
        enabled = function() return vim.g.copilot_enabled end,
      },
    },
  },
})

-- -------------------------------------------------------------- formatting --
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_format" },
    rust = { "rustfmt" },            -- from the rustup toolchain
    nix = { "nixfmt" },
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescriptreact = { "prettierd" },
    json = { "prettierd" },
    html = { "prettierd" },
    css = { "prettierd" },
    markdown = { "prettierd" },
  },
  format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
})

-- ------------------------------------------------------------ finder/files --
local fzf = require("fzf-lua")
vim.keymap.set("n", "<leader>f", fzf.files, { desc = "find files" })
vim.keymap.set("n", "<leader>g", fzf.live_grep, { desc = "grep project" })
vim.keymap.set("n", "<leader>bb", fzf.buffers, { desc = "list buffers" })
vim.keymap.set("n", "<leader>r", fzf.resume, { desc = "resume last search" })

-- snacks explorer — the file tree from the old LazyVim setup
require("snacks").setup({
  picker = { sources = { explorer = { hidden = true, ignored = true } } },
})
vim.keymap.set("n", "<leader>e", function() Snacks.explorer() end, { desc = "file explorer" })

-- buffer tabs along the top; H/L cycle (shadows top/bottom-of-screen jumps)
require("bufferline").setup({})
vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "prev buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "next buffer" })
vim.keymap.set("n", "<leader>bd", function() require("mini.bufremove").delete() end, { desc = "close buffer" })
vim.keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", { desc = "close other buffers" })
vim.keymap.set("n", "<leader>br", "<cmd>BufferLineCloseRight<CR>", { desc = "close buffers to the right" })
vim.keymap.set("n", "<leader>bl", "<cmd>BufferLineCloseLeft<CR>", { desc = "close buffers to the left" })

require("gitsigns").setup()
