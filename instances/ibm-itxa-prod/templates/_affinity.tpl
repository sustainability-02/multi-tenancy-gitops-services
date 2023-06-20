# Licensed Materials - Property of IBM
# IBM Transformation Extender Advanced (5724-Q23)
# (C) Copyright IBM Corp. 2021, 2022 All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

{{/* affinity - https://kubernetes.io/docs/concepts/configuration/assign-pod-node/ */}}




{{- define "itxa-chart.nodeaffinity.onlyArch" }}
#https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    {{- include "itxa-chart.nodeAffinityRequiredDuringScheduling" . }}
    preferredDuringSchedulingIgnoredDuringExecution:
    {{- include "itxa-chart.nodeAffinityPreferredDuringScheduling" . | indent 4 }}
{{- end }}


/*  If you specify multiple nodeSelectorTerms associated with nodeAffinity types,
    then the pod can be scheduled onto a node if one of the nodeSelectorTerms is satisfied.
    
    If you specify multiple matchExpressions associated with nodeSelectorTerms,
    then the pod can be scheduled onto a node only if all matchExpressions can be satisfied.
    
    valid operators: In, NotIn, Exists, DoesNotExist, Gt, Lt
 */
{{- define "itxa-chart.nodeAffinityRequiredDuringScheduling" }}
      nodeSelectorTerms:
      - matchExpressions:
      {{- include "itxa-chart.nodeAffinityArchRequired.matchExpressions" . | indent 8}}
{{- end }}



/*
  Apply the architecture nodeAffinity matchExpression to each of the matchExpressions provided in values.yaml.
*/
{{- define "itxa-chart.nodeAffinity" }}
{{- $rootCtx := index . 0 }}
{{- $currNodeAffinity := index . 1 }}
{{- $archRequiredMatchExpressions := include "itxa-chart.nodeAffinityArchRequired.matchExpressions" $rootCtx }}
{{- $archPreferred := include "itxa-chart.nodeAffinityPreferredDuringScheduling" $rootCtx }}
nodeAffinity:
  requiredDuringSchedulingIgnoredDuringExecution:
    nodeSelectorTerms:
    {{- if and ( $currNodeAffinity ) ( $currNodeAffinity.requiredDuringSchedulingIgnoredDuringExecution) }}
      {{- $nodeSelectorTerms := $currNodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms | default list }}
      {{- if gt (len $nodeSelectorTerms) 0  }}
        {{- range $nodeSelectorTerms }}
          {{- $nodeSelectorTerm := . }}
    - matchExpressions:
          {{- $archRequiredMatchExpressions | indent 6 }}
          {{- $matchExpressions := $nodeSelectorTerm.matchExpressions | default list }}
          {{- if gt (len $matchExpressions) 0 }}
{{ toYaml $nodeSelectorTerm.matchExpressions | indent 6 }}
          {{- end }}
        {{- end }}
      {{- else }}
    - matchExpressions:
      {{- $archRequiredMatchExpressions | indent 6 }}
      {{- end }}
    {{- else }}
    - matchExpressions:
      {{- $archRequiredMatchExpressions | indent 6 }}
    {{- end }}
  preferredDuringSchedulingIgnoredDuringExecution:
  {{- $archPreferred | indent 2 }}
  {{- $preferDuringSchIgnoreDuringExec := $currNodeAffinity.preferredDuringSchedulingIgnoredDuringExecution | default list }}
  {{- if gt ( len $preferDuringSchIgnoreDuringExec ) 0 }}
{{ toYaml $preferDuringSchIgnoreDuringExec | indent 2 }}
  {{- end }}
{{- end }}


/*
  Pod affinity
*/
{{- define "itxa-chart.podAffinity" }}
{{- $rootCtx := index . 0 }}
{{- $currPodAffinity := index . 1 }}
podAffinity:
  {{- if $currPodAffinity }}
    {{- $reqdDuringSchedulingIgnoredDuringExecutions := $currPodAffinity.requiredDuringSchedulingIgnoredDuringExecution | default list }}
    {{- if gt (len $reqdDuringSchedulingIgnoredDuringExecutions) 0  }}
  requiredDuringSchedulingIgnoredDuringExecution:
{{ toYaml $reqdDuringSchedulingIgnoredDuringExecutions | indent 2 }}
    {{- end }}
    {{- $preferedDuringSchedulingIgnoredDuringExecutions := $currPodAffinity.preferredDuringSchedulingIgnoredDuringExecution | default list }}
    {{- if gt (len $preferedDuringSchedulingIgnoredDuringExecutions) 0  }}
  preferredDuringSchedulingIgnoredDuringExecution:
{{ toYaml $preferedDuringSchedulingIgnoredDuringExecutions | indent 2 }}
    {{- end }}
  {{- end }}
{{- end }}


/*
  Pod anti affinity
*/
{{- define "itxa-chart.podAntiAffinity" }}
{{- $rootCtx := index . 0 }}
{{- $currPodAntiAffinity := index . 1 }}
{{- $podLabel := index . 2 }}
{{- $podLabelVal := index . 3 }}
{{- $antiAffinityReplicaNotOnSameNode := $currPodAntiAffinity.replicaNotOnSameNode }}
podAntiAffinity:
  {{- if $currPodAntiAffinity }}
  requiredDuringSchedulingIgnoredDuringExecution:
    {{- include "itxa-chart.podAntiAffinity.requireReplicaNotOnSameNode" (list $podLabel $podLabelVal $antiAffinityReplicaNotOnSameNode) | indent 2 }}
    {{- include "itxa-chart.podAntiAffinity.user.requiredDuringSchedulingIgnoredDuringExecution" $currPodAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution | indent 2 }}
  preferredDuringSchedulingIgnoredDuringExecution:
    {{- include "itxa-chart.podAntiAffinity.preferReplicaNotOnSameNode" (list $podLabel $podLabelVal $antiAffinityReplicaNotOnSameNode) | indent 2 }}
    {{- include "itxa-chart.podAntiAffinity.user.preferredDuringSchedulingIgnoredDuringExecution" $currPodAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution | indent 2 }}
  {{- end }}
{{- end }}





/*
 matchExpression for nodeAffinity based on architecture
*/
{{- define "itxa-chart.nodeAffinityArchRequired.matchExpressions" }}
- key: kubernetes.io/arch
  operator: In
  values:
{{- range $key, $val := .Values.global.arch }}
  {{- if gt ($val | trunc 1 | int) 0 }}
  - {{ $key }}
  {{- end }}
{{- end }}
{{- end }}


/*
  nodeAffinity preference term based on architecture
*/
{{- define "itxa-chart.nodeAffinityPreferredDuringScheduling" }}
  {{- range $key, $val := .Values.global.arch }}
    {{- if gt ($val | trunc 1 | int) 0 }}
- weight: {{ $val | trunc 1 | int }}
  preference:
    matchExpressions:
    - key: kubernetes.io/arch
      operator: In
      values:
      - {{ $key }}
    {{- end }}
  {{- end }}
{{- end }}



/*
  Pod anti affinity matchExpression
*/
{{- define "itxa-chart.podAntiAffinity.matchExpression" }}
  {{- $podLabel := index . 0 }}
  {{- $podLabelVal := index . 1 }}
- key: {{ $podLabel }}
  operator: In
  values:
  - {{ $podLabelVal }}
{{- end }}


/*
  Pod anti affinity prefer replica not on same node
*/
{{- define "itxa-chart.podAntiAffinity.preferReplicaNotOnSameNode" }}
  {{- $podLabel := index . 0 }}
  {{- $podLabelVal := index . 1 }}
  {{- $antiAffinityReplicaNotOnSameNode := index . 2 }}
  {{- $inputMode := $antiAffinityReplicaNotOnSameNode.mode | default "" }}
  {{- if and $antiAffinityReplicaNotOnSameNode (eq $inputMode "prefer") }}
- weight: {{ $antiAffinityReplicaNotOnSameNode.weightForPreference | default 100 }}
  podAffinityTerm:
    labelSelector:
      matchExpressions:
      {{- include "itxa-chart.podAntiAffinity.matchExpression" (list $podLabel $podLabelVal) | indent 6 }}
    topologyKey: kubernetes.io/hostname
  {{- end }}
{{- end }}

/*
  Pod anti affinity matchExpression, require replica not on same node
*/
{{- define "itxa-chart.podAntiAffinity.requireReplicaNotOnSameNode" }}
  {{- $podLabel := index . 0 }}
  {{- $podLabelVal := index . 1 }}
  {{- $antiAffinityReplicaNotOnSameNode := index . 2 }}
  {{- $inputMode := $antiAffinityReplicaNotOnSameNode.mode | default "" }}
  {{- if and $antiAffinityReplicaNotOnSameNode (eq $inputMode "require") }}
- labelSelector:
    matchExpressions:
    {{- include "itxa-chart.podAntiAffinity.matchExpression" (list $podLabel $podLabelVal) | indent 4 }}
  topologyKey: "kubernetes.io/hostname"
  {{- end }}
{{- end }}


/*
  Pod anti affinity : user provided preferredDuringSchedulingIgnoredDuringExecution
*/
{{- define "itxa-chart.podAntiAffinity.user.preferredDuringSchedulingIgnoredDuringExecution" }}
  {{- $preferDuringSchIgnoreDuringExec := . | default list }}
  {{- if gt ( len $preferDuringSchIgnoreDuringExec ) 0 }}
{{ toYaml $preferDuringSchIgnoreDuringExec }}
  {{- end }}
{{- end }}


/*
  Pod anti affinity : user provided requiredDuringSchedulingIgnoredDuringExecution
*/
{{- define "itxa-chart.podAntiAffinity.user.requiredDuringSchedulingIgnoredDuringExecution" }}
  {{- $reqDuringSchIgnoreDuringExec := . | default list }}
  {{- if gt ( len $reqDuringSchIgnoreDuringExec ) 0 }}
{{ toYaml $reqDuringSchIgnoreDuringExec }}
  {{- end }}
{{- end }}