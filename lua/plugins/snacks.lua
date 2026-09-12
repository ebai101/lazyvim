return {
  'folke/snacks.nvim',
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
