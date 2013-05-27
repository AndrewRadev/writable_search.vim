function! igrep#parser#Run()
  let grouped_lines = s:PartitionLines(getbufline('%', 1, '$'))
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

  return groups
endfunction

function! s:BuildProxies(grouped_lines)
  let proxies = []

  for lines in a:grouped_lines
    let current_proxy          = igrep#proxy#New(bufnr('%'))
    let current_proxy.filename = s:FindFilename(lines)
    let line_numbers           = []

    for line in lines
      " slice off the filename:
      let line = line[len(current_proxy.filename) : len(line) - 1]

      let matched_line_pattern     = '\v^:(\d+):(.*)$'
      let non_matched_line_pattern = '\v^-(\d+)-(.*)$'

      if line =~ matched_line_pattern
        let [_match, line_number, body; _rest] = matchlist(line, matched_line_pattern)
      elseif line =~ non_matched_line_pattern
        let [_match, line_number, body; _rest] = matchlist(line, non_matched_line_pattern)
      else
        echoerr "Unexpected format of line: ".line
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
