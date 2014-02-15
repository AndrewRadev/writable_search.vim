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
  let groups        = []
  let current_group = []

  for line in a:lines
    if line =~ '^--$'
      call add(groups, current_group)
      let current_group = []
    else
      call add(current_group, line)
    endif
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
    let current_proxy          = writable_search#proxy#New(bufnr('%'))
    let raw_filename           = s:FindFilename(lines)
    let current_proxy.filename = s:NormalizeFilename(raw_filename)
    let line_numbers           = []

    for line in lines
      " slice off the filename:
      let line = line[len(raw_filename) : len(line) - 1]

      let matched_line_pattern     = '\v^:(\d+):(.*)$'
      let non_matched_line_pattern = '\v^-(\d+)-(.*)$'

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
  let filename_pattern = '^.\{-}\ze:\d\+:.*'

  for line in a:lines
    if line =~ filename_pattern
      return matchstr(line, filename_pattern)
    endif
  endfor
endfunction

function! s:NormalizeFilename(filename)
  return fnamemodify(a:filename, ':~:.')
endfunction
