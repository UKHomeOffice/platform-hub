module.exports = {
  extends: [
    'angular'
  ],
  plugins: [
    'chai-friendly'
  ],
  rules: {
    'max-params': 0,
    'max-nested-callbacks': ["warn", 10],
    'angular/no-service-method': 0,
    "no-unused-expressions": 0,
    "chai-friendly/no-unused-expressions": 2
  }
}
