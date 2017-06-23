import angular from 'angular';

import {HubApiModule} from '../hub-api/hub-api.module';
import {UtilModule} from '../util/util.module';

import {Announcements} from './announcements';
import {AppSettings} from './app-settings';
import {Identities} from './identities';
import {Me} from './me';
import {PlatformThemes} from './platform-themes';
import {PlatformThemesResourceKinds} from './platform-themes-resource-kinds';
import {UserScopes} from './user-scopes';

export const ModelModule = angular
  .module('app.shared.model', [
    HubApiModule,
    UtilModule
  ])
  .service('Announcements', Announcements)
  .service('AppSettings', AppSettings)
  .service('Identities', Identities)
  .service('Me', Me)
  .service('PlatformThemes', PlatformThemes)
  .service('PlatformThemesResourceKinds', PlatformThemesResourceKinds)
  .service('UserScopes', UserScopes)
  .name;
