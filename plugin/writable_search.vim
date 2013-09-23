if exists('g:loaded_writable_search') || &cp
  finish
endif

let g:loaded_writable_search = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

if !exists('g:writable_search_command_type')
  let g:writable_search_command_type = 'egrep'
endif

if !exists('g:writable_search_new_buffer_command')
  let g:writable_search_new_buffer_command = 'tabnew'
endif

if !exists('g:writable_search_confirm_file_rename')
  let g:writable_search_confirm_file_rename = 1
endif

if !exists('g:writable_search_confirm_directory_creation')
  let g:writable_search_confirm_directory_creation = 1
endif

if !exists('g:writable_search_context_lines')
  let g:writable_search_context_lines = 3
endif

command! -nargs=* WritableSearch call writable_search#Start(<q-args>)

let &cpo = s:keepcpo
unlet s:keepcpo
