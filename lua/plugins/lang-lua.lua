return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
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
      },
    },
  },
}
