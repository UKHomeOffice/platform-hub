import angular from 'angular';

import {AppSettingsFormComponent} from './app-settings-form.component';

// Main section component names
export const AppSettingsForm = 'appSettingsForm';

export const AppSettingsModule = angular
  .module('app.app-settings', [
    'angular-sortable-view'
  ])
  .component(AppSettingsForm, AppSettingsFormComponent)
  .name;
