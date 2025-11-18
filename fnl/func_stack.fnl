(fn node-text [n] (vim.treesitter.get_node_text n 0))

(fn is-func-like [t]
  (or (t:find :function) (t:find :method) (t:find :lambda) (= t "func_literal")
      (= t "closure_expression") (= t "def") (= t "fn_form")))

(fn try-name [node]
  (or (let [name-field (node:field :name)]
        (when (and name-field (. name-field 1))
          (node-text (. name-field 1))))
      (do
        (var result nil)
        (each [child (node:iter_children) &until result]
          (let [ct (child:type)]
            (when (or (= ct "identifier") (= ct "name") (= ct "symbol")
                      (= ct "field_identifier") (= ct "property_identifier"))
              (set result (node-text child)))))
        result)))

(fn []
  (when (pcall vim.treesitter.get_parser 0)
    (local node (vim.treesitter.get_node {:ignore_injections false}))
    (when node
      (local inner-to-outer {})
      (var cur node)
      (while cur
        (when (is-func-like (cur:type))
          (table.insert inner-to-outer {:name (try-name cur) :node cur}))
        (set cur (cur:parent)))
      (when (not= (length inner-to-outer) 0)
        (var anon-n 0)
        (for [i 1 (length inner-to-outer)]
          (when (not (. inner-to-outer i :name)) (set anon-n (+ anon-n 1))
            (tset (. inner-to-outer i) :anon anon-n)))
        (let [parts {}]
          (for [i (length inner-to-outer) 1 (- 1)]
            (let [it (. inner-to-outer i)]
              (if (and it.name (not= it.name ""))
                  (table.insert parts (.. it.name "()"))
                  (table.insert parts (: "anon<%d>()" :format it.anon)))))
          (table.concat parts " -> "))))))
