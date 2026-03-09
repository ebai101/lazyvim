return {
  {
    'neovim/nvim-lspconfig',
    opts = {
      inlay_hints = { enabled = false },
      diagnostics = {
        update_in_insert = true,
        virtual_text = {
          spacing = 4,
          source = 'if_many',
          prefix = '●',
        },
      },
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
