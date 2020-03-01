syntax match nvpmwksp  '^\s*workspace\s*'
syntax match nvpmtabs  '^\s*tab\s*'
syntax match nvpmbuff  '^\s*buff\s*'
syntax match nvpmterm  '^\s*term\s*'

syntax match nvpmdwksp '^\s*\*\s*workspace\s*\(.*\)'
syntax match nvpmdtabs '^\s*\*\s*tab\s*\(.*\)'
syntax match nvpmdbuff '^\s*\*\s*buff\s*\(.*\)'
syntax match nvpmdterm '^\s*\*\s*term\s*\(.*\)'

syntax match nvpmpoint '\s*:\s*'
syntax match nvpmpath  '\s*:\s*\(\/*\w*\s*\w*\)*\/*\w*\.*\w*\s*$'

hi default link nvpmwksp  Include
hi default link nvpmtabs  Include
hi default link nvpmbuff  Include
hi default link nvpmterm  Include

hi default link nvpmdwksp Comment
hi default link nvpmdtabs Comment
hi default link nvpmdbuff Comment
hi default link nvpmdterm Comment

hi default link nvpmpoint Operator
hi default link nvpmpath  Operator

let b:current_syntax = "nvpm"
