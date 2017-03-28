import angular from 'angular';

import {PlatformThemesEditorFormComponent} from './editor/platform-themes-editor-form.component';
import {PlatformThemesEditorListComponent} from './editor/platform-themes-editor-list.component';
import {PlatformThemesPageComponent} from './platform-themes-page.component';

// Main section component names
export const PlatformThemesEditorForm = 'platformThemesEditorForm';
export const PlatformThemesEditorList = 'platformThemesEditorList';
export const PlatformThemesPage = 'platformThemesPage';

export const PlatformThemesModule = angular
  .module('app.platform-themes', [])
  .component(PlatformThemesEditorForm, PlatformThemesEditorFormComponent)
  .component(PlatformThemesEditorList, PlatformThemesEditorListComponent)
  .component(PlatformThemesPage, PlatformThemesPageComponent)
  .name;
