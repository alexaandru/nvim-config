{:cmd [:vscode-json-language-server :--stdio]
 :filetypes [:json :jsonc]
 :init_options {:provideFormatter true}
 :root_markers [:.git]
 :settings {:documentFormatting false}
 :on_attach #(set $.server_capabilities.documentFormattingProvider false)}
