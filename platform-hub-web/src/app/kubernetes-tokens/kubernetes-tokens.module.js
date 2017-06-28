import angular from 'angular';

import {KubernetesTokensFormComponent} from './kubernetes-tokens-form.component';
import {KubernetesTokensListComponent} from './kubernetes-tokens-list.component';
import {KubernetesTokensSyncComponent} from './kubernetes-tokens-sync.component';

// Main section component names
export const KubernetesTokensForm = 'kubernetesTokensForm';
export const KubernetesTokensList = 'kubernetesTokensList';
export const KubernetesTokensSync = 'kubernetesTokensSync';

export const KubernetesTokensModule = angular
  .module('app.kubernetes-tokens', [])
  .component(KubernetesTokensForm, KubernetesTokensFormComponent)
  .component(KubernetesTokensList, KubernetesTokensListComponent)
  .component(KubernetesTokensSync, KubernetesTokensSyncComponent)
  .name;
