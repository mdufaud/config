" ==============================================================================
" Vim Vundle
" ==============================================================================

if isdirectory(expand('~/.vim/bundle/Vundle.vim'))
  set nocompatible              " be iMproved, required
  filetype off                  " required

  " set the runtime path to include Vundle and initialize
  set rtp+=~/.vim/bundle/Vundle.vim
  call vundle#begin()
  " alternatively, pass a path where Vundle should install plugins
  "call vundle#begin('~/some/path/here')

  " let Vundle manage Vundle, required
  Plugin 'VundleVim/Vundle.vim'

  " The following are examples of different formats supported.
  " Keep Plugin commands between vundle#begin/end.
  " plugin on GitHub repo
  " Plugin 'tpope/vim-fugitive'
  " plugin from http://vim-scripts.org/vim/scripts.html
  " Plugin 'L9'
  " Git plugin not hosted on GitHub
  " Plugin 'git://git.wincent.com/command-t.git'
  " git repos on your local machine (i.e. when working on your own plugin)
  " Plugin 'file:///home/gmarik/path/to/plugin'
  " The sparkup vim script is in a subdirectory of this repo called vim.
  " Pass the path to set the runtimepath properly.
  " Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
  " Install L9 and avoid a Naming conflict if you've already installed a
  " different version somewhere else.
  " Plugin 'ascenator/L9', {'name': 'newL9'}

  " Command for tag list :Tlist
  Plugin 'vim-scripts/taglist.vim'
  " In visual: -> % for match
  Plugin 'adelarsq/vim-matchit'
  " Better navigation
  Plugin 'preservim/nerdtree'
  " In visual: comment \cc && uncomment \cu
  Plugin 'preservim/nerdcommenter'
  Plugin 'itchyny/lightline.vim'
  " Need: ack-grep
  Plugin 'mileszs/ack.vim'
  Plugin 'sheerun/vim-polyglot'
  " --------------------------------------------
  " Need: yarn, nodejs, npm (+ $>npm install)
  "Plugin 'neoclide/coc.nvim'
  "Plugin 'davidhalter/jedi-vim'
  " --------------------------------------------
  Plugin 'terryma/vim-multiple-cursors'

  " All of your Plugins must be added before the following line
  call vundle#end()            " required
  filetype plugin indent on    " required

endif

" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" ==============================================================================
" Vim configuration
" ==============================================================================

"
" Most basic
"

" Mouse usable
set mouse=a
" Colors
syntax on
" Line numbers
set nu
" Highlight searches
set hlsearch
let g:python_highlight_all = 1

"
" Tabs behavior
"

set tabstop=4 shiftwidth=4 softtabstop=4 expandtab
" Turn off expandtab only for makefile
autocmd FileType make setlocal noexpandtab
autocmd FileType python set tabstop=4|set shiftwidth=4|set expandtab

"
" Gui
"

set guioptions-=T " Removes top toolbar
set guioptions-=r " Removes right hand scroll bar
set go-=L " Removes left hand scroll bar
autocmd User Rails let b:surround_{char2nr('-')} = "<% \r %>" " displays <% %> correctly
:set cpoptions+=$ " puts a $ marker for the end of words/lines in cw/c$ commands
hi MatchParen cterm=underline ctermbg=none ctermfg=none
if has("multi_byte")
    if &termencoding == ""
        let &termencoding = &encoding
    endif
    set encoding=utf-8
    setglobal fileencoding=utf-8
    "setglobal bomb
    set fileencodings=ucs-bom,utf-8,latin1
endif

"
" Behavior
"

" Highlight > 80 char
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%81v.\+/

" Cursor
" -> block visual
au InsertEnter * silent execute "!echo -en \<esc>[5 q"
" -> bar insert
au InsertLeave * silent execute "!echo -en \<esc>[2 q"

"
" New commands
"

" :'<,'>SuperRetab 2 (2 space indent)
:command! -nargs=1 -range SuperRetab <line1>,<line2>s/\v%(^ *)@<= {<args>}/\t/g

"
" Mappings
"

" Copy pasta
map <F7> "+y
map <S-F7> "+d
map <F5> :set paste<CR>
map <S-F5> :set nopaste<CR>

" Tabs in
vmap <Tab> >>
nnoremap <Tab> >>
" Tabs out
vmap <S-Tab> <<
nnoremap <S-Tab> <<
inoremap <S-Tab> <C-d>

" Sweetness
colorscheme desert
set guifont=Monospace\ 10

"
" File auto command
"

"autocmd bufnewfile *.c so ${HOME}/Templates/c_header.txt
"autocmd bufnewfile *.cpp so ${HOME}/Templates/c_header.txt
"autocmd bufnewfile *.h so ${HOME}/Templates/c_header.txt
"autocmd bufnewfile *.hpp so ${HOME}/Templates/c_header.txt
"autocmd bufnewfile *.c exe "1," . 10 . "g/filename/s//" .expand("%")
"autocmd bufnewfile *.cpp exe "1," . 10 . "g/filename/s//" .expand("%")
"autocmd bufnewfile *.h exe "1," . 10 . "g/filename/s//" .expand("%")
"autocmd bufnewfile *.hpp exe "1," . 10 . "g/filename/s//" .expand("%")
"autocmd bufnewfile *.py so ${HOME}/Templates/py_header.txt

"
" Better command completion
"

set wildmenu
set wildmode=list:longest

" Show current line

set cursorline

"
" Indent
"

"set smartindent
"au! FileType python setl nosmartindent
"set autoindent

" =============================================================================
" Multicursor
" =============================================================================

if &rtp =~ 'vim-multiple-cursors'
    let g:multi_cursor_use_default_mapping=0

    " Default mapping
    let g:multi_cursor_start_word_key      = '<C-n>'
    let g:multi_cursor_select_all_word_key = '<A-n>'
    let g:multi_cursor_start_key           = 'g<C-n>'
    let g:multi_cursor_select_all_key      = 'g<A-n>'
    let g:multi_cursor_next_key            = '<C-n>'
    let g:multi_cursor_prev_key            = '<C-p>'
    let g:multi_cursor_skip_key            = '<C-x>'
    let g:multi_cursor_quit_key            = '<Esc>'
endif

" =============================================================================
" LightLine
" =============================================================================

set laststatus=2

if &rtp =~ 'lightline.vim'
    let g:lightline = {
          \ 'colorscheme': 'wombat',
          \ 'active': {
          \   'left': [['mode', 'paste'],['readonly', 'filename', 'modified']]
          \ },
    \ } 
    if !has('gui_running')
        set t_Co=256
    endif
endif

" =============================================================================
" Nerdtree
" =============================================================================

"Open up nerdtree with :NERDTree
"Open your first file with or o
"Open second file in horizontal split pane with i/s
"Open third file in tab with t

if &rtp =~ 'nerdtree'
    map <C-t> :NERDTreeToggle<CR>
    map <C-f> :NERDTreeFocus<CR>
endif

" =============================================================================
" Nerdcommenter
" =============================================================================

" <leader> == '\'

"[count]<leader>cc |NERDCommenterComment|
"Comment out the current line or text selected in visual mode.

"[count]<leader>cn |NERDCommenterNested|
"Same as cc but forces nesting.

"[count]<leader>c<space> |NERDCommenterToggle|
"Toggles the comment state of the selected line(s). If the topmost selected line is commented, all selected lines are uncommented and vice versa.

"[count]<leader>cm |NERDCommenterMinimal|
"Comments the given lines using only one set of multipart delimiters.

"[count]<leader>ci |NERDCommenterInvert|
"Toggles the comment state of the selected line(s) individually.

"[count]<leader>cs |NERDCommenterSexy|
"Comments out the selected lines with a pretty block formatted layout.

"[count]<leader>cy |NERDCommenterYank|
"Same as cc except that the commented line(s) are yanked first.

"<leader>c$ |NERDCommenterToEOL|
"Comments the current line from the cursor to the end of line.

"<leader>cA |NERDCommenterAppend|
"Adds comment delimiters to the end of line and goes into insert mode between them.

"|NERDCommenterInsert|
"Adds comment delimiters at the current cursor position and inserts between. Disabled by default.

"<leader>ca |NERDCommenterAltDelims|
"Switches to the alternative set of delimiters.

"[count]<leader>cl |NERDCommenterAlignLeft [count]<leader>cb |NERDCommenterAlignBoth
"Same as |NERDCommenterComment| except that the delimiters are aligned down the left side (<leader>cl) or both sides (<leader>cb).

"[count]<leader>cu |NERDCommenterUncomment|
"Uncomments the selected line(s).

if &rtp =~ 'nerdcommenter'
    " Add spaces after comment delimiters by default
    let g:NERDSpaceDelims = 1

    " Use compact syntax for prettified multi-line comments
    let g:NERDCompactSexyComs = 1

    " Align line-wise comment delimiters flush left instead of following code indentation
    let g:NERDDefaultAlign = 'left'

    " Set a language to use its alternate delimiters by default
    let g:NERDAltDelims_java = 1

    " Add your own custom formats or override the defaults
    let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

    " Allow commenting and inverting empty lines (useful when commenting a region)
    let g:NERDCommentEmptyLines = 1

    " Enable trimming of trailing whitespace when uncommenting
    let g:NERDTrimTrailingWhitespace = 1

    " Enable NERDCommenterToggle to check all selected lines is commented or not 
    let g:NERDToggleCheckAllLines = 1
endif

" =============================================================================
" Coc
" =============================================================================

if &rtp =~ 'coc.nvim'
    " TextEdit might fail if hidden is not set.
    set hidden

    " Some servers have issues with backup files, see #649.
    set nobackup
    set nowritebackup

    " Give more space for displaying messages.
    set cmdheight=2

    " Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
    " delays and poor user experience.
    set updatetime=300

    " Don't pass messages to |ins-completion-menu|.
    set shortmess+=c

    " Always show the signcolumn, otherwise it would shift the text each time
    " diagnostics appear/become resolved.
    if has("patch-8.1.1564")
      " Recently vim can merge signcolumn and number column into one
        set signcolumn=number
    else
        set signcolumn=yes
    endif

    " Use tab for trigger completion with characters ahead and navigate.
    " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
    " other plugin before putting this into your config.
    inoremap <silent><expr> <TAB>
          \ pumvisible() ? "\<C-n>" :
          \ <SID>check_back_space() ? "\<TAB>" :
          \ coc#refresh()
    inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

    function! s:check_back_space() abort
      let col = col('.') - 1
      return !col || getline('.')[col - 1]  =~# '\s'
    endfunction

    " Use <c-space> to trigger completion.
    inoremap <silent><expr> <c-space> coc#refresh()

    " Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
    " position. Coc only does snippet and additional edit on confirm.
    " <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
    if exists('*complete_info')
      inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
    else
      inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
    endif

    " Use `[g` and `]g` to navigate diagnostics
    " Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
    nmap <silent> [g <Plug>(coc-diagnostic-prev)
    nmap <silent> ]g <Plug>(coc-diagnostic-next)

    " GoTo code navigation.
    nmap <silent> gd <Plug>(coc-definition)
    nmap <silent> gy <Plug>(coc-type-definition)
    nmap <silent> gi <Plug>(coc-implementation)
    nmap <silent> gr <Plug>(coc-references)

    " Use K to show documentation in preview window.
    nnoremap <silent> K :call <SID>show_documentation()<CR>

    function! s:show_documentation()
      if (index(['vim','help'], &filetype) >= 0)
        execute 'h '.expand('<cword>')
      else
        call CocAction('doHover')
      endif
    endfunction

    " Highlight the symbol and its references when holding the cursor.
    autocmd CursorHold * silent call CocActionAsync('highlight')

    " Symbol renaming.
    nmap <leader>rn <Plug>(coc-rename)

    " Formatting selected code.
    xmap <leader>f  <Plug>(coc-format-selected)
    nmap <leader>f  <Plug>(coc-format-selected)

    augroup mygroup
      autocmd!
      " Setup formatexpr specified filetype(s).
      autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
      " Update signature help on jump placeholder.
      autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
    augroup end

    " Applying codeAction to the selected region.
    " Example: `<leader>aap` for current paragraph
    xmap <leader>a  <Plug>(coc-codeaction-selected)
    nmap <leader>a  <Plug>(coc-codeaction-selected)

    " Remap keys for applying codeAction to the current buffer.
    nmap <leader>ac  <Plug>(coc-codeaction)
    " Apply AutoFix to problem on the current line.
    nmap <leader>qf  <Plug>(coc-fix-current)

    " Map function and class text objects
    " NOTE: Requires 'textDocument.documentSymbol' support from the language server.
    xmap if <Plug>(coc-funcobj-i)
    omap if <Plug>(coc-funcobj-i)
    xmap af <Plug>(coc-funcobj-a)
    omap af <Plug>(coc-funcobj-a)
    xmap ic <Plug>(coc-classobj-i)
    omap ic <Plug>(coc-classobj-i)
    xmap ac <Plug>(coc-classobj-a)
    omap ac <Plug>(coc-classobj-a)

    " Use CTRL-S for selections ranges.
    " Requires 'textDocument/selectionRange' support of LS, ex: coc-tsserver
    nmap <silent> <C-s> <Plug>(coc-range-select)
    xmap <silent> <C-s> <Plug>(coc-range-select)



    " Add `:Format` command to format current buffer.
    command! -nargs=0 Format :call CocAction('format')

    " Add `:Fold` command to fold current buffer.
    command! -nargs=? Fold :call     CocAction('fold', <f-args>)

    " Add `:OR` command for organize imports of the current buffer.
    command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

    " Add (Neo)Vim's native statusline support.
    " NOTE: Please see `:h coc-status` for integrations with external plugins that
    " provide custom statusline: lightline.vim, vim-airline.
    set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

    " Mappings for CoCList
    " Show all diagnostics.
    nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>
    " Manage extensions.
    nnoremap <silent><nowait> <space>e  :<C-u>CocList extensions<cr>
    " Show commands.
    nnoremap <silent><nowait> <space>c  :<C-u>CocList commands<cr>
    " Find symbol of current document.
    nnoremap <silent><nowait> <space>o  :<C-u>CocList outline<cr>
    " Search workspace symbols.
    nnoremap <silent><nowait> <space>s  :<C-u>CocList -I symbols<cr>
    " Do default action for next item.
    nnoremap <silent><nowait> <space>j  :<C-u>CocNext<CR>
    " Do default action for previous item.
    nnoremap <silent><nowait> <space>k  :<C-u>CocPrev<CR>
    " Resume latest coc list.
    nnoremap <silent><nowait> <space>p  :<C-u>CocListResume<CR>
endif

hi Identifier ctermfg=darkgreen cterm=none guifg=lightgreen
hi pythonClassVar  term=bold ctermfg=yellow guifg=yellow2
