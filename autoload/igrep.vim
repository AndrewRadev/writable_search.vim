function! igrep#Start(...)
  if a:0 > 0
    if expand('%') != ''
      " TODO (2013-05-26) customizable "new" command
      new
    endif

    call s:Grep(a:1)
    let @/ = a:1
  endif

  let b:proxies = igrep#parser#Run()

  call igrep#Render()

  set nomodified
  set filetype=igrep
endfunction

function! igrep#Rerun(...)
  if a:0 > 0
    let b:rerun_args = a:1

    %delete _
    exe b:command.' '.a:1
    0delete _
  endif

  call igrep#Start()
endfunction

function! igrep#Update()
  try
    call igrep#cursor#Push()
    normal! gg

    let header_pattern   = '^\S.*$'
    let last_proxy_index = 0
    let proxy_updates    = []

    " Zip up proxies and their new line ranges
    let header_lineno = search(header_pattern, 'Wc')
    while header_lineno > 0
      let header_line          = getline(header_lineno)
      let previous_end_lineno  = header_lineno - 1
      let current_start_lineno = header_lineno + 1

      if len(b:proxies) <= last_proxy_index
        echoerr "Number of patches doesn't add up"
      endif

      if len(proxy_updates) > 0
        let proxy_updates[-1].local_end = previous_end_lineno
      endif

      let [_, filename, start_line, end_line; rest] = matchlist(header_line, '\v^(.*):(\d+)-(\d+)')

      call add(proxy_updates, {
            \ 'proxy':       b:proxies[last_proxy_index],
            \ 'local_start': current_start_lineno,
            \ 'local_end':   -1,
            \ 'filename':    filename,
            \ 'start_line':  str2nr(start_line),
            \ 'end_line':    str2nr(end_line),
            \ })
      let last_proxy_index += 1

      " Jump to the next line for the next search
      exe current_start_lineno
      let header_lineno = search(header_pattern, 'Wc')
    endwhile

    " Update last proxy
    if len(proxy_updates) > 0
      let proxy_updates[-1].local_end = line('$')
    endif

    " Validate that we've got all the proxies and their new lines
    if len(proxy_updates) != len(b:proxies)
      echoerr "Number of patches doesn't add up"
    endif

    for proxy_update in proxy_updates
      if proxy_update.local_end < 0
        echoerr "Error parsing update"
      endif
    endfor

    " Perform actual update
    for proxy_update in proxy_updates
      let proxy = proxy_update.proxy

      " collect new lines, removing first whitespace char from view
      let new_lines = []
      for line in getbufline('%', proxy_update.local_start, proxy_update.local_end)
        call add(new_lines, line[1:])
      endfor

      " TODO (2013-05-26) adjustment should be != 0 only for results in the
      " same file.
      call proxy.UpdateSource(new_lines, 0)

      let proxy.start_line = proxy_update.start_line
      let proxy.end_line   = proxy_update.end_line
    endfor

    setlocal nomodified
  finally
    call igrep#cursor#Pop()
  endtry
endfunction

function! igrep#Render()
  %delete _
  for proxy in b:proxies
    call proxy.Render()
  endfor
  0delete _
endfunction

function! igrep#ProxyUnderCursor()
  let cursor_lineno    = line('.')
  let header_pattern   = '^\S.*$'
  let last_proxy_index = -1

  call igrep#cursor#Push()
  exe 1

  let header_lineno = search(header_pattern, 'Wc')
  while header_lineno > 0 && header_lineno < cursor_lineno
    if len(b:proxies) <= last_proxy_index
      echoerr "Number of patches doesn't add up"
    endif

    let last_proxy_index += 1
    exe (header_lineno + 1)
    let header_lineno = search(header_pattern, 'Wc')
  endwhile

  call igrep#cursor#Pop()

  return b:proxies[last_proxy_index]
endfunction

" TODO (2013-05-26) customizable "ack" command
function! s:Grep(query)
  let b:command = 'r!ack '.shellescape(a:query).' -H --nogroup -C3'

  %delete _
  exe b:command
  0delete _
endfunction
