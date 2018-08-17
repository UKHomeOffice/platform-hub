import angular from 'angular';

import {DocsSourcesDetailComponent} from './docs-sources-detail.component';
import {DocsSourcesFormComponent} from './docs-sources-form.component';
import {DocsSourcesListComponent} from './docs-sources-list.component';

// Main section component names
export const DocsSourcesDetail = 'docsSourcesDetail';
export const DocsSourcesForm = 'docsSourcesForm';
export const DocsSourcesList = 'docsSourcesList';

export const AnnouncementsModule = angular
  .module('app.announcements', [])
  .component(DocsSourcesDetail, DocsSourcesDetailComponent)
  .component(DocsSourcesForm, DocsSourcesFormComponent)
  .component(DocsSourcesList, DocsSourcesListComponent)
  .name;
