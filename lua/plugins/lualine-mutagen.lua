local uv = vim.uv or vim.loop
local cache = {}

local function find_project_file()
  local dir = vim.fn.getcwd()
  while dir do
    local file = dir .. '/mutagen.yml'
    if uv.fs_stat(file) then
      return true
    end

    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then
      return false
    end
    dir = parent
  end
  return false
end

local function project_status()
  local project_file = find_project_file()
  if not project_file then
    return nil
  end

  local entry = cache[project_file]
  if not entry then
    entry = { status = 'checking' }
    cache[project_file] = entry
  end

  if not entry.running and (not entry.checked_at or os.time() - entry.checked_at >= 5) then
    entry.running = true
    vim.system({ 'mutagen', 'project', 'list', '--long' }, { text = true }, function(result)
      local output = (result.stdout or '') .. '\n' .. (result.stderr or '')
      local status

      if output:match 'project not running' then
        status = 'stopped'
      elseif result.code == 0 then
        if output:match '%[Paused%]' then
          status = 'paused'
        elseif
          output:match 'Last error:'
          or output:match 'Conflicts: %d*[1-9]'
          or output:match 'Scan problems: %d*[1-9]'
          or output:match 'Transition problems: %d*[1-9]'
        then
          status = 'error'
        else
          status = 'running'
        end
      else
        status = 'unavailable'
      end

      entry.status = status
      entry.checked_at = os.time()
      entry.running = false
      vim.schedule(function()
        if package.loaded['lualine'] then
          require('lualine').refresh()
        end
      end)
    end)
  end

  return '󰓦 ' .. entry.status
end

return {
  'nvim-lualine/lualine.nvim',
  opts = {
    sections = {
      lualine_x = { { project_status, cond = find_project_file } },
    },
  },
}
