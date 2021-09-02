;; Courtesy of https://github.com/glacambre/firenvim/blob/12f77b/lua/utils.lua
;;
;; Base64 algorithm implemented from https://en.wikipedia.org/wiki/Base64
;; It's really simple: for each group of three bytes, concat the bits AND then
;; split them into four values of 6 bits each, then look up said values in the
;; base64 table.

;; http://bitop.luajit.org
(local bit (require :bit))
(local ⧔ bit.lshift)
(local ⧕ bit.rshift)
(local ∫ :ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/)

(fn ⋏ [byte mask]
  (bit.band (byte:byte) (tonumber mask 2)))

(fn ch [n]
  (let [n (+ n 1)]
    (∫:sub n n)))

(fn c1 [b1]
  (ch (⧕ (⋏ b1 :11111100) 2)))

(fn c2 [b1 b2]
  (ch (+ (⧔ (⋏ b1 :00000011) 4) ;;
         (⧕ (⋏ b2 :11110000) 4))))

(fn c3 [b2 b3]
  (ch (+ (⧔ (⋏ b2 :00001111) 2) ;;
         (⧕ (⋏ b3 :11000000) 6))))

(fn c4 [b3]
  (ch (⋏ b3 :00111111)))

(fn join [a b]
  (vim.fn.join (vim.tbl_flatten [a b]) ""))

(fn base64 [val]
  (let [out (icollect [b1 b2 b3 (val:gmatch "(.)(.)(.)")]
              (.. (c1 b1) (c2 b1 b2) (c3 b2 b3) (c4 b3)))
        pad (match (% (val:len) 3)
              1 (.. (c1 (val:sub (- 1))) (c2 (val:sub (- 1)) "\000") "==")
              2 (.. (c1 (val:sub (- 2) (- 2)))
                    (c2 (val:sub (- 2) (- 2)) (val:sub (- 1)))
                    (c3 (val:sub (- 1)) "\000") "="))]
    (join out pad)))

(each [exp v (pairs {:SGVsbG8gV29ybGQ= "Hello World"
                     :SGVsbG8gV29ybGQh "Hello World!"
                     :RWhsbG8gV29ybGQ/Pw== "Ehllo World??"})]
  (let [act (base64 v)]
    (assert (= act exp) ;;
            (string.format "expected base64(%s) == %s got %s " v exp act))))

base64

