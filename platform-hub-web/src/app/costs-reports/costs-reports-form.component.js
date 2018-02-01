/* eslint camelcase: 0 */

export const CostsReportsFormComponent = {
  template: require('./costs-reports-form.html'),
  controller: CostsReportsFormController
};

function CostsReportsFormController($state, CostsReports, logger, moment, _) {
  'ngInject';

  const PREPARE_FIELDS = [
    'year',
    'month',
    'billing_file',
    'metrics_file'
  ];

  const ctrl = this;

  ctrl.months = moment.localeData('en').monthsShort();
  ctrl.years = generateYears();

  ctrl.loading = true;
  ctrl.preparing = false;
  ctrl.saving = false;
  ctrl.availableBillingFiles = [];
  ctrl.availableMetricsFiles = [];
  ctrl.report = null;
  ctrl.prepareResults = null;
  ctrl.projectsForExclusionsList = [];

  ctrl.isReadyToPrepare = isReadyToPrepare;
  ctrl.prepare = prepare;
  ctrl.hasSufficientMappingsToContinue = hasSufficientMappingsToContinue;
  ctrl.doMetricWeightsAddUp = doMetricWeightsAddUp;
  ctrl.create = create;

  init();

  function generateYears() {
    const currentYear = moment().year();
    return _.range(currentYear - 5, currentYear + 1);
  }

  function init() {
    ctrl.loading = true;

    CostsReports
      .getAvailableDataFiles()
      .then(([billingFiles, metricsFiles]) => {
        ctrl.availableBillingFiles = billingFiles;
        ctrl.availableMetricsFiles = metricsFiles;

        initReport();
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function initReport() {
    const lastMonth = moment().subtract(1, 'month');
    ctrl.report = {
      year: lastMonth.year(),
      month: lastMonth.format('MMM'),
      config: {
        shared_costs: {
          clusters: [],
          allocation_percentage: 100
        },
        metric_weights: {},
        excluded_projects: []
      }
    };
  }

  function isReadyToPrepare() {
    return _.every(PREPARE_FIELDS, f => Boolean(_.get(ctrl.report, f)));
  }

  function prepare() {
    if (!isReadyToPrepare()) {
      logger.error('Please fill in the necessary data before preparing');
      return;
    }

    ctrl.prepareResults = null;
    ctrl.projectsForExclusionsList = [];

    ctrl.preparing = true;

    const data = _.pick(ctrl.report, PREPARE_FIELDS);

    return CostsReports
      .prepare(data)
      .then(results => {
        ctrl.prepareResults = results;

        // Set metric weights defaults
        const metrics = ctrl.prepareResults.metrics;
        if (metrics && metrics.length) {
          const eachWeight = _.floor(100 / metrics.length);
          metrics.forEach(m => {
            ctrl.report.config.metric_weights[m.name] = eachWeight;
          });
        }

        // Find all mapped projects
        const projectsMap = results.namespaces.mapped.reduce((acc, n) => {
          if (!_.has(acc, n.project_id)) {
            acc[n.project_id] = {
              id: n.project_id,
              name: n.project_shortname
            };
          }
          return acc;
        }, {});
        angular.copy(
          _.sortBy(_.values(projectsMap), ['name']),
          ctrl.projectsForExclusionsList
        );
      })
      .finally(() => {
        ctrl.preparing = false;
      });
  }

  function hasSufficientMappingsToContinue() {
    const unmappedAccounts = _.get(ctrl.prepareResults, 'accounts.unmapped');
    const mappedNamespaces = _.get(ctrl.prepareResults, 'namespaces.mapped');
    return ctrl.prepareResults &&
      !unmappedAccounts.length &&
      mappedNamespaces.length;
  }

  function doMetricWeightsAddUp() {
    const weights = ctrl.report.config.metric_weights;
    return weights && _.sum(_.values(weights)) === 100;
  }

  function create() {
    ctrl.saving = true;

    CostsReports
      .create(ctrl.report)
      .then(() => {
        logger.success('Costs report successfully generated');
        $state.go('costs-reports.list');
      })
      .finally(() => {
        ctrl.saving = false;
      });
  }
}
