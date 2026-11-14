# Security checks

Proposed changes are reviewed using dependency vulnerability checks, CodeQL,
infrastructure scanning, container scanning, and secret detection. GitHub's
security views and pull request annotations provide detailed findings; pull
request comments summarize check results.

Dependabot proposes dependency security updates through pull requests. Renovate
proposes routine dependency updates. Changes require review, and security
scanning does not automatically edit source files or merge pull requests.

Secret scanning and push protection complement the local Gitleaks hooks and
SOPS encryption. See [Secrets](secrets.md) for the encryption approach.

Learn more in the official [GitHub security documentation](https://docs.github.com/en/code-security)
and [Trivy documentation](https://trivy.dev/).
