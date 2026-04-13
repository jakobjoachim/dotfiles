return {
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },
  {
    'vuki656/package-info.nvim',
    ft = { 'json' },
    dependencies = { 'MunifTanjim/nui.nvim' },
    config = function()
      local package_info = require 'package-info'
      package_info.setup {}
      -- Toggle dependency versions
      vim.keymap.set({ 'n' }, '<LEADER>nt', require('package-info').toggle, { silent = true, noremap = true })

      -- Update dependency on the line
      vim.keymap.set({ 'n' }, '<LEADER>nu', require('package-info').update, { silent = true, noremap = true })

      -- Install a different dependency version
      vim.keymap.set({ 'n' }, '<LEADER>np', require('package-info').change_version, { silent = true, noremap = true })
    end,
  },
}
