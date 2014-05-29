setlocal buftype=acwrite
setlocal bufhidden=wipe
setlocal autoindent

if exists('b:command')
  let command_string = b:command.String()
  exe 'silent file WritableSearch:\ '.fnameescape(command_string)
else
  exe 'silent file WritableSearch'
endif

command! -buffer -nargs=* Rerun call writable_search#Rerun(<q-args>)

augroup writable_search
  autocmd!

  autocmd BufWriteCmd <buffer> call writable_search#Update()
augroup END

nnoremap <buffer> <c-w>f :silent call <SID>OpenSource()<cr>
function! s:OpenSource()
  let proxy = writable_search#ProxyUnderCursor()
  exe 'split '.proxy.filename

  " jump to middle of match
  exe ((proxy.end_line + proxy.start_line) / 2)
  normal! zz

  silent! normal! zO
endfunction
