{:cmd [:yaml-language-server :--stdio]
 :filetypes [:yaml :yaml.docker-compose :yaml.gitlab :yaml.helm-values]
 :on_init #(set $.server_capabilities.documentFormattingProvider true)
 :root_markers [:.git]
 :settings {:redhat {:telemetry {:enabled false}}
            :yaml {:format {:enable true}}}}
