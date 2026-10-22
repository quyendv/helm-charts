{{/*
================================================================================
POD TEMPLATE
================================================================================
*/}}

{{/*
Pod template shared by the Deployment, StatefulSet and DaemonSet.
Usage (under the workload's spec):
  template: {{- include "generic-app.podTemplate" . | nindent 4 }}
*/}}
{{- define "generic-app.podTemplate" -}}
metadata:
  annotations:
    {{- include "generic-app.podAnnotations" . | nindent 4 }}
  labels:
    {{- include "generic-app.selectorLabels" . | nindent 4 }}
    {{- with .Values.podLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- include "generic-app.imagePullSecrets" . | nindent 2 }}
  serviceAccountName: {{ include "generic-app.serviceAccountName" . }}
  {{- if .Values.podSecurityContext.enabled }}
  securityContext: {{- omit .Values.podSecurityContext "enabled" | toYaml | nindent 4 }}
  {{- end }}
  {{- if .Values.hostAliases }}
  hostAliases: {{- toYaml .Values.hostAliases | nindent 4 }}
  {{- end }}
  {{- if .Values.affinity }}
  affinity: {{- toYaml .Values.affinity | nindent 4 }}
  {{- else }}
  affinity:
    podAffinity: {{- include "generic-app.affinities.podAffinity" . | nindent 6 }}
    podAntiAffinity: {{- include "generic-app.affinities.podAntiAffinity" . | nindent 6 }}
    nodeAffinity: {{- include "generic-app.affinities.nodes" . | nindent 6 }}
  {{- end }}
  {{- with .Values.nodeSelector }}
  nodeSelector: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if .Values.topologySpreadConstraints }}
  topologySpreadConstraints: {{- toYaml .Values.topologySpreadConstraints | nindent 4 }}
  {{- end }}
  {{- if .Values.priorityClassName }}
  priorityClassName: {{ .Values.priorityClassName | quote }}
  {{- end }}
  {{- if .Values.schedulerName }}
  schedulerName: {{ .Values.schedulerName | quote }}
  {{- end }}
  {{- if .Values.runtimeClassName }}
  runtimeClassName: {{ .Values.runtimeClassName | quote }}
  {{- end }}
  {{- if .Values.terminationGracePeriodSeconds }}
  terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
  {{- end }}
  {{- if .Values.initContainers }}
  initContainers: {{- include "generic-app.tplvalues.render" (dict "value" .Values.initContainers "context" $) | nindent 4 }}
  {{- end }}
  containers:
    - name: {{ .Chart.Name }}
      image: {{ include "generic-app.image" . }}
      imagePullPolicy: {{ .Values.image.pullPolicy }}
      {{- if .Values.containerSecurityContext.enabled }}
      securityContext: {{- omit .Values.containerSecurityContext "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- if .Values.command }}
      command: {{- include "generic-app.tplvalues.render" (dict "value" .Values.command "context" $) | nindent 8 }}
      {{- end }}
      {{- if .Values.args }}
      args: {{- include "generic-app.tplvalues.render" (dict "value" .Values.args "context" $) | nindent 8 }}
      {{- end }}
      env:
        {{- if .Values.extraEnvVars }}
        {{- include "generic-app.tplvalues.render" (dict "value" .Values.extraEnvVars "context" $) | nindent 8 }}
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
      {{- $ports := .Values.containerPorts | default (ternary .Values.service.ports dict .Values.service.enabled) }}
      {{- if $ports }}
      ports:
        {{- range $name, $port := $ports }}
        - name: {{ $name }}
          containerPort: {{ $port }}
          protocol: TCP
        {{- end }}
      {{- end }}
      {{- if .Values.livenessProbe.enabled }}
      {{- if .Values.customLivenessProbe }}
      livenessProbe: {{- include "generic-app.tplvalues.render" (dict "value" .Values.customLivenessProbe "context" $) | nindent 8 }}
      {{- else }}
      livenessProbe: {{- omit .Values.livenessProbe "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- else if .Values.customLivenessProbe }}
      livenessProbe: {{- include "generic-app.tplvalues.render" (dict "value" .Values.customLivenessProbe "context" $) | nindent 8 }}
      {{- end }}
      {{- if .Values.readinessProbe.enabled }}
      {{- if .Values.customReadinessProbe }}
      readinessProbe: {{- include "generic-app.tplvalues.render" (dict "value" .Values.customReadinessProbe "context" $) | nindent 8 }}
      {{- else }}
      readinessProbe: {{- omit .Values.readinessProbe "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- else if .Values.customReadinessProbe }}
      readinessProbe: {{- include "generic-app.tplvalues.render" (dict "value" .Values.customReadinessProbe "context" $) | nindent 8 }}
      {{- end }}
      {{- if .Values.startupProbe.enabled }}
      {{- if .Values.customStartupProbe }}
      startupProbe: {{- include "generic-app.tplvalues.render" (dict "value" .Values.customStartupProbe "context" $) | nindent 8 }}
      {{- else }}
      startupProbe: {{- omit .Values.startupProbe "enabled" | toYaml | nindent 8 }}
      {{- end }}
      {{- else if .Values.customStartupProbe }}
      startupProbe: {{- include "generic-app.tplvalues.render" (dict "value" .Values.customStartupProbe "context" $) | nindent 8 }}
      {{- end }}
      {{- if .Values.lifecycleHooks }}
      lifecycle: {{- include "generic-app.tplvalues.render" (dict "value" .Values.lifecycleHooks "context" $) | nindent 8 }}
      {{- end }}
      {{- if .Values.resources }}
      resources: {{- toYaml .Values.resources | nindent 8 }}
      {{- end }}
      volumeMounts:
        {{- if .Values.persistence.enabled }}
        - name: data
          mountPath: {{ .Values.persistence.mountPath }}
          {{- if .Values.persistence.subPath }}
          subPath: {{ .Values.persistence.subPath }}
          {{- end }}
        {{- end }}
        {{- if .Values.extraVolumeMounts }}
        {{- include "generic-app.tplvalues.render" (dict "value" .Values.extraVolumeMounts "context" $) | nindent 8 }}
        {{- end }}
    {{- if .Values.sidecars }}
    {{- include "generic-app.tplvalues.render" ( dict "value" .Values.sidecars "context" $) | nindent 4 }}
    {{- end }}
  volumes:
    {{- if eq .Values.kind "StatefulSet" }}
    {{- if .Values.persistence.existingClaim }}
    - name: data
      persistentVolumeClaim:
        claimName: {{ .Values.persistence.existingClaim }}
    {{- end }}
    {{- else if .Values.persistence.enabled }}
    - name: data
      persistentVolumeClaim:
        claimName: {{ .Values.persistence.existingClaim | default (include "generic-app.fullname" .) }}
    {{- end }}
    {{- if .Values.extraVolumes }}
    {{- include "generic-app.tplvalues.render" (dict "value" .Values.extraVolumes "context" $) | nindent 4 }}
    {{- end }}
{{- end -}}
