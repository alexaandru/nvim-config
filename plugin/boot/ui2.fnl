(let [{: enable} (require :vim._core.ui2)
      target :msg
      timeout 4000]
  (enable {:enable true :msg {: target : timeout}}))
