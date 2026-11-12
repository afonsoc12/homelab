const settings = require("/data/settings.js");
const configureAuth = require("./auth");

settings.adminAuth = configureAuth(JSON.parse(process.env.NODE_RED_OIDC_CONFIG));

module.exports = settings;
