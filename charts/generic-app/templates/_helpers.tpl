{{/*
Expand the name of the chart.
*/}}
{{- define "generic-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "generic-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "generic-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "generic-app.labels" -}}
helm.sh/chart: {{ include "generic-app.chart" . }}
{{ include "generic-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "generic-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "generic-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "generic-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "generic-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "generic-app.image" -}}
{{- $registryName := .Values.image.registry -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | toString -}}
{{- if .Values.global }}
    {{- if .Values.global.imageRegistry }}
      {{- $registryName = .Values.global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else -}}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "generic-app.imagePullSecrets" -}}
{{- $pullSecrets := list }}

{{- if .Values.global }}
  {{- range .Values.global.imagePullSecrets }}
    {{- $pullSecrets = append $pullSecrets . }}
  {{- end }}
{{- end }}

{{- range .Values.image.pullSecrets }}
  {{- $pullSecrets = append $pullSecrets . }}
{{- end }}

{{- if (not (empty $pullSecrets)) }}
imagePullSecrets:
{{- range $pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Return the namespace
*/}}
{{- define "generic-app.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment/statefulset.
*/}}
{{- define "generic-app.workload.apiVersion" -}}
{{- if eq .Values.kind "StatefulSet" -}}
{{- print "apps/v1" -}}
{{- else -}}
{{- print "apps/v1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "generic-app.ingress.apiVersion" -}}
{{- if .Values.ingress.apiVersion }}
{{- .Values.ingress.apiVersion }}
{{- else if semverCompare "<1.14-0" .Capabilities.KubeVersion.GitVersion }}
{{- print "extensions/v1beta1" }}
{{- else if semverCompare "<1.19-0" .Capabilities.KubeVersion.GitVersion }}
{{- print "networking.k8s.io/v1beta1" }}
{{- else }}
{{- print "networking.k8s.io/v1" }}
{{- end }}
{{- end }}

{{/*
Return true if cert-manager required annotations for TLS signed certificates are set in the Ingress annotations
Ref: https://cert-manager.io/docs/usage/ingress/#supported-annotations
*/}}
{{- define "generic-app.ingress.certManagerRequest" -}}
{{ if or (hasKey .Values.ingress.annotations "cert-manager.io/cluster-issuer") (hasKey .Values.ingress.annotations "cert-manager.io/issuer") }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Renders a value that contains template.
Usage:
{{ include "generic-app.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "generic-app.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Return the proper Storage Class
*/}}
{{- define "generic-app.storageClass" -}}
{{- $storageClass := .Values.persistence.storageClass -}}
{{- if .Values.global -}}
    {{- if .Values.global.storageClass -}}
        {{- $storageClass = .Values.global.storageClass -}}
    {{- end -}}
{{- end -}}
{{- if $storageClass -}}
  {{- if (eq "-" $storageClass) -}}
      {{- printf "storageClassName: \"\"" -}}
  {{- else }}
      {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Check if there are rolling tags in the images
*/}}
{{- define "generic-app.checkRollingTags" -}}
{{- $rollingTag := .Values.image.tag | toString -}}
{{- if and (contains "latest" $rollingTag) (not .Values.image.pullPolicy) }}
WARNING: Rolling tag detected ({{ .Values.image.repository }}:{{ .Values.image.tag }}), please note that it is strongly recommended to avoid using rolling tags in a production environment.
+info https://docs.bitnami.com/containers/how-to/understand-rolling-tags-containers/
{{- end }}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "generic-app.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "generic-app.checkRollingTags" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/*
Return the pod annotations
*/}}
{{- define "generic-app.podAnnotations" -}}
{{- if .Values.podAnnotations }}
{{ include "generic-app.tplvalues.render" (dict "value" .Values.podAnnotations "context" $) }}
{{- end }}
{{- if and .Values.configMaps.enabled (not .Values.extraEnvVarsCM) }}
checksum/configmap: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end }}
{{- if and .Values.secrets.enabled (not .Values.extraEnvVarsSecret) }}
checksum/secret: {{ include (print $.Template.BasePath "/secret.yaml") . | sha256sum }}
{{- end }}
{{- end -}}

{{/*
Return podAntiAffinity preset
*/}}
{{- define "generic-app.affinities.pods" -}}
{{- if eq .Values.podAntiAffinityPreset "soft" }}
preferredDuringSchedulingIgnoredDuringExecution:
  - podAffinityTerm:
      labelSelector:
        matchLabels: {{- (include "generic-app.selectorLabels" .) | nindent 10 }}
      namespaces:
        - {{ include "generic-app.namespace" . | quote }}
      topologyKey: kubernetes.io/hostname
    weight: 1
{{- else if eq .Values.podAntiAffinityPreset "hard" }}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels: {{- (include "generic-app.selectorLabels" .) | nindent 8 }}
    namespaces:
      - {{ include "generic-app.namespace" . | quote }}
    topologyKey: kubernetes.io/hostname
{{- end }}
{{- end -}}

{{/*
Return nodeAffinity preset
*/}}
{{- define "generic-app.affinities.nodes" -}}
{{- if .Values.nodeAffinityPreset.type }}
{{- if eq .Values.nodeAffinityPreset.type "soft" }}
preferredDuringSchedulingIgnoredDuringExecution:
  - preference:
      matchExpressions:
        - key: {{ .Values.nodeAffinityPreset.key }}
          operator: In
          values:
            {{- range .Values.nodeAffinityPreset.values }}
            - {{ . | quote }}
            {{- end }}
    weight: 1
{{- else if eq .Values.nodeAffinityPreset.type "hard" }}
requiredDuringSchedulingIgnoredDuringExecution:
  nodeSelectorTerms:
    - matchExpressions:
        - key: {{ .Values.nodeAffinityPreset.key }}
          operator: In
          values:
            {{- range .Values.nodeAffinityPreset.values }}
            - {{ . | quote }}
            {{- end }}
{{- end }}
{{- end }}
{{- end -}}

