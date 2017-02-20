# HODDAT PaaS Hub – Web App

## Tech summary

An AngularJS 1.5 web app that runs fully client side (as static assets), with a local development and build stack for easy development, testing and building.

## Dev

### Prerequisites

#### Node v6.9.1

[`nave`](https://github.com/isaacs/nave) is a useful way to manage multiple/specific versions of NodeJS

To set up:
- `npm install -g nave`
- `nave use 6.9.1`

NOTE: you'll then need to run `nave use 6.9.1` every time you start up a new shell.

#### Yarn v0.20.3 (for package management)

[`Yarn`](https://yarnpkg.com) provides a more deterministic, safe and reliable mechanism for NodeJS package management (substitute for `npm`).

The simplest way to set this up is: `npm install -g yarn@0.20.3` though see the [install docs](https://yarnpkg.com/en/docs/install) for details on potentially better ways. Note that Yarn needs to be available for the version of NodeJS you set up above.

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

### Coding guidelines and source code structure

The structure of this app, and the coding guidelines to work on it, are largely based on:

- https://github.com/toddmotto/angular-styleguide
- https://github.com/johnpapa/angular-styleguide/tree/master/a1

Important exceptions to the above styleguides:

- When defining an AngularJS `component` or `directive`, place it's corresponding `Controller` function (assuming it has one) in the same file. This is a conscious decision to keep the logic in components/directives as close as possible to the declaration.
- All application routes are defined in one file: `src/app/app.routes.js`.

#### Key points about structure and guidelines to follow

- The various `app.*.js` files in `src/app` set up everything needed for the overall AngularJS app to run, including any module dependencies, runtime config, routes, constants, etc.
  - The `app.module.js` is the main "assembly" of the app, and is also where app-wide constants are defined.
- We break down the app as much as possible into [AngularJS modules](https://docs.angularjs.org/guide/module) – in theory, each module could be tested in isolation.
  - We have one top level `app` module that assembles everything together (as mentioned above).
  - Each individual _section_ – usually a routable part – of the app has it's own folder in `src/app` (e.g. `src/app/home`) and has it's own module definition in `<section-name>.module.js` where all of it's dependencies are described, and all of it's children components, directives, services, factories, etc. are assmebled into the module. Everything needed for this section of app should go in this folder (and broken down into further modules within this folder, if needed).
  - A special `app/shared` module is used for shared code across the app. You can register stuff directly within this module, or in further modules inside of the `app/shared` folder (e.g. `app/shared/auth`).
  - The individual files that provide AngularJS components, directives, services, factories, etc. don't actually know they are AngularJS specific things, as such – they are just functions and objects that make use of AngularJS' conventions, dependency injection and structures, and only get registered in their relevant parent's `<foo>.module.js` file in to the AngularJS runtime.
- For CSS we use [SASS](http://sass-lang.com/) because it's awesome.
  - The `src/app/app.scss` file provides app level styling.
  - Individual app sections and shared modules should have their own `<foo>.scss` file, within their folders, if needed. The dev server and build pipeline will automatically pick these up when building the styles.

### Resources

- [Angular Material docs](https://material.angularjs.org/1.1.3/)
- [lodash docs](https://lodash.com/docs/4.17.4)
- [jasmine-jquery special matchers you can use in your tests](https://github.com/velesin/jasmine-jquery)
