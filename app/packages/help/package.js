Package.describe({
  name: 'flirt:help',
  summary: 'Flirt help package',
  version: '0.0.1',
  git: 'git@github.com:ecohealthalliance/flirt.git',
});

Package.onUse(function(api) {
  api.versionsFrom('1.2.1');

  api.use('coffeescript');

  api.use([
    'blaze-html-templates',
    'mquandalle:jade@0.4.9',
    'mquandalle:stylus@1.0.10',
    'twbs:bootstrap@3.3.6'
  ], 'client');

  api.addFiles([
    'help.styl',
    'help.jade',
    'help.coffee',
  ], 'client');

});
