" Vim's prefix variables.
let mapleader=","
let maplocalleader = "||"

" echo '" (>^.^<) "'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                            "Vundle Plugin Setup"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

set nocompatible              " be iMproved, required
filetype off                  " required for Vundle, will be turned on later

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin() "Alternatively, vundle#begin('~/path/install/plugins')

Plugin 'VundleVim/Vundle.vim' " let Vundle manage Vundle, required

" ~~~~~~~~~~~~~~~ Plugin commands between vundle#begin/end. ~~~~~~~~~~~~~~~~ "
Plugin 'tpope/vim-fugitive'              " Git for Vim
Plugin 'tpope/vim-surround'              " Easily d, c, i surroundings in pairs
Plugin 'tpope/vim-commentary'            " Comment stuff out
Plugin 'tpope/vim-repeat'                " Expands dot operator's capability
Plugin 'tpope/vim-abolish'               " Find/replace support for plurals
Plugin 'scrooloose/syntastic'            " Lint check code inside Vim
Plugin 'bronson/vim-trailing-whitespace' " Highlights trailing whitespace
Plugin 'nelstrom/vim-visual-star-search' " In Visual, * searches the selection
Plugin 'tmhedberg/matchit'               " Expands % oprtr to include html tags
Plugin 'sickill/vim-pasta'               " Auto-tabs based on surrounding code
Plugin 'bling/vim-airline'               " Lean & mean status/tabline for vim
Plugin 'ctrlpvim/ctrlp.vim'              " Fuzzy file, buffer, mru, etc finder
Plugin 'scrooloose/nerdtree'             " A tree explorer plugin for vim
Plugin 'Xuyuanp/nerdtree-git-plugin'     " NerdTree Git highlighting
Plugin 'pangloss/vim-javascript'         " Improved JS indentation &
Plugin 'mattn/emmet-vim'                 " Emmet for Vim
Plugin 'easymotion/vim-easymotion'       " Vim motions on speed!
Plugin 'ervandew/supertab'               " Vim Insert mode completions with tab
Plugin 'nathanaelkane/vim-indent-guides' " Visually display indent levels
Plugin 'mhinz/vim-startify'              " A fancy start screen for Vim
Plugin 'benmills/vimux'                  " Interact with tmux from Vim

" Suggested by: http://oli.me.uk/2015/06/17/wrangling-javascript-with-vim/
Plugin 'vim-scripts/ZoomWin'             " Toggle between one and multi-window
Plugin 'PeterRincker/vim-argumentative'  " Change the order of arguments easily
Plugin 'Raimondi/delimitMate'            " Automatically match pairs smartly.
Plugin 'Valloric/YouCompleteMe'          " Great completion engine
Plugin 'Wolfy87/vim-enmasse'             " Edit quickfix list and write the changes to their files.
Plugin 'helino/vim-json'                 " Show JSON some love.
Plugin 'junegunn/vim-easy-align'         " Makes alignment issues trivial.
Plugin 'marijnh/tern_for_vim'            " Completion for JS, esp. w/ YouCompleteMe
Plugin 'mhinz/vim-signify'               " Git info in the gutter.
Plugin 'rking/ag.vim'                    " Search across a lot of files.

" Examples of the ways Vundle can find and install Plugins...

	" From http://vim-scripts.org
		" Plugin 'L9'

	" Git plugin not hosted on GitHub
		" Plugin 'git://git.wincent.com/command-t.git'

	" Git repos on your local machine (when working on your own plugin)
		" Plugin 'file:///home/gmarik/path/to/plugin'

	" Vim script is in a subdirectory of this repo called vim.
	" Pass the path to set the runtimepath properly.
		" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}

	" Avoid a name conflict with L9
		" Plugin 'user/L9', {'name': 'newL9'}


call vundle#end()            " Add all plugins before this line, Vundle
filetype plugin indent on    " required by Vundle
" To ignore plugin indent changes, instead use: filetype plugin on

""" Brief Help With Vundle
    " see :h vundle for more details or wiki for FAQ
    " :PluginList       - lists configured plugins
    " :PluginInstall    - installs plugins; append `!` to update or just
    " :PluginUpdate
    " :PluginSearch foo - searches for foo; append `!` to refresh local cache
    " :PluginClean      - confirms removal of unused plugins; append `!` to
    " auto-approve removal



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                            "Plugin Customization"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Airline Customization:
	set laststatus=2
	set noshowmode
	set timeoutlen=300
	let g:airline_theme='bubblegum'
	set encoding=utf-8
	let g:Powerline_symbols = 'fancy'
	let g:airline_powerline_fonts=1
	set t_Co=256
	set fillchars+=stl:\ ,stlnc:\
	set term=xterm-256color
	set termencoding=utf-8

	if !exists('g:airline_symbols')
		let g:airline_symbols = {}
	endif

	" unicode symbols
	let g:airline_left_sep = '»'
	let g:airline_left_sep = '>'
	let g:airline_right_sep = '«'
	let g:airline_right_sep = '◀'
	let g:airline_symbols.linenr = '␊'
	let g:airline_symbols.linenr = '␤'
	let g:airline_symbols.linenr = '¶'
	let g:airline_symbols.branch = '⎇'
	let g:airline_symbols.paste = 'ρ'
	let g:airline_symbols.paste = 'Þ'
	let g:airline_symbols.paste = '∥'
	let g:airline_symbols.whitespace = 'Ξ'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" NerdTree Customization:
	let NERDTreeShowHidden=1      " show hidden files in NerdTree

	autocmd VimEnter *
            \   if !argc()
            \ |   Startify
            \ |   NERDTree
            \ |   wincmd w
            \ | endif

        " Ctrl-n Toggles NerdTree
	map <C-n> :NERDTreeToggle<CR>

	" Close NerdTree if it's the only window left
	autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree")
	      	\ && b:NERDTree.isTabTree()) | q | endif

	" Provide Bookmarks to Startify
	let g:startify_bookmarks = [ {'v': '~/.vimrc'}, {'z': '~/.zshrc'} ]

	let g:startify_custom_footer = [
	    \ '',
	    \ '',
	    \ '',
	    \ '    This shit be poppin''. Welcome to Vim.               ',
	    \ '',
	    \ ]

	let g:startify_custom_header = [
            \ '    "And Lo, for the Earth was empty of Form, and void.  ',
            \ '     And Darkness was all over the Face of the Deep.     ',
            \ '       And We said: ''Look at that fucker Dance.''"      ',
            \ '                                                         ',
            \ '           - David Foster Wallace, Infinite Jest         ',
            \ '',
            \ ]

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" DragVisuals Customization:
    " Drag Visuals - Created By Damian Conway Customization:
    " vmap  <expr>  <LEFT>   DVB_Drag('left')
    " vmap  <expr>  <RIGHT>  DVB_Drag('right')
    " vmap  <expr>  <DOWN>   DVB_Drag('down')
    " vmap  <expr>  <UP>     DVB_Drag('up')
    " vmap  <expr>  D        DVB_Duplicate()

    " Remove any introduced trailing whitespace after moving...
    " let g:DVB_TrimWS = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Syntastic Customization:
    set statusline+=%#warningmsg#
    set statusline+=%{SyntasticStatuslineFlag()}
    set statusline+=%*

    let g:syntastic_always_populate_loc_list = 1
    let g:syntastic_auto_loc_list = 1
    let g:syntastic_check_on_open = 1
    let g:syntastic_check_on_wq = 0

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                            "Non-Plugin Customization"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

syntax on

set number                 " line numbers
set history=500		   " keep 500 lines of command line history
set noruler		   " hide the cursor position all the time
set showcmd		   " display incomplete commands
set incsearch		   " do incremental searching
set hlsearch               " search highlighting on.

set backspace=indent,eol,start    " allow backspacing over everything in insert

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                 " LEARN VIM THE HARD WAY - PLAYGROUND "

" ~~~~~~~~~~~~~~~~~~~~~~~~~~ Normal Mode Mappings ~~~~~~~~~~~~~~~~~~~~~~~~~~~ "

" Assign <space> to center the screen on cursor.
nnoremap <space> zz

" Center the screen on the search next/previous
nnoremap n nzz
nnoremap N Nzz

" H moves to the beginning of a line, L moves to the end.
nnoremap H ^
nnoremap L $

" - swaps current line with line below, _ does the reverse.
nnoremap <Leader>- ddp
nnoremap <Leader>_ ddkkp

" Convert current word to uppercase with <Leader>\
nnoremap <leader>\ viwU


" Easily edit vimrc from inside any other file
nnoremap <leader>ev :vsplit $MYVIMRC<cr>

" 'Source' my Vimrc file to apply any new changes made to Vimrc
" Note: Not currently working? Also, messes with Airline... just wq and reopen
nnoremap <leader>sv :source $MYVIMRC<cr>


" ~~~~~~~~~~~~~~~~~~~~~~~~~~ Insert Mode Mappings ~~~~~~~~~~~~~~~~~~~~~~~~~~~ "

" In insert mode, CTRL-d deletes a line.
inoremap <leader><c-d> <esc>ddi

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>


" ~~~~~~~~~~~~~~~~~~~~~~~~ Operator Pending Mappings ~~~~~~~~~~~~~~~~~~~~~~~ "

" Edit around/inside next/previous (, {, or [
onoremap in( :<c-u>normal! f(vi(<cr>
onoremap il( :<c-u>normal! F)vi(<cr>
onoremap an( :<c-u>normal! f(bvt(<cr>
onoremap al( :<c-u>normal! F(bvt(<cr>
onoremap in{ :<c-u>normal! f{vi{<cr>
onoremap il{ :<c-u>normal! F)vi{<cr>
onoremap an{ :<c-u>normal! f{bvt{<cr>
onoremap al{ :<c-u>normal! F{bvt{<cr>
onoremap in[ :<c-u>normal! f[vi[<cr>
onoremap il[ :<c-u>normal! F)vi[<cr>
onoremap an[ :<c-u>normal! f[bvt[<cr>
onoremap al[ :<c-u>normal! F[bvt[<cr>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                               " Abbreviations "

iabbrev adn and
iabbrev waht what
iabbrev teh the
iabbrev @@ david.riott1@gmail.com
iabbrev ccopy Copyright 2016 David Riott, all rights reserved.


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                               " Auto-Commands "
" Html file settings ------------- {{{
augroup filetype_html
    autocmd!

        " Auto-indent html files on creation, read, and pre-write.
        autocmd BufWritePre,BufRead,BufNewFile *.html :normal gg=G

        " When editing html files, set nowrap
        autocmd BufNewFile,BufRead *.html setlocal nowrap

    augroup END
" }}}

" Vimscript file settings ------------ {{{
augroup filetype_vim
    autocmd!
        autocmd FileType vim setlocal foldmethod=marker
    augroup END
" }}}

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Method Folding
" Open a fold & close a fold: za
" Foldlevel tells vim which level of indents to show, where 0 is
" unindented lines, and 1 is both unindented and singlely indented, etc.
set foldlevel=3
set foldmethod=indent      " sets method folding on.


" Codebase that uses 4 space characters for each indent
set tabstop=8              " size of a hard tabstop
set softtabstop=0          " comination of spaces and tabs are used to simulate tab stops at a width
set expandtab              " always uses spaces insead of tab characters
set shiftwidth=4           " size of an 'indent'
set smarttab               " make 'tab' insert indents indead of tabs at the beginning of a line

" Codebase that uses a single tab character that appears 4-spaces-wide
" set tabstop=4 softtabstop=0 noexpandtab shiftwidth=4


" Damian Conway:  Guide Highlight in magenta the 81st column
highlight ColorColumn ctermbg=magenta
call matchadd('ColorColumn', '\%81v', 100)

" Damian Conway: Releases 'last search pattern' register by hitting return
nnoremap <CR> :noh<CR><CR>


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
                    " New Stuff Not Yet Worked Out "

" This gives autocompletion with Java
" ctags -f ~/.tags -R ~/myprojects/src $JAVA_HOME/src

" Allows you to complete any class, method, or field name
" with [Ctrl]N while in insert mode
" set complete=.,w,b,u,t,

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


if has("vms")
  set nobackup		   " do not keep a backup file, use versions instead
else
  set backup	           " keep a backup file
endif


" Enable the mouse... for the faint-hearted
" if has('mouse')
 "  set mouse=a
" endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
" if &t_Co > 2 || has("gui_running")
  " syntax on
  " set hlsearch
" endif

" Only when compiled with support for autocommands.
if has("autocmd")
    " Put these in an autocmd group, so that we can delete them easily.
    augroup vimrcEx
    au!

    " For all text files set 'textwidth' to 80 characters.
    autocmd FileType text setlocal textwidth=80

    " When editing a file, always jump to the last known cursor position.
    " Don't do it when the position is invalid or when inside an event handler
    " (happens when dropping a file on gvim).
    " Also don't do it when the mark is in the first line, that is the default
    " position when opening a file.
    autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
    augroup END
else
    set autoindent		" always set autoindenting on
endif " has("autocmd")

" Command to see dif btwn current buffer & file loaded from, thus: changes made
if !exists(":DiffOrig") " Only define it when not defined already.
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

"************************* End Vimrc ****************************
