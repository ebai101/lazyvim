require('which-key').add {
  { '<leader>fs', group = 'sops', icon = require('mini.icons').get('lsp', 'Key') },
}
return {
  'prismatic-koi/nvim-sops',
  event = { 'BufEnter' },
  keys = {
    { '<leader>fse', vim.cmd.SopsEncrypt, desc = '[S]ops [E]ncrypt' },
    { '<leader>fsd', vim.cmd.SopsDecrypt, desc = '[S]ops [D]ecrypt' },
  },
}
