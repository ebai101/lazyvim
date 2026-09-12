return {
  {
    'saghen/blink.cmp',
    opts = {
      keymap = { preset = 'super-tab' },
      completion = {
        trigger = {
          show_in_snippet = false,
        },
        list = {
          selection = {
            preselect = function(_)
              return not require('blink.cmp').snippet_active { direction = 1 }
            end,
          },
        },
      },
    },
  },
}
