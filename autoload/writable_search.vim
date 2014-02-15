function! writable_search#Start(query)
  if a:query != ''
    if expand('%') != '' && &filetype != 'writable_search'
      call s:NewBuffer()
    endif

    call s:Grep(a:query)
    let @/ = a:query
  endif

  let b:proxies = writable_search#parser#Run()

  if empty(b:proxies)
    echomsg "No results"
    return
  endif

  call writable_search#Render()

  set nomodified
  set filetype=writable_search
endfunction

function! writable_search#Rerun(...)
  if a:0 > 0
    let b:rerun_args = a:1

    %delete _
    exe b:command.' '.a:1
    0delete _
  endif

  call writable_search#Start('')
endfunction

function! writable_search#Update()
  try
    call writable_search#cursor#Push()
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
        return
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
      return
    endif

    for proxy_update in proxy_updates
      if proxy_update.local_end < 0
        echoerr "Error parsing update"
        return
      endif
    endfor

    " Keep a dictionary of changed line counts per filename
    let deltas = {}

    " Perform actual update
    for proxy_update in proxy_updates
      let proxy = proxy_update.proxy

      " collect new lines, removing first whitespace char from view
      let new_lines = []
      for line in getbufline('%', proxy_update.local_start, proxy_update.local_end)
        call add(new_lines, line[1:])
      endfor

      if !has_key(deltas, proxy.filename)
        let deltas[proxy.filename] = 0
      endif
      let deltas[proxy.filename] += proxy.UpdateSource(new_lines, deltas[proxy.filename])

      let proxy.start_line = proxy_update.start_line
      let proxy.end_line   = proxy_update.end_line

      if proxy_update.filename != proxy.filename
        if g:writable_search_confirm_file_rename
          if confirm(printf('Rename "%s" to "%s"?', proxy.filename, proxy_update.filename))
            call proxy.RenameFile(proxy_update.filename)
          endif
        else
          call proxy.RenameFile(proxy_update.filename)
        endif
      endif

      call proxy.UpdateLocal()
    endfor

    " Re-render to make changes visible
    call writable_search#Render()
    set nomodified
  finally
    call writable_search#cursor#Pop()
  endtry
endfunction

function! writable_search#Render()
  %delete _
  for proxy in b:proxies
    call proxy.Render()
  endfor
  0delete _
endfunction

function! writable_search#ProxyUnderCursor()
  let cursor_lineno    = line('.')
  let header_pattern   = '^\S.*$'
  let last_proxy_index = -1

  call writable_search#cursor#Push()
  exe 1

  let header_lineno = search(header_pattern, 'Wc')
  while header_lineno > 0 && header_lineno < cursor_lineno
    if len(b:proxies) <= last_proxy_index
      echoerr "Number of patches doesn't add up"
      return
    endif

    let last_proxy_index += 1
    exe (header_lineno + 1)
    let header_lineno = search(header_pattern, 'Wc')
  endwhile

  call writable_search#cursor#Pop()

  return b:proxies[last_proxy_index]
endfunction

function! s:NewBuffer()
  exe g:writable_search_new_buffer_command
endfunction

function! s:Grep(query)
  let egrep_command = 'r!egrep %s . -R -n -H %s'
  let ack_command   = 'r!ack %s --nogroup %s'
  let ag_command    = 'r!ag %s --nogroup %s'

  let escaped_query = shellescape(a:query)

  if g:writable_search_context_lines
    let flags = '-C'.g:writable_search_context_lines
  else
    let flags = ''
  endif

  if g:writable_search_command_type == 'egrep'
    let b:command = printf(egrep_command, escaped_query, flags)
  elseif g:writable_search_command_type == 'ack'
    let b:command = printf(ack_command, escaped_query, flags)
  elseif g:writable_search_command_type == 'ag'
    let b:command = printf(ag_command, escaped_query, flags)
  elseif g:writable_search_command_type == 'ack.vim'
    let ackprg = g:ackprg
    let ackprg = substitute(ackprg, '--column', '', '')

    let b:command = 'r!'.ackprg.' '.escaped_query.' --nogroup '.flags
  else
    echoerr "Unknown value for g:writable_search_command_type:  "
          \ .g:writable_search_command_type
          \ .". Needs to be one of 'egrep', 'ack', 'ack.vim'"
    return
  endif

  %delete _
  exe b:command
  0delete _
endfunction
