/* eslint camelcase: 0 */

export const CostsAndResourcesAnalysisComponent = {
  template: require('./costs-and-resources-analysis.html'),
  controller: costsAndResourcesAnalysisController
};

function costsAndResourcesAnalysisController($q, Projects, CostsReports, d3, logger, _) {
  'ngInject';

  const COLORS_FOR_METRICS = {
    'cpu.used.percent': '#d62728',
    'memory.used.percent': '#1f77b4',
    default: '#343434'
  };

  const ctrl = this;

  ctrl.Projects = Projects;

  ctrl.namespacesUsageChartOptions = buildNamespacesUsageChartOptions();

  ctrl.loading = true;
  ctrl.availableBillingFiles = [];
  ctrl.availableMetricsFiles = [];
  ctrl.selectedProject = null;
  ctrl.selectedBillingFile = null;
  ctrl.selectedMetricsFile = null;
  ctrl.data = null;
  ctrl.charts = null;

  ctrl.isReadyToAnalyse = isReadyToAnalyse;
  ctrl.analyse = analyse;

  init();

  function init() {
    ctrl.loading = true;

    const projectsPromise = Projects.refresh();

    const filesPromise = CostsReports
      .getAvailableDataFiles()
      .then(([billingFiles, metricsFiles]) => {
        ctrl.availableBillingFiles = billingFiles;
        ctrl.availableMetricsFiles = metricsFiles;
      });

    $q
      .all([projectsPromise, filesPromise])
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function isReadyToAnalyse() {
    return _.every(
      [
        ctrl.selectedProject,
        ctrl.selectedBillingFile,
        ctrl.selectedMetricsFile
      ],
      Boolean
    );
  }

  function analyse() {
    if (!isReadyToAnalyse()) {
      logger.error('Please fill in the necessary data before analysing');
      return;
    }

    ctrl.data = null;

    ctrl.loading = true;

    CostsReports
      .prepareAnalysis({
        project_id: ctrl.selectedProject.id,
        billing_file: ctrl.selectedBillingFile,
        metrics_file: ctrl.selectedMetricsFile
      })
      .then(data => {
        ctrl.data = data;
        console.log(ctrl.data); // eslint-disable-line

        ctrl.charts = buildCharts(data);
        console.log(ctrl.charts); // eslint-disable-line
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }

  function buildCharts(data) {
    const results = {
      namespacesUsage: {}
    };

    function processNamespaces(namespaces) {
      if (_.isEmpty(namespaces)) {
        return [];
      }

      const byMetric = _.toPairs(namespaces).reduce((acc, [name, n]) => {
        _.forEach(n.averages.metrics, (metricValue, metricName) => {
          if (!_.has(acc, metricName)) {
            acc[metricName] = [];
          }
          acc[metricName].push({
            label: name,
            value: metricValue
          });
        });
        return acc;
      }, {});

      return _.map(byMetric, (values, metricName) => {
        return {
          key: metricName,
          color: COLORS_FOR_METRICS[metricName] || COLORS_FOR_METRICS.default,
          values
        };
      });
    }

    _.forEach(data, (c, clusterName) => {
      console.log(clusterName); //eslint-disable-line
      results.namespacesUsage[clusterName] = processNamespaces(c.namespaces);
    });

    return results;
  }

  function buildNamespacesUsageChartOptions() {
    return {
      chart: {
        type: 'multiBarHorizontalChart',
        height: 500,
        x(d) {
          return d.label;
        },
        y(d) {
          return d.value;
        },
        showControls: true,
        showValues: false,
        duration: 500,
        xAxis: {
          showMaxMin: true
        },
        yAxis: {
          axisLabel: 'Avg % usage',
          tickFormat(d) {
            return d3.format('.2p')(d);
          }
        }
      }
    };
  }
}
