import angular from 'angular';
import 'angular-mocks';
import sinon from 'sinon';
import chai from 'chai';
import 'chai/register-should';
import sinonChai from 'sinon-chai';
chai.use(sinonChai);
import _ from 'lodash';

import {KubernetesModule} from './kubernetes.module';

describe('kubernetes user tokens form', () => {
  let sandbox = null;

  let params = {};
  let element = null;

  let $compile = null;
  let $rootScope = null;
  let $q = null;
  let $httpBackend = null;
  let $state = null;
  let roleCheckerService = null;
  let Projects = null;

  beforeEach(() => {
    const moduleName = `${KubernetesModule}.KubernetesUserTokensFormComponent.spec`;
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject((_$compile_, _$rootScope_, _$q_, _$httpBackend_, _$state_, _roleCheckerService_, _Projects_) => {
    sandbox = sinon.sandbox.create();

    $compile = _$compile_;
    $rootScope = _$rootScope_;
    $q = _$q_;
    $httpBackend = _$httpBackend_;
    $state = _$state_;
    roleCheckerService = _roleCheckerService_;
    Projects = _Projects_;

    $httpBackend
      .whenGET(/.+/)
      .respond('{}');
  }));

  afterEach(() => {
    params = {};
    element = null;

    sandbox.restore();
  });

  function renderComponentWithTransitionParams(transitionParams) {
    $rootScope.transition = {
      params() {
        return transitionParams;
      }
    };

    element = $compile('<kubernetes-user-tokens-form transition="transition"></kubernetes-user-tokens-form>')($rootScope);
    $rootScope.$digest();
  }

  function stubAdmin(result) {
    sandbox
      .stub(roleCheckerService, 'hasHubRole')
      .withArgs('admin')
      .usingPromise($q)
      .resolves(result);
  }

  function stubProjectAdminRole(projectId, result) {
    sandbox
      .stub(Projects, 'membershipRoleCheck')
      .withArgs(projectId, 'admin')
      .usingPromise($q)
      .resolves({result});
  }

  function stubProjectMemberships(projectId, userIds) {
    sandbox
      .stub(Projects, 'getMemberships')
      .withArgs(params.fromProject)
      .usingPromise($q)
      .resolves(
        _.map(userIds, i => {
          return {user: {id: i}};
        })
      );
  }

  beforeEach(() => {
    sandbox.spy($state, 'go');
    sandbox.spy(Projects, 'refresh');
  });

  describe('for an admin user', () => {
    beforeEach(() => {
      stubAdmin(true);
    });

    describe('for a new user token', () => {
      describe('when not providing the fromProject params', () => {
        beforeEach(() => {
          renderComponentWithTransitionParams(params);
        });

        it('should load the form as expected', () => {
          $state.go.should.have.callCount(0);
          Projects.refresh.should.have.callCount(1);
          expect(element).toContainElement('div.kubernetes-user-tokens-form');
        });
      });

      describe('when providing fromProject=foo', () => {
        beforeEach(() => {
          params.fromProject = 'foo';

          stubProjectMemberships('foo', ['bob']);

          renderComponentWithTransitionParams(params);
        });

        it('should load the form as expected', () => {
          $state.go.should.have.callCount(0);
          Projects.refresh.should.have.callCount(1);
          expect(element).toContainElement('div.kubernetes-user-tokens-form');
        });
      });

      describe('when providing mismatched fromProject and userId params', () => {
        beforeEach(() => {
          params.fromProject = 'foo';
          params.userId = 'bob';

          stubProjectMemberships('foo', ['notbob', 'definitelynotbob!']);

          renderComponentWithTransitionParams(params);
        });

        it('should boot the user out', () => {
          $state.go.should.have.been.calledWith('home');
          Projects.refresh.should.have.callCount(0);
        });
      });
    });

    describe('for an existing user token', () => {
      beforeEach(() => {
        params.userId = 'bob';
        params.tokenId = 'token1';
      });

      describe('when not providing the fromProject param', () => {
        beforeEach(() => {
          renderComponentWithTransitionParams(params);
        });

        it('should load the form as expected', () => {
          $state.go.should.have.callCount(0);
          Projects.refresh.should.have.callCount(1);
          expect(element).toContainElement('div.kubernetes-user-tokens-form');
        });
      });

      describe('when providing fromProject=foo param and user is a member', () => {
        beforeEach(() => {
          params.fromProject = 'foo';

          stubProjectMemberships('foo', ['bob']);

          renderComponentWithTransitionParams(params);
        });

        it('should load the form as expected', () => {
          $state.go.should.have.callCount(0);
          Projects.refresh.should.have.callCount(1);
          expect(element).toContainElement('div.kubernetes-user-tokens-form');
        });
      });

      describe('when providing fromProject=foo param and user is not a member', () => {
        beforeEach(() => {
          params.fromProject = 'foo';

          stubProjectMemberships('foo', ['notbob', 'definitelynotbob!']);

          renderComponentWithTransitionParams(params);
        });

        it('should boot the user out', () => {
          $state.go.should.have.been.calledWith('home');
          Projects.refresh.should.have.callCount(0);
        });
      });

      describe('when user in token doesn\'t match userId param provided', () => {
        beforeEach(() => {
          params.userId = 'someoneelse';
          params.fromProject = 'foo';

          stubProjectMemberships('foo', ['bob', 'someoneelse']);

          // Unspy the existing spy!
          Projects.refresh.restore();

          sandbox
            .stub(Projects, 'refresh')
            .withArgs()
            .usingPromise($q)
            .resolves([]);

          sandbox
            .stub(Projects, 'getKubernetesUserToken')
            .withArgs('foo', 'token1')
            .usingPromise($q)
            .resolves({
              id: 'token1',
              kind: 'user',
              user: {
                id: 'bob'  // This token does not belong to someoneelse!
              },
              project: {
                id: 'foo'
              }
            });

          sandbox.spy(Projects, 'getKubernetesClusters');

          renderComponentWithTransitionParams(params);
        });

        it('should boot the user out', () => {
          $state.go.should.have.been.calledWith('home');
          Projects.getKubernetesClusters.should.have.callCount(0);
        });
      });
    });
  });

  describe('for a non-admin user', () => {
    beforeEach(() => {
      stubAdmin(false);
    });

    describe('for a project admin of project foo', () => {
      describe('for a new user token', () => {
        describe('when not providing the fromProject param', () => {
          beforeEach(() => {
            stubProjectAdminRole('foo', true);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });

        describe('when providing fromProject=foo param', () => {
          beforeEach(() => {
            stubProjectAdminRole('foo', true);

            params.fromProject = 'foo';

            stubProjectMemberships('foo', []);

            renderComponentWithTransitionParams(params);
          });

          it('should load the form as expected', () => {
            $state.go.should.have.callCount(0);
            Projects.refresh.should.have.callCount(1);
            expect(element).toContainElement('div.kubernetes-user-tokens-form');
          });
        });

        describe('when providing fromProject=other param', () => {
          beforeEach(() => {
            stubProjectAdminRole('other', false);

            params.fromProject = 'other';

            stubProjectMemberships('other', []);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });
      });

      describe('for an existing user token', () => {
        beforeEach(() => {
          params.userId = 'bob';
          params.tokenId = 'token1';
        });

        describe('when not providing the fromProject param', () => {
          beforeEach(() => {
            stubProjectAdminRole('foo', true);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });

        describe('when providing fromProject=foo param', () => {
          beforeEach(() => {
            stubProjectAdminRole('foo', true);

            params.fromProject = 'foo';

            stubProjectMemberships('foo', ['bob']);

            renderComponentWithTransitionParams(params);
          });

          it('should load the form as expected', () => {
            $state.go.should.have.callCount(0);
            Projects.refresh.should.have.callCount(1);
            expect(element).toContainElement('div.kubernetes-user-tokens-form');
          });
        });

        describe('when providing fromProject=other param', () => {
          beforeEach(() => {
            stubProjectAdminRole('other', false);

            params.fromProject = 'other';

            stubProjectMemberships('other', ['bob']);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });
      });
    });

    describe('for a user that is not a project admin of any project', () => {
      beforeEach(() => {
        sandbox
          .stub(Projects, 'membershipRoleCheck')
          .usingPromise($q)
          .resolves({result: false});
      });

      describe('for a new user token', () => {
        describe('when not providing the fromProject param', () => {
          beforeEach(() => {
            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });

        describe('when providing fromProject=foo param', () => {
          beforeEach(() => {
            params.fromProject = 'foo';

            stubProjectMemberships('foo', []);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });

        describe('when providing fromProject=other param', () => {
          beforeEach(() => {
            params.fromProject = 'other';

            stubProjectMemberships('other', []);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });
      });

      describe('for an existing user token', () => {
        beforeEach(() => {
          params.userId = 'bob';
          params.tokenId = 'token1';
        });

        describe('when not providing the fromProject param', () => {
          beforeEach(() => {
            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });

        describe('when providing fromProject=foo param', () => {
          beforeEach(() => {
            params.fromProject = 'foo';

            stubProjectMemberships('foo', ['bob']);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });

        describe('when providing fromProject=other param', () => {
          beforeEach(() => {
            params.fromProject = 'other';

            stubProjectMemberships('foo', ['other']);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
            Projects.refresh.should.have.callCount(0);
          });
        });
      });
    });
  });
});
