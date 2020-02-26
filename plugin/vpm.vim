if exists('g:vpm.loaded')
  echo 'VPM was already loaded. Closing...'
  finish
endif

" Variables  {

let g:vpm = {}

let g:vpm.temp = {} 
let g:vpm.save = {}
let g:vpm.edit = {}
let g:vpm.patt = {}
let g:vpm.line = {}

let g:vpm.data      = {}
let g:vpm.data.make = {}
let g:vpm.data.curr = {}

let g:vpm.dirs = {}
let g:vpm.dirs.vpm  = get( g:vpm , 'vpm'  , '.vpm'   )
let g:vpm.dirs.main = get( g:vpm , 'main' , '~/.vpm' )
let g:vpm.dirs.proj = 'proj'

let g:vpm.term      = {}


" }
" Functions  {

" g:vpm      {

function! g:vpm.init()                    "{

  let g:vpm.loaded    = 1

  call self.patt.init()
  call self.line.init()
  call self.data.init()
  call self.temp.init()
  call self.edit.init()
  call self.dirs.init()
  call self.term.init()

endfunction
"}
function! g:vpm.null()                    "{
  return ''
endfunction
"}
function! g:vpm.test()                    "{
endfunction
"}
function! g:vpm.deft()                    "{

  let root = self.dirs.path('root')

  let file = root . 'default'

  if filereadable(file)
    let project = readfile(file)[0]
    if Found(project)
      call self.data.load(project)
      if g:vpm.data.loaded
        echo "VPM: Loaded default project: " . project
        echo "Press any key to start!"
      endif
    endif
  endif

endfunction
"}
function! g:vpm.loop(s,t)                 "{

  if !g:vpm.data.loaded
    echo 'Load project first [:VPMLoadProject]'
    return -1
  endif

  call self.data.curr.loop(a:s,a:t[0])
  call self.data.curr.edit()

endfunction
"}

"}
" g:vpm.data {

" g:vpm.data.*    {

function! g:vpm.data.init()               "{
  let self.loaded = 0
  let self.last = 0
  let self.path = ''
  call self.curr.init()
endfunction
"}
function! g:vpm.data.show()               "{

  for wksp in self.proj
    echo 'w' wksp.name
    for tab in wksp.tabs
      echo 't  ' tab.name
      for buffer in tab.buff
        if has_key(buffer,'path')
          echo 'b    ' buffer.name buffer.path
        else
          echo 'c    ' buffer.name buffer.cmd
        endif
      endfor
    endfor
  endfor

endfunction
"}

" misc }
" g:vpm.data.load {

function! g:vpm.data.load(file)           "{

  " Variables                       {
  let workspaces = []
  let patt       = g:vpm.patt.wksp

  " Edit project files 
  let g:vpm.edit.mode = a:file == g:vpm.edit.path
  let path = g:vpm.edit.mode ? '' : g:vpm.dirs.path('proj')
  let path = resolve(expand(path.a:file))

  if !filereadable(path)
    echo "VPM: default project '".path."' is unreadable or missing"
    return -1
  endif
  "}
  " Look up in file                 {

  let file = readfile(path)
  if Found(file)

    let self.path  = path
    let self.file  = file

    for i in range(len(self.file))

      let line = self.file[i]
      let awkspmatch = matchlist(line,patt)

      if Found(awkspmatch)
        let workspace = self.wksp(awkspmatch,i)
        if workspace.enabled
          call add(workspaces,workspace)
        endif
      endif

    endfor
    let self.proj   = workspaces
    let self.loaded = Found(workspaces)

    " Make buffers and terminals
    call self.make.proj()
    " Update Last Position
    call self.curr.last()
    " Edit Current Buffer
    call self.curr.edit()
    " Show Top and Bottom Lines
    call g:vpm.line.show()

  endif
  "}

endfunction
" load }
function! g:vpm.data.wksp(match,index)    "{

  " Capture workspace meta-data                 {
  let i                = a:index
  let workspace        = {}
  let workspace.tabs   = []
  let workspace.enabled = trim(a:match[1]) == '*' ? 0 : 1
  let workspace.name   = trim(a:match[2])
  let workspace.line   = self.file[i]
  let workspace.last   = 0
  "}
  " Look for tabs until workspace               {
  for j in range(i+1,len(self.file)-1)
    " Line matching {
    let line = self.file[j]
    let awkspmatch = matchlist(line,g:vpm.patt.wksp)
    let atabmatch  = matchlist(line,g:vpm.patt.tabs)
    "}

    if Found(awkspmatch)
      break
    elseif Found(atabmatch)
      let tab = self.tabs(atabmatch,j)
      if tab.enabled
        call add(workspace.tabs,tab)
      endif
    endif

  endfor
  "}

  return workspace

endfunction
"}
function! g:vpm.data.tabs(match,index)    "{

  " Capture tab meta-data                 {

  let i           = a:index
  let tab         = {}
  let tab.buff    = []
  let tab.enabled = trim(a:match[1]) == '*' ? 0 : 1
  let tab.name    = trim(a:match[2])
  let tab.line    = self.file[i]
  let tab.last    = 0

  "}
  " Look for bufs until next tab          {
  for j in range(i+1,len(self.file)-1)
    " Line matching {
    let line = self.file[j]
    let atabmatch  = matchlist(line,g:vpm.patt.tabs)
    let abuffmatch = matchlist(line,g:vpm.patt.buff)
    let atermmatch = matchlist(line,g:vpm.patt.term)
    "}

    if Found(atabmatch)
      break
    elseif Found(abuffmatch)
      let buff = self.buff(abuffmatch,j)
      if buff.enabled
        call add(tab.buff,buff)
      endif
    elseif Found(atermmatch)
      let term = self.term(atermmatch,j)
      if term.enabled
        call add(tab.buff,term)
      endif
    endif

  endfor
  "}

  return tab

endfunction
"}
function! g:vpm.data.buff(match,index)    "{

  " Capture buff meta-data {

  let buff         = {}
  let buff.enabled = trim(a:match[1]) == '*' ? 0 : 1
  let buff.name    = trim(a:match[2])
  let buff.path    = resolve(expand(trim(a:match[3])))
  let buff.line    = self.file[a:index]
  let buff.last    = 0

  "}

  return buff

endfunction
"}
function! g:vpm.data.term(match,index)    "{

  " Capture term meta-data {

  let term         = {}
  let term.enabled = trim(a:match[1]) == '*' ? 0 : 1
  let term.name    = trim(a:match[2])
  let term.cmd     = trim(a:match[3])
  let term.line    = self.file[a:index]
  let term.last    = 0

  "}

  return term

endfunction
"}

" load }
" g:vpm.data.make {

function! g:vpm.data.make.proj()          "{

  let proj = g:vpm.data.proj
  let wlen = len(proj)
  let g:vpm.data.last %= wlen

  for w in range(wlen) "{
    let tabs = proj[w].tabs
    let tlen = len(tabs)

    let proj[w].last %= tlen

    for t in range(tlen) "{
      let buff = tabs[t].buff
      let blen = len(buff)

      let tabs[t].last %= blen

      for b in range(blen) "{
        let buffer = buff[b]

        if     has_key(buffer,'cmd')
          let path = self.term(buffer)
          let buffer.path = path
        elseif has_key(buffer,'path')
          call self.buff(buffer)
        endif

      endfor
      "}
    endfor
    "}
  endfor
  "}

endfunction
"}
function! g:vpm.data.make.buff(b)         "{
  exec 'badd ' . a:b.path
endfunction
"}
function! g:vpm.data.make.term(t)         "{

  let cmd = a:t.cmd

  if Found(cmd)
    exec 'edit term://.//'.cmd
  else
    exec 'buffer|terminal'
  endif

  return bufname('%')

endfunction
"}

" make }
" g:vpm.data.curr {

function! g:vpm.data.curr.init()          "{
  let self.w = 0
  let self.t = 0
  let self.b = 0
endfunction
"}
function! g:vpm.data.curr.edit()          "{
  exec ':edit ' . self.item('b').path
endfunction
"}
function! g:vpm.data.curr.leng(t)         "{
  return len(self.list(a:t))
endfunction
"}
function! g:vpm.data.curr.list(t)         "{

  if     a:t == 'w'
    return g:vpm.data.proj
  elseif a:t == 't'
    return self.list('w')[self.w].tabs
  elseif a:t == 'b'
    return self.list('t')[self.t].buff
  endif

endfunction
"}
function! g:vpm.data.curr.item(t)         "{

  if     a:t == 'w'
    return self.list('w')[self.w]
  elseif a:t == 't'
    return self.item('w').tabs[self.t]
  elseif a:t == 'b'
    return self.item('t').buff[self.b]
  endif

endfunction
"}
function! g:vpm.data.curr.loop(s,t)       "{

  if g:vpm.data.loaded "{

    if bufname('%') != self.item('b').path "{
      call self.edit()
    else
      let step = a:s
      let type = a:t
      let self[type] += step
      let self[type]  = self[type] % self.leng(type)

      if     type == 'b' "{
        let g:vpm.data.proj[self.w].tabs[self.t].last = self.b
      "}
      elseif type == 't' "{
        " Update new current tab position after cycling
        let g:vpm.data.proj[self.w].last = self.t
        " For the new tab, retrieve last buffer position
        let self.b = self.item('t').last
      "}
      elseif type == 'w' "{
        " Update new current Workspace position after cycling
        let g:vpm.data.last = self.w
        " Update tab and buf with last positions
        let self.t = self.item('w').last
        let self.b = self.item('t').last
      endif "}

    endif   "}

  " }
  else
    echo 'Load layout first!'
  endif

endfunction
"}
function! g:vpm.data.curr.last()          "{

  let self.t = self.item('w').last
  let self.b = self.item('t').last

endfunction
"}
function! g:vpm.data.curr.term()          "{

  if bufname('%') != g:vpm.term.buf
    exec ':buffer ' . self.item('b').path
  endif

endfunction
" focus }

" curr}

" data}
" g:vpm.line {

function! g:vpm.line.init() "{
  let self.visible = 0
  let enclosure   = {}
  let enclosure.s = {}
  let enclosure.u = {}
  let enclosure.s.w = {'l':'(','r':')'}
  let enclosure.u.w = {'l':' ','r':' '}
  let enclosure.s.t = {'l':'[','r':']'}
  let enclosure.u.t = {'l':' ','r':' '}
  let enclosure.s.b = enclosure.s.t
  let enclosure.u.b = enclosure.u.t
  let g:vpm.line.enclosure = get(g: , 'vpm_line_enclosure' , enclosure)
endfunction "}
function! g:vpm.line.tabs() "{
  let line  = ''
  let line .= '%#VPMW#'
  let line .= self.enclosure.s.w.l
  let line .= g:vpm.data.curr.item('w').name
  let line .= self.enclosure.s.w.r

  let currtab = g:vpm.data.curr.item('t')

  for tab in g:vpm.data.curr.list('t')
    if tab.name == currtab.name
      let line .= '%#VPMTabSel#'
      let line .= self.enclosure.s.t.l
      let line .= tab.name
      let line .= self.enclosure.s.t.r
    else
      let line .= '%#VPMTab#'
      let line .= self.enclosure.u.t.l
      let line .= tab.name
      let line .= self.enclosure.u.t.r
    endif
  endfor

  let line .= '%#VPMTabFill#'

  return line
endfunction
" }
function! g:vpm.line.buff() "{
  let line  = ''

  let currbuf = g:vpm.data.curr.item('b')

  for buf in g:vpm.data.curr.list('b')
    if buf.name == currbuf.name
      let line .= '%#VPMBufSel#'
      let line .= self.enclosure.s.b.l
      let line .= buf.name
      let line .= self.enclosure.s.b.r
    else
      let line .= '%#VPMBuf#'
      let line .= self.enclosure.u.b.l
      let line .= buf.name
      let line .= self.enclosure.u.b.r
    endif
  endfor

  let line .= '%#VPMbufFill#'

  return line
endfunction
" }
function! g:vpm.line.show() "{

  " NOTE: Don't put spaces!
  set tabline=%!g:vpm.line.tabs()
  set statusline=%!g:vpm.line.buff()

  let self.visible = 1

endfunction
" }
function! g:vpm.line.hide() "{

  set tabline=%!g:vpm.null()
  set statusline=%!g:vpm.null()

  let self.visible = 0

endfunction
" }
function! g:vpm.line.swap() "{

  if self.visible
    call self.hide()
  else
    call self.show()
  endif

endfunction
" }


" edit }
" g:vpm.edit {

function! g:vpm.edit.init()               "{

  let self.path = g:vpm.dirs.path('temp').'proj'
  let self.mode = 0
  let self.currpath = ''
  let self.currname = ''

endfunction "}
function! g:vpm.edit.proj()               "{

  if !g:vpm.data.loaded
    echo 'Load project first [:VPMLoadProject]'
    return -1
  endif

  if self.mode 
    call g:vpm.data.load(self.currname)
    call self.init()
    return
  endif
  " Save loaded project name  {
  
  let currpath = g:vpm.data.path
  let self.currpath = g:vpm.data.path
  let self.currname = matchlist(self.currpath,g:vpm.patt.edit)
  let self.currname = [currpath,self.currname[1]][Found(self.currname)]

  " }
  " Create temporary project  {

  let projects = g:vpm.dirs.list('proj')
  if DoesNotFind(projects)
    echo 'No project files were found.'
    return -1
  endif

  let currproj = matchstr(currpath,g:vpm.patt.edit)

  let lines = []
  
  " Loop over projects
  for project in projects
    if project == currproj
      continue
    endif
    let name  = matchlist(project,g:vpm.patt.edit)
    let name  = [project,name[1]][Found(name)]
    let buff  = 'buff '.name.':'.project
    let lines = add(lines,buff)
  endfor
  let lines = add(lines,'tab Edit-Terminal')
  let lines = add(lines,'term Terminal:bash')
  
  " Give priority to current loaded project
  if Found(currpath)
    let name  = matchlist(currpath,g:vpm.patt.edit)
    let name  = [currpath,name[1]][Found(name)]
    let lines = ['buff * '.name.':'.currpath] + lines
  endif

  " Pre-append tab and workspace lines
  let lines = ['tab       Project Files'    ] + lines
  let lines = ['workspace VPM Edit Projects'] + lines

  call writefile(lines,self.path)

  " }
  " Load  temporary  project  {
  
  call g:vpm.data.load(self.path)

  " }

endfunction "}

" edit }
" g:vpm.temp {

function! g:vpm.temp.init()               "{

  let patt       = g:vpm.patt.temp
  let self.path  = matchstr(v:servername,patt)
  let self.path  = resolve(self.path)
  let self.path .= '/vpm/'

  if !isdirectory(self.path)
    call mkdir(self.path,"p")
  endif

  return self.path

endfunction "}

" temp }
" g:vpm.save {

function! g:vpm.save.deft(p)              "{

  let proj = ''
  let dest = g:vpm.dirs.path('root') . 'default'

  " Argument takes priority
  if Found(a:p)
    let proj = a:p
  else
    let path = g:vpm.data.path
    if filewritable(path)
      " Split: get the filename. Look for better solution
      let proj = split(path,'/')[-1]
    endif
  endif

  if writefile([proj],dest) == 0
    echo "VPM: Saved default projet [".proj."] at location. ".dest
  else
    echo "VPM: Failed to save default projet [".proj."] at location. ".dest"
    echo "Location is missing or doesn't have write permition"
  endif

endfunction "}

" save }
" g:vpm.dirs {

function! g:vpm.dirs.init()  "{
endfunction "}
function! g:vpm.dirs.path(t) "{
  if     a:t == 'proj'
    return self.vpm . '/' . self.proj . '/'
  elseif a:t == 'root'
    return resolve(self.vpm) . '/'
  elseif a:t == 'temp'
    return resolve(g:vpm.temp.path) . '/'
  endif
  return ''
endfunction
"}
function! g:vpm.dirs.list(t) "{

  if a:t == 'proj'
    let projpath = self.path('proj')
    let projects = glob(projpath.'*')
    let projects = split(projects,"\n")
    return projects
  elseif a:t == 'projname'

    let projects = self.list('proj')

    let projnames = []

    if Found(projects)
      for path in projects
        let name = matchlist(path,g:vpm.patt.tail)
        if Found(name)
          call add(projnames,name[1])
        endif
      endfor
    endif

    return projnames

  endif

endfunction
"}

" init }
" g:vpm.term {

function! g:vpm.term.init() "{
  let self.buf  = ''
endfunction
" }
function! g:vpm.term.make() "{

 if !bufexists(self.buf)

   exec 'buffer|terminal'
   let self.buf = bufname('%')

 endif

endfunction
" }
function! g:vpm.term.kill() "{

 if bufexists(self.buf)

   exec 'bdelete! ' . self.buf

   let self.buf = ''

 endif

endfunction
" }
function! g:vpm.term.edit() "{

  call self.make()
  exec 'edit! ' . self.buf

endfunction
" }

" }
" g:vpm.patt {

function! g:vpm.patt.init()               "{

  let s = '\s*'
  let a = '\(.*\)'
  let f = '\/'
  let w = '\(\w*\)'
  let sa = s.a
  let sas = sa.s
  let h = '\(\**\)'
  let shs = s.h.s
  let self.term = '^'.shs.'term'.sas.':'.sas.'$'
  let self.buff = '^'.shs.'buff'.sas.':'.sas.'$'
  let self.tabs = '^'.shs.'tab' . sa         .'$'
  let self.wksp = '^'.shs.'workspace' . sa   .'$'
  let self.temp = '^'.a.f.'nvim'.w
  let self.tail = '^\/*.*\/\(.*\)$'
  let self.edit = '^'.g:vpm.dirs.path('proj')
  let self.edit = substitute(self.edit,'\/','\\/','g')
  let self.edit .= a.'$'

endfunction
"}
function! g:vpm.patt.show()               "{

  echo 'term -' string(self.term)
  echo 'buff -' string(self.buff)
  echo 'tabs -' string(self.tabs)
  echo 'wksp -' string(self.wksp)
  echo 'edit -' string(self.edit)

endfunction
"}

" }

" func}
" Helpers    {

function! VPMNextPrev(a,l,p)

 return "workspace\nbuffer\ntab"

endfunction
function! VPMListProjects(a,l,p)

 return join(g:vpm.dirs.list('projname'),"\n")

endfunction
function! Found(x)
  return !empty(a:x)
endfunction
function! DoesNotFind(x)
  return !Found(a:x)
endfunction

"}
" Commands   {

command! -nargs=0 VPMEditProjects call g:vpm.edit.proj()

command!
\ -complete=custom,VPMListProjects
\ -nargs=1
\ VPMLoadProject
\ call g:vpm.data.load("<args>")

command!
\ -complete=custom,VPMListProjects
\ -nargs=*
\ VPMSaveDefaultProject
\ call g:vpm.save.deft("<args>")

command! -complete=custom,VPMNextPrev -nargs=1 VPMNext call g:vpm.loop(+1,"<args>")
command! -complete=custom,VPMNextPrev -nargs=1 VPMPrev call g:vpm.loop(-1,"<args>")

command! -nargs=0 VPMTerminal    call g:vpm.term.edit()
command! -nargs=0 VPMDevTest call g:vpm.test()

" }
" Autocmds   {

" autocmd VimEnter * call g:vpm.default()

" }

call g:vpm.init()
if get(g: ,'vpm_load_default',1)
  call g:vpm.deft()
endif
