import angular from 'angular';

import {chipsHelpers} from './chips-helpers.factory';
import {FieldsEditorComponent} from './fields-editor.component';
import {FieldsListingsComponent} from './fields-listings.component';
import {FormFieldComponent} from './form-field.component';
import {LoadingIndicatorComponent} from './loading-indicator.component';
import {PaginatedListDirective} from './paginated-list.directive';
import {PaginationToolbarComponent} from './pagination-toolbar.component';
import {SimpleFormatFilter} from './simple-format.filter';
import {treeDataHelper} from './tree-data-helper.factory';
import {validateEmails} from './validate-emails.directive';

export const UiModule = angular
  .module('app.shared.ui', [])
  .factory('chipsHelpers', chipsHelpers)
  .component('fieldsEditor', FieldsEditorComponent)
  .component('fieldsListings', FieldsListingsComponent)
  .component('formField', FormFieldComponent)
  .component('loadingIndicator', LoadingIndicatorComponent)
  .directive('paginatedList', PaginatedListDirective)
  .component('paginationToolbar', PaginationToolbarComponent)
  .filter('simpleFormat', SimpleFormatFilter)
  .factory('treeDataHelper', treeDataHelper)
  .directive('validateEmails', validateEmails)
  .name;
