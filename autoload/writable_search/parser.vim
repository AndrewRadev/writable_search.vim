function! writable_search#parser#Run()
  let lines = getbufline('%', 1, '$')
  let lines = s:FilterBlanks(lines)

  if empty(lines)
    return []
  endif

  let grouped_lines = s:PartitionLines(lines)
  return s:BuildProxies(grouped_lines)
endfunction

function! s:PartitionLines(lines)
  if empty(a:lines)
    return []
  endif

  let groups           = []
  let current_group    = []
  let current_filename = s:FindFilename([a:lines[0]])
  let last_lineno      = -1

  for line in a:lines
    if line =~ '^--$'
      " then we definitely have a new group
      call add(groups, current_group)
      let current_group = []

      let current_filename = ''
      let last_lineno = -1

      continue
    elseif current_filename != '' && current_filename != s:FindFilename([line])
      " then we're starting a new file, new group
      call add(groups, current_group)
      let current_group = []
    elseif last_lineno > 0 && abs(last_lineno - s:FindLineno(line)) > 1
      " then we have a line number jump, new group
      call add(groups, current_group)
      let current_group = []
    else
      " keep on parsing
    endif

    call add(current_group, line)

    let current_filename = s:FindFilename([line])
    let last_lineno      = s:FindLineno(line)
  endfor

  call add(groups, current_group)

  return groups
endfunction

function! s:FilterBlanks(lines)
  return filter(a:lines, 'v:val !~ "^\\s*$"')
endfunction

function! s:BuildProxies(grouped_lines)
  let proxies = []

  for lines in a:grouped_lines
    let current_proxy = writable_search#proxy#New(bufnr('%'))
    let raw_filename  = s:FindFilename(lines)

    if raw_filename == ''
      echoerr "Couldn't parse the filename from: \n".string(lines)
      return
    endif

    let current_proxy.filename = s:NormalizeFilename(raw_filename)
    let line_numbers           = []

    for line in lines
      " slice off the filename:
      let line = line[len(raw_filename) : len(line) - 1]

      let matched_line_pattern     = '\v^[-:](\d+):(.*)$'
      let non_matched_line_pattern = '\v^[-:](\d+)-(.*)$'

      if line =~ matched_line_pattern
        let [_match, line_number, body; _rest] = matchlist(line, matched_line_pattern)
      elseif line =~ non_matched_line_pattern
        let [_match, line_number, body; _rest] = matchlist(line, non_matched_line_pattern)
      else
        echoerr "Unexpected format of line: ".line
        return
      endif

      call add(current_proxy.lines, body)
      call add(line_numbers, line_number)
    endfor

    let current_proxy.start_line = min(line_numbers)
    let current_proxy.end_line   = max(line_numbers)

    call add(proxies, current_proxy)
  endfor

  return proxies
endfunction

function! s:FindFilename(lines)
  let filename_pattern = '^.\{-}\ze[:-]\d\+[:-].*'

  for line in a:lines
    if line =~ filename_pattern
      return matchstr(line, filename_pattern)
    endif
  endfor

  return ''
endfunction

function! s:FindLineno(line)
  let lineno_pattern = '^.\{-}[:-]\zs\d\+\ze[:-].*'

  if a:line =~ lineno_pattern
    return str2nr(matchstr(a:line, lineno_pattern))
  else
    return -1
  endif
endfunction

function! s:NormalizeFilename(filename)
  return fnamemodify(a:filename, ':~:.')
endfunction
