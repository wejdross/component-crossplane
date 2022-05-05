local com = import 'lib/commodore.libjsonnet';
local inv = com.inventory();

local helmchart_dir = std.extVar('output_path');
local on_openshift4 = inv.parameters.facts.distribution;

local fixup(obj) =
  if obj.kind == 'Deployment' then
    obj {
      spec+: {
        template+: {
          spec+: {
            containers: [
              c {
                securityContext+: {
                  runAsUser: null,
                },
              }
              for c in obj.spec.template.spec.containers
            ],
          },
        },
      },
    }
  else
    obj;

if on_openshift4 == 'openshift4' then
  com.fixupDir(std.extVar('output_path'), fixup)
else
  {}
