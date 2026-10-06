(function () {
  var links = document.querySelectorAll('.site-nav a[href^="#"]');
  if (!links.length || !('IntersectionObserver' in window)) return;

  var linkById = {};
  links.forEach(function (link) {
    linkById[link.getAttribute('href').slice(1)] = link;
  });

  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      links.forEach(function (link) { link.removeAttribute('aria-current'); });
      linkById[entry.target.id].setAttribute('aria-current', 'true');
    });
  }, { rootMargin: '-20% 0px -70% 0px' });

  Object.keys(linkById).forEach(function (id) {
    var section = document.getElementById(id);
    if (section) observer.observe(section);
  });
})();
