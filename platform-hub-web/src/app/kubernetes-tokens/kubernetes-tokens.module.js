import angular from 'angular';

import {KubernetesTokensListComponent} from './kubernetes-tokens-list.component';
import {KubernetesTokensFormComponent} from './kubernetes-tokens-form.component';

// Main section component names
export const KubernetesTokensList = 'kubernetesTokensList';
export const KubernetesTokensForm = 'kubernetesTokensForm';

export const KubernetesTokensModule = angular
  .module('app.kubernetes-tokens', [])
  .component(KubernetesTokensList, KubernetesTokensListComponent)
  .component(KubernetesTokensForm, KubernetesTokensFormComponent)
  .name;
