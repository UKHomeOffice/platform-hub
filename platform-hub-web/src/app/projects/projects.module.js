import angular from 'angular';

import {ProjectsFormComponent} from './projects-form.component';
import {ProjectsDetailComponent} from './projects-detail.component';
import {ProjectsListComponent} from './projects-list.component';

// Main section component names
export const ProjectsForm = 'projectsForm';
export const ProjectsDetail = 'projectsDetail';
export const ProjectsList = 'projectsList';

export const ProjectsModule = angular
  .module('app.projects', [])
  .component(ProjectsForm, ProjectsFormComponent)
  .component(ProjectsDetail, ProjectsDetailComponent)
  .component(ProjectsList, ProjectsListComponent)
  .name;
