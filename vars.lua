return {
  env = {GOFLAGS = "-tags=development"},
  g = {
    cursorhold_updatetime = 500,
    netrw = {
      banner = 0,
      liststyle = 0,
      browse_split = 4,
      preview = 1,
      altv = 1,
      list_hide = [[^\.[a-zA-Z].*,^\./$]],
      winsize = -25,
    },
  },
}
