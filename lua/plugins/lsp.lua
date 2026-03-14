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
    },
  },
}
