return {
  'folke/snacks.nvim',
  keys = {
    {
      '<leader>gp',
      function()
        require('forge').pr()
      end,
      desc = 'Pull Requests (open)',
    },
    {
      '<leader>gP',
      function()
        require('forge').pr { state = 'all' }
      end,
      desc = 'Pull Requests (all)',
    },
  },
  opts = {
    picker = {
      sources = {
        files = {
          hidden = true,
        },
        explorer = {
          win = {
            list = {
              keys = {
                ['<C-q>'] = 'close',
              },
            },
          },
        },
      },
    },
    dashboard = { enabled = false },
    scroll = {
      animate_repeat = {
        delay = 100,
        duration = { step = 1, total = 1 },
        easing = 'linear',
      },
    },
  },
}
