import angular from 'angular';

import {HubApiModule} from '../hub-api/hub-api.module';
import {UtilModule} from '../util/util.module';

import {Announcements} from './announcements';
import {AppSettings} from './app-settings';
import {FeatureFlags} from './feature-flags';
import {Identities} from './identities';
import {KubernetesClusters} from './kubernetes-clusters';
import {Me} from './me';
import {PlatformThemes} from './platform-themes';
import {PlatformThemesResourceKinds} from './platform-themes-resource-kinds';
import {UserScopes} from './user-scopes';

import {announcementTemplateValidator} from './validators/announcement-template-validator';
import {formFieldsValidator} from './validators/form-fields-validator';

export const ModelModule = angular
  .module('app.shared.model', [
    HubApiModule,
    UtilModule
  ])
  .service('Announcements', Announcements)
  .service('AppSettings', AppSettings)
  .service('FeatureFlags', FeatureFlags)
  .service('Identities', Identities)
  .service('KubernetesClusters', KubernetesClusters)
  .service('Me', Me)
  .service('PlatformThemes', PlatformThemes)
  .service('PlatformThemesResourceKinds', PlatformThemesResourceKinds)
  .service('UserScopes', UserScopes)
  .service('announcementTemplateValidator', announcementTemplateValidator)
  .service('formFieldsValidator', formFieldsValidator)
  .name;
