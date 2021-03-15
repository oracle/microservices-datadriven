/*
 ** Copyright (c) 2021 Oracle and/or its affiliates.
 ** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */
   define(['ojs/ojcomposite', 'text!./oj-spatial-map-view.html', './oj-spatial-map-viewModel', 'text!./component.json', 'css!./styles'],
    function(Composite, view, viewModel, metadata) {
      Composite.register('oj-spatial-map', {
        view: view,
        viewModel: viewModel,
        metadata: JSON.parse(metadata)
      });
    }
  );