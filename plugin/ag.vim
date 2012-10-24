" Author: Eric Van Dewoestine

" Description: {{{
"   Plugin for invoking the silver searcher (ag), using :Ag, and adding the
"   result to vim's quickfix.  Also performs some simple conversions from vim
"   regex patterns to perl's (\{-} to *?, \<foo\> to \bfoo\b).
" }}}

" License: {{{
"   Copyright (c) 2012, Eric Van Dewoestine
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

" Command Declarations {{{
if !exists(":Ag")
  command -nargs=+ -complete=dir Ag :call <SID>Ag(<q-args>, 0)
endif
if !exists(":AgRelative")
  command -nargs=+ AgRelative :call <SID>Ag(<q-args>, 1)
endif
" }}}

function! s:Ag(args, relative) " {{{
  if !executable('ag')
    call s:Echo("'ag' not found on your system path.", 'Error')
    return
  endif

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

  let cmd = 'ag --search-files --column ' . join(map(args, 'shellescape(v:val)'), ' ')

  if a:relative
    let cwd = getcwd()
    exec 'cd ' . expand('%:p:h')
  endif
  let saveerrorformat = &errorformat
  try
    silent! doautocmd QuickFixCmdPre grep
    " As described here, if there is no tty (which is the case when call ag
    " via system), ag will default to searching stdin, so force it to search
    " files via the --search-files arg.
    " https://github.com/ggreer/the_silver_searcher/issues/57
    cexpr system(cmd)
    if exists('*setqftitle')
      call setqftitle('ag' . args)
    endif
    silent! doautocmd QuickFixCmdPost grep
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

function! s:Echo(message, highlight) " {{{
  exec "echohl " . a:highlight
  redraw
  for line in split(a:message, '\n')
    echom line
  endfor
  echohl None
endfunction " }}}

" vim:ft=vim:fdm=marker
