function! igrep#Start(...)
  if a:0 > 0
    " TODO (2013-05-26) customizable "new" command
    new
    call s:Grep(a:1)
  endif

  let b:proxies = igrep#parser#Run()

  %delete _
  for proxy in b:proxies
    call proxy.Render()
  endfor
  0delete _

  set nomodified
  set filetype=igrep
endfunction

function! igrep#Rerun(params)
  let b:command .= ' '.params

  %delete _
  exe b:command
  0delete _

  call igrep#Start()
endfunction

function! igrep#Update()
  try
    call igrep#cursor#Push()
    normal! gg

    let banner_pattern   = '^--\n^\S.*\n^--$'
    let last_proxy_index = 0
    let proxy_updates    = []

    " Zip up proxies and their new line ranges
    let banner_lineno = search(banner_pattern, 'Wc')
    while banner_lineno > 0
      let previous_end_lineno  = banner_lineno - 1
      let current_start_lineno = banner_lineno + 3

      if len(b:proxies) <= last_proxy_index
        echoerr "Number of patches doesn't add up"
      endif

      if len(proxy_updates) > 0
        let proxy_updates[-1].end = previous_end_lineno
      endif

      call add(proxy_updates, {
            \ 'proxy': b:proxies[last_proxy_index],
            \ 'start': current_start_lineno,
            \ 'end':   -1,
            \ })
      let last_proxy_index += 1

      " Jump to the next line for the next search
      exe current_start_lineno
      let banner_lineno = search(banner_pattern, 'Wc')
    endwhile

    " Update last proxy
    if len(proxy_updates) > 0
      let proxy_updates[-1].end = line('$')
    endif

    " Validate that we've got all the proxies and their new lines
    if len(proxy_updates) != len(b:proxies)
      echoerr "Number of patches doesn't add up"
    endif

    for proxy_update in proxy_updates
      if proxy_update.end < 0
        echoerr "Error parsing update"
      endif
    endfor

    " Perform actual update
    for proxy_update in proxy_updates
      let proxy = proxy_update.proxy

      " collect new lines, removing first whitespace char
      let new_lines = []
      for line in getbufline('%', proxy_update.start, proxy_update.end)
        call add(new_lines, line[1:])
      endfor

      " TODO (2013-05-26) adjustment should be != 0 only for results in the
      " same file.
      call proxy.UpdateSource(new_lines, 0)
    endfor

    setlocal nomodified
  finally
    " call igrep#cursor#Pop()
  endtry
endfunction

" TODO (2013-05-26) customizable "ack" command
function! s:Grep(query)
  let b:search_term = a:query
  let b:command     = 'r!ack '.shellescape(a:query).' -H --nogroup -C3'

  %delete _
  exe b:command
  0delete _
endfunction
