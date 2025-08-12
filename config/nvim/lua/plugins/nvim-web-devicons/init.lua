-- lua/plugins/nvim-web-devicons/init.lua
return {
  'nvim-tree/nvim-web-devicons',
  event = 'VeryLazy',
  opts = function()
    return {
      color_icons = true,
      default = true, -- usa íconos genéricos si no hay match
      strict = true, -- coincide por filename antes que por extensión
      override = {
        -- Extensiones
        ts = { icon = '', color = '#3178c6', name = 'Ts' },
        tsx = { icon = '', color = '#3178c6', name = 'Tsx' },
        js = { icon = '', color = '#f7df1e', name = 'Js' },
        jsx = { icon = '', color = '#61dafb', name = 'Jsx' },
        mjs = { icon = '', color = '#f7df1e', name = 'Mjs' },
        cjs = { icon = '', color = '#f7df1e', name = 'Cjs' },

        json = { icon = '', color = '#cbcb41', name = 'Json' },
        jsonc = { icon = '', color = '#cbcb41', name = 'Jsonc' },
        md = { icon = '', color = '#519aba', name = 'Markdown' },
        mdx = { icon = '', color = '#519aba', name = 'Mdx' },

        css = { icon = '', color = '#563d7c', name = 'Css' },
        scss = { icon = '', color = '#c6538c', name = 'Scss' },
        sass = { icon = '', color = '#c6538c', name = 'Sass' },
        less = { icon = '', color = '#2b4c80', name = 'Less' },

        html = { icon = '', color = '#e44d26', name = 'Html' },
        htm = { icon = '', color = '#e44d26', name = 'Htm' },

        vue = { icon = '', color = '#41b883', name = 'Vue' },
        svelte = { icon = '', color = '#ff3e00', name = 'Svelte' },
        astro = { icon = '', color = '#f8c1ff', name = 'Astro' },

        graphql = { icon = '', color = '#e10098', name = 'GraphQL' },
        prisma = { icon = '', color = '#0c344b', name = 'Prisma' },

        dockerfile = { icon = '', color = '#2496ed', name = 'Dockerfile' },
        yml = { icon = '', color = '#6d8086', name = 'Yml' },
        yaml = { icon = '', color = '#6d8086', name = 'Yaml' },

        toml = { icon = '', color = '#9c4221', name = 'Toml' },
        lock = { icon = '', color = '#cfcfcf', name = 'Lock' },

        sh = { icon = '', color = '#89e051', name = 'Sh' },
        bash = { icon = '', color = '#89e051', name = 'Bash' },
        zsh = { icon = '', color = '#428850', name = 'Zsh' },

        lua = { icon = '', color = '#51a0cf', name = 'Lua' },
        py = { icon = '', color = '#3572A5', name = 'Py' },
        rb = { icon = '', color = '#cc342d', name = 'Rb' },
        go = { icon = '', color = '#00ADD8', name = 'Go' },
        rs = { icon = '', color = '#dea584', name = 'Rust' },

        -- Filenames específicos
        ['package.json'] = { icon = '', color = '#e8274b', name = 'PackageJson' },
        ['package-lock.json'] = { icon = '', color = '#e8274b', name = 'PackageLockJson' },
        ['yarn.lock'] = { icon = '', color = '#2c8ebb', name = 'YarnLock' },
        ['pnpm-lock.yaml'] = { icon = '', color = '#f69220', name = 'PnpmLock' },
        ['.env'] = { icon = '', color = '#faf743', name = 'Env' },
        ['.env.local'] = { icon = '', color = '#faf743', name = 'EnvLocal' },
        ['tailwind.config.js'] = { icon = '󱏿', color = '#38bdf8', name = 'Tailwind' },
        ['tailwind.config.ts'] = { icon = '󱏿', color = '#38bdf8', name = 'TailwindTs' },
        ['.prettierrc'] = { icon = '', color = '#56b3b4', name = 'Prettier' },
        ['.eslintrc'] = { icon = '', color = '#4b32c3', name = 'Eslint' },
        ['Dockerfile'] = { icon = '', color = '#2496ed', name = 'DockerfileRoot' },
        ['Makefile'] = { icon = '', color = '#6d8086', name = 'Makefile' },
        ['LICENSE'] = { icon = '', color = '#d0bf41', name = 'License' },
        ['README.md'] = { icon = '', color = '#519aba', name = 'Readme' },
      },
    }
  end,
  config = function(_, opts)
    require('nvim-web-devicons').setup(opts)
  end,
}
