local function safe_require(module)
  local ok, err = pcall(require, module)
  if not ok then
    vim.notify('Error loading ' .. module .. '\n\n' .. err, vim.log.levels.ERROR)
  end
end

local function load_modules(modules)
  for _, module in ipairs(modules) do
    safe_require(module)
  end
end

load_modules({
  'config.option',
  'config.lazy',
  'config.map',
  'config.autocmd',
})