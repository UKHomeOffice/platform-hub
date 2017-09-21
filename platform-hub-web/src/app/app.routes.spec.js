/* eslint angular/log: 0, padded-blocks: 0 */

import angular from 'angular';
import 'angular-mocks';
import lodash from 'lodash';
import sinon from 'sinon';
import chai from 'chai';
import 'chai/register-should';
import sinonChai from 'sinon-chai';
chai.use(sinonChai);

describe('routes', () => {
  const PARAM_REGEX = /(:\w+)/g;

  const ALLOWED_DATA_CONFIG_FIELDS = [
    'authenticate',
    'rolePermitted',
    'featureFlag'
  ];

  const abstractStates = {};

  let sandbox = null;

  let $q = null;
  let $httpBackend = null;
  let $state = null;
  let $location = null;
  let $rootScope = null;
  let authService = null;
  let loginDialogService = null;
  let FeatureFlags = null;
  let roleCheckerService = null;
  let Me = null;

  beforeEach(() => {
    const moduleName = 'app.routes.spec';
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject((_$q_, _$httpBackend_, _$state_, _$location_, _$rootScope_, _authService_, _loginDialogService_, _FeatureFlags_, _roleCheckerService_, _Me_) => {
    sandbox = sinon.sandbox.create();

    $q = _$q_;
    $httpBackend = _$httpBackend_;
    $state = _$state_;
    $location = _$location_;
    $rootScope = _$rootScope_;
    authService = _authService_;
    loginDialogService = _loginDialogService_;
    FeatureFlags = _FeatureFlags_;
    roleCheckerService = _roleCheckerService_;
    Me = _Me_;

    $httpBackend
      .whenGET('/api/app_settings')
      .respond('{}');
  }));

  afterEach(() => {
    sandbox.restore();
  });

  describe('route config', () => {
    it(`should only allow certain fields in the 'data' object`, () => {
      function stubs() { }

      function checks(state) {
        lodash.keys(state.data).forEach(k => {
          expect(ALLOWED_DATA_CONFIG_FIELDS).toContain(k, `in 'data' config for route: ${state.name}`);
        });
      }

      eachNavigableState(stubs, checks);
    });
  });

  describe(`for not logged in users who don't log in`, () => {
    it(`should only transition to states that don't need authentication`, () => {
      console.log(`\n*** Not logged in users who don't log in`);

      function stubs() {
        sandbox.stub(authService, 'isAuthenticated').returns(false);

        sandbox.stub(loginDialogService, 'run').usingPromise($q).rejects();

        sandbox.spy(FeatureFlags, 'isEnabled');

        sandbox.spy(roleCheckerService, 'hasHubRole');
      }

      function checks(state) {
        if (state.data.authenticate) {
          authService.isAuthenticated.should.have.callCount(1);
          loginDialogService.run.should.have.callCount(1);
          FeatureFlags.isEnabled.should.have.callCount(0);
          roleCheckerService.hasHubRole.should.have.callCount(0);
          expect($state.current.name).toBe('home');
        } else {
          authService.isAuthenticated.should.have.callCount(0);
          loginDialogService.run.should.have.callCount(0);
          FeatureFlags.isEnabled.should.have.callCount(0);
          roleCheckerService.hasHubRole.should.have.callCount(0);
          expect($state.current.name).toBe(state.name);
        }
      }

      eachNavigableState(stubs, checks);
    });
  });

  describe('for not logged in users who log in', () => {

    // We currently assume that only the 'admin' role is used.
    // If new roles are added later, these tests will need to be updated, and
    // rethought (in terms of structure).

    describe('when all feature flags are turned on', () => {

      describe('for non-admin users', () => {
        it(`should transition to states as expected`, () => {
          console.log(`\n*** Not logged in non-admin users that log in (all feature flags ON)`);

          function stubs() {
            const stub = sandbox.stub(authService, 'isAuthenticated');
            stub.onFirstCall().returns(false);
            stub.onSecondCall().returns(true);

            sandbox.stub(loginDialogService, 'run').usingPromise($q).resolves();

            sandbox.stub(FeatureFlags, 'refresh').usingPromise($q).resolves({});
            sandbox.stub(FeatureFlags, 'isEnabled').returns(true);

            sandbox.spy(roleCheckerService, 'hasHubRole');

            sandbox.stub(Me, 'refresh').usingPromise($q).resolves({role: undefined});
          }

          function checks(state) {
            if (state.data.authenticate) {
              loginDialogService.run.should.have.callCount(1);

              if (hasFeatureFlag(state)) {
                FeatureFlags.isEnabled.should.have.callCount(1);
              }

              if (requiresAdmin(state)) {
                authService.isAuthenticated.should.have.callCount(2);
                roleCheckerService.hasHubRole.should.have.callCount(1);
                expect($state.current.name).toBe('home');
              } else {
                authService.isAuthenticated.should.have.callCount(1);
                roleCheckerService.hasHubRole.should.have.callCount(0);
                expect($state.current.name).toBe(state.name);
              }
            } else {
              authService.isAuthenticated.should.have.callCount(0);
              loginDialogService.run.should.have.callCount(0);
              FeatureFlags.isEnabled.should.have.callCount(0);
              roleCheckerService.hasHubRole.should.have.callCount(0);
              expect($state.current.name).toBe(state.name);
            }
          }

          eachNavigableState(stubs, checks);
        });
      });

      describe('for admin users', () => {
        it(`should transition to states as expected`, () => {
          console.log(`\n*** Not logged in admin users that log in (all feature flags ON)`);

          function stubs() {
            const stub = sandbox.stub(authService, 'isAuthenticated');
            stub.onFirstCall().returns(false);
            stub.onSecondCall().returns(true);

            sandbox.stub(loginDialogService, 'run').usingPromise($q).resolves();

            sandbox.stub(FeatureFlags, 'refresh').usingPromise($q).resolves({});
            sandbox.stub(FeatureFlags, 'isEnabled').returns(true);

            sandbox.spy(roleCheckerService, 'hasHubRole');

            sandbox.stub(Me, 'refresh').usingPromise($q).resolves({role: 'admin'});
          }

          function checks(state) {
            if (state.data.authenticate) {
              loginDialogService.run.should.have.callCount(1);

              if (hasFeatureFlag(state)) {
                FeatureFlags.isEnabled.should.have.callCount(1);
              }

              if (requiresAdmin(state)) {
                authService.isAuthenticated.should.have.callCount(2);
                roleCheckerService.hasHubRole.should.have.callCount(1);
              } else {
                authService.isAuthenticated.should.have.callCount(1);
                roleCheckerService.hasHubRole.should.have.callCount(0);
              }

              expect($state.current.name).toBe(state.name);
            } else {
              authService.isAuthenticated.should.have.callCount(0);
              loginDialogService.run.should.have.callCount(0);
              FeatureFlags.isEnabled.should.have.callCount(0);
              roleCheckerService.hasHubRole.should.have.callCount(0);
              expect($state.current.name).toBe(state.name);
            }
          }

          eachNavigableState(stubs, checks);
        });
      });

    });

    describe('when all feature flags are turned off', () => {

      describe('for non-admin users', () => {
        it(`should transition to states as expected`, () => {
          console.log(`\n*** Not logged in non-admin users that log in (all feature flags OFF)`);

          function stubs(state) {
            const stub = sandbox.stub(authService, 'isAuthenticated');
            stub.onFirstCall().returns(false);
            if (!hasFeatureFlag(state)) {
              stub.onSecondCall().returns(true);
            }

            sandbox.stub(loginDialogService, 'run').usingPromise($q).resolves();

            sandbox.stub(FeatureFlags, 'refresh').usingPromise($q).resolves({});
            sandbox.stub(FeatureFlags, 'isEnabled').returns(false);

            sandbox.spy(roleCheckerService, 'hasHubRole');

            sandbox.stub(Me, 'refresh').usingPromise($q).resolves({role: undefined});
          }

          function checks(state) {
            if (state.data.authenticate) {
              loginDialogService.run.should.have.callCount(1);

              if (hasFeatureFlag(state)) {
                authService.isAuthenticated.should.have.callCount(1);
                FeatureFlags.isEnabled.should.have.callCount(1);
                roleCheckerService.hasHubRole.should.have.callCount(0);
                expect($state.current.name).toBe('home');
              } else if (requiresAdmin(state)) {
                authService.isAuthenticated.should.have.callCount(2);
                FeatureFlags.isEnabled.should.have.callCount(0);
                roleCheckerService.hasHubRole.should.have.callCount(1);
                expect($state.current.name).toBe('home');
              } else {
                authService.isAuthenticated.should.have.callCount(1);
                FeatureFlags.isEnabled.should.have.callCount(0);
                roleCheckerService.hasHubRole.should.have.callCount(0);
                expect($state.current.name).toBe(state.name);
              }
            } else {
              authService.isAuthenticated.should.have.callCount(0);
              loginDialogService.run.should.have.callCount(0);
              FeatureFlags.isEnabled.should.have.callCount(0);
              roleCheckerService.hasHubRole.should.have.callCount(0);
              expect($state.current.name).toBe(state.name);
            }
          }

          eachNavigableState(stubs, checks);
        });
      });

      describe('for admin users', () => {
        it(`should transition to states as expected`, () => {
          console.log(`\n*** Not logged in admin users that log in (all feature flags OFF)`);

          function stubs(state) {
            const stub = sandbox.stub(authService, 'isAuthenticated');
            stub.onFirstCall().returns(false);
            if (!hasFeatureFlag(state)) {
              stub.onSecondCall().returns(true);
            }

            sandbox.stub(loginDialogService, 'run').usingPromise($q).resolves();

            sandbox.stub(FeatureFlags, 'refresh').usingPromise($q).resolves({});
            sandbox.stub(FeatureFlags, 'isEnabled').returns(false);

            sandbox.spy(roleCheckerService, 'hasHubRole');

            sandbox.stub(Me, 'refresh').usingPromise($q).resolves({role: 'admin'});
          }

          function checks(state) {
            if (state.data.authenticate) {
              loginDialogService.run.should.have.callCount(1);

              if (hasFeatureFlag(state)) {
                authService.isAuthenticated.should.have.callCount(1);
                FeatureFlags.isEnabled.should.have.callCount(1);
                roleCheckerService.hasHubRole.should.have.callCount(0);
                expect($state.current.name).toBe('home');
              } else if (requiresAdmin(state)) {
                authService.isAuthenticated.should.have.callCount(2);
                FeatureFlags.isEnabled.should.have.callCount(0);
                roleCheckerService.hasHubRole.should.have.callCount(1);
                expect($state.current.name).toBe(state.name);
              } else {
                authService.isAuthenticated.should.have.callCount(1);
                FeatureFlags.isEnabled.should.have.callCount(0);
                roleCheckerService.hasHubRole.should.have.callCount(0);
                expect($state.current.name).toBe(state.name);
              }
            } else {
              authService.isAuthenticated.should.have.callCount(0);
              loginDialogService.run.should.have.callCount(0);
              FeatureFlags.isEnabled.should.have.callCount(0);
              roleCheckerService.hasHubRole.should.have.callCount(0);
              expect($state.current.name).toBe(state.name);
            }
          }

          eachNavigableState(stubs, checks);
        });
      });

    });

  });

  describe('for already logged in users', () => {
    it('can transition between multiple authenticated states as expected', () => {
      sandbox.stub(authService, 'isAuthenticated').returns(true);

      // We'll hand pick some states we know are only for authenticated users
      // (and that don't have any other special requirements).

      goTo('/terms-of-service');
      authService.isAuthenticated.should.have.callCount(1);
      expect($state.current.name).toBe('terms-of-service');

      goTo('/onboarding/hub-setup');
      authService.isAuthenticated.should.have.callCount(2);
      expect($state.current.name).toBe('onboarding.hub-setup');

      goTo('/identities');
      authService.isAuthenticated.should.have.callCount(3);
      expect($state.current.name).toBe('identities');
    });
  });

  function goTo(url) {
    $location.url(url);
    $rootScope.$digest();
  }

  function eachNavigableState(stubs, checks) {
    $state.get().forEach(state => {
      if (state.abstract) {
        if (state.name) {
          abstractStates[state.name] = state;
        }
      } else {
        stubs(state);

        const urlSegments = [state.url].concat(findParentUrlSegmentsFor(state.name));
        const params = urlSegments.reduce((acc, s) => {
          Object.assign(acc, generateParamsFor(s));
          return acc;
        }, {});
        const url = $state.href(state.name, params);
        console.log(`Testing ${url}`);
        goTo(url);

        checks(state);

        sandbox.restore();
      }
    });
  }

  function hasFeatureFlag(state) {
    return lodash.has(state.data, 'featureFlag');
  }

  function requiresAdmin(state) {
    return lodash.has(state.data, 'rolePermitted') &&
      state.data.rolePermitted === 'admin';
  }

  function findParentUrlSegmentsFor(stateName) {
    // This makes the assumption that the `abstractStates` collection will
    // already contain the necessary parent states for the `stateName` provided.

    // The aim here is to take a state name and find any parent abstract states
    // matching up the "tree" and return their URL patterns.
    // Example: for the state name 'foo.bar.baz.abc', find any abstract states
    // for the following and return their particular URL patterns:
    // - 'foo'
    // - 'foo.bar'
    // - 'foo.bar.baz'

    const segments = [];

    const nameSplits = stateName.split('.');
    if (nameSplits.length > 0) {
      for (let i = 1; i < nameSplits.length; i++) {
        const parentStateName = nameSplits.slice(0, i).join('.');
        const parentState = abstractStates[parentStateName];
        if (parentState) {
          segments.push(parentState.url);
        }
      }
    }

    return segments;
  }

  function generateParamsFor(stateUrlPattern) {
    const match = stateUrlPattern.match(PARAM_REGEX);

    if (match) {
      return match.reduce((acc, m) => {
        acc[m.replace(':', '')] = 'foo';
        return acc;
      }, {});
    }

    return {};
  }
});
