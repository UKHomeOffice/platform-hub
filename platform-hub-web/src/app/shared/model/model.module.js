import angular from 'angular';

import {HubApiModule} from '../hub-api/hub-api.module';

import {AppSettings} from './app-settings';
import {PlatformThemesList} from './platform-themes-list';
import {PlatformThemesResourceKinds} from './platform-themes-resource-kinds';

export const ModelModule = angular
  .module('app.shared.model', [
    HubApiModule
  ])
  .service('AppSettings', AppSettings)
  .service('PlatformThemesList', PlatformThemesList)
  .service('PlatformThemesResourceKinds', PlatformThemesResourceKinds)
  .name;
