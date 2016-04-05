Package.describe({
  name: 'flirt-sidebars',
  version: '0.0.1',
  // Brief, one-line summary of the package.
  summary: '',
  // URL to the Git repository containing the source code for this package.
  git: '',
  // By default, Meteor will default to using README.md for documentation.
  // To avoid submitting documentation, set this field to null.
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2.1');

  api.use([
    'coffeescript',
    'blaze-html-templates',
    'mquandalle:jade@0.4.9',
    'mquandalle:stylus@1.0.10',
    'reactive-var',
    'eha:sidebar'
  ], 'client');

  api.addFiles([
    'tabular_sidebar.jade',
    'tabular_sidebar.coffee',
    'main_sidebar.jade',
    'main_sidebar.coffee',
  ], 'client');

});
