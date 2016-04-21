Package.describe({
  name: 'sidebar',
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
    'stylus',
  ], 'client');

  api.addFiles([
    'variables.import.styl',
    'base.import.styl',
    'tabular.import.styl',
    'main.styl',
    'sidebar.jade',
    'sidebar.coffee',
  ], 'client');

});
