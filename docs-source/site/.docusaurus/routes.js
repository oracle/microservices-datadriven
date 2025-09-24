import React from 'react';
import ComponentCreator from '@docusaurus/ComponentCreator';

export default [
  {
    path: '/microservices-datadriven/obaas/markdown-page',
    component: ComponentCreator('/microservices-datadriven/obaas/markdown-page', 'e67'),
    exact: true
  },
  {
    path: '/microservices-datadriven/obaas/docs',
    component: ComponentCreator('/microservices-datadriven/obaas/docs', '0bd'),
    routes: [
      {
        path: '/microservices-datadriven/obaas/docs',
        component: ComponentCreator('/microservices-datadriven/obaas/docs', 'ba8'),
        routes: [
          {
            path: '/microservices-datadriven/obaas/docs',
            component: ComponentCreator('/microservices-datadriven/obaas/docs', '9ec'),
            routes: [
              {
                path: '/microservices-datadriven/obaas/docs/category/deploy',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/category/deploy', '856'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/category/observability',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/category/observability', 'b25'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/category/platform-services',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/category/platform-services', '9ab'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/category/setup',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/category/setup', 'e32'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/deploy/buildpushapp',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/deploy/buildpushapp', '381'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/deploy/dbaccess',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/deploy/dbaccess', '71e'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/deploy/deployapp',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/deploy/deployapp', '304'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/deploy/introflow',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/deploy/introflow', '63c'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/intro',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/intro', 'ece'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/observability/acces',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/observability/acces', '71f'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/observability/configure',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/observability/configure', 'fd1'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/observability/dashboards',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/observability/dashboards', 'c16'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/observability/dbexporter',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/observability/dbexporter', '0f5'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/observability/metricslogstraces',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/observability/metricslogstraces', '91a'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/observability/overview',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/observability/overview', 'ab4'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/platform/',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/platform/', 'a7f'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/setup/',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/setup/', '02a'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/setup/database',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/setup/database', '83e'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/setup/namespace',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/setup/namespace', '525'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/setup/obaas',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/setup/obaas', '317'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/setup/observability',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/setup/observability', '71c'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/setup/obtaining',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/setup/obtaining', '490'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/setup/prereq-chart',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/setup/prereq-chart', '6f8'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/setup/prereqs',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/setup/prereqs', '9dc'),
                exact: true,
                sidebar: "tutorialSidebar"
              },
              {
                path: '/microservices-datadriven/obaas/docs/setup/secrets',
                component: ComponentCreator('/microservices-datadriven/obaas/docs/setup/secrets', '6ed'),
                exact: true,
                sidebar: "tutorialSidebar"
              }
            ]
          }
        ]
      }
    ]
  },
  {
    path: '/microservices-datadriven/obaas/',
    component: ComponentCreator('/microservices-datadriven/obaas/', '6c3'),
    exact: true
  },
  {
    path: '*',
    component: ComponentCreator('*'),
  },
];
