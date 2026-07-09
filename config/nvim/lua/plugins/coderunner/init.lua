local M = {
  'CRAG666/code_runner.nvim',
  cmd = 'RunCode',
  config = true,
}

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
      c = function(...)
        local c_base = {
          'cd $dir &&',
          'gcc $fileName -o',
          '/tmp/$fileNameWithoutExt',
        }
        local c_exec = {
          '&& /tmp/$fileNameWithoutExt &&',
          'rm /tmp/$fileNameWithoutExt',
        }
        vim.ui.input({ prompt = 'Add more args:' }, function(input)
          c_base[4] = input
          require('code_runner.commands').run_from_fn(vim.list_extend(c_base, c_exec))
        end)
      end,
    },
  })
end

return M
