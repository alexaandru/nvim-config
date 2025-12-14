;; picker/config.fnl - Configuration for extui-based picker

(local M {})

;; Default configuration
(set M.default
     {:opts {:preselect true
             :bottom true
             :shrink true
             :promptprefix "›"
             :prompt-title true
             :pointer "▶"
             :marker "▌"
             :use-icons (if _G.MiniIcons true false)}
      :win {:height 0.4
            :hide-statusline true
            :preview-opts nil
            :preview-default true}
      :mappings {:<Down> :down
                 :<Up> :up
                 :<C-n> :down
                 :<C-p> :up
                 :<CR> :accept
                 :<Esc> :cancel
                 :<Tab> :mark
                 :<Right> :select
                 :<Left> :deselect
                 :<C-l> :toggle-preview
                 :<C-u> :page-up
                 :<C-d> :page-down
                 :<PageUp> :page-up
                 :<PageDown> :page-down
                 :<M-k> :preview-scroll-up
                 :<M-j> :preview-scroll-down
                 :<ScrollWheelUp> :up
                 :<ScrollWheelDown> :down
                 :<C-q> :setqflist
                 :<M-CR> :vsplit
                 :<C-S-CR> :split}})

;; Current config (set via setup)
(set M.config {})

;; Deep merge tables, with special handling for mappings
(fn tmerge [tdefault toverride]
  (if (= toverride nil)
      tdefault
      (or (= tdefault vim.NIL) (vim.islist tdefault))
      toverride
      (vim.tbl_isempty tdefault)
      toverride
      (: (vim.iter (pairs tdefault)) :fold
         {}
         (fn [tnew k v]
           (if (= (. toverride k) nil)
               (tset tnew k v)
               (not= (type v) (type (. toverride k)))
               (tset tnew k v)
               (= (type v) :table)
               (tset tnew k (tmerge v (. toverride k)))
               (tset tnew k (. toverride k)))
           tnew))))

;; Merge config with defaults, special case for mappings
(fn M.merge [tdefault toverride]
  (let [defaults (vim.deepcopy tdefault true)
        mappings tdefault.mappings]
    (set defaults.mappings vim.NIL)
    (let [t (tmerge defaults toverride)]
      (set t.mappings (or toverride.mappings mappings))
      t)))

;; Get merged config
(fn M.get []
  (M.merge M.default M.config))

;; Override defaults with custom config
(fn M.override [cfg]
  (M.merge M.default cfg))

;; Set global config
(fn M.set [cfg]
  (set M.config cfg))

M
