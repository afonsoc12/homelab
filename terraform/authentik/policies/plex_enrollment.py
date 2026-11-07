# Authentik expression policy: validate, but do not consume, the invitation.
from uuid import UUID

from authentik.stages.invitation.models import Invitation
from django.utils.timezone import now

query = http_request.session.get("authentik/flows/get", {})
profile = context.get("prompt_data", {})
token = query.get("itoken") or query.get("token") or profile.get("token")
if not token:
    return False
try:
    invitation_id = UUID(str(token))
except (ValueError, TypeError, AttributeError):
    return False

invitation = Invitation.objects.filter(
    pk=invitation_id,
    flow__slug="homelab-plex-enrollment",
    single_use=True,
    expiring=True,
).first()
if (
    invitation is None
    or invitation.expires is None
    or invitation.expires <= now()
    or invitation.fixed_data
):
    return False

if not ak_is_sso_flow:
    # Only the source-selection stage can run before Plex proves identity.
    # A separate deny stage blocks any attempt to proceed without that proof.
    return True

source = context.get("source")
connection = context.get("goauthentik.io/sources/connection")
if not (
    source is not None
    and source.enabled
    and source.slug == "plex"
    and connection is not None
    and connection.source_id == source.pk
    and connection.identifier
):
    return False

# The Plex callback redirects without the original invitation query string.
# Keep its token in the server-side flow plan for the native Invitation stage,
# which revalidates and consumes the single-use invitation after Plex login.
profile["token"] = str(invitation_id)
return True
