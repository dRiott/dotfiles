"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                              " Basic Settings:
syntax on
set nocompatible                  " required by vimwiki
filetype plugin on                " required by vimwiki

set number                        " line numbers
set history=500		              " keep 500 lines of command line history
set noruler		                  " hide the cursor position all the time
set showcmd		                  " display incomplete commands
set incsearch		              " do incremental searching
set hlsearch                      " search highlighting on.

set backspace=indent,eol,start    " allow backspacing over everything in insert

" Foldlevel 0 is unindented lines, 1 is both unindented and singlely, etc.
set nofoldenable                  " disable folding
" set foldmethod=indent
" set foldlevel=3

" Codebase that uses 2 space characters for each indent
set tabstop=4                     " size of a hard tabstop
set softtabstop=0                 " comination of spaces and tabs are used to simulate tab stops at a width
set expandtab                     " always uses spaces insead of tab characters
set shiftwidth=2                  " size of an 'indent'
set smarttab                      " make 'tab' insert indents indead of tabs at the beginning of a line

" Codebase that uses a single tab character that appears 4-spaces-wide
" set tabstop=4 softtabstop=0 noexpandtab shiftwidth=4


" Plugins
" :PlugInstall
" sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

call plug#begin('~/.vim/plugged')

Plug 'morhetz/gruvbox'
Plug 'tpope/vim-surround'
Plug 'kyoz/purify', { 'rtp': 'vim' }
Plug 'vimwiki/vimwiki'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

" Vimwiki Configuration
" Make Vimwiki use Markdown
let g:vimwiki_list = [{'path': '~/vimwiki/',
                      \ 'syntax': 'markdown', 'ext': '.md'}]

" Airline Configuration
let g:airline_theme='gruvbox'

"
" Colors
"
set termguicolors
set t_Co=256

"
" Color-Schemes
"

" PaperColor
" https://github.com/NLKNguyen/papercolor-theme
"set background=dark
"colorscheme PaperColor

" Gruvbox
" https://github.com/morhetz/gruvbox/
colorscheme gruvbox
set background=dark
let g:gruvbox_contrast_dark = 'hard'

" Zenburn
" https://github.com/jnurmine/Zenburn
" colors zenburn

" Purify
" https://github.com/kyoz/purify/tree/master/vim
" colorscheme purify


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Mappings

noremap <Down> 15<Down>
noremap <Up> 15<Up>
noremap <Left> 15<Left>
noremap <Right> 15<Right>


