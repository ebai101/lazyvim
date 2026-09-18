local function markdownlint_parser(output, bufnr, cwd)
  local parse = require('lint.parser').from_errorformat('stdin:%l:%c %m,stdin:%l %m', {
    source = 'markdownlint',
    severity = vim.diagnostic.severity.WARN,
  })
  local diagnostics = parse(output, bufnr, cwd)

  return vim.tbl_filter(function(diagnostic)
    return not diagnostic.message:match 'MD013[/ ]'
  end, diagnostics)
end

return {
  {
    'mfussenegger/nvim-lint',
    opts = {
      linters = {
        ['markdownlint-cli2'] = {
          args = { '-' },
          parser = markdownlint_parser,
        },
      },
    },
  },
  {
    'stevearc/conform.nvim',
    optional = true,
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters.mdreflow = {
        command = 'mdreflow',
        args = { '--mode', 'sentence', '--max-width', '0' },
        stdin = true,
        cwd = require('conform.util').root_file { '.git' },
      }
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, filetype in ipairs { 'markdown', 'markdown.mdx' } do
        opts.formatters_by_ft[filetype] = { 'markdownlint-cli2', 'mdreflow', 'markdown-toc' }
      end
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    opts = { enabled = false },
  },
}
