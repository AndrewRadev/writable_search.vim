setlocal buftype=acwrite
setlocal bufhidden=delete
setlocal autoindent

if exists('b:command')
  let command_string = b:command.String()
  exe 'silent file WritableSearch:\ '.fnameescape(command_string)
else
  silent file WritableSearch
endif

autocmd BufWriteCmd <buffer> call writable_search#Update()

if g:writable_search_result_buffer_utilities
  command! -buffer -nargs=* Rerun call writable_search#Rerun(<q-args>)
  nnoremap <buffer> <c-w>f :silent call writable_search#ftplugin#OpenSource('split')<cr>
endif
