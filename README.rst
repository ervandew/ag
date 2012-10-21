.. Copyright (c) 2012, Eric Van Dewoestine
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

ag.vim is a plugin for vim which allows you to search using the `silver
searcher (ag)`_.

=====
Usage
=====

::

  :Ag [options] pattern [directory]

When running :Ag some vim based regex atoms will be converted to their PCRE
equivalent so that you can do something like hit '*' on a word in vim, then run
``:Ag <c-r>/`` to search for that word with ag:

- Word boundaries: ``\<Word\>`` will be converted to ``\bWord\b``
- Non-greedy matches: ``foo.\{-}bar`` will be converted to ``foo.*?bar``

.. _silver searcher (ag): https://github.com/ggreer/the_silver_searcher
