import angular from 'angular';
import 'angular-mocks';
import sinon from 'sinon';
import chai from 'chai';
import 'chai/register-should';
import sinonChai from 'sinon-chai';
chai.use(sinonChai);

import {KubernetesModule} from './kubernetes.module';

describe('kubernetes robot tokens form', () => {
  let sandbox = null;

  let params = {};
  let element = null;

  const barService = {
    id: 'bar',
    name: 'bar',
    project: {
      id: 'foo',
      shortname: 'bar'
    }
  };

  let $compile = null;
  let $rootScope = null;
  let $q = null;
  let $httpBackend = null;
  let $state = null;
  let roleCheckerService = null;
  let Projects = null;

  beforeEach(() => {
    const moduleName = `${KubernetesModule}.KubernetesRobotTokensFormComponent.spec`;
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

    element = $compile('<kubernetes-robot-tokens-form transition="transition"></kubernetes-robot-tokens-form>')($rootScope);
    $rootScope.$digest();
  }

  function stubAdmin(result) {
    sandbox
      .stub(roleCheckerService, 'hasHubRole')
      .withArgs('admin')
      .usingPromise($q)
      .resolves(result);
  }

  function stubProjectManagerRole(projectId, result) {
    sandbox
      .stub(Projects, 'membershipRoleCheck')
      .withArgs(projectId, 'manager')
      .usingPromise($q)
      .resolves({result});
  }

  function stubBarService() {
    sandbox
      .stub(Projects, 'getService')
      .withArgs('foo', 'bar')
      .usingPromise($q)
      .resolves(barService);
  }

  beforeEach(() => {
    sandbox.spy($state, 'go');
  });

  describe('for an admin user', () => {
    beforeEach(() => {
      stubAdmin(true);
    });

    describe('for a new robot token', () => {
      describe('when providing mismatched fromProject and fromService params', () => {
        beforeEach(() => {
          params.fromProject = '';
          params.fromService = 'bar';

          renderComponentWithTransitionParams(params);
        });

        it('should boot the user out', () => {
          $state.go.should.have.been.calledWith('home');
        });
      });

      describe('when not providing fromProject and fromService params', () => {
        beforeEach(() => {
          renderComponentWithTransitionParams(params);
        });

        it('should load the form as expected', () => {
          $state.go.should.have.callCount(0);
          expect(element).toContainElement('div.kubernetes-robot-tokens-form');
        });
      });

      describe('when providing fromProject=foo and fromService=bar params', () => {
        beforeEach(() => {
          stubBarService();

          params.fromProject = 'foo';
          params.fromService = 'bar';

          renderComponentWithTransitionParams(params);
        });

        it('should load the form as expected', () => {
          $state.go.should.have.callCount(0);
          expect(element).toContainElement('div.kubernetes-robot-tokens-form');
        });
      });
    });

    describe('for an existing robot token', () => {
      beforeEach(() => {
        params.cluster = 'cluster1';
        params.tokenId = 'token1';
      });

      describe('when not providing fromProject and fromService params', () => {
        beforeEach(() => {
          renderComponentWithTransitionParams(params);
        });

        it('should load the form as expected', () => {
          $state.go.should.have.callCount(0);
          expect(element).toContainElement('div.kubernetes-robot-tokens-form');
        });
      });

      describe('when providing fromProject=foo and fromService=bar params', () => {
        beforeEach(() => {
          stubBarService();

          params.fromProject = 'foo';
          params.fromService = 'bar';

          renderComponentWithTransitionParams(params);
        });

        it('should load the form as expected', () => {
          $state.go.should.have.callCount(0);
          expect(element).toContainElement('div.kubernetes-robot-tokens-form');
        });
      });
    });
  });

  describe('for a non-admin user', () => {
    beforeEach(() => {
      stubAdmin(false);
    });

    describe('for a project manager of project foo', () => {
      describe('for a new robot token', () => {
        describe('when not providing fromProject and fromService params', () => {
          beforeEach(() => {
            stubProjectManagerRole('foo', true);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });

        describe('when providing fromProject=foo and fromService=bar params', () => {
          beforeEach(() => {
            stubProjectManagerRole('foo', true);
            stubBarService();

            params.fromProject = 'foo';
            params.fromService = 'bar';

            renderComponentWithTransitionParams(params);
          });

          it('should load the form as expected', () => {
            $state.go.should.have.callCount(0);
            expect(element).toContainElement('div.kubernetes-robot-tokens-form');
          });
        });

        describe('when providing fromProject=other and fromService=bar params', () => {
          beforeEach(() => {
            stubProjectManagerRole('other', false);

            params.fromProject = 'other';
            params.fromService = 'bar';

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });
      });

      describe('for an existing robot token', () => {
        beforeEach(() => {
          params.cluster = 'cluster1';
          params.tokenId = 'token1';
        });

        describe('when not providing fromProject and fromService params', () => {
          beforeEach(() => {
            stubProjectManagerRole('foo', true);

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });

        describe('when providing fromProject=foo and fromService=bar params', () => {
          beforeEach(() => {
            stubProjectManagerRole('foo', true);
            stubBarService();

            params.fromProject = 'foo';
            params.fromService = 'bar';

            renderComponentWithTransitionParams(params);
          });

          it('should load the form as expected', () => {
            $state.go.should.have.callCount(0);
            expect(element).toContainElement('div.kubernetes-robot-tokens-form');
          });
        });

        describe('when providing fromProject=other and fromService=bar params', () => {
          beforeEach(() => {
            stubProjectManagerRole('other', false);

            params.fromProject = 'other';
            params.fromService = 'bar';

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });
      });
    });

    describe('for a user that is not a project manager of any project', () => {
      beforeEach(() => {
        sandbox
          .stub(Projects, 'membershipRoleCheck')
          .usingPromise($q)
          .resolves({result: false});
      });

      describe('for a new robot token', () => {
        describe('when not providing fromProject and fromService params', () => {
          beforeEach(() => {
            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });

        describe('when providing fromProject=foo and fromService=bar params', () => {
          beforeEach(() => {
            params.fromProject = 'foo';
            params.fromService = 'bar';

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });

        describe('when providing fromProject=other and fromService=bar params', () => {
          beforeEach(() => {
            params.fromProject = 'other';
            params.fromService = 'bar';

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });
      });

      describe('for an existing robot token', () => {
        beforeEach(() => {
          params.cluster = 'cluster1';
          params.tokenId = 'token1';
        });

        describe('when not providing fromProject and fromService params', () => {
          beforeEach(() => {
            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });

        describe('when providing fromProject=foo and fromService=bar params', () => {
          beforeEach(() => {
            params.fromProject = 'foo';
            params.fromService = 'bar';

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });

        describe('when providing fromProject=other and fromService=bar params', () => {
          beforeEach(() => {
            params.fromProject = 'other';
            params.fromService = 'bar';

            renderComponentWithTransitionParams(params);
          });

          it('should boot the user out', () => {
            $state.go.should.have.been.calledWith('home');
          });
        });
      });
    });
  });
});
