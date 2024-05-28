.. Copyright (c) 2012 - 2024, Eric Van Dewoestine
   All rights reserved.

   Redistribution and use of this software in source and binary forms, with
   or without modification, are permitted provided that the following
   conditions are met:

   * Redistributions of source code must retain the above
     copyright notice, this list of conditions and the
     following disclaimer.

   * Redistributions in binary form must reproduce the above
     copyright notice, this list of conditions and the
     following disclaimer in the documentation and/or other
     materials provided with the distribution.

   * Neither the name of Eric Van Dewoestine nor the names of its
     contributors may be used to endorse or promote products derived from
     this software without specific prior written permission of
     Eric Van Dewoestine.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

.. _overview:

========
Overview
========

ag.vim is a plugin for vim which allows you to search over files using the
`silver searcher (ag)`_.

=====
Usage
=====

::

  :Ag [options] [pattern] [directory]

Note: When no arguments are supplied, the the word under the cursor is searched,
honoring the case of that word.

The **:Ag** command provides several features to make running ag easier:

* **:Ag** supports command completion of:

  - **patterns from your vim search history:** You can hit ``<tab>`` when
    starting to run ``:Ag`` and you can choose from a list of 10 of your most
    recent vim searches. A common use case while editing code could be running
    ``/something`` to search for occurrences in the current file, then running
    ``:Ag <tab>`` to search for the pattern across all files.
  - **ag options:** If you type ``-`` and then hit ``<tab>``, you can scroll
    through all the ag.vim supported ag options.
  - **file/directory name to search in:** Once you've supplied a search
    pattern, the next argument to ``:Ag`` is an optional directory or file to
    search in and you can make use of ``<tab>`` completion to choose that file or
    directory.

  Note: I highly recommend turning on vim's wildmenu support to get the most
  out of vim's command completion:

  ::

    set wildmenu
    set wildmode=longest:full,full

* Some vim based regex atoms in the supplied pattern will be converted to their
  PCRE equivalent so that you can do something like hit ``*`` on a word in vim,
  then run ``:Ag <tab>`` or ``:Ag <c-r>/`` to search for that word with ag
  without having to convert the pattern yourself:

  - Word boundaries: ``\<Word\>`` will be converted to ``\bWord\b``
  - Non-greedy matches: ``foo.\{-}bar`` will be converted to ``foo.*?bar``

* The directory argument supplied to ``:Ag`` supports simple glob patterns. To
  simplify filtering of your search by file extension, you can pass a glob
  pattern to ``:Ag`` and it will convert it to a file search regex for ag. For
  example, to limit your search to only python files starting in some directory,
  you could run:

  ::

    :Ag FooBar foo/*.py

  Which will search all .py files directly in the 'foo' directory.

  To search .py files in all the nested sub-directories of 'foo' as well as
  those .py files directly under 'foo' you can use:

  ::

    :Ag FooBar foo/***.py

  If you want to search all the sub-directories but skip .py files directly
  under 'foo' you can use:

  ::

    :Ag FooBar foo/**/*.py

* If you use ``:Ag -g`` with no other arguments, then it will attempt to extract
  a file name from under the cursor and search for that and either:

  - Open the file in the current window if there is only 1 result.

      Note: If you supply a bang (``:Ag! -g``), then the result will be opened
      in a new split window.

  - Open the quickfix window if there are multiple results.

  You can replace the built in vim mappings to go to a file by adding the
  following to your .vimrc:

  ::

    nmap gf :Ag -g<cr>
    nmap gF :Ag! -g<cr>

The **:AgPrompt** command provides a prompt from which you can perform a fuzzy
search on file names.

  ::

    :AgPrompt

From the prompt you can start typing portions of a file name you are looking for
and results will be populated in another window.

The following keybindings are available from the prompt:

  - <esc> - close the ag prompt + results
  - <tab>, <down> - select the next file
  - <s-tab>, <up> - select the previous file
  - <cr> - open selected file w/ default action
  - <c-e> - open with :edit
  - <c-s> - open in a split window
  - <c-t> - open in a new tab
  - <c-h> - toggle help buffer

Note: To use <c-s> in vim running in a terminal, you may need to add the
following to your vimrc to prevent the terminal from suspending display updates:

  ::

    silent !stty -ixon

=============
Configuration
=============

* **:Ag**

  - **g:AgSmartCase** (default: 0) - When set to a non-0 value, **:Ag** will run
    ``ag`` with the ``--smart-case`` option.

* **:AgPrompt**

  - **g:AgPromptDefaultAction** (default: 'edit') - The default command used to
    open the selected file.
  - **g:AgPromptCaseInsensitive** (default: 'lower') - Sets under what condition
    will the search be case insensitive, one of:

    - lower: when the pattern is all lower case
    - never: never case insensitive
    - always: aways case insensitive

======
Extras
======

**ag#search#FindFile(path, cmd)** - A globally available function that other
scripts can use to find a file and open it with the supplied command. This can
be useful for custom mappings that need to first translate a file name from a
finally artifact to the source file (Eg. a .css file to the .scss source).

.. _silver searcher (ag): https://github.com/ggreer/the_silver_searcher
