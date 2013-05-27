setlocal buftype=acwrite
setlocal bufhidden=wipe

if exists('b:command')
  let shell_command = b:command[2:] " strip off the initial r!

  if exists('b:rerun_args')
    let shell_command .= ' '.b:rerun_args
  endif

  exe 'silent file InteractiveGrep:\ '.fnameescape(shell_command)
else
  exe 'silent file InteractiveGrep'
endif

command! -buffer -nargs=* Rerun call igrep#Rerun(<q-args>)

augroup igrep
  autocmd!

  autocmd BufWriteCmd <buffer> call igrep#Update()
augroup END

nnoremap <buffer> <c-w>f :silent call <SID>OpenSource()<cr>
function! s:OpenSource()
  let proxy = igrep#ProxyUnderCursor()
  exe 'split '.proxy.filename

  " jump to middle of match
  exe ((proxy.end_line + proxy.start_line) / 2)
  normal! zz

  silent! normal! zO
endfunction
