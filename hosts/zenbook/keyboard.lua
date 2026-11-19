hl.config({
  input = {
    kb_layout = "es",
    kb_variant = "",
    kb_options = "",
  },
})
for _, name in ipairs({
  "smartcloud-al68-keyboard", "smartcloud-al68-keyboard-1",
  "i-chip-yunzii-al68-2.4g", "i-chip-yunzii-al68-2.4g-keyboard", "i-chip-yunzii-al68-2.4g-keyboard-1",
}) do
  hl.device({ name = name, kb_layout = "us", kb_variant = "intl", kb_options = "", resolve_binds_by_sym = true })
end
