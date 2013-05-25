syn match igrepBannerDelimiter '^--$'
syn match igrepBanner '^\S.*$'

hi def link igrepBannerDelimiter Identifier
hi def link igrepBanner          Identifier
