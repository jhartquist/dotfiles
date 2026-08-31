-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Tmux navigation (requires vim-tmux-navigator plugin, tmux only;
-- under herdr, herdr-splits.nvim binds these keys instead)
if vim.env.TMUX then
  vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>")
  vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR>")
  vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR>")
  vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR>")
end

-- Keep cursor centered while navigating
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "{", "{zz")
vim.keymap.set("n", "}", "}zz")
