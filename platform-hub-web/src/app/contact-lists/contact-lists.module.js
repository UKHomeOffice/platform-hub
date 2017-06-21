import angular from 'angular';

import {ContactListsFormComponent} from './contact-lists-form.component';
import {ContactListsListComponent} from './contact-lists-list.component';

// Main section component names
export const ContactListsForm = 'contactListsForm';
export const ContactListsList = 'contactListsList';

export const ContactListsModule = angular
  .module('app.contact-lists', [])
  .component(ContactListsForm, ContactListsFormComponent)
  .component(ContactListsList, ContactListsListComponent)
  .name;
