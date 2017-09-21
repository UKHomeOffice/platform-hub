import angular from 'angular';

import {ProjectsFormComponent} from './projects-form.component';
import {ProjectsDetailComponent} from './projects-detail.component';
import {ProjectsListComponent} from './projects-list.component';
import {ProjectServicesDetailComponent} from './services/project-services-detail.component';
import {ProjectServicesFormComponent} from './services/project-services-form.component';

// Main section component names
export const ProjectsForm = 'projectsForm';
export const ProjectsDetail = 'projectsDetail';
export const ProjectsList = 'projectsList';
export const ProjectServicesDetail = 'projectServicesDetail';
export const ProjectServicesForm = 'projectServicesForm';

export const ProjectsModule = angular
  .module('app.projects', [])
  .component(ProjectsForm, ProjectsFormComponent)
  .component(ProjectsDetail, ProjectsDetailComponent)
  .component(ProjectsList, ProjectsListComponent)
  .component(ProjectServicesDetail, ProjectServicesDetailComponent)
  .component(ProjectServicesForm, ProjectServicesFormComponent)
  .name;
