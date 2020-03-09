if exists('g:nvpm_loaded')
  finish
endif

let g:nvpm_loaded = v:true

" Dictionaries {

let g:nvpm = {}
let g:nvpm.temp = {}
let g:nvpm.save = {}
let g:nvpm.edit = {}
let g:nvpm.patt = {}
let g:nvpm.line = {}
let g:nvpm.dirs = {}
let g:nvpm.term = {}
let g:nvpm.data = {}
let g:nvpm.data.make = {}
let g:nvpm.data.curr = {}


" }
" Functions    {

" g:nvpm      {

function! g:nvpm.init()                    "{

  call self.dirs.init()
  call self.patt.init()
  call self.line.init()
  call self.data.init()
  call self.temp.init()
  call self.edit.init()
  call self.term.init()

endfunction
"}
function! g:nvpm.null()                    "{
  return ''
endfunction
"}
function! g:nvpm.test()                    "{
endfunction
"}
function! g:nvpm.deft()                    "{

  let root = self.dirs.path('root')

  let file = root . 'default'

  if filereadable(file)
    let project = readfile(file)[0]
    if Found(project)
      call self.data.load(project)
    endif
  endif

  return 1

endfunction
"}
function! g:nvpm.newp(name)                "{

  call self.dirs.make()

  let path = self.dirs.path('proj').a:name

  if FoundItem(path,self.dirs.list('proj'))
    echo 'NVPM: project ['.path.'] already located in projects folder.'
    echo '      Choose another name!'
    return
  endif

  let lines  = ['// ']
  let lines += ['// This example file already works!']
  let lines += ['// change the <*-name> to your liking.']
  let lines += ["// Also, don't forget change the path of buff entry."]
  let lines += ['// ']
  let lines += ['// List of existing projects in: ['.g:nvpm.dirs.path('proj').']']
  let lines += ['// ']
  let lines += ['// --> '.a:name]
  let lines += ['// ']

  let projects = g:nvpm.dirs.list('projname')
  for project in projects
    let lines += ['//     '.project]
  endfor

  let lines += ['// ']
  let lines += ["//   reload this proj to apply differencies!"]
  let lines += ['// ']
  let lines += ['// Note: You may delete these comments']
  let lines += ['// by using "dip" inside this paragraph!']
  let lines += ['// ---------------------------------']
  let lines += ['']
  let lines += ['workspace <workspace-name>'  ]
  let lines += ['  tab <tab-name>'            ]
  let lines += ['    buff <buff-name> : '.path]
  let lines += ['    term Terminal:']

  call writefile(lines,path)

  call self.data.load(a:name)

endfunction
"}
function! g:nvpm.loop(s,t)                 "{

  if !g:nvpm.data.loaded
    echo 'Load project first [:NVPMLoadProject]'
    return -1
  endif

  call self.data.curr.loop(a:s,a:t[0])
  call self.data.curr.edit()

endfunction
"}

"}
" g:nvpm.data {

" g:nvpm.data.*    {

function! g:nvpm.data.init()               "{
  let self.loaded = 0
  let self.last = 0
  let self.path = ''
  call self.curr.init()
endfunction
"}
function! g:nvpm.data.show()               "{

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
" g:nvpm.data.load {

function! g:nvpm.data.load(file)           "{

  " Variables                       {
  let workspaces = []
  let patt       = g:nvpm.patt.wksp

  " Edit project files
  let g:nvpm.edit.mode = a:file == g:nvpm.edit.path
  let path = g:nvpm.edit.mode ? '' : g:nvpm.dirs.path('proj')
  let path = resolve(expand(path.a:file))

  if !filereadable(path)
    echo "NVPM: default project '".path."' is unreadable or missing"
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
    call g:nvpm.line.show()

  endif
  "}

endfunction
" load }
function! g:nvpm.data.wksp(match,index)    "{

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
    let awkspmatch = matchlist(line,g:nvpm.patt.wksp)
    let atabmatch  = matchlist(line,g:nvpm.patt.tabs)
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
function! g:nvpm.data.tabs(match,index)    "{

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
    let atabmatch  = matchlist(line,g:nvpm.patt.tabs)
    let abuffmatch = matchlist(line,g:nvpm.patt.buff)
    let atermmatch = matchlist(line,g:nvpm.patt.term)
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
function! g:nvpm.data.buff(match,index)    "{

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
function! g:nvpm.data.term(match,index)    "{

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
" g:nvpm.data.make {

function! g:nvpm.data.make.proj()          "{

  let proj = g:nvpm.data.proj
  let wlen = len(proj)
  let g:nvpm.data.last %= wlen

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
function! g:nvpm.data.make.buff(b)         "{
  exec 'badd ' . a:b.path
endfunction
"}
function! g:nvpm.data.make.term(t)         "{

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
" g:nvpm.data.curr {

function! g:nvpm.data.curr.init()          "{
  let self.w = 0
  let self.t = 0
  let self.b = 0
endfunction
"}
function! g:nvpm.data.curr.edit()          "{
  exec ':edit ' . self.item('b').path
endfunction
"}
function! g:nvpm.data.curr.leng(t)         "{
  return len(self.list(a:t))
endfunction
"}
function! g:nvpm.data.curr.list(t)         "{

  if     a:t == 'w'
    return g:nvpm.data.proj
  elseif a:t == 't'
    return self.list('w')[self.w].tabs
  elseif a:t == 'b'
    return self.list('t')[self.t].buff
  endif

endfunction
"}
function! g:nvpm.data.curr.item(t)         "{

  if     a:t == 'w'
    return self.list('w')[self.w]
  elseif a:t == 't'
    return self.item('w').tabs[self.t]
  elseif a:t == 'b'
    return self.item('t').buff[self.b]
  endif

endfunction
"}
function! g:nvpm.data.curr.loop(s,t)       "{

  if g:nvpm.data.loaded "{

    if bufname('%') != self.item('b').path "{
      call self.edit()
    else
      let step = a:s
      let type = a:t
      let self[type] += step
      let self[type]  = self[type] % self.leng(type)

      if     type == 'b' "{
        let g:nvpm.data.proj[self.w].tabs[self.t].last = self.b
      "}
      elseif type == 't' "{
        " Update new current tab position after cycling
        let g:nvpm.data.proj[self.w].last = self.t
        " For the new tab, retrieve last buffer position
        let self.b = self.item('t').last
      "}
      elseif type == 'w' "{
        " Update new current Workspace position after cycling
        let g:nvpm.data.last = self.w
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
function! g:nvpm.data.curr.last()          "{

  let self.t = self.item('w').last
  let self.b = self.item('t').last

endfunction
"}
function! g:nvpm.data.curr.term()          "{

  if bufname('%') != g:nvpm.term.buf
    exec ':buffer ' . self.item('b').path
  endif

endfunction
" focus }

" curr}

" data}
" g:nvpm.line {

function! g:nvpm.line.init() "{
  let self.visible = 0

  let self.noenclosure = get(g: , 'nvpm_line_noenclosure' , 0)

  if self.noenclosure
    return
  endif

  let enclosure   = {}
  let enclosure.s = {}
  let enclosure.u = {}
  let enclosure.s.w = {'l':'(','r':')'}
  let enclosure.u.w = {'l':' ','r':' '}
  let enclosure.s.t = {'l':'[','r':']'}
  let enclosure.u.t = {'l':' ','r':' '}
  let enclosure.s.b = {'l':'[','r':']'}
  let enclosure.u.b = {'l':' ','r':' '}
  let self.enclosure   = get(g: , 'nvpm_line_enclosure' , enclosure)
endfunction "}
function! g:nvpm.line.topl() "{
  let line  = ''
  let line .= '%#NVPMLineWksp#'

  if self.noenclosure
    let line .= ' '
    let line .= g:nvpm.data.curr.item('w').name
    let line .= ' '
  else
    let line .= self.enclosure.s.w.l
    let line .= g:nvpm.data.curr.item('w').name
    let line .= self.enclosure.s.w.r
  endif

  let currtab = g:nvpm.data.curr.item('t')

  for tab in g:nvpm.data.curr.list('t')
    if tab.name == currtab.name
      let line .= '%#NVPMLineTabsSel#'
      if self.noenclosure
        let line .= ' '
        let line .= tab.name
        let line .= ' '
      else
        let line .= self.enclosure.s.t.l
        let line .= tab.name
        let line .= self.enclosure.s.t.r
      endif
    else
      let line .= '%#NVPMLineTabs#'
      if self.noenclosure
        let line .= ' '
        let line .= tab.name
        let line .= ' '
      else
        let line .= self.enclosure.u.t.l
        let line .= tab.name
        let line .= self.enclosure.u.t.r
      endif
    endif
  endfor

  let line .= '%#NVPMLineTabsFill#'

  return line
endfunction
" }
function! g:nvpm.line.botl() "{
  let line  = ''

  let currbuf = g:nvpm.data.curr.item('b')

  for buf in g:nvpm.data.curr.list('b')
    if buf.name == currbuf.name
      let line .= '%#NVPMLineBuffSel#'
      if self.noenclosure
        let line .= ' '
        let line .= buf.name
        let line .= ' '
      else
        let line .= self.enclosure.s.b.l
        let line .= buf.name
        let line .= self.enclosure.s.b.r
      endif
    else
      let line .= '%#NVPMLineBuff#'
      if self.noenclosure
        let line .= ' '
        let line .= buf.name
        let line .= ' '
      else
        let line .= self.enclosure.u.b.l
        let line .= buf.name
        let line .= self.enclosure.u.b.r
      endif
    endif
  endfor

  let line .= '%#NVPMLinebuffFill#'

  return line
endfunction
" }
function! g:nvpm.line.show() "{

  " NOTE: Don't put spaces!
  set tabline=%!g:nvpm.line.topl()
  set statusline=%!g:nvpm.line.botl()

  let self.visible = 1

endfunction
" }
function! g:nvpm.line.hide() "{

  set tabline=%!g:nvpm.null()
  set statusline=%!g:nvpm.null()

  let self.visible = 0

endfunction
" }
function! g:nvpm.line.swap() "{

  if self.visible
    call self.hide()
  else
    call self.show()
  endif

endfunction
" }


" edit }
" g:nvpm.edit {

function! g:nvpm.edit.init()               "{

  let self.path = g:nvpm.dirs.path('temp').'proj'
  let self.mode = 0
  let self.currpath = ''
  let self.currname = ''

endfunction "}
function! g:nvpm.edit.proj()               "{

  if !g:nvpm.data.loaded
    echo 'Load project first [:NVPMLoadProject]'
    return -1
  endif

  if self.mode
    call g:nvpm.data.load(self.currname)
    call self.init()
    return
  endif
  " Save loaded project name  {

  let currpath = g:nvpm.data.path
  let self.currpath = g:nvpm.data.path
  let self.currname = matchlist(self.currpath,g:nvpm.patt.edit)
  let self.currname = [currpath,self.currname[1]][Found(self.currname)]

  " }
  " Create temporary project  {

  let projects = g:nvpm.dirs.list('proj')
  if DoesNotFind(projects)
    echo 'No project files were found.'
    return -1
  endif

  let currproj = matchstr(currpath,g:nvpm.patt.edit)

  let lines = []

  " Loop over projects
  for project in projects
    if project == currproj
      continue
    endif
    let name  = matchlist(project,g:nvpm.patt.edit)
    let name  = [project,name[1]][Found(name)]
    let buff  = 'buff '.name.':'.project
    let lines = add(lines,buff)
  endfor
  let lines = add(lines,'tab Edit-Terminal')
  let lines = add(lines,'term Terminal:bash')

  " Give priority to current loaded project
  if Found(currpath)
    let name  = matchlist(currpath,g:nvpm.patt.edit)
    let name  = [currpath,name[1]][Found(name)]
    let lines = ['buff * '.name.':'.currpath] + lines
  endif

  " Pre-append tab and workspace lines
  let lines = ['tab       Project Files'    ] + lines
  let lines = ['workspace NVPM Edit Projects'] + lines

  call writefile(lines,self.path)

  " }
  " Load  temporary  project  {

  call g:nvpm.data.curr.init()
  call g:nvpm.data.load(self.path)

  " }

endfunction "}

" edit }
" g:nvpm.temp {

function! g:nvpm.temp.init()               "{

  let patt       = g:nvpm.patt.temp
  let self.path  = matchstr(v:servername,patt)
  let self.path  = resolve(self.path)
  let self.path .= '/nvpm/'

  if !isdirectory(self.path)
    call mkdir(self.path,"p")
  endif

  return self.path

endfunction "}

" temp }
" g:nvpm.save {

function! g:nvpm.save.deft(p)              "{

  let proj = ''
  let dest = g:nvpm.dirs.path('root') . 'default'

  " Argument takes priority
  if Found(a:p)
    let proj = a:p
  else
    let path = g:nvpm.data.path
    if filewritable(path)
      " Split: get the filename. Look for better solution
      let proj = split(path,'/')[-1]
    endif
  endif

  if writefile([proj],dest) == 0
    echo "NVPM: Saved default projet [".proj."] at location. ".dest
  else
    echo "NVPM: Failed to save default projet [".proj."] at location. ".dest"
    echo "Location is missing or doesn't have write permition"
  endif

endfunction "}

" save }
" g:nvpm.dirs {

function! g:nvpm.dirs.init()  "{
  let self.nvpm = get( g: , 'nvpm_local_dir'  , '.nvpm'  )
  let self.main = get( g: , 'nvpm_main_dir' , '~/.nvpm' )
  let self.proj = 'proj'
endfunction "}
function! g:nvpm.dirs.make()  "{
  call mkdir(self.path('proj'),"p")
  call mkdir(self.path('temp'),"p")
endfunction "}
function! g:nvpm.dirs.path(t) "{
  if     a:t == 'proj'
    return self.nvpm . '/' . self.proj . '/'
  elseif a:t == 'root'
    return resolve(self.nvpm) . '/'
  elseif a:t == 'temp'
    return resolve(g:nvpm.temp.path) . '/'
  endif
  return ''
endfunction
"}
function! g:nvpm.dirs.list(t) "{

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
        let name = matchlist(path,g:nvpm.patt.tail)
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
" g:nvpm.term {

function! g:nvpm.term.init() "{
  let self.buf  = ''
endfunction
" }
function! g:nvpm.term.make() "{

 if !bufexists(self.buf)

   exec 'buffer|terminal'
   let self.buf = bufname('%')

 endif

endfunction
" }
function! g:nvpm.term.kill() "{

 if bufexists(self.buf)

   exec 'bdelete! ' . self.buf

   let self.buf = ''

 endif

endfunction
" }
function! g:nvpm.term.edit() "{

  call self.make()
  exec 'edit! ' . self.buf

endfunction
" }

" }
" g:nvpm.patt {

function! g:nvpm.patt.init()               "{

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
  let self.edit = '^'.g:nvpm.dirs.path('proj')
  let self.edit = substitute(self.edit,'\/','\\/','g')
  let self.edit .= a.'$'

endfunction
"}
function! g:nvpm.patt.show()               "{

  echo 'term -' string(self.term)
  echo 'buff -' string(self.buff)
  echo 'tabs -' string(self.tabs)
  echo 'wksp -' string(self.wksp)
  echo 'edit -' string(self.edit)

endfunction
"}

" }

" func}
" Helpers      {

function! NVPMNextPrev(a,l,p)

 return "workspace\nbuffer\ntab"

endfunction
function! NVPMListProjects(a,l,p)

 return join(g:nvpm.dirs.list('projname'),"\n")

endfunction
function! FoundItem(item,list)
    let found = 0

    for element in a:list
      if element == a:item
        let found = 1
        break
      endif
    endfor

    return found
endfunction
function! Found(x)
  return !empty(a:x)
endfunction
function! DoesNotFind(x)
  return !Found(a:x)
endfunction

"}
" Init         {
call g:nvpm.init()
if get(g: ,'nvpm_load_default',1)
  call g:nvpm.deft()
endif
" init }
" Commands     {

command! -nargs=0 NVPMEditProjects call g:nvpm.edit.proj()

command!
\ -complete=custom,NVPMListProjects
\ -nargs=1
\ NVPMNewProject
\ call g:nvpm.newp("<args>")
command!
\ -complete=custom,NVPMListProjects
\ -nargs=1
\ NVPMLoadProject
\ call g:nvpm.data.load("<args>")

command!
\ -complete=custom,NVPMListProjects
\ -nargs=*
\ NVPMSaveDefaultProject
\ call g:nvpm.save.deft("<args>")

command! -complete=custom,NVPMNextPrev -nargs=1 NVPMNext call g:nvpm.loop(+1,"<args>")
command! -complete=custom,NVPMNextPrev -nargs=1 NVPMPrev call g:nvpm.loop(-1,"<args>")

command! -nargs=0 NVPMLineShow call g:nvpm.line.show()
command! -nargs=0 NVPMLineHide call g:nvpm.line.hide()

command! -nargs=0 NVPMTerminal call g:nvpm.term.edit()
command! -nargs=0 NVPMDevTest  call g:nvpm.test()

" }
" AutoCommands {

" Set project files filetype as nvpm
execute 'au BufEnter *'. g:nvpm.dirs.path("proj") .'* set ft=nvpm'

if get(g:,'nvpm_echo_path',0)
  au BufEnter * echo printf("%s",bufname("%"))
endif

if get(g:,'nvpm_buffresh',0)
  au FocusGained,BufEnter * :silent! !
  au FileChangedShell     * :silent! !
endif

" AutoCommands }
