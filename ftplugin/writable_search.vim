setlocal buftype=acwrite
setlocal bufhidden=wipe
setlocal autoindent

if exists('b:command')
  let shell_command = b:command[2:] " strip off the initial r!

  if exists('b:rerun_args')
    let shell_command .= ' '.b:rerun_args
  endif

  exe 'silent file WritableSearch:\ '.fnameescape(shell_command)
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
