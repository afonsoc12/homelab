document.addEventListener("DOMContentLoaded", function () {
  var meta = document.getElementById("docs-version-meta");
  if (!meta) return;
  var a = document.createElement("a");
  a.href = meta.dataset.url;
  a.textContent = meta.dataset.version;
  a.className = "md-version-text";
  a.target = "_blank";
  var footer = document.querySelector(".md-footer-meta__inner");
  if (footer) footer.appendChild(a);
});
