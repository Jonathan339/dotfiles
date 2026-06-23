local M = {}

local defaults = {
  formatters = nil,
  log_level = vim.log.levels.INFO,
}

local state = {
  opts = nil,
  format_enabled = true,
}

local function log(msg, level)
  level = level or state.opts.log_level
  vim.schedule(function()
    pcall(vim.notify, '[auto-ensure] ' .. msg, level)
  end)
end

local function setup_formatting(fmt_opts)
  if not fmt_opts or not fmt_opts.formatters_by_ft then return end

  local ok, conform = pcall(require, 'conform')
  if not ok then
    log('conform.nvim not available, skipping format setup', vim.log.levels.WARN)
    return false
  end

  local fmt_cfg = vim.tbl_deep_extend('force', {
    notify_on_error = false,
    format_on_save = false,
    default_format_opts = {
      lsp_format = 'fallback',
      timeout_ms = 1000,
    },
  }, fmt_opts)

  conform.setup(fmt_cfg)

  local max_size = fmt_opts.max_format_size or 200 * 1024

  local function safe_format(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name == '' then return end
    local ok_st, st = pcall((vim.uv or vim.loop).fs_stat, name)
    if ok_st and st and st.size and st.size > max_size then return end

    conform.format({
      bufnr = bufnr,
      lsp_fallback = fmt_cfg.default_format_opts.lsp_format == 'fallback',
      quiet = true,
      timeout_ms = fmt_cfg.default_format_opts.timeout_ms or 1000,
    })
  end

  local fmt_aug = vim.api.nvim_create_augroup('AutoEnsureFormat', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = fmt_aug,
    callback = function(args)
      if not state.format_enabled then return end
      safe_format(args.buf)
    end,
  })

  vim.api.nvim_create_user_command('Format', function()
    safe_format(vim.api.nvim_get_current_buf())
  end, {})

  vim.api.nvim_create_user_command('FormatToggle', function()
    state.format_enabled = not state.format_enabled
    vim.notify('Format on Save: ' .. (state.format_enabled and 'ON' or 'OFF'))
  end, {})

  return true
end

function M.setup(opts)
  state.opts = vim.tbl_deep_extend('force', {}, defaults, opts or {})

  if state.opts.formatters then
    setup_formatting(state.opts.formatters)
  end
end

return M
