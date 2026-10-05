return {
  'imax153/git-worktree.nvim',
  opts = {},
  keys = {
    {
      '<leader>gw',
      function()
        require('git-worktree.snacks').worktrees()
      end,
      desc = 'Git Worktree',
    },
  },
}
