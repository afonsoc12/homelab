# Invitation fixed_data is merged into prompt_data by the invitation stage.
# Use a separate field so account settings can retain its editable name input.
# Authentik replaces submitted read-only values with their server-side defaults.
resource "authentik_stage_prompt_field" "invitation_name" {
  name                     = "Homelab - Invitation Name"
  field_key                = "name"
  label                    = "Name"
  type                     = "text_read_only"
  order                    = 201
  required                 = true
  initial_value            = ""
  initial_value_expression = false
  placeholder              = ""
  placeholder_expression   = false
  sub_text                 = "Set by the person who invited you. Contact them if it needs correcting."
}

# Read-only fields do not enforce required=True. Fail validation for invitations
# without an administrator-supplied name, and verify against the invitation
# rather than trusting any value supplied by the browser.
resource "authentik_policy_expression" "invitation_name" {
  name              = "Homelab - Validate Invitation Name"
  execution_logging = false
  expression        = <<-PY
    plan = context.get("flow_plan")
    invitation = plan.context.get("invitation") if plan else None
    fixed_data = invitation.fixed_data if invitation else {}
    name = fixed_data.get("name")
    if not isinstance(name, str) or not name.strip():
        ak_message("This invitation is missing your name. Ask the person who invited you for a corrected invitation.")
        return False
    if context.get("prompt_data", {}).get("name") != name:
        ak_message("Your name must match the invitation. Restart enrollment with the invitation link.")
        return False
    return True
  PY
}
