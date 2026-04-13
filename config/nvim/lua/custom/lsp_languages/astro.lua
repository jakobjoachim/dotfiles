return {
  server = 'astro',
  mason = { 'astro-language-server' },
  opts = {
    filetypes = { 'astro' },
    init_options = {
      typescript = {
        serverPath = vim.fn.exepath 'typescript-language-server',
      },
    },
  },
}
