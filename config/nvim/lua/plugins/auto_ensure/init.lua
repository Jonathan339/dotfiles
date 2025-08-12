-- lua/plugins/auto_ensure/init.lua
-- Auto-instala Treesitter, LSP y formatters/linters al abrir un nuevo filetype
-- Robusto contra carreras, con skip-list, alias TS, comandos útiles y linters.

return {
  dir = os.getenv('HOME') .. '/.dotfiles/config/nvim/lua/plugins/auto_ensure',
  name = 'auto-ensure-tools',
  lazy = false,
  config = function()
    ---------------------------------------------------------------------
    -- Ajustes rápidos
    ---------------------------------------------------------------------
    local settings = {
      enable_linters = true, -- 🔛 linters activados
      log_level = vim.log.levels.INFO, -- DEBUG | INFO | WARN | ERROR
      max_file_size = 1024 * 1024, -- 1 MB
      skip_fts = { 'gitcommit', 'gitrebase', 'help', 'TelescopePrompt', 'neo-tree', 'oil', 'dirvish', 'alpha', 'startify' },
    }

    local function log(msg, level)
      level = level or settings.log_level
      vim.schedule(function()
        pcall(vim.notify, '[auto-ensure] ' .. msg, level)
      end)
    end
    local function in_list(val, list)
      for _, v in ipairs(list) do
        if v == val then
          return true
        end
      end
      return false
    end

    ---------------------------------------------------------------------
    -- CONFIG: mapeos por filetype
    ---------------------------------------------------------------------
    local lsp_by_ft = {
      lua = 'lua_ls',
      python = 'pyright',
      javascript = 'ts_ls',
      javascriptreact = 'ts_ls',
      typescript = 'ts_ls',
      typescriptreact = 'ts_ls',
      tsx = 'ts_ls',
      jsx = 'ts_ls',
      json = 'jsonls',
      yaml = 'yamlls',
      bash = 'bashls',
      sh = 'bashls',
      html = 'html',
      css = 'cssls',
      dockerfile = 'dockerls',
      terraform = 'terraformls',
      go = 'gopls',
      rust = 'rust_analyzer',
      php = 'intelephense',
      java = 'jdtls',
      c = 'clangd',
      cpp = 'clangd',
      markdown = 'marksman',
      vue = 'vuels', -- o "volar" (vue-language-server) si preferís Vue 3 + TS
      svelte = 'svelte',
      astro = 'astro',
      kotlin = 'kotlin_language_server',
      ruby = 'ruby_ls',
      elixir = 'elixirls',
      r = 'r_language_server',
      tex = 'texlab',
      zig = 'zls',
      nix = 'nil_ls',
    }

    -- overrides: server LSP -> paquete Mason
    local mason_pkg_for_lsp = {
      lua_ls = 'lua-language-server',
      ts_ls = 'typescript-language-server',
      jsonls = 'json-lsp',
      html = 'html-lsp',
      cssls = 'css-lsp',
      bashls = 'bash-language-server',
      yamlls = 'yaml-language-server',
      dockerls = 'dockerfile-language-server',
      terraformls = 'terraform-ls',
      rust_analyzer = 'rust-analyzer',
      marksman = 'marksman',
      gopls = 'gopls',
      pyright = 'pyright',
      intelephense = 'intelephense',
      jdtls = 'jdtls',
      clangd = 'clangd',
      svelte = 'svelte-language-server',
      astro = 'astro-language-server',
      vuels = 'vls',
      volar = 'vue-language-server',
      kotlin_language_server = 'kotlin-language-server',
      ruby_ls = 'ruby-lsp',
      elixirls = 'elixir-ls',
      r_language_server = 'r-languageserver',
      texlab = 'texlab',
      zls = 'zls',
      nil_ls = 'nil',
    }

    local mason_pkg_for_formatter = {
      stylua = 'stylua',
      prettier = 'prettier',
      ['prettierd'] = 'prettierd',
      eslint_d = 'eslint_d',
      black = 'black',
      isort = 'isort',
      shfmt = 'shfmt',
      beautysh = 'beautysh',
      yapf = 'yapf',
      ['clang-format'] = 'clang-format',
      gofumpt = 'gofumpt',
      goimports = 'goimports-reviser',
      rustfmt = 'rustfmt',
      alejandra = 'alejandra',
      taplo = 'taplo',
      stylis = 'stylelint',
    }

    -- Orden: eslint_d (autofix) -> prettierd/prettier (formato)
    local formatters_by_ft = {
      lua = { 'stylua' },
      javascript = { 'eslint_d', 'prettierd', 'prettier' },
      javascriptreact = { 'eslint_d', 'prettierd', 'prettier' },
      typescript = { 'eslint_d', 'prettierd', 'prettier' },
      typescriptreact = { 'eslint_d', 'prettierd', 'prettier' },
      jsx = { 'eslint_d', 'prettierd', 'prettier' },
      tsx = { 'eslint_d', 'prettierd', 'prettier' },
      json = { 'prettierd', 'prettier' },
      yaml = { 'prettierd', 'prettier' },
      markdown = { 'prettierd', 'prettier' },
      sh = { 'shfmt' },
      python = { 'isort', 'black' },
      c = { 'clang-format' },
      cpp = { 'clang-format' },
      go = { 'gofumpt', 'goimports' },
      rust = { 'rustfmt' },
      nix = { 'alejandra' },
      toml = { 'taplo' },
      css = { 'prettierd', 'prettier' },
      html = { 'prettierd', 'prettier' },
      vue = { 'eslint_d', 'prettierd', 'prettier' },
      svelte = { 'eslint_d', 'prettierd', 'prettier' },
      astro = { 'eslint_d', 'prettierd', 'prettier' },
    }

    -- Linters (si usás nvim-lint, etc.)
    local linters_by_ft = {
      javascript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      typescript = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
      vue = { 'eslint_d' },
      svelte = { 'eslint_d' },
      astro = { 'eslint_d' },
      python = { 'ruff' },
    }
    local mason_pkg_for_linter = { eslint_d = 'eslint_d', ruff = 'ruff' }

    ---------------------------------------------------------------------
    -- Helpers: carga/chequeo lspconfig (evita warnings y falsos negativos)
    ---------------------------------------------------------------------
    local function require_lspconfig()
      local ok, lspconfig = pcall(require, 'lspconfig')
      if ok then
        return lspconfig
      end
      local ok_lazy, lazy = pcall(require, 'lazy')
      if ok_lazy then
        pcall(lazy.load, { plugins = { 'nvim-lspconfig' } })
        pcall(lazy.load, { plugins = { 'neovim/nvim-lspconfig' } })
      end
      local ok2, lspconfig2 = pcall(require, 'lspconfig')
      return ok2 and lspconfig2 or nil
    end

    local function lsp_server_available(server)
      require_lspconfig()
      -- ts_ls puede existir como builtin (nuevo) o custom; probamos ambos nombres
      local candidates = (server == 'ts_ls') and { 'ts_ls', 'tsserver' } or { server }

      -- 1) ¿Existe módulo builtin?
      for _, name in ipairs(candidates) do
        if pcall(require, 'lspconfig.server_configurations.' .. name) then
          return true
        end
      end

      -- 2) ¿Está registrado como custom en lspconfig.configs?
      local ok_cfgs, cfgs = pcall(require, 'lspconfig.configs')
      if ok_cfgs then
        for _, name in ipairs(candidates) do
          if cfgs[name] ~= nil then
            return true
          end
        end
      end

      return false
    end

    ---------------------------------------------------------------------
    -- Cola de instalaciones + utilidades
    ---------------------------------------------------------------------
    local visited = {}
    local install_queue, running_install = {}, false

    local function enqueue_install(fn)
      table.insert(install_queue, fn)
      if running_install then
        return
      end
      running_install = true
      local function step()
        local job = table.remove(install_queue, 1)
        if not job then
          running_install = false
          return
        end
        job(function()
          vim.schedule(step)
        end)
      end
      vim.schedule(step)
    end

    local function ensure_mason_package(pkg_name, done)
      local ok_reg, registry = pcall(require, 'mason-registry')
      if not ok_reg then
        log('mason-registry no disponible', vim.log.levels.WARN)
        return done and done()
      end
      local ok_pkg, pkg = pcall(registry.get_package, pkg_name)
      if not ok_pkg then
        log('paquete Mason invalido: ' .. tostring(pkg_name), vim.log.levels.WARN)
        return done and done()
      end
      if pkg:is_installed() then
        return done and done()
      end
      if done then
        pkg:once('install:success', function()
          log('instalado: ' .. pkg_name, vim.log.levels.DEBUG)
          pcall(done)
        end)
        pkg:once('install:failed', function()
          log('falló instalación: ' .. pkg_name, vim.log.levels.ERROR)
          pcall(done)
        end)
      end
      pkg:install()
    end

    ---------------------------------------------------------------------
    -- Treesitter
    ---------------------------------------------------------------------
    local function treesitter_install(ft)
      local ok_parsers, parsers = pcall(require, 'nvim-treesitter.parsers')
      if not ok_parsers or not ft or ft == '' then
        return
      end
      local alias = {
        sh = 'bash',
        jsx = 'javascript',
        javascriptreact = 'javascript',
        typescriptreact = 'tsx',
      }
      ft = alias[ft] or ft

      local extra_by_ft = { markdown = { 'markdown', 'markdown_inline' } }
      local candidates = extra_by_ft[ft] or { ft }

      local configs = parsers.get_parser_configs() or {}
      local to_install = {}
      for _, name in ipairs(candidates) do
        if configs[name] and not parsers.has_parser(name) then
          table.insert(to_install, name)
        end
      end
      if #to_install == 0 then
        return
      end

      for _, name in ipairs(to_install) do
        vim.schedule(function()
          local ok = pcall(vim.cmd, 'TSInstallSync ' .. name)
          if ok then
            log('TS parser ok: ' .. name, vim.log.levels.DEBUG)
          end
        end)
      end
    end

    ---------------------------------------------------------------------
    -- LSP on-demand (sin warnings)
    ---------------------------------------------------------------------
    local function lsp_setup_on_demand(server)
      -- 1) Confirmar que el server exista en lspconfig
      if not lsp_server_available(server) then
        log('server no disponible en lspconfig: ' .. server, vim.log.levels.WARN)
        return
      end

      local lspconfig = require_lspconfig()
      if not lspconfig then
        return
      end

      -- 2) Cargar defaults/handlers del usuario (si existen)
      local capabilities, user_on_attach
      pcall(function()
        capabilities = require('plugins.lsp.defaults').capabilities
      end)
      pcall(function()
        user_on_attach = require('plugins.lsp.handlers').on_attach
      end)

      -- 3) Un on_attach que desactiva formateo del LSP donde usamos Conform
      local disable_fmt = { ts_ls = true, lua_ls = true, jsonls = true, eslint = true }
      local function merged_on_attach(client, bufnr)
        if disable_fmt[server] and client.server_capabilities then
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end
        if type(user_on_attach) == 'function' then
          pcall(user_on_attach, client, bufnr)
        end
      end

      -- 4) Hacer setup mínimo si aún no fue configurado por mason-lspconfig
      local cfg = lspconfig[server]
      if cfg and (not cfg.document_config or not cfg.document_config.on_new_config) then
        cfg.setup({
          capabilities = capabilities,
          on_attach = merged_on_attach,
        })
      end
    end

    local function ensure_lsp(ft, bufnr)
      local server = lsp_by_ft[ft]
      if not server then
        return
      end

      -- 🔴 importante: garantizá que lspconfig esté cargado ANTES de checks
      require_lspconfig()

      local mason_pkg = mason_pkg_for_lsp[server] or server
      enqueue_install(function(next)
        ensure_mason_package(mason_pkg, function()
          -- verificar config disponible sin producir falsos negativos
          if not lsp_server_available(server) then
            -- intenta forzar carga nuevamente
            require_lspconfig()
            if not lsp_server_available(server) then
              log(('config "%s" no encontrada en lspconfig (post-inst)'):format(server), vim.log.levels.WARN)
              next()
              return
            end
          end

          -- setup y attach
          lsp_setup_on_demand(server)
          vim.schedule(function()
            local lspconfig = require_lspconfig()
            if lspconfig and lspconfig[server] and lspconfig[server].manager then
              pcall(function()
                lspconfig[server].manager.try_add_wrapper(bufnr)
              end)
            end
            next()
          end)
        end)
      end)
    end

    local function ensure_formatters(ft)
      local tools = formatters_by_ft[ft]
      if not tools then
        return
      end
      for _, fmt in ipairs(tools) do
        local pkg = mason_pkg_for_formatter[fmt]
        if pkg then
          enqueue_install(function(next)
            ensure_mason_package(pkg, next)
          end)
        end
      end
    end

    local function ensure_linters(ft)
      if not settings.enable_linters then
        return
      end
      local tools = linters_by_ft[ft]
      if not tools then
        return
      end
      for _, l in ipairs(tools) do
        local pkg = mason_pkg_for_linter[l]
        if pkg then
          enqueue_install(function(next)
            ensure_mason_package(pkg, next)
          end)
        end
      end
    end

    ---------------------------------------------------------------------
    -- Skip conditions
    ---------------------------------------------------------------------
    local function should_skip(ft, buf)
      if not ft or ft == '' then
        return true
      end
      if in_list(ft, settings.skip_fts) then
        return true
      end
      local name = vim.api.nvim_buf_get_name(buf)
      if name == '' then
        return false
      end
      local ok, st = pcall(vim.loop.fs_stat, name)
      if ok and st and st.size and st.size > settings.max_file_size then
        log(('skip por tamaño (%.1f KB): %s'):format(st.size / 1024, ft), vim.log.levels.DEBUG)
        return true
      end
      return false
    end

    ---------------------------------------------------------------------
    -- Autocomando central
    ---------------------------------------------------------------------
    local aug = vim.api.nvim_create_augroup('AutoEnsureTools', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      group = aug,
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        if should_skip(ft, args.buf) or visited[ft] then
          return
        end
        visited[ft] = true
        treesitter_install(ft)
        ensure_lsp(ft, args.buf)
        ensure_formatters(ft)
        ensure_linters(ft)
      end,
    })

    ---------------------------------------------------------------------
    -- Comandos
    ---------------------------------------------------------------------
    vim.api.nvim_create_user_command('AutoEnsureHere', function()
      local buf = vim.api.nvim_get_current_buf()
      local ft = vim.bo[buf].filetype
      if should_skip(ft, buf) then
        log('skip en buffer actual (' .. tostring(ft) .. ')', vim.log.levels.WARN)
        return
      end
      visited[ft] = nil
      treesitter_install(ft)
      ensure_lsp(ft, buf)
      ensure_formatters(ft)
      ensure_linters(ft)
      log('reintentado ensure para ft=' .. ft, vim.log.levels.INFO)
    end, {})

    vim.api.nvim_create_user_command('AutoEnsurePurgeVisited', function()
      visited = {}
      log('visited cache limpiado', vim.log.levels.INFO)
    end, {})

    vim.api.nvim_create_user_command('AutoEnsureAllKnown', function()
      for ft, _ in pairs(lsp_by_ft) do
        if not in_list(ft, settings.skip_fts) then
          visited[ft] = nil
          treesitter_install(ft)
          ensure_lsp(ft, vim.api.nvim_get_current_buf())
          ensure_formatters(ft)
          ensure_linters(ft)
        end
      end
      log('ensure lanzado para todos los fts conocidos', vim.log.levels.INFO)
    end, {})
  end,
}
