-- lua/plugins/coderunner/init.lua
-- Único camino de ejecución de la config (<leader>m). C y C++ comparten el
-- mismo flujo: compilar a /tmp, ejecutar con argumentos opcionales y limpiar.
local M = {
  'CRAG666/code_runner.nvim',
  cmd = 'RunCode',
}

local function compile_and_run(compiler)
  return function()
    vim.ui.input({ prompt = 'Argumentos (vacío = ninguno): ' }, function(input)
      if input == nil then
        return
      end

      local cmd = ('cd $dir && %s $fileName -o /tmp/$fileNameWithoutExt && /tmp/$fileNameWithoutExt'):format(compiler)
      if input ~= '' then
        cmd = cmd .. ' ' .. input
      end
      cmd = cmd .. '; rm -f /tmp/$fileNameWithoutExt'

      require('code_runner.commands').run_from_fn(cmd)
    end)
  end
end

function M.config()
  require('code_runner').setup({
    filetype = {
      java = {
        'cd $dir &&',
        'javac $fileName &&',
        'java $fileNameWithoutExt',
      },
      python = 'python3 -u',
      typescript = 'bun run',
      rust = {
        'cd $dir &&',
        'rustc $fileName &&',
        '$dir/$fileNameWithoutExt',
      },
      c = compile_and_run('gcc'),
      cpp = compile_and_run('g++'),
    },
  })
end

return M
