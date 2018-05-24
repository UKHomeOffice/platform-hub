import angular from 'angular';

import {CostsReportsDetailComponent} from './costs-reports-detail.component';
import {CostsReportsFormComponent} from './costs-reports-form.component';
import {CostsReportsListComponent} from './costs-reports-list.component';

// Main section component names
export const CostsReportsDetail = 'costsReportsDetail';
export const CostsReportsForm = 'costsReportsForm';
export const CostsReportsList = 'costsReportsList';

export const CostsReportsModule = angular
  .module('app.costs-reports', [])
  .component(CostsReportsDetail, CostsReportsDetailComponent)
  .component(CostsReportsForm, CostsReportsFormComponent)
  .component(CostsReportsList, CostsReportsListComponent)
  .name;
