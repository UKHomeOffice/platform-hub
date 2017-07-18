import angular from 'angular';

import {FieldsEditorComponent} from './fields-editor.component';
import {FieldsListingsComponent} from './fields-listings.component';
import {FormFieldComponent} from './form-field.component';
import {LoadingIndicatorComponent} from './loading-indicator.component';
import {SimpleFormatFilter} from './simple-format.filter';

export const UiModule = angular
  .module('app.shared.ui', [])
  .component('fieldsEditor', FieldsEditorComponent)
  .component('fieldsListings', FieldsListingsComponent)
  .component('formField', FormFieldComponent)
  .component('loadingIndicator', LoadingIndicatorComponent)
  .filter('simpleFormat', SimpleFormatFilter)
  .name;
