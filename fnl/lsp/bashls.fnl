{:cmd [:bash-language-server :start]
 :settings {:bashIde {:globPattern (or vim.env.GLOB_PATTERN "*@(.sh|.inc|.bash|.command)")}}
 :filetypes [:bash :sh]
 :root_markers [:.git]}
