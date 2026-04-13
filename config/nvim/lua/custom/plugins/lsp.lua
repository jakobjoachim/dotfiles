return {
  -- Main LSP Configuration
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    -- Mason must be loaded before its dependents so we need to set it up here.
    -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
    { 'mason-org/mason.nvim', opts = {} },
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP.
    { 'j-hui/fidget.nvim', opts = {} },

    -- Allows extra capabilities provided by blink.cmp
    'saghen/blink.cmp',

    -- Rich TypeScript language server integration
    {
      'pmizio/typescript-tools.nvim',
      dependencies = { 'nvim-lua/plenary.nvim' },
    },
  },
  config = function()
    -- Brief aside: **What is LSP?**
    --
    -- LSP is an initialism you've probably heard, but might not understand what it is.
    --
    -- LSP stands for Language Server Protocol. It's a protocol that helps editors
    -- and language tooling communicate in a standardized fashion.
    --
    -- In general, you have a "server" which is some tool built to understand a particular
    -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
    -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
    -- processes that communicate with some "client" - in this case, Neovim!
    --
    -- LSP provides Neovim with features like:
    --  - Go to definition
    --  - Find references
    --  - Autocompletion
    --  - Symbol Search
    --  - and more!
    --
    -- Thus, Language Servers are external tools that must be installed separately from
    -- Neovim. This is where `mason` and related plugins come into play.
    --
    -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
    -- and elegantly composed help section, `:help lsp-vs-treesitter`

    --  This function gets run when an LSP attaches to a particular buffer.
    --    That is to say, every time a new file is opened that is associated with
    --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
    --    function will be executed to configure the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method('textDocument/documentHighlight', event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client:supports_method('textDocument/inlayHint', event.buf) then
          map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    local function is_list(tbl)
      return type(tbl) == 'table' and vim.tbl_islist(tbl)
    end

    local function load_language_specs()
      local specs = {}
      local languages_dir = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', 'custom', 'lsp_languages')
      local ok, iter = pcall(vim.fs.dir, languages_dir)
      if not ok then return specs end

      for name, type_ in iter do
        if type_ == 'file' and name:sub(-4) == '.lua' then
          local module = 'custom.lsp_languages.' .. name:sub(1, -5)
          package.loaded[module] = nil
          local success, lang_spec = pcall(require, module)
          if success and lang_spec then
            if is_list(lang_spec) then
              for _, entry in ipairs(lang_spec) do
                if type(entry) == 'table' and next(entry) ~= nil then table.insert(specs, entry) end
              end
            elseif type(lang_spec) == 'table' and next(lang_spec) ~= nil then
              table.insert(specs, lang_spec)
            end
          else
            vim.notify(('LSP: failed loading %s: %s'):format(module, lang_spec), vim.log.levels.ERROR)
          end
        end
      end

      table.sort(specs, function(a, b) return (a.order or 100) < (b.order or 100) end)
      return specs
    end

    local languages = load_language_specs()

    -- Ensure the language specific tools above are installed via Mason
    local ensure_installed = {}
    local seen = {}
    local function ensure(tool)
      if tool and not seen[tool] then
        seen[tool] = true
        table.insert(ensure_installed, tool)
      end
    end

    for _, spec in ipairs(languages) do
      if spec.mason then
        for _, tool in ipairs(spec.mason) do
          ensure(tool)
        end
      end
    end

    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    for _, spec in ipairs(languages) do
      if spec.enabled == false then goto continue end

      if type(spec.setup) == 'function' then
        spec.setup(capabilities)
      elseif spec.server then
        local server_opts = vim.tbl_deep_extend('force', {}, spec.opts or {})
        server_opts.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server_opts.capabilities or {})
        vim.lsp.config(spec.server, server_opts)
        vim.lsp.enable(spec.server)
      end

      ::continue::
    end
  end,
}
