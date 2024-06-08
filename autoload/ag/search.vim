" Author: Eric Van Dewoestine

" License: {{{
"   Copyright (c) 2012 - 2024, Eric Van Dewoestine
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

let s:save_cpo=&cpo
set cpo&vim

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

function! ag#search#Ag(args, relative, bang) " {{{
  if !executable('ag')
    call s:Echo("'ag' not found on your system path.", 'Error')
    return
  endif

  if a:relative
    let cwd = getcwd()
    exec 'cd ' . expand('%:p:h')
  endif

  if empty(a:args)
    let cword = expand("<cword>")
    if cword == ''
      call s:Echo("No word under the cursor to search for.", 'Error')
      return
    endif
    let args = s:ParseArgs("\\<" . cword . "\\>")
    let args = ['-s'] + args
  elseif a:args == '-g'
    let line = getline(line('.'))
    let uri = substitute(line,
      \ "\\(.*[[:space:]\"',(\\[{><]\\|^\\)\\(.*\\%" .
      \ col('.') . "c.\\{-}\\)\\([[:space:]\"',)\\]}<>].*\\|$\\)",
      \ '\2', '')
    let args = s:ParseArgs(a:args)
    call add(args, uri)
  else
    let args = s:ParseArgs(a:args)
    let args = [g:AgSmartCase ? '--smart-case' : '-s'] + args
  end

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
      let args =
        \ options +
        \ ['-G', file, '--depth', '0'] +
        \ non_option_args[:-2] +
        \ [path]

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

  try
    call s:Ag(args, a:bang)
  finally
    if a:relative
      exec 'cd ' . cwd
    endif
  endtry
endfunction " }}}

function! s:Ag(args, bang) " {{{
  let args = a:args
  let results = []
  let saveerrorformat = &errorformat
  try
    silent! doautocmd QuickFixCmdPre grep
    if index(args, '-g') != -1
      let filename = 1
      set errorformat=%-GERR:%.%#,%f,%-G%.%#
    else
      let filename = 0
      set errorformat=%-GERR:%.%#,%f:%l:%c:%m,%-G%.%#
    endif

    " If there is no tty (which is the case when calling ag via system), ag
    " will default to searching stdin, so force it to search files via the
    " --search-files arg: https://github.com/ggreer/the_silver_searcher/issues/57
    let args = ['--search-files'] + args
    " when searching for a pattern in files, then ensure column numbers are in
    " the results
    if !filename
      let args = ['--column'] + args
    endif

    let cmd = 'ag ' .
      \ join(map(copy(args), 'shellescape(v:val)'), ' ') .
      \ ' | sort'

    if &verbose
      echom "Ag: executing" cmd
    endif

    let bufnum = bufnr()
    let output = system(cmd)
    silent cexpr output

    let qftitle = 'ag ' . join(args)
    try
      call setqflist([], 'a', {'title': qftitle})
    catch
      " don't let attempting to set the quickfix title break anything
    endtry

    if v:shell_error || output =~ '^ERR:'
      " may be a bug in ag, but it is returning an error code on file name searches
      " (-g <pattern>) when results are found
      if index(args, '-g') != -1
        if len(results) && bufname(results[0].bufnr) !~ '^ag: '
          return
        endif
        " our -g errorformat matches every line of ag's error message if there was
        " a legitimate error, so jump back to the file the user was editing and
        " clear the quickfix list
        if bufnr() != bufnum
          exec "normal! \<c-o>"
        endif
        call setqflist([], 'r')
      endif

      " note: an error code is returned on no results as well.
      if output != ''
        call s:Echo(output, 'Error')
        return
      endif
    endif

    let results = getqflist()
    if len(results) == 0
      if filename
        call s:QuickfixRestore()
      endif
      call s:Echo('No results found: ' . cmd, 'WarningMsg')
      return 0
    endif

    if filename
      " if this is a file search and there is only 1 result, then open it
      " and restore any previous quickfix results
      if len(results) == 1
        if a:bang != '' && a:bang != 'edit'
          " allow a command to be supplied for the bang arg to support
          " ag#search#FindFile
          let cmd = a:bang == '!' ? 'split' : a:bang
          silent exec "normal! \<c-o>"
          exec cmd
          exec 'buffer' . results[0]['bufnr']
        endif
        " restore  the previous quickfix results if any
        call s:QuickfixRestore()

      " if there are multiple results, then return the user to where they
      " were and open the quickfix window for the user to choose the file
      " from
      else
        silent exec "normal! \<c-o>"
        copen
      endif

    " open up the fold on the first result
    elseif a:bang == ''
      normal! zv
      silent! doautocmd WinEnter

    " if the user doesn't want to jump to the first result, then navigate back
    " to where they were (cexpr! just ignores changes to the current file, so
    " we need to use the jumplist) and open the quickfix window.
    else
      exec "normal! \<c-o>"
      copen
    endif
    silent! doautocmd QuickFixCmdPost grep
  catch /E325/
    " vim handles this by prompting the user for how to proceed
  finally
    let &errorformat = saveerrorformat
  endtry
  return 1
endfunction " }}}

function! s:ParseArgs(args) " {{{
  let rawargs = a:args
  let rawargs = substitute(rawargs, '\\[<>]', '\\b', 'g')
  let rawargs = substitute(rawargs, '\\{-}', '*?', 'g')
  let arglist = split(rawargs, ' ')
  let quoted = ''
  let escaped = 0
  let args = []
  for arg in arglist
    if quoted != ''
      let args[-1] .= ' ' . arg
      " closing quote while in 'quoted' state, strip it off if not escaped
      if arg =~ quoted . '$' && arg[len(arg) - 2] != '\'
        let quoted = ''
        let args[-1] = args[-1][:-2]
      endif
    elseif escaped
      let args[-1] .= ' ' . arg
      let escaped = arg =~ '\\$'
    else
      let escaped = arg =~ '\\$'
      let quoted = arg =~ '^[''"]' ? arg[0] : ''
      " a lone quote, so must have been a quote with n spaces
      if arg == quoted
        call add(args, '')

      " fully quoted or not quoted at all
      elseif arg =~ quoted . '$'
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

function! s:QuickfixRestore() " {{{
  try
    silent colder
  catch /E380/
    " if we are at the bottom of the stack, then clear our results
    call setqflist([], 'r')
    call setqflist([], 'a', {'title': ''})
  endtry
endfunction " }}}

function! ag#search#CompleteRelative(argLead, cmdLine, cursorPos) " {{{
  return ag#Complete(a:argLead, a:cmdLine, a:cursorPos, 1)
endfunction " }}}

function! ag#search#Complete(argLead, cmdLine, cursorPos, ...) " {{{
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
      call add(results, substitute(hist, '\([^\\]\)\s', '\1\\ ', 'g'))
      let i -= 1
    endwhile
    return filter(results, 'v:val =~# "^\\M" . a:argLead')
  endif

  " complete file relative files/directories
  if a:0 && a:1
    let path = expand('%:h')
    if path == ''
      let path = getcwd()
    endif
    let path .= '/'
    let results = glob(path . substitute(a:argLead, '^/', '', '') . '*', 0, 1)
    let results = map(results, 'isdirectory(fnamemodify(v:val, ":p")) ? v:val . "/" : v:val')
    let results = map(results, 'substitute(v:val, "^" . path, "", "")')

  " complete absolute / cwd relative files/directories
  else
    let results = glob(a:argLead . '*', 0, 1)
    let results = map(results, 'isdirectory(fnamemodify(v:val, ":p")) ? v:val . "/" : v:val')
  endif
  return results
endfunction " }}}

function! ag#search#FindFile(path, cmd) " {{{
  " A helper function that other scripts can use to locate a file by path
  return s:Ag(['-g', a:path], a:cmd)
endfunction " }}}

let &cpo = s:save_cpo

" vim:ft=vim:fdm=marker
