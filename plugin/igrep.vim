if exists('g:loaded_igrep') || &cp
  finish
endif

let g:loaded_igrep = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

command! -nargs=* InteractiveGrep call igrep#Start(<q-args>)

let &cpo = s:keepcpo
unlet s:keepcpo
