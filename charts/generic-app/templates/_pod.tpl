{{/*
================================================================================
POD TEMPLATE
================================================================================
*/}}

{{/*
Pod template shared by the Deployment, StatefulSet and DaemonSet.
Usage (under the workload's spec):
  template: {{- include "generic-app.podTemplate" . | nindent 4 }}
Optional keys are emitted only when they carry a value, so the manifest matches
what the API server stores and GitOps diffs stay quiet.
*/}}
{{- define "generic-app.podTemplate" -}}
metadata:
  {{- with include "generic-app.podAnnotations" . }}
  annotations: {{- . | nindent 4 }}
  {{- end }}
  labels: {{- include "generic-app.podLabels" . | nindent 4 }}
spec:
  {{- with include "generic-app.imagePullSecrets" . }}
  imagePullSecrets: {{- . | nindent 4 }}
  {{- end }}
  serviceAccountName: {{ include "generic-app.serviceAccountName" . }}
  automountServiceAccountToken: {{ .Values.serviceAccount.automountServiceAccountToken }}
  {{- if .Values.podSecurityContext.enabled }}
  securityContext: {{- omit .Values.podSecurityContext "enabled" | toYaml | nindent 4 }}
  {{- end }}
  {{- with .Values.hostAliases }}
  hostAliases: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if .Values.affinity }}
  affinity: {{- include "generic-app.tplvalues.render" (dict "value" .Values.affinity "context" $) | nindent 4 }}
  {{- else }}
  {{- $podAffinity := include "generic-app.affinities.podAffinity" . | trim }}
  {{- $podAntiAffinity := include "generic-app.affinities.podAntiAffinity" . | trim }}
  {{- $nodeAffinity := include "generic-app.affinities.nodes" . | trim }}
  {{- if or $podAffinity $podAntiAffinity $nodeAffinity }}
  affinity:
    {{- with $podAffinity }}
    podAffinity: {{- . | nindent 6 }}
    {{- end }}
    {{- with $podAntiAffinity }}
    podAntiAffinity: {{- . | nindent 6 }}
    {{- end }}
    {{- with $nodeAffinity }}
    nodeAffinity: {{- . | nindent 6 }}
    {{- end }}
  {{- end }}
  {{- end }}
  {{- with .Values.nodeSelector }}
  nodeSelector: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.topologySpreadConstraints }}
  topologySpreadConstraints: {{- include "generic-app.tplvalues.render" (dict "value" . "context" $) | nindent 4 }}
  {{- end }}
  {{- with .Values.priorityClassName }}
  priorityClassName: {{ . | quote }}
  {{- end }}
  {{- with .Values.schedulerName }}
  schedulerName: {{ . | quote }}
  {{- end }}
  {{- with .Values.runtimeClassName }}
  runtimeClassName: {{ . | quote }}
  {{- end }}
  {{- if include "generic-app.isSet" .Values.terminationGracePeriodSeconds }}
  terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
  {{- end }}
  {{- with .Values.initContainers }}
  initContainers: {{- include "generic-app.tplvalues.render" (dict "value" . "context" $) | nindent 4 }}
  {{- end }}
  containers:
    - name: {{ .Chart.Name }}
      image: {{ include "generic-app.image" . }}
      {{- with .Values.image.pullPolicy }}
      imagePullPolicy: {{ . }}
      {{- end }}
      {{- if .Values.containerSecurityContext.enabled }}
      securityContext: {{- omit .Values.containerSecurityContext "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- with .Values.command }}
      command: {{- include "generic-app.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
      {{- end }}
      {{- with .Values.args }}
      args: {{- include "generic-app.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
      {{- end }}
      {{- with .Values.extraEnvVars }}
      env: {{- include "generic-app.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
      {{- end }}
      {{- if or .Values.extraEnvVarsConfigMaps .Values.extraEnvVarsSecrets }}
      envFrom:
        {{- range .Values.extraEnvVarsConfigMaps }}
        - configMapRef:
            name: {{ include "generic-app.tplvalues.render" (dict "value" . "context" $) }}
        {{- end }}
        {{- range .Values.extraEnvVarsSecrets }}
        - secretRef:
            name: {{ include "generic-app.tplvalues.render" (dict "value" . "context" $) }}
        {{- end }}
      {{- end }}
      {{- with include "generic-app.containerPorts" . | fromYaml }}
      ports:
        {{- range $name, $port := . }}
        - name: {{ $name }}
          containerPort: {{ $port }}
          protocol: TCP
        {{- end }}
      {{- end }}
      {{- if .Values.customLivenessProbe }}
      livenessProbe: {{- include "generic-app.tplvalues.render" (dict "value" .Values.customLivenessProbe "context" $) | nindent 8 }}
      {{- else if .Values.livenessProbe.enabled }}
      livenessProbe: {{- omit .Values.livenessProbe "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- if .Values.customReadinessProbe }}
      readinessProbe: {{- include "generic-app.tplvalues.render" (dict "value" .Values.customReadinessProbe "context" $) | nindent 8 }}
      {{- else if .Values.readinessProbe.enabled }}
      readinessProbe: {{- omit .Values.readinessProbe "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- if .Values.customStartupProbe }}
      startupProbe: {{- include "generic-app.tplvalues.render" (dict "value" .Values.customStartupProbe "context" $) | nindent 8 }}
      {{- else if .Values.startupProbe.enabled }}
      startupProbe: {{- omit .Values.startupProbe "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- with .Values.lifecycleHooks }}
      lifecycle: {{- include "generic-app.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
      {{- end }}
      {{- with .Values.resources }}
      resources: {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if or .Values.persistence.enabled .Values.extraVolumeMounts }}
      volumeMounts:
        {{- if .Values.persistence.enabled }}
        - name: data
          mountPath: {{ .Values.persistence.mountPath }}
          {{- with .Values.persistence.subPath }}
          subPath: {{ . }}
          {{- end }}
        {{- end }}
        {{- with .Values.extraVolumeMounts }}
        {{- include "generic-app.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
        {{- end }}
      {{- end }}
    {{- with .Values.sidecars }}
    {{- include "generic-app.tplvalues.render" (dict "value" . "context" $) | nindent 4 }}
    {{- end }}
  {{- /*
  The data volume: a StatefulSet gets it from volumeClaimTemplates unless an
  existing claim is shared; the other kinds mount the chart PVC or the existing one.
  */}}
  {{- $dataClaim := "" }}
  {{- if .Values.persistence.enabled }}
  {{- if .Values.persistence.existingClaim }}
  {{- $dataClaim = .Values.persistence.existingClaim }}
  {{- else if ne .Values.kind "StatefulSet" }}
  {{- $dataClaim = include "generic-app.fullname" . }}
  {{- end }}
  {{- end }}
  {{- if or $dataClaim .Values.extraVolumes }}
  volumes:
    {{- with $dataClaim }}
    - name: data
      persistentVolumeClaim:
        claimName: {{ . }}
    {{- end }}
    {{- with .Values.extraVolumes }}
    {{- include "generic-app.tplvalues.render" (dict "value" . "context" $) | nindent 4 }}
    {{- end }}
  {{- end }}
{{- end -}}
