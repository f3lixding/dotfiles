# Build on save
See [this guide here](https://zigtools.org/zls/guides/build-on-save/) to add a check step in the build script
And then symlink (after changing the hoem dir) zls.json to somewhere the zls has access to
After that configure zls to configure itself with this file with `zls --config-path`
(You can also check to see what zls is current using to configure itself with `zls env`)
