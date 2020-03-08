function! writable_search#file_parser#New()
  return {
        \ 'cache': {},
        \
        \ 'ParseLine':    function('writable_search#file_parser#ParseLine'),
        \ 'FindFilename': function('writable_search#file_parser#FindFilename'),
        \ }
endfunction

" TODO (2020-03-08) What if a file isn't readable? Good to remove it from the
" output and show some message...
"
function! writable_search#file_parser#ParseLine(line) dict
  let line = a:line
  let failure = ['', -1]

  for delimiter in ['-', ':']
    let parts = split(line, delimiter)
    if len(parts) < 3
      " we expect [filename, line_number, text], so less than 3 parts means
      " this is not a line we can parse, go on to the next delimiter
      continue
    endif

    let delimiter_index = 0

    while delimiter_index < len(parts) - 2
      let filename = join(parts[0:delimiter_index], delimiter)
      let line_number = parts[delimiter_index + 1]
      if line_number !~ '^\d\+$'
        " not a real number, so this isn't the right breakdown
        let delimiter_index += 1
        continue
      endif
      let text = join(parts[delimiter_index + 2:], delimiter)

      if !filereadable(filename)
        " not an existing file, not the right breakdown
        let delimiter_index += 1
        continue
      endif

      if !has_key(self.cache, filename)
        let file_lines = readfile(filename)
        let self.cache[filename] = {'lines': file_lines}
      endif

      let file_lines = self.cache[filename].lines

      if len(file_lines) < line_number
        " the file exists, but the lines don't match up
        let delimiter_index += 1
        continue
      endif

      if file_lines[line_number - 1] != text
        " the file exists, the line exists, but the text doesn't match
        let delimiter_index += 1
        continue
      endif

      return [filename, line_number]
    endwhile
  endfor

  return failure
endfunction

function! writable_search#file_parser#FindFilename(lines) dict
  for line in a:lines
    let [filename, _] = self.ParseLine(line)
    if filename != ''
      return filename
    endif
  endfor

  return ''
endfunction
