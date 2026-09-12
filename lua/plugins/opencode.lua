local opencode_cmd = 'opencode --port'
local snacks_terminal_opts = {
  win = {
    position = 'right',
    width = 70,
    enter = false,
  },
}

vim.api.nvim_create_autocmd('User', {
  pattern = { 'OpencodeEvent:tui.command.execute' },
  callback = function(args)
    ---@type opencode.server.Event
    local event = args.data.event
    if event.properties.command == 'prompt.submit' then
      local win = require('snacks.terminal').get(opencode_cmd, { create = false })
      if win then
        win:show()
      end
    end
  end,
})

return {
  {
    'nickjvandyke/opencode.nvim',
    version = '*',
    config = function()
      vim.g.opencode_opts = {
        server = {
          start = function()
            require('snacks.terminal').open(opencode_cmd, snacks_terminal_opts)
          end,
        },
      }
      vim.keymap.set({ 'n', 'x' }, '<C-a>', function()
        require('opencode').ask '@this: '
      end, { desc = 'Ask OpenCode…' })
      vim.keymap.set({ 'n', 'x' }, '<C-x>', function()
        require('opencode').select()
      end, { desc = 'Select OpenCode…' })
      vim.keymap.set({ 'n', 'x' }, 'go', function()
        return require('opencode').operator '@this '
      end, { desc = 'Append range to OpenCode', expr = true })
      vim.keymap.set({ 'n' }, 'goo', function()
        return require('opencode').operator '@this ' .. '_'
      end, { desc = 'Append line to OpenCode', expr = true })
      vim.keymap.set({ 'n' }, '<leader>.', function()
        require('snacks.terminal').toggle(opencode_cmd, snacks_terminal_opts)
      end, { desc = 'Toggle OpenCode' })
    end,
  },
  {
    'snacks.nvim',
    opts = {
      input = {
        enabled = true,
      },
      picker = {
        enabled = true,
        win = {
          input = {
            keys = {
              ['<a-o>'] = { 'opencode_send', mode = { 'n', 'i' } },
            },
          },
        },
        actions = {
          opencode_send = function(picker) ---@param picker snacks.Picker
            local items = vim.tbl_map(function(item) ---@param item snacks.picker.Item
              return item.file and require('opencode').format { path = item.file, from = item.pos, to = item.end_pos } or item.text
            end, picker:selected { fallback = true })

            require('opencode').prompt(table.concat(items, ', ') .. ' ')
          end,
        },
      },
    },
  },
  {
    'saghen/blink.cmp',
    opts = {
      sources = {
        per_filetype = {
          opencode_ask = { 'lsp', 'buffer' },
        },
      },
    },
  },
}
