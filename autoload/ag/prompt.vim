" Author: Eric Van Dewoestine

" Description: {{{
"   Plugin for using the silver searcher (ag), via :AgPrompt, to provide an
"   interactive prompt with fuzzy searching to find and open files.
" }}}

" License: {{{
"   Copyright (c) 2024, Eric Van Dewoestine
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

" Global Variables {{{

let g:ag_prompt_default_updatetime = &updatetime

" disable autocomplpop in the locate prompt
if exists('g:acp_behavior')
  let g:acp_behavior['ag_prompt'] = []
endif

" }}}

function! ag#prompt#Open() " {{{
  let results = []
  let action = g:AgPromptDefaultAction
  let file = expand('%')
  let bufnum = bufnr('%')
  let winnr = winnr()
  let winrestcmd = winrestcmd()

  topleft 12split [Ag\ Results]
  set filetype=ag_results
  setlocal nonumber nowrap
  setlocal noswapfile nobuflisted
  setlocal nospell norelativenumber
  setlocal buftype=nofile bufhidden=delete

  let results_bufnum = bufnr('%')

  let search_in = getcwd()
  exec 'topleft 1split ' . escape('[Search in ' . search_in . ']', ' -')
  setlocal modifiable
  call setline(1, '> ')
  call cursor(1, col('$'))
  set filetype=ag_prompt
  syntax match Keyword /^>/
  setlocal winfixheight
  setlocal nonumber
  setlocal nolist
  setlocal noswapfile nobuflisted
  setlocal nospell norelativenumber
  setlocal buftype=nofile bufhidden=delete

  let b:bufnum = bufnum
  let b:winnr = winnr
  let b:results_bufnum = results_bufnum
  let b:selection = 1
  let b:winrestcmd = winrestcmd

  set updatetime=300

  augroup ag_prompt_init
    autocmd!
    autocmd BufEnter <buffer> nested startinsert! | let &updatetime = 300
    autocmd BufLeave \[Ag\ Results\] call <SID>Close()
    exec 'autocmd InsertLeave <buffer> ' .
      \ 'let &updatetime = g:ag_prompt_default_updatetime | ' .
      \ 'doautocmd BufWinLeave | bw | ' .
      \ 'doautocmd BufWinLeave | bw ' . b:results_bufnum . ' | ' .
      \ 'exec bufwinnr(' . b:bufnum . ') "winc w" | ' .
      \ 'doautocmd BufEnter | ' .
      \ 'doautocmd WinEnter | ' .
      \ winrestcmd
    exec 'autocmd WinEnter <buffer=' . b:results_bufnum .'> '
      \ 'exec bufwinnr(' . bufnr('%') . ') "winc w"'
  augroup END

  " enable searching after user starts typing
  call s:FileSearchAutocmdDeferred()

  inoremap <buffer> <silent> <tab> <c-r>=<SID>FileSelection("n")<cr>
  inoremap <buffer> <silent> <c-j> <c-r>=<SID>FileSelection("n")<cr>
  inoremap <buffer> <silent> <down> <c-r>=<SID>FileSelection("n")<cr>
  inoremap <buffer> <silent> <s-tab> <c-r>=<SID>FileSelection("p")<cr>
  inoremap <buffer> <silent> <up> <c-r>=<SID>FileSelection("p")<cr>
  inoremap <buffer> <silent> <c-k> <c-r>=<SID>FileSelection("p")<cr>
  exec 'inoremap <buffer> <silent> <cr> ' .
    \ '<c-r>=<SID>FileSelect("' . action . '")<cr>'
  inoremap <buffer> <silent> <c-e> <c-r>=<SID>FileSelect('edit')<cr>
  inoremap <buffer> <silent> <c-s> <c-r>=<SID>FileSelect('split')<cr>
  inoremap <buffer> <silent> <c-t> <c-r>=<SID>FileSelect("tablast \| tabnew")<cr>
  inoremap <buffer> <silent> <c-h> <c-r>=<SID>Help()<cr>

  startinsert!
endfunction " }}}

function! s:Search() " {{{
  let line = getline('.')
  if line !~ '^> '
    call setline(1, substitute(line, '^>\?\s*', '> \1', ''))
    call cursor(1, 3)
    let line = getline('.')
  endif

  let results = []
  let name = substitute(line, '^>\s*', '', '')
  if name !~ '^\s*$'
    let pattern = name
    let pattern = '[^/]*' . substitute(pattern, '\(.\)', '\1[^/]*?', 'g')
    let pattern = substitute(pattern, '\.\([^*]\)', '\\.\1', 'g')
    let results = s:Ag(pattern)
  endif
  let b:results = results
  let winnr = winnr()
  noautocmd exec bufwinnr(b:results_bufnum) . 'winc w'
  setlocal modifiable
  1,$delete _
  call append(1, results)
  1,1delete _
  setlocal nomodifiable
  exec winnr . 'winc w'

  " part of bad hack for gvim on windows
  let b:start_selection = 1

  call s:FileSelection(1)
endfunction " }}}

function! s:Close() " {{{
  if bufname(bufnr('%')) !~ '^\[Ag Results\]$'
    let bufnr = bufnr('\[Search in *\]')
    let winnr = bufwinnr(bufnr)
    if winnr != -1
      let curbuf = bufnr('%')
      exec winnr . 'winc w'
      try
        exec 'bw ' . b:results_bufnum
        bw
        autocmd! ag_prompt_init
        stopinsert
      finally
        exec bufwinnr(curbuf) . 'winc w'
      endtry
    endif
  endif
endfunction " }}}

function! s:FileSearchAutocmd() " {{{
  augroup ag_prompt
    autocmd!
    autocmd CursorHoldI <buffer> call <SID>Search()
  augroup END
endfunction " }}}

function! s:FileSearchAutocmdDeferred() " {{{
  augroup ag_prompt
    autocmd!
    autocmd CursorMovedI <buffer> call <SID>FileSearchAutocmd()
  augroup END
endfunction " }}}

function! s:FileSelection(sel) " {{{
  " pause searching while tabbing though results
  augroup ag_prompt
    autocmd!
  augroup END

  let sel = a:sel
  let prev_sel = b:selection

  let winnr = winnr()
  noautocmd exec bufwinnr(b:results_bufnum) . 'winc w'

  if sel == 'n'
    let sel = prev_sel < line('$') ? prev_sel + 1 : 1
  elseif sel == 'p'
    let sel = prev_sel > 1 ? prev_sel - 1 : line('$')
  endif

  syntax clear
  exec 'syntax match PmenuSel /\%' . sel . 'l.*/'
  exec 'call cursor(' . sel . ', 1)'
  let save_scrolloff = &scrolloff
  let &scrolloff = 5
  normal! zt
  let &scrolloff = save_scrolloff

  exec winnr . 'winc w'

  exec 'let b:selection = ' . sel

  " resume searching while tabbing though results
  call s:FileSearchAutocmdDeferred()

  return ''
endfunction " }}}

function! s:FileSelect(action) " {{{
  if exists('b:results') && !empty(b:results)
    let &updatetime = g:ag_prompt_default_updatetime

    let file = b:results[b:selection - 1]
    let bufnum = b:bufnum
    let winnr = b:winnr
    let winrestcmd = b:winrestcmd

    " close prompt windows
    exec 'bdelete ' . b:results_bufnum
    exec 'bdelete ' . bufnr('%')

    " reset windows to pre-prompt sizes
    exec winrestcmd

    " open the selected result
    exec winnr . "wincmd w"

    let cmd = a:action
    let winnr = bufwinnr(bufnr('^' . file . '$'))
    if winnr != -1 && cmd == 'edit'
      if winnr != winnr()
        exec winnr . "winc w"
        doautocmd WinEnter
      endif
    else
      " if splitting and the buffer is a unamed empty buffer, then switch to an
      " edit.
      if cmd == 'split' && expand('%') == '' &&
       \ !&modified && line('$') == 1 && getline(1) == ''
        let cmd = 'edit'
      endif
      exec cmd . ' ' . escape(file, ' ')
      echom cmd . ' ' . escape(file, ' ')
    endif

    call feedkeys("\<esc>", 'n')
    doautocmd WinEnter
  endif
  return ''
endfunction " }}}

function! s:Help() " {{{
  let winnr = winnr()
  noautocmd exec bufwinnr(b:results_bufnum) . 'winc w'

  let orig_bufnr = bufnr('%')
  let name = expand('%') . ' Help'

  " close the help buffer if it's open
  if bufwinnr(name) != -1
    exec 'bd ' . bufnr(name)

  " otherwise open and populate the help buffer
  else
    silent! noautocmd exec "50 vnew " . escape(name, ' ')
    setlocal winfixwidth
    setlocal nowrap
    setlocal noswapfile nobuflisted nonumber
    setlocal nospell norelativenumber
    setlocal buftype=nofile bufhidden=delete
    setlocal modifiable noreadonly
    silent 1,$delete _
    call append(1, [
      \ '<esc> - close the ag prompt + results',
      \ '<tab>, <down> - select the next file',
      \ '<s-tab>, <up> - select the previous file',
      \ '<cr> - open selected file w/ default action (' . g:AgPromptDefaultAction . ')',
      \ '<c-e> - open with :edit',
      \ '<c-s> - open in a split window',
      \ '<c-t> - open in a new tab',
      \ '<c-h> - toggle help buffer',
    \ ])
    retab
    silent 1,1delete _
    setlocal nomodified nomodifiable readonly

    let help_bufnr = bufnr('%')
    augroup ag_prompt_help_buffer
      autocmd! BufWinLeave <buffer>
      autocmd BufWinLeave <buffer> nested autocmd! ag_prompt_help_buffer * <buffer>
      exec 'autocmd BufWinLeave <buffer> nested ' .
        \ 'autocmd! ag_prompt_help_buffer * <buffer=' . orig_bufnr . '>'
      exec 'autocmd! BufWinLeave <buffer=' . orig_bufnr . '>'
      exec 'autocmd BufWinLeave <buffer=' . orig_bufnr . '> nested bd ' . help_bufnr
    augroup END
  endif

  " return back to the prompt window
  exec winnr . 'winc w'

  return ''
endfunction " }}}

function! s:Ag(pattern) " {{{
  let results = []
  if len(a:pattern) >= 5
    let command = 'ag --search-files '
    if g:AgPromptCaseInsensitive == 'always' ||
     \ (a:pattern !~# '[A-Z]' && g:AgPromptCaseInsensitive != 'never')
      let command .= '-i '
    else
      let command .= '-s '
    endif
    let command .= '-g "' . a:pattern . '" | sort'
    let results = split(system(command), "\n")
  endif
  return results
endfunction " }}}

let &cpo = s:save_cpo

" vim:ft=vim:fdm=marker
