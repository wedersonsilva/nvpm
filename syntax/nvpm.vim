syntax match nvpmwksp  '^\s*workspace\s*'
syntax match nvpmtabs  '^\s*tab\s*'
syntax match nvpmbuff  '^\s*buff\s*'
syntax match nvpmterm  '^\s*term\s*'
syntax match nvpmdwksp '^\s*\*\s*workspace\s*\(.*\)'
syntax match nvpmdtabs '^\s*\*\s*tab\s*\(.*\)'
syntax match nvpmdbuff '^\s*\*\s*buff\s*\(.*\)'
syntax match nvpmdterm '^\s*\*\s*term\s*\(.*\)'
syntax match nvpmpoint '\s*:\s*'

hi default link nvpmwksp  IncSearch
hi default link nvpmtabs  IncSearch
hi default link nvpmbuff  IncSearch
hi default link nvpmterm  IncSearch
hi default link nvpmdwksp Comment
hi default link nvpmdtabs Comment
hi default link nvpmdbuff Comment
hi default link nvpmdterm Comment
hi default link nvpmpoint SpecialKey

let b:current_syntax = "nvpm"
