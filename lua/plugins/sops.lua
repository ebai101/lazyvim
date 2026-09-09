return {
  'prismatic-koi/nvim-sops',
  event = { 'BufEnter' },
  keys = {
    {
      '<leader>fs',
      function()
        local sops_cmd = vim.system({ 'sops', 'filestatus', vim.api.nvim_buf_get_name(0) }):wait()
        if sops_cmd.stdout ~= '' then
          local is_encrypted = vim.json.decode(sops_cmd.stdout)['encrypted']
          if is_encrypted then
            vim.cmd.SopsDecrypt()
          else
            vim.cmd.SopsEncrypt()
          end
        end
      end,
      desc = 'Encrypt sops file',
    },
  },
}
