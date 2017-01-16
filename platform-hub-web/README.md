# Platform Hub Web App

## Dev

### Prerequisites

#### Node v6.9.1

[`nave`](https://github.com/isaacs/nave) is a useful way to manage multiple/specific versions of NodeJS

To set up:
- `npm install -g nave`
- `nave use 6.9.1`

NOTE: you'll then need to run `nave use 6.9.1` every time you start up a new shell.

#### Yarn (for package management)

[`Yarn`](https://yarnpkg.com) provides a more deterministic, safe and reliable mechanism for NodeJS package management (substitute for `npm`).

The simplest way to set this up is: `npm install -g yarn` though see the [install docs](https://yarnpkg.com/en/docs/install) for details on potentially better ways. Note that Yarn needs to be available for the version of NodeJS you set up above.

### Dev flows

#### Install dependencies

```bash
yarn
```

#### Common tasks

- `yarn run serve` – runs a local dev server to serve the app in dev mode (with auto reloading)
- `yarn run build` – builds the optimized version of the app for production environments (in `/dist`)
- `yarn run serve:dist` – runs a local server to serve the optimized version of the app (runs the build in the process)
- `yarn run test` – runs tests
- `yarn run test:auto` – runs tests and then reruns tests automatically on changes

See all available tasks in the `scripts` section of `package.json`.

### Coding guidelines

The structure of this app, and the coding guidelines to work on it, are largely based on:

- https://github.com/johnpapa/angular-styleguide/tree/master/a1
- https://github.com/toddmotto/angular-styleguide

Key guidelines:

_TODO: break these into separate sections_

- One important exception/difference to the styleguides linked above: when defining an AngularJS `component` or `directive` place it's corresponding `Controller` function (assuming it has one) in the same file. This is a conscious decision to keep the logic in components/directives as close as possible to the declaration.
- _TODO: describe the app.* files and the important exception that routes are defined in one file instead of with the components_
- _TODO: something about app structure (i.e. the various folders)_
- _TODO: something about how Angular modules are the key abstraction to group sections / components / shared bits in self-contained, errr, modules + something about when to define a new module (i.e. top level section folders, as well, as folders within app/shared)_
- _TODO: something about the top level app sections – and how this can evolve later based on sub-sections / partials / etc_
- _TODO: something about "assembling" all the AngularJS specific things like components, directives, services, etc. within the relevant module file_


### Resources

- https://github.com/velesin/jasmine-jquery
- _TODO: more to come_
