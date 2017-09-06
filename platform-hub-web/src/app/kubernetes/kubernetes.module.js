import angular from 'angular';

import {KubernetesClustersFormComponent} from './kubernetes-clusters-form.component';
import {KubernetesClustersListComponent} from './kubernetes-clusters-list.component';
import {KubernetesRobotTokensFormComponent} from './kubernetes-robot-tokens-form.component';
import {KubernetesRobotTokensListComponent} from './kubernetes-robot-tokens-list.component';
import {KubernetesTokensSyncComponent} from './kubernetes-tokens-sync.component';
import {KubernetesUserTokensFormComponent} from './kubernetes-user-tokens-form.component';
import {KubernetesUserTokensListComponent} from './kubernetes-user-tokens-list.component';

// Main section component names
export const KubernetesClustersForm = 'kubernetesClustersForm';
export const KubernetesClustersList = 'kubernetesClustersList';
export const KubernetesRobotTokensForm = 'kubernetesRobotTokensForm';
export const KubernetesRobotTokensList = 'kubernetesRobotTokensList';
export const KubernetesTokensSync = 'kubernetesTokensSync';
export const KubernetesUserTokensForm = 'kubernetesUserTokensForm';
export const KubernetesUserTokensList = 'kubernetesUserTokensList';

export const KubernetesModule = angular
  .module('app.kubernetes', [])
  .component(KubernetesClustersForm, KubernetesClustersFormComponent)
  .component(KubernetesClustersList, KubernetesClustersListComponent)
  .component(KubernetesRobotTokensForm, KubernetesRobotTokensFormComponent)
  .component(KubernetesRobotTokensList, KubernetesRobotTokensListComponent)
  .component(KubernetesTokensSync, KubernetesTokensSyncComponent)
  .component(KubernetesUserTokensForm, KubernetesUserTokensFormComponent)
  .component(KubernetesUserTokensList, KubernetesUserTokensListComponent)
  .name;
