return {
  {
    'mason.nvim',
    opts = {
      ensure_installed = {
        'ty',
        'ruff',
      },
      servers = {
        ty = {
          settings = {
            ty = {
              completions = {
                autoImport = true,
              },
            },
          },
        },
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
  {
    'jay-babu/mason-nvim-dap.nvim',
    opts = {
      ensure_installed = {
        'debugpy',
      },
    },
  },
}
