-- luacheck: globals vim
--
-- NOTE: watch https://github.com/neovim/neovim/blob/971e0ca903fce05bd4853b129ed40dee7366956f/src/nvim/lua/vim.lua#L498
-- for improvements/changes
local ll = vim.log.levels
local notify_pre = {
  [ll.INFO] = "🅸",
  [ll.WARN] = "🆆",
  [ll.ERROR] = "🅴",
  [ll.TRACE] = "🆃",
  [ll.DEBUG] = "🅳",
}

local function notify(msg, log_level, _)
  local c = vim.cmd
  local l = vim.log.levels[log_level or 1000]
  local pre = ""

  if l and l ~= "" then
    c("echohl Echo" .. l);
    pre = notify_pre[log_level] .. " "
  end

  c(([[echom "%s%s"]]):format(pre, msg))
  c("echohl none")
end

return function()
  vim.notify = notify

  local n = function(level)
    return function(msg)
      vim.notify(msg, level)
    end
  end

  -- NOTE: this is bad, I know... :-)
  vim.Info = vim.Info or n(ll.INFO)
  vim.Warn = vim.Warn or n(ll.WARN)
  vim.Error = vim.Error or n(ll.ERROR)
  vim.Debug = vim.Debug or n(ll.DEBUG)
end
