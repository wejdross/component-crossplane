local com = import 'lib/commodore.libjsonnet';
local crossplane = import 'lib/crossplane.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.crossplane;
local on_openshift4 = inv.parameters.facts.distribution == 'openshift4';
local has_service_account(provider) = std.count(std.objectFields(params.serviceAccounts), provider) > 0;
local has_any_service = std.length(std.filter(function(x) std.objectHas(params.serviceAccounts, x), std.objectFields(params.providers))) > 0;

local controller_config_ref(controller_config_name) = {
  controllerConfigRef: {
    name: controller_config_name,
  },
};

local controller_on_openshift = {
  podSecurityContext: {},
  securityContext: {},
};

local controller_with_service_account(provider) = {
  serviceAccountName: provider,
};

local service_accounts = com.generateResources(params.serviceAccounts, kube.ServiceAccount);
local cluster_roles = com.generateResources(params.clusterRoles, kube.ClusterRole);
local cluster_role_bindings = com.generateResources(params.clusterRoleBindings, kube.ClusterRoleBinding);

{
  '00_namespace': kube.Namespace(params.namespace),
  [if std.length(params.providers) > 0 then '10_providers']: [
    crossplane.Provider(provider) {
      spec+: params.providers[provider] +
             if on_openshift4 || has_service_account(provider) then controller_config_ref(provider) else {},
    }
    for provider in std.objectFields(params.providers)
  ],
  [if on_openshift4 || has_any_service then '30_controller_configs']: [
    crossplane.ControllerConfig(provider) {
      spec+:
        (if on_openshift4 then controller_on_openshift else {}) +
        if has_service_account(provider) then controller_with_service_account(provider) else {},
    }
    for provider in std.objectFields(params.providers)
  ],
  [if params.monitoring.enabled then '20_monitoring']: import 'monitoring.libsonnet',
  [if std.length(service_accounts) > 0 then '40_service_accounts']: service_accounts,
  [if std.length(cluster_roles) > 0 then '50_cluster_roles']: cluster_roles,
  [if std.length(cluster_role_bindings) > 0 then '60_cluster_role_bindings']: cluster_role_bindings,
}
