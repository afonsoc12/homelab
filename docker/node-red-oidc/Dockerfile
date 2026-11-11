FROM nodered/node-red:5.0.9@sha256:2ccd38b4066648bd5e17430c50a2f8102c566a82fd4f2fc5c342e61664d6896f

USER root
WORKDIR /opt/node-red-oidc
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
    && chown -R node-red:node-red /opt/node-red-oidc
COPY auth.js settings.js ./

USER node-red
WORKDIR /usr/src/node-red
CMD ["npm", "--no-update-notifier", "--no-fund", "start", "--cache", "/data/.npm", "--", "--userDir", "/data", "--settings", "/opt/node-red-oidc/settings.js"]
