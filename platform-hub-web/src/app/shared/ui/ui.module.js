import angular from 'angular';

import {FieldsEditorComponent} from './fields-editor.component';
import {FieldsListingsComponent} from './fields-listings.component';
import {FormFieldComponent} from './form-field.component';
import {LoadingIndicatorComponent} from './loading-indicator.component';
import {PaginatedListDirective} from './paginated-list.directive';
import {PaginationToolbarComponent} from './pagination-toolbar.component';
import {SimpleFormatFilter} from './simple-format.filter';
import {validateEmails} from './validate-emails.directive';

export const UiModule = angular
  .module('app.shared.ui', [])
  .component('fieldsEditor', FieldsEditorComponent)
  .component('fieldsListings', FieldsListingsComponent)
  .component('formField', FormFieldComponent)
  .component('loadingIndicator', LoadingIndicatorComponent)
  .directive('paginatedList', PaginatedListDirective)
  .component('paginationToolbar', PaginationToolbarComponent)
  .filter('simpleFormat', SimpleFormatFilter)
  .directive('validateEmails', validateEmails)
  .name;
