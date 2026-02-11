return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      inlay_hints = { enabled = false },
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              runtime = {
                version = 'LuaJIT',
              },
              completion = {
                callSnippet = 'Replace',
              },
              diagnostics = {
                disable = { 'missing-fields' },
                globals = { 'vim', 'hs', 'spoon' },
              },
              format = {
                enable = false,
              },
              workspace = {
                library = {
                  vim.env.HOME .. '/.hammerspoon/Spoons/EmmyLua.spoon/annotations',
                },
                checkThirdParty = false,
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
      },
    },
  },
  {
    'mason.nvim',
    opts = {
      ensure_installed = {
        'lua-language-server',
        'ty',
        'ruff',
      },
    },
  },
}
