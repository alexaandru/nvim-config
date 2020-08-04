scriptencoding utf-8

func! ListSnippets(A, L, P)
  return systemlist('ls ' . stdpath('data') . '/snippets/')
endf

com! -nargs=1 -complete=customlist,ListSnippets Snippet silent exe '-1read ' . stdpath('data') . '/snippets/' . <q-args>
com! -nargs=1 -complete=customlist,ListSnippets OpenSnippet silent exe 'new ' . stdpath('data') . '/snippets/' . <q-args>

nno <silent> \html     <Cmd>Snippet skeleton.html<CR>o
