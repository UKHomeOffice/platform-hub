import angular from 'angular';

import {KubernetesClustersFormComponent} from './kubernetes-clusters-form.component';
import {KubernetesClustersListComponent} from './kubernetes-clusters-list.component';
import {KubernetesTokensSyncComponent} from './kubernetes-tokens-sync.component';
import {KubernetesUserTokensFormComponent} from './kubernetes-user-tokens-form.component';
import {KubernetesUserTokensListComponent} from './kubernetes-user-tokens-list.component';

// Main section component names
export const KubernetesClustersForm = 'kubernetesClustersForm';
export const KubernetesClustersList = 'kubernetesClustersList';
export const KubernetesTokensSync = 'kubernetesTokensSync';
export const KubernetesUserTokensForm = 'kubernetesTokensForm';
export const KubernetesUserTokensList = 'kubernetesTokensList';

export const KubernetesModule = angular
  .module('app.kubernetes', [])
  .component(KubernetesClustersForm, KubernetesClustersFormComponent)
  .component(KubernetesClustersList, KubernetesClustersListComponent)
  .component(KubernetesTokensSync, KubernetesTokensSyncComponent)
  .component(KubernetesUserTokensForm, KubernetesUserTokensFormComponent)
  .component(KubernetesUserTokensList, KubernetesUserTokensListComponent)
  .name;
