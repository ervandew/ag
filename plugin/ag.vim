" Author: Eric Van Dewoestine

" Description: {{{
"   Plugin for invoking the silver searcher (ag), using :Ag, and adding the
"   result to vim's quickfix.  Also performs some simple conversions from vim
"   regex patterns to perl's (\{-} to *?, \<foo\> to \bfoo\b).
" }}}

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

if v:version < 700
  finish
endif

let s:save_cpo=&cpo
set cpo&vim

" Global Variables {{{
if !exists("g:AgSmartCase")
  let g:AgSmartCase = 0
endif

" The default action to use when opening files from :AgPrompt
if !exists("g:AgPromptDefaultAction")
  let g:AgPromptDefaultAction = 'edit'
endif

" Sets under what condition will the search be case insensitive, one of:
" - lower: when the pattern is all lower case
" - never: never case insensitive
" - always: aways case insensitive
if !exists("g:AgPromptCaseInsensitive")
  let g:AgPromptCaseInsensitive = 'lower'
endif

" }}}

" Command Declarations {{{
if exists(":Ag") != 2
  command -bang -nargs=* -complete=customlist,ag#search#Complete
    \ Ag :call ag#search#Ag(<q-args>, 0, '<bang>')
endif
if exists(":AgRelative") != 2
  command -bang -nargs=* -complete=customlist,ag#search#CompleteRelative
    \ AgRelative :call ag#search#Ag(<q-args>, 1, '<bang>')
endif
if exists(":AgPrompt") != 2
  command -nargs=0 AgPrompt :call ag#prompt#Open()
endif
" }}}

let &cpo = s:save_cpo

" vim:ft=vim:fdm=marker
