.. Copyright (c) 2012 - 2022, Eric Van Dewoestine
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

  :Ag [options] pattern [directory]

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

=============
Configuration
=============

* **g:AgSmartCase** (default: 0) - When set to a non-0 value, **:Ag** will run
  ``ag`` with the ``--smart-case`` option.

======
Extras
======

ag.vim also registers itself as a backend for `eclim's`_ `:LocateFile`_
functionality. You can even set ag as the default for non-eclim projects by
adding the following to your vimrc:

::

  let g:EclimLocateFileNonProjectScope = 'ag'

Note: requires eclim 2.2.5 or greater (or 1.7.13 or greater for Indigo users).

.. _silver searcher (ag): https://github.com/ggreer/the_silver_searcher
.. _eclim's: http://eclim.org
.. _\:LocateFile: http://eclim.org/vim/core/locate.html
