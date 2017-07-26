import angular from 'angular';

import {FeatureFlagsFormComponent} from './feature-flags-form.component';

// Main section component names
export const FeatureFlagsForm = 'featureFlagsForm';

export const FeatureFlagsModule = angular
  .module('app.feature-flags', [])
  .component(FeatureFlagsForm, FeatureFlagsFormComponent)
  .name;
