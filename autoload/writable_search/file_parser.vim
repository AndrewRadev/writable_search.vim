function! writable_search#file_parser#New()
  return {
        \ 'cache': {},
        \
        \ 'FindFilename': function('writable_search#file_parser#FindFilename'),
        \ }
endfunction

function! writable_search#file_parser#FindFilename(lines)
  let filename_pattern = '^.\{-}\ze[:-]\d\+[:-].*'

  for line in a:lines
    if line =~ filename_pattern
      return matchstr(line, filename_pattern)
    endif
  endfor

  return ''
endfunction
