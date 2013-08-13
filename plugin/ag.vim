" Author: Eric Van Dewoestine

" Description: {{{
"   Plugin for invoking the silver searcher (ag), using :Ag, and adding the
"   result to vim's quickfix.  Also performs some simple conversions from vim
"   regex patterns to perl's (\{-} to *?, \<foo\> to \bfoo\b).
" }}}

" License: {{{
"   Copyright (c) 2012 - 2013, Eric Van Dewoestine
"   All rights reserved.
"
"   Redistribution and use of this software in source and binary forms, with
"   or without modification, are permitted provided that the following
"   conditions are met:
"
"   * Redistributions of source code must retain the above
"     copyright notice, this list of conditions and the
"     following disclaimer.
"
"   * Redistributions in binary form must reproduce the above
"     copyright notice, this list of conditions and the
"     following disclaimer in the documentation and/or other
"     materials provided with the distribution.
"
"   * Neither the name of Eric Van Dewoestine nor the names of its
"     contributors may be used to endorse or promote products derived from
"     this software without specific prior written permission of
"     Eric Van Dewoestine.
"
"   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
"   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
"   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
"   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
"   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
"   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
"   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
"   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
"   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
"   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
"   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" }}}

if v:version < 700
  finish
endif

let s:save_cpo=&cpo
set cpo&vim

" Command Declarations {{{
if !exists(":Ag")
  command -nargs=+ -complete=customlist,<SID>Complete
    \ Ag :call <SID>Ag(<q-args>, 0)
endif
if !exists(":AgRelative")
  command -nargs=+ -complete=customlist,<SID>CompleteRelative
    \ AgRelative :call <SID>Ag(<q-args>, 1)
endif
" }}}

" Script Variables {{{
  let s:supported_options = [
      \ '-a', '--all-types',
      \ '--depth',
      \ '-f', '--follow',
      \ '-g PATTERN',
      \ '-G PATTERN', '--file-search-regex PATTERN',
      \ '--hidden',
      \ '-i', '--ignore-case',
      \ '--ignore PATTERN',
      \ '-m NUM', '--max-count NUM',
      \ '-p PATH', '--path-to-agignore PATH',
      \ '-Q', '--literal',
      \ '-s', '--case-sensitive',
      \ '-S', '--smart-case',
      \ '--search-binary',
      \ '-t', '--all-text',
      \ '-u', '--unrestricted',
      \ '-U', '--skip-vcs-ignores',
      \ '-v', '--invert-match',
      \ '-w', '--word-regexp',
    \ ]
" }}}

function! s:Ag(args, relative) " {{{
  if !executable('ag')
    call s:Echo("'ag' not found on your system path.", 'Error')
    return
  endif

  if a:relative
    let cwd = getcwd()
    exec 'cd ' . expand('%:p:h')
  endif

  let args = s:ParseArgs(a:args)
  " if pattern and dir supplied, see if dir is a glob pattern
  let [options, non_option_args] = s:SplitOptionsFromArgs(args)
  if len(non_option_args) == 2
    let dir = non_option_args[-1]
    if dir =~ '%'
      let toexpand = substitute(dir, '.\{-}\(%\(:[phtre]\)*\).*', '\1', '')
      let dir = substitute(dir, toexpand, expand(toexpand), '')
    endif

    " ag seems to only support a dir arg, so if a file path is supplied tweak
    " it to be a dir with a file filter
    if filereadable(dir)
      let path = fnamemodify(dir, ':h')
      let file = fnamemodify(dir, ':t')
      let args = options + ['-G', file, '--depth', '0'] + non_option_args[:-2] + [path]

    " globs
    elseif dir =~ '\*'
      let dir = escape(dir, '.')
      let parts = split(dir, '\*\{2,}')
      let parts = map(parts, 'substitute(v:val, "*", "[^/]*", "g")')
      let pattern = join(parts, '.*')
      if dir =~ '^\*\{2,}'
        let pattern = '.*' . pattern
      endif
      let args = options + ['-G', pattern . '$'] + non_option_args[:-2]
    endif
  endif

  let cmd = 'ag --search-files --column ' .
    \ join(map(copy(args), 'shellescape(v:val)'), ' ')

  let saveerrorformat = &errorformat
  try
    silent! doautocmd QuickFixCmdPre grep
    if index(args, '-g') != -1
      set errorformat=%-GERR:%.%#,%f,%-G%.%#
    else
      set errorformat=%-GERR:%.%#,%f:%l:%c:%m,%-G%.%#
    endif
    " As described here, if there is no tty (which is the case when calling ag
    " via system), ag will default to searching stdin, so force it to search
    " files via the --search-files arg:
    " https://github.com/ggreer/the_silver_searcher/issues/57
    cexpr system(cmd)
    if exists('*setqftitle')
      call setqftitle('ag' . args)
    endif
    silent! doautocmd QuickFixCmdPost grep
  catch /E325/
    " vim handles this by prompting the user for how to proceed
  finally
    let &errorformat = saveerrorformat
    if a:relative
      exec 'cd ' . cwd
    endif
  endtry

  if v:shell_error
    let error = system(cmd)
    call s:Echo(error, 'Error')
  elseif len(getqflist()) == 0
    call s:Echo('No results found: ' . cmd, 'WarningMsg')
  endif
endfunction " }}}

function! s:ParseArgs(args) " {{{
  let rawargs = a:args
  let rawargs = substitute(rawargs, '\\[<>]', '\\b', 'g')
  let rawargs = substitute(rawargs, '\\{-}', '*?', 'g')
  let arglist = split(rawargs, ' ')
  let quoted = ''
  let args = []
  for arg in arglist
    if quoted != ''
      let args[-1] .= ' ' . arg
      " closing quote while in 'quoted' state, strip it off if not escaped
      if arg =~ quoted . '$' && arg[len(arg) - 2] != '\'
        let quoted = ''
        let args[-1] = args[-1][:-2]
      endif
    else
      let quoted = arg =~ '^[''"]' ? arg[0] : ''
      " fully quoted
      if arg =~ quoted . '$'
        let quoted = ''
        call add(args, arg)

      " starting quote only, assuming quoted because of spaces
      else
        call add(args, arg[1:])
      endif
    endif
  endfor
  return args
endfunction " }}}

function! s:Echo(message, highlight) " {{{
  exec "echohl " . a:highlight
  redraw
  for line in split(a:message, '\n')
    echom line
  endfor
  echohl None
endfunction " }}}

function! s:OptionHasArg(option) " {{{
  for option in s:supported_options
    if option =~# '^' . a:option . '\>'
      return option != a:option
    endif
  endfor
  return 0
endfunction " }}}

function! s:SplitOptionsFromArgs(args) " {{{
  let options = []
  let args = []
  let prevarg = ''
  for arg in a:args
    if prevarg =~ '^-' && s:OptionHasArg(prevarg)
      call add(options, arg)
      let prevarg = arg
      continue
    endif
    if arg =~ '^-'
      call add(options, arg)
      let prevarg = arg
      continue
    endif
    call add(args, arg)
  endfor
  return [options, args]
endfunction " }}}

function! s:CompleteRelative(argLead, cmdLine, cursorPos) " {{{
  return s:Complete(a:argLead, a:cmdLine, a:cursorPos, 1)
endfunction " }}}

function! s:Complete(argLead, cmdLine, cursorPos, ...) " {{{
  let pre = substitute(a:cmdLine[:a:cursorPos], '\w\+\s\+', '', '')
  let args = s:ParseArgs(pre)

  " complete ag options
  if a:argLead =~ '^-'
    return filter(copy(s:supported_options), 'v:val =~# "^" . a:argLead')
  endif

  " ag option with an arg
  if len(args) && args[-1] =~ '^-' && s:OptionHasArg(args[-1])
    return []
  endif

  " complete patterns from search history
  let [options, args] = s:SplitOptionsFromArgs(args)
  if len(args) == 0 || (len(args) == 1 && a:argLead != '')
    let results = []
    let i = -1
    while i >= -10
      let hist = histget('search', i)
      if hist == ''
        break
      endif
      call add(results, hist)
      let i -= 1
    endwhile
    return filter(results, 'v:val =~# "^\\M" . a:argLead')
  endif

  " complete files/directories
  if a:0 && a:1
    let path = expand('%:h') . '/'
    let results = glob(path . a:argLead . '*', 0, 1)
    return map(results, 'substitute(v:val, "^" . path, "", "")')
  endif
  return glob(a:argLead . '*', 0, 1)
endfunction " }}}

" allow ag to be used with eclim's :LocateFile
if !exists('g:EclimLocateUserScopes')
  let g:EclimLocateUserScopes = ['ag']
else
  call add(g:EclimLocateUserScopes, 'ag')
endif

function! LocateFile_ag(pattern) " {{{
  if len(a:pattern) >= 5
    let command = '`ag --search-files -g "' . a:pattern . '"`'
    let results = split(eclim#util#Glob(command, 1), "\n")

    if len(results) > 0
      let tempfile = substitute(tempname(), '\', '/', 'g')
      call writefile(results, tempfile)
      try
        return eclim#common#locate#LocateFileFromFileList(a:pattern, tempfile)
      finally
        call delete(tempfile)
      endtry
    endif
  endif
  return []
endfunction " }}}

let &cpo = s:save_cpo

" vim:ft=vim:fdm=marker
