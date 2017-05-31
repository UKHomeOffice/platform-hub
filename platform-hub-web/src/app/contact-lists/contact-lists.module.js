import angular from 'angular';

import {ContactListFormComponent} from './contact-list-form.component';

// Main section component names
export const ContactListForm = 'contactListForm';

export const ContactListsModule = angular
  .module('app.contact-lists', [])
  .component(ContactListForm, ContactListFormComponent)
  .name;
