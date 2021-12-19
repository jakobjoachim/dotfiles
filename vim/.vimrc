"" General
set number	                " Show line numbers
set nowrap	                " Wrap lines
set showbreak=+++ 	        " Wrap-broken line prefix
set showmatch	                " Highlight matching brace
set spell	                " Enable spell-checking
set visualbell	                " Use visual bell (no beeping)
set nospell			" no spellcheck
 
set hlsearch	                " Highlight all search results
set smartcase	                " Enable smart-case search
set ignorecase	                " Always case-insensitive
set incsearch	                " Searches for strings incrementally
 
set autoindent	                " Auto-indent new lines
set shiftwidth=2	        " Number of auto-indent spaces
set smartindent	                " Enable smart-indent
set smarttab	                " Enable smart-tabs
set softtabstop=2	        " Number of spaces per Tab
 
"" Advanced
set ruler	                " Show row and column ruler information
 
set undolevels=1000	        " Number of undo levels
set backspace=indent,eol,start	" Backspace behaviour

"" Lightline Plugin
set laststatus=2                " for lightline plugin
set noshowmode			" lightline already shows this information
let g:lightline = {
      \ 'colorscheme': 'wombat',
      \ }

"" Load Vim Plugins
so ~/.vim/plugins.vim
