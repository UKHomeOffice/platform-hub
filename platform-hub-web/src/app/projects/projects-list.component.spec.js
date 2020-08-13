import angular from 'angular';
import 'angular-mocks';
import sinon from 'sinon';
import chai from 'chai';
import 'chai/register-should';
import sinonChai from 'sinon-chai';
chai.use(sinonChai);
import _ from 'lodash';

import {ProjectsModule} from './projects.module';

describe('projects-list component', () => {
  let sandbox = null;
  let element = null;
  let $componentController = null;
  let $compile = null;
  let $rootScope = null;
  let $q = null;
  let $httpBackend = null;
  let $state = null;
  let roleCheckerService = null;
  let Projects = null;

  beforeEach(() => {
    const moduleName = `${ProjectsModule}.ProjectsListComponent.spec`;
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject((_$compile_, _$rootScope_, _$q_, _$httpBackend_, _$state_, _roleCheckerService_, _Projects_, _$componentController_) => {
    sandbox = sinon.sandbox.create();

    $compile = _$compile_;
    $componentController = _$componentController_;
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
    element = null;

    sandbox.restore();
  });

  function renderComponent() {
    element = $compile('<projects-list></projects-list>')($rootScope);
    $rootScope.$digest();
  }

  function stubAdmin(result) {
    sandbox
      .stub(roleCheckerService, 'hasHubRole')
      .withArgs('admin')
      .usingPromise($q)
      .resolves(result);
  }

  beforeEach(() => {
    sandbox.spy($state, 'go');
    sandbox.spy(Projects, 'getAll');
  });

  it('should render projects page', () => {
    renderComponent();
    expect(element).toContainElement('div.projects-list');
  });

  describe('for a non-admin user', () => {
    beforeEach(() => {
      stubAdmin(false);
    });

    it('shows all projects with user prioritised', () => {
      const ctrl = $componentController('projectsList');
      ctrl.myProjects = [{id: 'test1', shortname: 'Test1', name: 'Testing1', description: null, costCentreCode: null, isProjectTeamMember: true, membersCount: 1, createdAt: '2020-07-30T16:19:02Z', updatedAt: '2020-07-30T16:19:02Z'}];
      ctrl.notMyProjects = [{id: 'test2', shortname: 'Test2', name: 'Testing2', description: null, costCentreCode: null, isProjectTeamMember: false, membersCount: 0, createdAt: '2020-07-30T16:29:02Z', updatedAt: '2020-07-30T16:29:02Z'}];
      Projects.all = _.concat(ctrl.myProjects, ctrl.notMyProjects);

      expect(Projects.all[0].isProjectTeamMember).toBe(true);
      expect(Projects.all[1].isProjectTeamMember).toBe(false);
      expect(Projects.all).toEqual([{id: 'test1', shortname: 'Test1', name: 'Testing1', description: null, costCentreCode: null, isProjectTeamMember: true, membersCount: 1, createdAt: '2020-07-30T16:19:02Z', updatedAt: '2020-07-30T16:19:02Z'},
                                    {id: 'test2', shortname: 'Test2', name: 'Testing2', description: null, costCentreCode: null, isProjectTeamMember: false, membersCount: 0, createdAt: '2020-07-30T16:29:02Z', updatedAt: '2020-07-30T16:29:02Z'}]);
    });
  });

  describe('for an admin user', () => {
    beforeEach(() => {
      stubAdmin(true);
    });

    it('shows all projects with user prioritised', () => {
      const ctrl = $componentController('projectsList');
      ctrl.myProjects = [{id: 'test1', shortname: 'Test1', name: 'Testing1', description: null, costCentreCode: null, isProjectTeamMember: true, membersCount: 1, createdAt: '2020-07-30T16:19:02Z', updatedAt: '2020-07-30T16:19:02Z'}];
      ctrl.notMyProjects = [{id: 'test2', shortname: 'Test2', name: 'Testing2', description: null, costCentreCode: null, isProjectTeamMember: false, membersCount: 0, createdAt: '2020-07-30T16:29:02Z', updatedAt: '2020-07-30T16:29:02Z'}];
      Projects.all = _.concat(ctrl.myProjects, ctrl.notMyProjects);

      expect(Projects.all[0].isProjectTeamMember).toBe(true);
      expect(Projects.all[1].isProjectTeamMember).toBe(false);
      expect(Projects.all).toEqual([{id: 'test1', shortname: 'Test1', name: 'Testing1', description: null, costCentreCode: null, isProjectTeamMember: true, membersCount: 1, createdAt: '2020-07-30T16:19:02Z', updatedAt: '2020-07-30T16:19:02Z'},
                                    {id: 'test2', shortname: 'Test2', name: 'Testing2', description: null, costCentreCode: null, isProjectTeamMember: false, membersCount: 0, createdAt: '2020-07-30T16:29:02Z', updatedAt: '2020-07-30T16:29:02Z'}]);
    });
  });
});
