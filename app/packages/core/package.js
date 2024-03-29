Package.describe({
  name: 'flirt:core',
  version: '0.0.1',
  summary: 'Flirt core package',
  git: 'git@github.com:ecohealthalliance/flirt.git',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2.1');

  api.use('coffeescript');
  api.use('blaze-html-templates', 'client');
  api.use('mquandalle:jade', 'client');
  api.use('stylus', 'client');
  api.use('reactive-var', 'client');
  api.use('reactive-dict', 'client');
  api.use('andrei:tablesorter', 'client');

  api.use('sidebar-main', 'client');
  api.use('sidebar-tabular', 'client');

  api.addFiles('moduleSelector.jade', 'client');
  api.addFiles('core.styl', 'client');
  api.addFiles('core.jade', 'client');
  api.addFiles('core.coffee', 'client');
});

Package.onTest(function(api) {
  api.versionsFrom('1.2.1');

  api.use('xolvio:cucumber');
});
