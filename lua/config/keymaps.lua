-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map('n', '<C-q>', function()
  Snacks.bufdelete()
end, { desc = 'Delete Buffer' })
map('n', '<leader>6', '<C-^>')

map('n', '\\', function()
  local explorer = Snacks.picker.get({ source = 'explorer' })[1]
  if not explorer then
    Snacks.explorer { cwd = LazyVim.root() }
  elseif explorer:is_focused() then
    explorer:close()
  else
    explorer:focus('list', { show = true })
  end
end, { desc = 'Explorer Snacks (toggle/focus)' })

map('v', 'J', ":m '>+1<CR>gv=gv")
map('v', 'K', ":m '<-2<CR>gv=gv")
