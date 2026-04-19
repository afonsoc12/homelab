document$.subscribe(function () {
  const logo = document.querySelector(".md-header__button.md-logo");
  const title = document.querySelector(".md-header__title");
  if (logo && title && !title.querySelector("a")) {
    title.style.cursor = "pointer";
    title.addEventListener("click", function (e) {
      if (!e.target.closest("a")) {
        window.location.href = logo.getAttribute("href");
      }
    });
  }
});
