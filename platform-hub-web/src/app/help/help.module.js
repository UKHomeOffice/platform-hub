import angular from 'angular';

import {FaqComponent} from './faq/faq.component';
import {FaqEntriesComponent} from './faq/faq-entries.component';
import {SearchComponent} from './search/search.component.js';
import {SupportRequestsFormComponent} from './support/requests/support-requests-form.component';
import {SupportRequestsOverviewComponent} from './support/requests/support-requests-overview.component';
import {SupportRequestTemplatesDetailComponent} from './support/request-templates/support-request-templates-detail.component';
import {SupportRequestTemplatesFormComponent} from './support/request-templates/support-request-templates-form.component';
import {SupportRequestTemplatesListComponent} from './support/request-templates/support-request-templates-list.component';

// Main section component names
export const Faq = 'faq';
export const FaqEntries = 'faqEntries';
export const Search = 'search';
export const SupportRequestsForm = 'supportRequestsForm';
export const SupportRequestsOverview = 'supportRequestsOverview';
export const SupportRequestTemplatesDetail = 'supportRequestTemplatesDetail';
export const SupportRequestTemplatesForm = 'supportRequestTemplatesForm';
export const SupportRequestTemplatesList = 'supportRequestTemplatesList';

export const HelpModule = angular
  .module('app.help', [])
  .component(Faq, FaqComponent)
  .component(FaqEntries, FaqEntriesComponent)
  .component(Search, SearchComponent)
  .component(SupportRequestsForm, SupportRequestsFormComponent)
  .component(SupportRequestsOverview, SupportRequestsOverviewComponent)
  .component(SupportRequestTemplatesDetail, SupportRequestTemplatesDetailComponent)
  .component(SupportRequestTemplatesForm, SupportRequestTemplatesFormComponent)
  .component(SupportRequestTemplatesList, SupportRequestTemplatesListComponent)
  .name;
