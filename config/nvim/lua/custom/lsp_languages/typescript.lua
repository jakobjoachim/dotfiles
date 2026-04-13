return {
  mason = { 'typescript-language-server' },
  setup = function(capabilities)
    local ts_tools = require 'typescript-tools'

    ts_tools.setup {
      capabilities = capabilities,
      settings = {
        tsserver_max_memory = 4096,
        tsserver_file_preferences = {
          includeInlayParameterNameHints = 'all',
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeCompletionsForModuleExports = true,
          importModuleSpecifierPreference = 'non-relative',
        },
        expose_as_code_action = {
          'fix_all',
          'add_missing_imports',
          'remove_unused',
          'add_missing_enum_members',
        },
      },
    }
  end,
}
