-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map('n', '<C-q>', function()
  Snacks.bufdelete()
end, { desc = 'Delete Buffer' })
map('n', '<leader>6', '<C-^>')

map('n', '\\', function()
  Snacks.explorer { cwd = LazyVim.root() }
end, { desc = 'Explorer Snacks (root dir)' })

map('v', 'J', ":m '>+1<CR>gv=gv")
map('v', 'K', ":m '<-2<CR>gv=gv")
