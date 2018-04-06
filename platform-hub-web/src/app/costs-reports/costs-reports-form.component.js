/* eslint camelcase: 0 */

export const CostsReportsFormComponent = {
  template: require('./costs-reports-form.html'),
  controller: CostsReportsFormController
};

function CostsReportsFormController($state, CostsReports, treeDataHelper, logger, moment, _) {
  'ngInject';

  const PREPARE_FIELDS = [
    'year',
    'month',
    'billing_file',
    'metrics_file'
  ];

  const SHARED_BUCKET = 'Shared';

  const ctrl = this;

  ctrl.months = generateMonthsList();
  ctrl.years = generateYearsList();

  ctrl.loading = true;
  ctrl.preparing = false;
  ctrl.saving = false;
  ctrl.availableBillingFiles = [];
  ctrl.availableMetricsFiles = [];
  ctrl.report = null;
  ctrl.prepareResults = null;
  ctrl.prepareResultsTreeData = null;
  ctrl.prepareResultsTreeFilter = null;
  ctrl.availableClusters = [];
  ctrl.availableProjects = [];
  ctrl.mappedMetricsNamespacesCount = null;
  ctrl.allMappedClustersGrouped = null;

  ctrl.handleYearOrMonthChange = handleYearOrMonthChange;
  ctrl.isReadyToPrepare = isReadyToPrepare;
  ctrl.prepare = prepare;
  ctrl.hasSufficientMappingsToContinue = hasSufficientMappingsToContinue;
  ctrl.doMetricWeightsAddUp = doMetricWeightsAddUp;
  ctrl.readyToGenerate = readyToGenerate;
  ctrl.create = create;

  init();

  function generateMonthsList() {
    return moment.localeData('en').monthsShort();
  }

  function generateYearsList() {
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

        handleYearOrMonthChange();
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function initReport() {
    const lastMonth = moment().subtract(1, 'month');
    ctrl.report = {
      year: lastMonth.year(),
      month: lastMonth.format('MMM')
    };
  }

  function initReportConfig() {
    ctrl.report.config = {
      metric_weights: {},
      shared_costs: {
        clusters: [],
        projects: []
      },
      cluster_groups: {}
    };
  }

  function handleYearOrMonthChange() {
    if (ctrl.report && ctrl.report.year && ctrl.report.month) {
      const prefix = `${ctrl.report.year}-${ctrl.report.month}`;
      ctrl.report.billing_file = _.find(ctrl.availableBillingFiles, f => _.startsWith(f, prefix));
      ctrl.report.metrics_file = _.find(ctrl.availableMetricsFiles, f => _.startsWith(f, prefix));
    }
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
    ctrl.prepareResultsTreeData = null;
    ctrl.availableClusters = [];
    ctrl.availableProjects = [];
    ctrl.mappedMetricsNamespacesCount = null;
    ctrl.allMappedClustersGrouped = null;

    initReportConfig();

    ctrl.preparing = true;

    const data = _.pick(ctrl.report, PREPARE_FIELDS);

    return CostsReports
      .prepare(data)
      .then(results => {
        ctrl.prepareResults = results;

        setPrepareResultsTreeData();
        setMetricWeightsDefaults();
        setAvailableClusters();
        setAvailableProjects();
        setMappedMetricsNamespacesCount();
        setAllClustersGrouped();
        setConfigSharedClustersAndGroupedClusters();
      })
      .finally(() => {
        ctrl.preparing = false;
      });
  }

  function hasSufficientMappingsToContinue() {
    return ctrl.prepareResults && ctrl.mappedMetricsNamespacesCount && ctrl.allMappedClustersGrouped;
  }

  function doMetricWeightsAddUp() {
    const weights = ctrl.report.config.metric_weights;
    return weights && _.sum(_.values(weights)) === 100;
  }

  function readyToGenerate() {
    return ctrl.prepareResults &&
      !ctrl.prepareResults.already_published &&
      ctrl.report.config &&
      hasSufficientMappingsToContinue() &&
      doMetricWeightsAddUp();
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

  function setPrepareResultsTreeData() {
    ctrl.prepareResultsTreeData = treeDataHelper.objectToTreeData(ctrl.prepareResults);
  }

  function setMetricWeightsDefaults() {
    ctrl.report.config.metric_weights = {};
    const metrics = ctrl.prepareResults.metrics.metric_types;
    if (metrics && metrics.length) {
      const eachWeight = _.floor(100 / metrics.length);
      metrics.forEach(m => {
        ctrl.report.config.metric_weights[m.name] = eachWeight;
      });
    }
  }

  function setAvailableClusters() {
    ctrl.availableClusters = _.sortBy(
      _.values(ctrl.prepareResults.billing.clusters_and_namespaces.mapped),
      ['cluster_name']
    );
  }

  function setAvailableProjects() {
    ctrl.availableProjects = _.sortBy(
      _.values(ctrl.prepareResults.billing.projects.mapped),
      ['project_shortname']
    );
  }

  function setMappedMetricsNamespacesCount() {
    const mappedMetricsClusters = ctrl.prepareResults.metrics.clusters_and_namespaces.mapped;
    ctrl.mappedMetricsNamespacesCount = _.reduce(mappedMetricsClusters, (count, cluster) => {
      count += _.keys(cluster.namespaces.mapped).length;
      return count;
    }, 0);
  }

  function setAllClustersGrouped() {
    ctrl.allMappedClustersGrouped = _.every(
      _.values(ctrl.prepareResults.billing.clusters_and_namespaces.mapped),
      c => c.costs_bucket
    );
  }

  function setConfigSharedClustersAndGroupedClusters() {
    if (ctrl.allMappedClustersGrouped) {
      const config = ctrl.report.config;
      _.values(ctrl.prepareResults.billing.clusters_and_namespaces.mapped).forEach(c => {
        if (c.costs_bucket.toLowerCase() === SHARED_BUCKET.toLowerCase()) {
          config.shared_costs.clusters.push(c.cluster_name);
        } else {
          if (!_.has(config.cluster_groups, c.costs_bucket)) {
            config.cluster_groups[c.costs_bucket] = [];
          }
          if (!_.includes(config.cluster_groups[c.costs_bucket], c.cluster_name)) {
            config.cluster_groups[c.costs_bucket].push(c.cluster_name);
          }
        }
      });
    }
  }
}
