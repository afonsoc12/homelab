"use strict";

(() => {
    // Open while the click still grants popup permission. The stock Plex stage
    // requests a PIN asynchronously, then reuses this exact named window.
    function openPlex(url = "about:blank") {
        const width = 550;
        const height = 700;
        const left = Math.max(0, (screen.width - width) / 2);
        const top = Math.max(0, (screen.height - height) / 4);
        return window.open(url, "plex auth", `popup,scrollbars=yes,width=${width},height=${height},left=${left},top=${top}`);
    }

    window.addEventListener("click", (event) => {
        if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        const path = event.composedPath();
        const start = path.find((node) => node instanceof Element && node.matches("a.hl-plex, button[name='source-plex']"));
        if (start) {
            if (start.hasAttribute("disabled") || event.defaultPrevented) return;
            const popup = openPlex();
            if (popup) {
                popup.document.title = "Opening Plex sign-in";
                popup.document.body.textContent = "Opening Plex sign-in…";
            }
            return;
        }
        const plexStage = path.find((node) => node instanceof Element && node.localName === "ak-flow-source-plex");
        const retry = path.find((node) => node instanceof Element && node.matches("button.pf-m-primary"));
        if (plexStage && retry && plexStage.authUrl) {
            event.preventDefault();
            event.stopImmediatePropagation();
            openPlex(plexStage.authUrl);
        }
    }, { capture: true });

    // Native stages render into open shadow roots. Observe each root so helper
    // copy also survives Lit re-renders; never copy or store challenge secrets.
    const observed = new WeakSet();
    const emailMessage = 'Open your email and click "Confirm Account" to continue. Check your spam or junk folder if the email is missing. This page will wait until you open the link.';
    const duoMessage = 'Open Duo Mobile, choose Add, then scan this QR code. On the same phone, tap "Duo activation" instead. After activation, click "Check status". Other authenticator apps cannot scan this Duo activation code.';

    function updateCopy(root, inPlexStage) {
        if (inPlexStage) {
            const text = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
            while (text.nextNode()) {
                if (/^Waiting for authentication(?:\.\.\.|…)?$/i.test(text.currentNode.textContent.trim())) {
                    text.currentNode.textContent = "";
                }
            }
        }
        if (root.host?.localName === "ak-stage-email") {
            const paragraph = root.querySelector(".pf-c-form__group > p");
            if (paragraph && paragraph.textContent !== emailMessage) paragraph.textContent = emailMessage;
        }
        if (root.host?.localName === "ak-stage-authenticator-duo") {
            const form = root.querySelector("form");
            if (form && !form.querySelector("[data-homelab-duo-help]")) {
                const help = document.createElement("p");
                help.dataset.homelabDuoHelp = "";
                help.textContent = duoMessage;
                form.prepend(help);
            }
            const activation = root.querySelector("a[href^='duo:']");
            if (activation && activation.textContent !== "Open Duo Mobile on this phone") {
                activation.textContent = "Open Duo Mobile on this phone";
            }
        }
    }

    function observe(root, inPlexStage = false) {
        inPlexStage ||= root.host?.localName === "ak-flow-source-plex";
        if (!observed.has(root)) {
            observed.add(root);
            new MutationObserver(() => observe(root, inPlexStage)).observe(root, { childList: true, subtree: true });
        }
        updateCopy(root, inPlexStage);
        for (const element of root.querySelectorAll("*")) {
            if (element.shadowRoot) observe(element.shadowRoot, inPlexStage);
        }
    }

    observe(document);
    for (const name of ["ak-flow-executor", "ak-stage-email", "ak-stage-authenticator-duo", "ak-flow-source-plex"]) {
        customElements.whenDefined(name).then(() => requestAnimationFrame(() => observe(document)));
    }
})();
