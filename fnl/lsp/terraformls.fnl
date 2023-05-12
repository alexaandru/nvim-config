; https://github.com/hashicorp/terraform-ls/blob/main/docs/SETTINGS.md
{:cmd [:terraform-ls :serve]
 :filetypes [:terraform :terraform-vars :hcl]
 :root_markers [:.terraform :.git]
 :init_options {:experimentalFeatures {:validateOnSave true}}}
