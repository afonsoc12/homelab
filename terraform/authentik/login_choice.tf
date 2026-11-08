# Native Authentik prompt and identification stages provide the login choice.
# This flow only selects a provider; it never creates an authenticated session.
locals {
  login_choice_markup = <<-HTML
    <style>
    .pf-c-form:has(#hl-login-options) > .pf-m-action { display: none !important; }
    #hl-login-options { display: grid; gap: 14px; width: 100%; margin: 4px 0 8px; }
    #hl-login-options .hl-login-intro { margin: 0 0 12px; color: #9da7b7; font-size: 14px; line-height: 1.6; }
    #hl-login-options .hl-login-method {
      display: flex; align-items: center; gap: 16px; padding: 18px;
      border: 1px solid #30343e; border-radius: 13px; background: #13171e;
      color: #f5f7fa !important; text-decoration: none !important;
      transition: border-color .16s ease, background .16s ease, transform .16s ease;
    }
    #hl-login-options .hl-login-method:hover { border-color: var(--provider); background: #191e27; transform: translateY(-1px); }
    #hl-login-options .hl-login-method:focus-visible { outline: 2px solid var(--provider); outline-offset: 4px; }
    #hl-login-options .hl-authentik { --provider: #fd4b2d; }
    #hl-login-options .hl-plex { --provider: #e5a00d; }
    #hl-login-options .hl-login-mark { display: grid; place-items: center; width: 46px; height: 46px; flex: 0 0 46px; border-radius: 11px; }
    #hl-login-options .hl-authentik .hl-login-mark { background: #fd4b2d18; }
    #hl-login-options .hl-plex .hl-login-mark { background: #e5a00d18; }
    #hl-login-options .hl-provider-logo { width: 29px; height: 29px; display: block; }
    #hl-login-options .hl-login-copy { display: grid; gap: 5px; }
    #hl-login-options .hl-login-name { color: #f5f7fa; font-size: 16px; line-height: 1.3; font-weight: 650; letter-spacing: -.015em; }
    #hl-login-options .hl-login-detail { color: #8f9baa; font-size: 12px; line-height: 1.4; }
    #hl-login-options .hl-login-arrow { color: #6d788a; margin-left: auto; font-size: 23px; line-height: 1; font-weight: 300; }
    #hl-login-options .hl-login-method:hover .hl-login-arrow { color: var(--provider); }
    #hl-login-options .hl-login-security { display: flex; align-items: center; justify-content: center; gap: 7px; margin: 15px 0 0; color: #768293; font-size: 11px; }
    #hl-login-options .hl-login-security svg { width: 13px; height: 13px; }
    @media (prefers-reduced-motion: reduce) { #hl-login-options .hl-login-method { transition: none; } }
    </style>
    <span id="hl-login-options">
      <span class="hl-login-intro">Choose how you’d like to sign in.</span>
      <a class="hl-login-method hl-authentik" href="__AUTHENTIK_URL__">
        <span class="hl-login-mark"><svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" viewBox="0 0 512 512" aria-hidden="true" class="hl-provider-logo"><path d="M511.8 131.1c-.4-3.6-1.1-7.2-2-10.8-.3-1.1-.7-2.3-1-3.4-.1-.2-.2-.5-.3-.8-.1-.6-.3-1.1-.5-1.7s-.4-1.2-.6-1.7c-.2-.6-.5-1.2-.7-1.8-.3-.6-.6-1.2-.8-1.8-2-4.8-4.4-9.3-7.3-13.6l-.1-.1c-.8-1.1-1.5-2.1-2.3-3.2-.7-.9-1.3-1.8-2-2.6-.8-.9-1.6-1.9-2.4-2.8-.7-.9-1.6-1.8-2.4-2.6-3.4-3.4-7.1-6.6-11-9.4-.9-.6-1.8-1.3-2.8-1.9-1.1-.7-2.2-1.3-3.3-2-2.1-1.2-4.3-2.4-6.5-3.4-.7-.4-1.4-.7-2.1-1-3.1-1.3-6.2-2.5-9.4-3.4-1.2-.4-2.4-.7-3.7-1-.6-.1-1.2-.3-1.8-.4-3.6-.8-7.2-1.3-10.9-1.6l-1.6-.1h-.8c-1.2-.1-2.5-.1-3.7-.1H200.5c-1.3 0-2.5 0-3.7.1h-.8l-1.6.1c-3.7.3-7.3.8-10.9 1.6-.6.1-1.2.2-1.8.4-1.2.3-2.5.6-3.7 1-3.2.9-6.3 2.1-9.4 3.4-.7.3-1.4.7-2.1 1-2.3 1-4.4 2.2-6.5 3.4-1.1.6-2.2 1.3-3.3 2-.9.6-1.9 1.2-2.8 1.9-3.4 2.4-6.6 5.1-9.6 8-.5.5-1 .9-1.4 1.4l-.1.1c-.8.8-1.6 1.7-2.4 2.6s-1.6 1.9-2.4 2.8c-.7.9-1.3 1.7-2 2.6-.8 1.1-1.6 2.1-2.3 3.2l-.1.1c-2.9 4.3-5.3 8.9-7.3 13.6-.3.6-.6 1.2-.8 1.8s-.5 1.2-.7 1.8-.4 1.2-.6 1.7c-.1.6-.3 1.1-.5 1.7-.1.2-.2.5-.3.8-.4 1.1-.7 2.3-1 3.4-.9 3.5-1.6 7.1-2 10.8-.3 3-.5 6.1-.5 9.2v94.4c-.8-1.1-1.5-2.2-2.3-3.2-12.6-17.1-31.4-34.3-52.3-34.3-24 0-45.9 13.2-57.3 34.2h-.1C-15.9 273 17 329 65.3 327.8c37.4 0 68.2-55.5 68.2-65.3 0-3.6-4.2-13.5-11.5-24.5h131.6v-78.2h26.3v32.4h17.9v-32.4h28.7v19h17.9v-19h34v139H120v72.8c0 44.3 36 80.4 80.4 80.4h34.1v-78.8h163V452h34.1c44.3 0 80.4-36.1 80.4-80.4V140.3c0-3.1-.2-6.1-.2-9.2M38.2 231.6c13.6-11.6 33.1-15 47.2 0h.1c10.7 9.7 19.9 23.6 23.2 30.8-41.9 87.5-115.2 13-70.5-30.8" style="fill:#fd4b2d" /></svg></span>
        <span class="hl-login-copy"><span class="hl-login-name">Log in with Authentik</span><span class="hl-login-detail">Use your homelab account</span></span>
        <span class="hl-login-arrow" aria-hidden="true">&#8250;</span>
      </a>
      <a class="hl-login-method hl-plex" href="__PLEX_URL__">
        <span class="hl-login-mark"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" aria-hidden="true" class="hl-provider-logo"><rect width="512" height="512" fill="#282a2d" rx="15%" /><path fill="#e5a00d" d="M256 70H148l108 186-108 186h108l108-186z" /></svg></span>
        <span class="hl-login-copy"><span class="hl-login-name">Log in with Plex</span><span class="hl-login-detail">Continue with your Plex account</span></span>
        <span class="hl-login-arrow" aria-hidden="true">&#8250;</span>
      </a>
      <span class="hl-login-security"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true"><rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/></svg>Protected with two-factor authentication</span>
    </span>
  HTML
}

resource "authentik_flow" "login_choice" {
  name               = "Homelab - Login Choice"
  slug               = "homelab-login-choice"
  title              = "Welcome back"
  designation        = "authentication"
  authentication     = "require_unauthenticated"
  policy_engine_mode = "all"
  denied_action      = "message_continue"
  layout             = "stacked"
}

resource "authentik_stage_prompt_field" "login_choice" {
  name                     = "Homelab - Login Methods"
  field_key                = "login_methods"
  label                    = ""
  type                     = "static"
  order                    = 0
  required                 = false
  placeholder              = ""
  placeholder_expression   = false
  initial_value_expression = true
  initial_value            = <<-PY
    from html import escape
    from urllib.parse import urlencode

    query = urlencode(dict(http_request.session.get("authentik/flows/get", {}).items()))
    markup = ${jsonencode(local.login_choice_markup)}
    authentik_url = "/if/flow/${authentik_flow.login.slug}/?" + query
    plex_url = "/if/flow/${authentik_flow.plex_entry.slug}/?" + query
    return markup.replace("__AUTHENTIK_URL__", escape(authentik_url, quote=True)).replace("__PLEX_URL__", escape(plex_url, quote=True))
  PY
}

resource "authentik_stage_prompt" "login_choice" {
  name   = "Homelab - Login Choice"
  fields = [authentik_stage_prompt_field.login_choice.id]
}

resource "authentik_flow_stage_binding" "login_choice" {
  target                  = authentik_flow.login_choice.uuid
  stage                   = authentik_stage_prompt.login_choice.id
  order                   = 10
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  invalid_response_action = "retry"
}

resource "authentik_flow" "plex_entry" {
  name               = "Homelab - Plex Sign In"
  slug               = "homelab-plex-sign-in"
  title              = "Log in with Plex"
  designation        = "authentication"
  authentication     = "require_unauthenticated"
  policy_engine_mode = "all"
  denied_action      = "message_continue"
  layout             = "stacked"
}

resource "authentik_stage_identification" "plex_entry" {
  name                = "Homelab - Plex Sign In"
  user_fields         = []
  sources             = [authentik_source_plex.plex.uuid]
  show_source_labels  = true
  pretend_user_exists = false
  password_stage      = ""
  passwordless_flow   = ""
  enrollment_flow     = ""
  recovery_flow       = ""
  webauthn_stage      = ""
}

resource "authentik_flow_stage_binding" "plex_entry" {
  target                  = authentik_flow.plex_entry.uuid
  stage                   = authentik_stage_identification.plex_entry.id
  order                   = 10
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  invalid_response_action = "retry"
}

# Submitting the chooser or proceeding past source selection without actually
# authenticating must not complete an authentication flow.
resource "authentik_stage_deny" "login_choice" {
  name = "Homelab - Login Method Required"
}

resource "authentik_flow_stage_binding" "login_choice_deny" {
  for_each = {
    choice = authentik_flow.login_choice.uuid
    plex   = authentik_flow.plex_entry.uuid
  }
  target                  = each.value
  stage                   = authentik_stage_deny.login_choice.id
  order                   = 100
  evaluate_on_plan        = false
  re_evaluate_policies    = true
  invalid_response_action = "retry"
}
