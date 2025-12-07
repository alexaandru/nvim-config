;; Courtesy of @S1M0N38:
;; https://github.com/folke/sidekick.nvim/issues/158#issuecomment-3491732950
{:cmd [:amp]
 :format #(let [Text (require :sidekick.text)
                tt #(or (and ($:find "[^%w/_%.%-]") (.. "\"" $ "\"")) $)]
            (Text.transform $ tt :SidekickLocFile)
            (doto (Text.to_string $)
              (: :gsub "@([^ ]+)%s*:L(%d+):C%d+%-L(%d+):C%d+" "@%1#L%2-%3")
              (: :gsub "@([^ ]+)%s*:L(%d+):C%d+%-C%d+" "@%1#L%2")
              (: :gsub "@([^ ]+)%s*:L(%d+)%-L(%d+)" "@%1#L%2-%3")
              (: :gsub "@([^ ]+)%s*:L(%d+):C%d+" "@%1#L%2")
              (: :gsub "@([^ ]+)%s*:L(%d+)" "@%1#L%2")))}
