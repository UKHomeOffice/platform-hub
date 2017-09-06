import angular from 'angular';

import {KubernetesTokensSyncComponent} from './kubernetes-tokens-sync.component';
import {KubernetesUserTokensFormComponent} from './kubernetes-user-tokens-form.component';
import {KubernetesUserTokensListComponent} from './kubernetes-user-tokens-list.component';

// Main section component names
export const KubernetesTokensSync = 'kubernetesTokensSync';
export const KubernetesUserTokensForm = 'kubernetesTokensForm';
export const KubernetesUserTokensList = 'kubernetesTokensList';

export const KubernetesModule = angular
  .module('app.kubernetes', [])
  .component(KubernetesTokensSync, KubernetesTokensSyncComponent)
  .component(KubernetesUserTokensForm, KubernetesUserTokensFormComponent)
  .component(KubernetesUserTokensList, KubernetesUserTokensListComponent)
  .name;
