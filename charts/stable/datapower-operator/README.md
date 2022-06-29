# IBM DataPower Operator Chart

## Introduction

The IBM DataPower Operator manages StatefulSets of DataPower Pods following configuration defined in DataPowerService Custom Resources.

## Chart Details

This chart deploys a DataPower Operator Deployment into a namespace. The DataPowerService CRD will be deployed from this chart if and only if a version of it does not already exist in the cluster.

## Prerequisites

- Helm v3
- Kubernetes/OpenShift cluster

### PodDisruptionBudget

The DataPower Operator is recommended to have a single instance active at all time. The following PodDisruptionBudget can be created to enforce this.

```yaml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: datapower-operator-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      name: datapower-operator
```

### PodSecurityPolicy Requirements

Custom PodSecurityPolicy definition:

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: ibm-datapower-operator-restricted-psp
spec:
  allowPrivilegeEscalation: false
  forbiddenSysctls:
  - '*'
  hostNetwork: false
  hostPorts: false
  requiredDropCapabilities:
  - ALL
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  volumes:
  - configMap
  - emptyDir
  - projected
  - secret
  - downwardAPI
  - persistentVolumeClaim
```

### SecurityContextConstraints Requirements

Custom SecurityContextConstraints definition:

```yaml
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: ibm-datapower-operator-scc
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: false
allowPrivilegedContainer: false
allowedCapabilities: null
defaultAddCapabilities: null
groups:
- system:authenticated
priority: null
readOnlyRootFilesystem: false
requiredDropCapabilities:
- KILL
- MKNOD
- SETUID
- SETGID
runAsUser:
  type: MustRunAsNonRoot
seLinuxContext:
  type: MustRunAs
users: []
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
```

### Multiple Failure Zones

This chart is configured to spread DataPower Operator pods evenly across multiple Kubernetes zones. To take advantage of this functionality, follow the [prerequisites](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/#prerequisites) for Pod Topology Spread Constraints.

With EvenPodsSpread enabled in the cluster, no more than one Operator pod will be deployed per zone. If replicaCount is higher than the number of available zones, the remaining replicas will not be scheduled.

## Resources Required

The DataPower Operator requires a minimum of

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
```

## Installing the Chart

To install this chart, issue the following command:

```
helm install <name> .
```

See configuration section below for information regarding tuning your operator installation.

## Uninstalling the Chart

To uninstall this chart, issue the following command:

```
helm uninstall <name>
```

Due to [limitations](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/) in Helm, the Custom Resource Definitions (CRDs) are not deleted when the operator is uninstalled via Helm. To clean up the CRDs, issue the following commands:

```
kubectl delete crd/datapowerservices.datapower.ibm.com
kubectl delete crd/datapowermonitors.datapower.ibm.com
kubectl delete crd/datapowerservicebindings.datapower.ibm.com
kubectl delete crd/datapowerrollouts.datapower.ibm.com
```

**Warning:** Deleting the CRDs will cause all Custom Resource (CR) instances to also be deleted.

## Configuration
### Chart values

|Value|Description|Default|
|-|-|-|
|`operator.replicas`|Number of Operator pods to deploy|`1`|
|`operator.image.repository`|Repository containing Operator image|`icr.io/cpopen/datapower-operator`|
|`operator.image.tag`|Name of Operator image|`latest`|
|`operator.image.pullPolicy`|Image pull policy for Operator|`Always`|
|`operator.imagePullSecrets`|List of pull secret names|`[]`|
|`operator.installMode`|InstallMode of the operator|`OwnNamespace`|
|`operator.watchNamespaces`|Namespaces the Operator should watch|`[]`|
|`operator.logLevel`|Set logLevel for Operator pod|`info`|

#### `operator.replicas`

This Operator supports deploying with multiple replicas across multiple zones. When more than one Operator pod is present, a leader will be determined. Only the leader manages DataPower StatefulSets.

#### `operator.imagePullSecrets`

Optional list of pull secrets if operator images are pulled from a registry which requires authentication. Example syntax:

```yaml
operator:
  imagePullSecrets:
    - name: my-pull-secret
```

#### `operator.installMode`

This can be one of four options:
- OwnNamespace
- SingleNamespace
- MultiNamespace
- AllNamespaces

**OwnNamespace**

OwnNamespace makes the Operator listen in the namespace it is installed in and nowhere else. With this option, `operator.watchNamespaces` is ignored.

**SingleNamespace**

SingleNamespace makes the Operator listen to an arbitrary namespace, defined in `operator.watchNamespaces`. With this option, the first namespace in the `operator.watchNamespaces` list is used, the rest are ignored.

**MultiNamespace**

MultiNamespace makes the Operator listen to any number of arbitrary namespaces, defined in `operator.watchNamespaces`. With this option, all namespaces defined in `operator.watchNamespaces` are used.

**AllNamespaces**

AllNamespaces makes the Operator listen to all namespaces. With this option, `operator.watchNamespaces` is ignored.

#### `operator.watchNamespaces`

This is a list of namespaces the Operator should watch. Usage of this list is dependent on the `operator.installMode`.

#### `operator.logLevel`

Log level can be set to one of:
- error
- info
- debug
- integer > 0

This value will adjust the verbosity of the logs produced by the Operator. Default value is `info`. Operator logs currently only support `error`, `info`, and `debug` logs, setting an integer higher than 1 will increase the verbosity of library code while higher than 4 will set the verbosity level of `client-go` for Kubernetes API logging.

### Operator Components

|Resource Type|Name Format|Created By|
|-|-|-|
|Cluster Role|`<release>-<namespace>-datapower-operator`|Chart|
|Cluster Role Binding|`<release>-<namespace>-datapower-operator`|Chart|
|Deployment|`<release>-datapower-operator`|Chart|
|Role|`<release>-<namespace>-datapower-operator`|Chart|
|Role Binding|`<release>-<namespace>-datapower-operator`|Chart|
|Service Account|`<release>-<namespace>-datapower-operator`|Chart|
|MutatingWebhookConfigurations|`<namespace>.datapowerservices.defaulter.datapower.ibm.com`|Operator|
|ValidatingWebhookConfigurations|`<namespace>.datapowerservices.validator.datapower.ibm.com`|Operator|
|Secret (webhook TLS)|`datapower-operator`|Operator|

## Limitations

This chart is able to be installed in development, nonproduction, and production environments.
