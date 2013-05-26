setlocal buftype=acwrite
setlocal bufhidden=wipe

if exists('b:search_term')
  exe 'silent file InteractiveGrep\ ('.escape(b:search_term, ' ').')'
else
  exe 'silent file InteractiveGrep'
endif

command! -buffer -nargs=+ Rerun call igrep#Rerun()

augroup igrep
  autocmd!

  autocmd BufWriteCmd <buffer> call igrep#Update()
augroup END
