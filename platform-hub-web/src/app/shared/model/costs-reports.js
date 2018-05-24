export const CostsReports = function (hubApiService, _) {
  'ngInject';

  const model = {};

  model.getAvailableDataFiles = getAvailableDataFiles;
  model.getAll = hubApiService.getCostsReports;
  model.get = hubApiService.getCostsReport;
  model.prepare = hubApiService.prepareCostsReport;
  model.create = hubApiService.createCostsReport;
  model.delete = hubApiService.deleteCostsReport;
  model.publish = hubApiService.publishCostsReport;

  return model;

  function getAvailableDataFiles() {
    const billingFiles = [];
    const metricsFiles = [];

    return hubApiService
      .getCostsReportsAvailableDataFiles()
      .then(entries => {
        entries.forEach(f => {
          if (_.includes(f, 'billing')) {
            billingFiles.push(f);
          } else if (_.includes(f, 'metrics')) {
            metricsFiles.push(f);
          }
        });

        return [
          billingFiles,
          metricsFiles
        ];
      });
  }
};
