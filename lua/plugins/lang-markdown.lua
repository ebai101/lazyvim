return {
  {
    'mfussenegger/nvim-lint',
    opts = {
      linters = {
        ['markdownlint-cli2'] = {
          args = { '--disable', 'MD013', '--' },
        },
      },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    opts = { enabled = false },
  },
}
