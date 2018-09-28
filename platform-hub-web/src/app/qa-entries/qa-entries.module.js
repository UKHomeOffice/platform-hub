import angular from 'angular';

import {QaEntriesDetailComponent} from './qa-entries-detail.component';
import {QaEntriesFormComponent} from './qa-entries-form.component';
import {QaEntriesListComponent} from './qa-entries-list.component';

// Main section component names
export const QaEntriesDetail = 'qaEntriesDetail';
export const QaEntriesForm = 'qaEntriesForm';
export const QaEntriesList = 'qaEntriesList';

export const QaEntriesModule = angular
  .module('app.qa-entries', [])
  .component(QaEntriesDetail, QaEntriesDetailComponent)
  .component(QaEntriesForm, QaEntriesFormComponent)
  .component(QaEntriesList, QaEntriesListComponent)
  .name;
