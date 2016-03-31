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
    'reactive-var',
    'blaze-html-templates',
    'mquandalle:jade@0.4.9',
    'mquandalle:stylus@1.0.10',
    'twbs:bootstrap@3.3.6',
    'fortawesome:fontawesome@4.5.0',
  ], 'client');

  api.addFiles([
    'client/user_guide.jade',
    'client/user_guide.coffee',
    'client/help.styl',
    'client/help.jade',
    'client/help.coffee',
  ], 'client');

});
