import angular from 'angular';

import {UsersListComponent} from './users-list.component';

// Main section component names
export const UsersList = 'usersList';

export const UsersModule = angular
  .module('app.users', [])
  .component(UsersList, UsersListComponent)
  .name;
