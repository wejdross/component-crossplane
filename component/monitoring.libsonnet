local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.crossplane;

local name = 'crossplane';
local labels = {
  'app.kubernetes.io/name': name,
  'app.kubernetes.io/managed-by': 'syn',
};

[
  kube.Service(name + '-metrics') {
    metadata+: {
      namespace: params.namespace,
      labels+: labels,
    },
    spec+: {
      selector: {
        release: 'crossplane',
      },
      ports: [ {
        name: 'metrics',
        port: 8080,
      } ],
    },
  },
  kube._Object('monitoring.coreos.com/v1', 'ServiceMonitor', name) {
    metadata+: {
      namespace: params.namespace,
      labels+: labels,
    },
    spec: {
      endpoints: [ {
        port: 'metrics',
        path: '/metrics',
      } ],
      selector: {
        matchLabels: labels,
      },
    },
  },
  kube._Object('monitoring.coreos.com/v1', 'PrometheusRule', name) {
    metadata+: {
      namespace: params.namespace,
      labels+: labels {
        role: 'alert-rules',
      } + params.monitoring.prometheus_rule_labels,
    },
    spec: {
      groups: [
        {
          name: 'crossplane.rules',
          rules: [
            {
              alert: 'CrossplaneDown',
              expr: 'up{namespace="' + params.namespace + '", job=~"^crossplane-.+$"} != 1',
              'for': '10m',
              labels: {
                severity: 'critical',
                syn: 'true',
              },
              annotations: {
                summary: 'Crossplane controller is down',
                description: 'Crossplane pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is down',
              },
            },
          ],
        },
      ],
    },
  },
]
