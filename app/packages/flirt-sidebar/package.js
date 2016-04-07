Package.describe({
  name: 'grits:flirt-sidebar',
  version: '0.0.1',
  summary: 'Bundled revision of sidebar-v2 for meteor',
  git: 'https://github.com/ecohealthalliance/flirt-sidebar',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2.1');
  api.addFiles('js/leaflet-sidebar.js', 'client');
  api.addFiles('css/leaflet-sidebar.css', 'client');
});
