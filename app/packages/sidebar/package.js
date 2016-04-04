Package.describe({
  name: 'eha:sidebar',
  summary: 'Sidebar',
  version: '0.0.1',
});

Package.onUse(function(api) {
  api.versionsFrom('1.2.1');

  api.use('coffeescript');

  api.use([
    'reactive-var',
    'blaze-html-templates',
    'mquandalle:jade@0.4.9',
    'mquandalle:stylus@1.0.10',
  ], 'client');

  api.addFiles([
    'variables.import.styl',
    'sidebar_base.import.styl',
    'sidebar_tabular.import.styl',
    'main.styl',
    'sidebar.jade',
    'sidebar.coffee',
  ], 'client');

});
