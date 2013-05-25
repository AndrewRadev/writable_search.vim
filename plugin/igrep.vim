if exists('g:loaded_igrep') || &cp
  finish
endif

let g:loaded_igrep = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

command! -nargs=* InteractiveGrep call s:InteractiveGrep(<q-args>)
function! s:InteractiveGrep(...)
  if a:0 > 0
    new
    exe 'r!ack '.shellescape(a:1).' -H --nogroup -C3'
    0delete _
  endif

  let grouped_lines = s:PartitionLines(getbufline('%', 1, '$'))
  let grep_results = s:ProcessLines(grouped_lines)

  %delete _

  for grep_result in grep_results
    let banner = grep_result.filename . ':' . grep_result.start_line . '-' . grep_result.end_line

    call append(line('$'), grep_result.lines)
    call append(line('$'), '--')
    call append(line('$'), banner)
    call append(line('$'), '--')
  endfor

  0delete _
  set nomodified
  set filetype=igrep
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

function! s:NewGrepResult()
  return {
        \ 'filename':   '',
        \ 'lines':      [],
        \ 'start_line': -1,
        \ 'end_line':   -1,
        \ }
endfunction

function! s:ProcessLines(grouped_lines)
  let results = []

  for lines in a:grouped_lines
    let current_grep_result          = s:NewGrepResult()
    let current_grep_result.filename = s:FindFilename(lines)
    let line_numbers                 = []

    for line in lines
      " slice off the filename:
      let line = line[len(current_grep_result.filename) : len(line) - 1]

      let matched_line_pattern     = '\v^:(\d+):(.*)$'
      let non_matched_line_pattern = '\v^-(\d+)-(.*)$'

      if line =~ matched_line_pattern
        let [_match, line_number, body; _rest] = matchlist(line, matched_line_pattern)
      elseif line =~ non_matched_line_pattern
        let [_match, line_number, body; _rest] = matchlist(line, non_matched_line_pattern)
      else
        echoerr "Unexpected format of line: ".line
      endif

      " additional space used for editability
      call add(current_grep_result.lines, ' '.body)
      call add(line_numbers, line_number)
    endfor

    let current_grep_result.start_line = min(line_numbers)
    let current_grep_result.end_line   = max(line_numbers)

    call add(results, current_grep_result)
  endfor

  return results
endfunction

function! s:FindFilename(lines)
  let filename_pattern = '^.\{-}\ze:\d\+:.*'

  for line in a:lines
    if line =~ filename_pattern
      return matchstr(line, filename_pattern)
    endif
  endfor
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo
