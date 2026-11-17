# Keep a separate name field for invitation enrollment so invitees can enter
# their own profile name without requiring it in invitation fixed_data.
resource "authentik_stage_prompt_field" "invitation_name" {
  name                     = "Homelab - Invitation Name"
  field_key                = "name"
  label                    = "Name"
  type                     = "text"
  order                    = 201
  required                 = true
  initial_value            = ""
  initial_value_expression = false
  placeholder              = ""
  placeholder_expression   = false
  sub_text                 = "Enter the name you want on your account."
}
