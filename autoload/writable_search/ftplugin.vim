function! writable_search#ftplugin#OpenSource(command)
  let proxy = writable_search#ProxyUnderCursor()
  exe a:command.' '.proxy.filename

  " jump to middle of match
  exe ((proxy.end_line + proxy.start_line) / 2)
  normal! zz

  silent! normal! zO
endfunction
