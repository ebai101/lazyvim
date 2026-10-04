local M = {}

local function clean(text)
  -- fj 0.6.0 leaks a literal STYLE() token under --style minimal
  return text:gsub('\u{2068}', ''):gsub('\u{2069}', ''):gsub('STYLE%(%)', '')
end

local actions = {
  browse = {
    desc = 'Browse',
    notify = true,
    run = function(item)
      return { 'fj', 'pr', 'browse', tostring(item.number) }
    end,
  },
  checkout = {
    desc = 'Checkout',
    run = function(item)
      if vim.fn.confirm('Checkout pull request #' .. item.number .. '?', '&Yes\n&No', 2) ~= 1 then
        return
      end
      return { 'fj', 'pr', 'checkout', tostring(item.number) }
    end,
  },
  diff = {
    desc = 'Diff',
    ft = 'diff',
    run = function(item)
      return { 'fj', '--style', 'minimal', 'pr', 'view', tostring(item.number), 'diff' }
    end,
  },
  comments = {
    desc = 'Comments',
    ft = 'markdown',
    run = function(item)
      return { 'fj', '--style', 'minimal', 'pr', 'view', tostring(item.number), 'comments' }
    end,
  },
  status = {
    desc = 'Status',
    ft = 'text',
    run = function(item)
      return { 'fj', '--style', 'minimal', 'pr', 'status', tostring(item.number) }
    end,
  },
}

local function run_action(name, item)
  local action = actions[name]
  local argv = action.run(item)
  if not argv then
    return
  end
  local result = vim.system(argv, { cwd = item.cwd, text = true }):wait()
  local output = clean(result.stdout or '')
  if result.code ~= 0 then
    vim.notify(clean(result.stderr or output), vim.log.levels.ERROR)
    return
  end
  if action.ft then
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', action.ft)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, '\n', { plain = true }))
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>bd<cr>', { noremap = true, silent = true })
    vim.api.nvim_set_current_buf(buf)
  elseif action.notify then
    vim.notify(output ~= '' and output or 'Opened pull request in browser')
  end
end

function M.pr(opts)
  opts = opts or {}
  local state = opts.state or 'open'
  local cwd = opts.cwd or LazyVim.root()
  Snacks.picker.pick {
    source = 'forgejo_pr',
    title = '  Forgejo Pull Requests',
    cwd = cwd,
    live = false,
    state = state,
    finder = function(_, ctx)
      return require('snacks.picker.source.proc').proc({
        cmd = 'fj',
        args = { '--style', 'minimal', 'pr', 'search', '--state', state },
        cwd = cwd,
        notify = true,
        transform = function(item)
          local line = clean(item.text)
          local number, title, author = line:match '^#(%d+):%s*(.*)%s*%(by%s+([^)]*)%)%s*$'
          if not number then
            return false
          end
          number = tonumber(number)
          item.number = number
          item.title = vim.trim(title)
          item.author = author
          item.cwd = cwd
          item.text = ('#%d %s %s'):format(number, title, author)
          return item
        end,
      }, ctx)
    end,
    format = function(item)
      return {
        { ('#%d'):format(item.number), 'SnacksPickerIdx' },
        { ' ' .. item.title .. ' ' },
        { '@' .. item.author, 'SnacksPickerGitAuthor' },
      }
    end,
    preview = function(ctx)
      return Snacks.picker.preview.cmd({ 'fj', '--style', 'minimal', 'pr', 'view', tostring(ctx.item.number) }, ctx, { ft = 'markdown' })
    end,
    confirm = function(_, item)
      local order = { 'browse', 'checkout', 'diff', 'comments', 'status' }
      vim.ui.select(order, {
        prompt = 'Action',
        format_item = function(name)
          return actions[name].desc
        end,
      }, function(name)
        if name then
          run_action(name, item)
        end
      end)
    end,
    win = {
      input = {
        keys = {
          ['<a-b>'] = { 'forgejo_browse', mode = { 'n', 'i' } },
        },
      },
    },
    actions = {
      forgejo_browse = function(_, item)
        run_action('browse', item)
      end,
    },
  }
end

return M
