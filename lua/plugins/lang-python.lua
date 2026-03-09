return {
  {
    'mason.nvim',
    opts = {
      ensure_installed = {
        'ty',
        'ruff',
      },
    },
  },
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        python = {
          'ruff_organize_imports',
          'ruff_format',
        },
      },
    },
  },
}
