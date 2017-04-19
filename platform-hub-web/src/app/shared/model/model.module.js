import angular from 'angular';

import {HubApiModule} from '../hub-api/hub-api.module';
import {UtilModule} from '../util/util.module';

import {AppSettings} from './app-settings';
import {Me} from './me';
import {PlatformThemesList} from './platform-themes-list';
import {PlatformThemesResourceKinds} from './platform-themes-resource-kinds';

export const ModelModule = angular
  .module('app.shared.model', [
    HubApiModule,
    UtilModule
  ])
  .service('AppSettings', AppSettings)
  .service('Me', Me)
  .service('PlatformThemesList', PlatformThemesList)
  .service('PlatformThemesResourceKinds', PlatformThemesResourceKinds)
  .name;
