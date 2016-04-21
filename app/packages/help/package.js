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
    'stylus',
    'twbs:bootstrap@3.3.6',
    'fortawesome:fontawesome@4.5.0',
  ], 'client');

  api.addFiles([
    'client/styles/help.styl',
    'client/templates/topics/help_all_airports.jade',
    'client/templates/topics/help_direct_flights.jade',
    'client/templates/topics/help_filters.jade',
    'client/templates/topics/help_layers.jade',
    'client/templates/topics/help_simulation.jade',
    'client/templates/help_link.jade',
    'client/templates/user_guide.jade',
    'client/templates/help.jade',
    'client/controllers/help_link.coffee',
    'client/controllers/user_guide.coffee',
    'client/controllers/help.coffee',
  ], 'client');

});
