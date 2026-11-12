const { createHash, timingSafeEqual } = require("node:crypto");
const client = require("openid-client");
const { Strategy } = require("openid-client/passport");

class NodeRedOIDCStrategy extends Strategy {
    authorizationRequestParams(request, options) {
        const params = super.authorizationRequestParams(request, options);
        params.set("state", client.randomState());
        params.set("nonce", client.randomNonce());
        return params;
    }
}

module.exports = function configureAuth(config) {
    for (const field of ["issuer", "authorization_endpoint", "token_endpoint", "jwks_uri"]) {
        if (new URL(config.metadata[field]).protocol !== "https:") {
            throw new Error("Node-RED OIDC endpoints require HTTPS");
        }
    }
    if (new URL(config.callbackURL).protocol !== "https:") {
        throw new Error("Node-RED OIDC callback requires HTTPS");
    }

    const users = new Map();
    for (const user of Object.values(config.subjects)) {
        if (!user.username || !["*", "read"].includes(user.permissions) || users.has(user.username)) {
            throw new Error("Node-RED OIDC requires unique existing usernames and explicit permissions");
        }
        users.set(user.username, { username: user.username, permissions: user.permissions });
    }

    const oidc = new client.Configuration(config.metadata, config.clientID, config.clientSecret);
    client.enableNonRepudiationChecks(oidc);
    const recoveryHash = createHash("sha256").update(config.recovery.token).digest();

    return {
        type: "strategy",
        sessionExpiryTime: 28800,
        strategy: {
            name: "authentik",
            label: "Sign in with Authentik",
            icon: "fa-lock",
            strategy: NodeRedOIDCStrategy,
            options: {
                name: "authentik",
                config: oidc,
                callbackURL: config.callbackURL,
                scope: "openid",
                verify(tokens, done) {
                    const claims = tokens.claims();
                    const user = claims && Object.hasOwn(config.subjects, claims.sub)
                        ? config.subjects[claims.sub]
                        : undefined;
                    done(null, user ? { username: user.username } : false);
                }
            }
        },
        users(username) {
            return Promise.resolve(users.get(username) || null);
        },
        tokens(token) {
            const supplied = createHash("sha256").update(token).digest();
            return Promise.resolve(timingSafeEqual(supplied, recoveryHash)
                ? { username: config.recovery.username, permissions: "*" }
                : null);
        }
    };
};
