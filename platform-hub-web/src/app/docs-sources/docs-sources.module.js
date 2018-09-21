import angular from 'angular';

import {DocsSourcesDetailComponent} from './docs-sources-detail.component';
import {DocsSourcesFormComponent} from './docs-sources-form.component';
import {DocsSourcesListComponent} from './docs-sources-list.component';
import {PinnedHelpEntriesFormComponent} from './pinned-help-entries-form.component';

// Main section component names
export const DocsSourcesDetail = 'docsSourcesDetail';
export const DocsSourcesForm = 'docsSourcesForm';
export const DocsSourcesList = 'docsSourcesList';
export const PinnedHelpEntriesForm = 'pinnedHelpEntriesForm';

export const DocsSourcesModule = angular
  .module('app.docs-sources', [])
  .component(DocsSourcesDetail, DocsSourcesDetailComponent)
  .component(DocsSourcesForm, DocsSourcesFormComponent)
  .component(DocsSourcesList, DocsSourcesListComponent)
  .component(PinnedHelpEntriesForm, PinnedHelpEntriesFormComponent)
  .name;
