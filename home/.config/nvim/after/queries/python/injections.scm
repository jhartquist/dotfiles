;; extends

; `# language=<lang>` comment on the line before a string assignment
; highlights the string as <lang>
((comment) @injection.language
  .
  (expression_statement
    (assignment
      right: (string
        (string_content) @injection.content)))
  (#lua-match? @injection.language "^#%s*language=")
  (#gsub! @injection.language "^#%s*language=%s*([%w_-]+).*$" "%1"))

; same, when the comment opens a body (tree-sitter puts it outside the block)
((comment) @injection.language
  .
  (block
    .
    (expression_statement
      (assignment
        right: (string
          (string_content) @injection.content))))
  (#lua-match? @injection.language "^#%s*language=")
  (#gsub! @injection.language "^#%s*language=%s*([%w_-]+).*$" "%1"))
