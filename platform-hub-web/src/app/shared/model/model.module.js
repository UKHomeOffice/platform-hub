import angular from 'angular';

import {HubApiModule} from '../hub-api/hub-api.module';
import {UtilModule} from '../util/util.module';

import {AnnouncementTemplates} from './announcement-templates';
import {Announcements} from './announcements';
import {AppSettings} from './app-settings';
import {CostsReports} from './costs-reports';
import {DocsSources} from './docs-sources';
import {FeatureFlags} from './feature-flags';
import {Identities} from './identities';
import {KubernetesClusters} from './kubernetes-clusters';
import {KubernetesGroups} from './kubernetes-groups';
import {KubernetesNamespaces} from './kubernetes-namespaces';
import {KubernetesTokens} from './kubernetes-tokens';
import {Me} from './me';
import {PinnedHelpEntries} from './pinned-help-entries';
import {PlatformThemes} from './platform-themes';
import {PlatformThemesResourceKinds} from './platform-themes-resource-kinds';
import {Projects} from './projects';
import {QaEntries} from './qa-entries';
import {UserScopes} from './user-scopes';

import {announcementTemplateValidator} from './validators/announcement-template-validator';
import {formFieldsValidator} from './validators/form-fields-validator';

export const ModelModule = angular
  .module('app.shared.model', [
    HubApiModule,
    UtilModule
  ])
  .service('AnnouncementTemplates', AnnouncementTemplates)
  .service('Announcements', Announcements)
  .service('AppSettings', AppSettings)
  .service('CostsReports', CostsReports)
  .service('DocsSources', DocsSources)
  .service('FeatureFlags', FeatureFlags)
  .service('Identities', Identities)
  .service('KubernetesClusters', KubernetesClusters)
  .service('KubernetesGroups', KubernetesGroups)
  .service('KubernetesNamespaces', KubernetesNamespaces)
  .service('KubernetesTokens', KubernetesTokens)
  .service('Me', Me)
  .service('PinnedHelpEntries', PinnedHelpEntries)
  .service('PlatformThemes', PlatformThemes)
  .service('PlatformThemesResourceKinds', PlatformThemesResourceKinds)
  .service('Projects', Projects)
  .service('QaEntries', QaEntries)
  .service('UserScopes', UserScopes)
  .service('announcementTemplateValidator', announcementTemplateValidator)
  .service('formFieldsValidator', formFieldsValidator)
  .name;
