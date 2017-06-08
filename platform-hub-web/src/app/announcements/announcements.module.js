import angular from 'angular';

import {AnnouncementsEditorFormComponent} from './editor/announcements-editor-form.component';
import {AnnouncementsEditorListComponent} from './editor/announcements-editor-list.component';
import {GlobalAnnouncementsComponent} from './global-announcements.component';
import {StickyAnnouncementsComponent} from './sticky-announcements.component';

// Main section component names
export const AnnouncementsEditorForm = 'announcementsEditorForm';
export const AnnouncementsEditorList = 'announcementsEditorList';
export const GlobalAnnouncements = 'globalAnnouncements';

export const AnnouncementsModule = angular
  .module('app.announcements', [])
  .component(AnnouncementsEditorForm, AnnouncementsEditorFormComponent)
  .component(AnnouncementsEditorList, AnnouncementsEditorListComponent)
  .component(GlobalAnnouncements, GlobalAnnouncementsComponent)
  .component('stickyAnnouncements', StickyAnnouncementsComponent)
  .name;
