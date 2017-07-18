import angular from 'angular';

import {AnnouncementsEditorFormComponent} from './editor/announcements-editor-form.component';
import {AnnouncementsEditorListComponent} from './editor/announcements-editor-list.component';
import {AnnouncementTemplatesDetailComponent} from './templates/announcement-templates-detail.component';
import {AnnouncementTemplatesFormComponent} from './templates/announcement-templates-form.component';
import {AnnouncementTemplatesListComponent} from './templates/announcement-templates-list.component';
import {GlobalAnnouncementsComponent} from './global-announcements.component';
import {StickyAnnouncementsComponent} from './sticky-announcements.component';

// Main section component names
export const AnnouncementsEditorForm = 'announcementsEditorForm';
export const AnnouncementsEditorList = 'announcementsEditorList';
export const AnnouncementTemplatesDetail = 'announcementTemplatesDetail';
export const AnnouncementTemplatesForm = 'announcementTemplatesForm';
export const AnnouncementTemplatesList = 'announcementTemplatesList';
export const GlobalAnnouncements = 'globalAnnouncements';

export const AnnouncementsModule = angular
  .module('app.announcements', [])
  .component(AnnouncementsEditorForm, AnnouncementsEditorFormComponent)
  .component(AnnouncementsEditorList, AnnouncementsEditorListComponent)
  .component(AnnouncementTemplatesDetail, AnnouncementTemplatesDetailComponent)
  .component(AnnouncementTemplatesForm, AnnouncementTemplatesFormComponent)
  .component(AnnouncementTemplatesList, AnnouncementTemplatesListComponent)
  .component(GlobalAnnouncements, GlobalAnnouncementsComponent)
  .component('stickyAnnouncements', StickyAnnouncementsComponent)
  .name;
