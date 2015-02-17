" Use Vim settings, rather then Vi settings (much better!).
" This must be first, because it changes other options as a side effect.
set nocompatible

" show ruler
set ruler
set history=50
set showcmd
set incsearch
set background=dark
" tabstop
set ts=4
" shiftwidth
set sw=4
" expand tabs
set et
:if &term == 'xterm'
:  exe "set t_Sb=\e[4%dm"
:  exe "set t_Sf=\e[3%dm"
:  syntax on
:endif

"map <F5> I||'<Esc>ea'||<Esc>

" some abbreviations
:ab *b /************************************************
:ab *e ************************************************/
:ab #b #-----------------------------------------------
:ab #e #-----------------------------------------------
:set sw=4
:ab #d #define
:ab #i #include
:ab #f function
:ab #p procedure
:ab #r return
:ab #c create or replace

" modeline example -- removevim: ft=sql sw=4 ts=4 et:
