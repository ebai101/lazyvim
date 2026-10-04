local M = {}

local backends = {
  github = function(opts)
    Snacks.picker.gh_pr(opts)
  end,
  forgejo = function(opts)
    require('forge.forgejo').pr(opts)
  end,
}

function M.current()
  local ok, neoconf = pcall(require, 'neoconf')
  local name = ok and neoconf.get('lazyvim.git.forge', 'github') or 'github'
  return backends[name] and name or 'github'
end

function M.pr(opts)
  backends[M.current()](opts)
end

return M
