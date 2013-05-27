if exists('g:loaded_writable_search') || &cp
  finish
endif

let g:loaded_writable_search = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

command! -nargs=* WritableSearch call writable_search#Start(<q-args>)

let &cpo = s:keepcpo
unlet s:keepcpo
