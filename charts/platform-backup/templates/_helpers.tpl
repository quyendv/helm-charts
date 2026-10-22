{{/*
================================================================================
NAMING HELPERS
================================================================================
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "platform-backup.name" -}}
  {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified name: the CronJob's name and the prefix of every other object.
Not truncated: a CronJob name is limited to 52 characters, and silently cutting
it could drop the "backup" that monitoring selects on. Validation fails instead.
If the release name contains the chart name it is used as the full name.
*/}}
{{- define "platform-backup.fullname" -}}
  {{- if .Values.fullnameOverride }}
    {{- .Values.fullnameOverride | trimSuffix "-" }}
  {{- else }}
    {{- $name := default .Chart.Name .Values.nameOverride }}
    {{- if contains $name .Release.Name }}
      {{- .Release.Name | trimSuffix "-" }}
    {{- else }}
      {{- printf "%s-%s" .Release.Name $name | trimSuffix "-" }}
    {{- end }}
  {{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "platform-backup.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Names of the Secrets the ExternalSecrets create.
*/}}
{{- define "platform-backup.s3SecretName" -}}
  {{- printf "%s-s3" (include "platform-backup.fullname" .) -}}
{{- end -}}

{{- define "platform-backup.targetSecretName" -}}
  {{- printf "%s-target" (include "platform-backup.fullname" .) -}}
{{- end -}}

{{/*
================================================================================
LABELS
================================================================================
*/}}

{{/*
Selector labels: identify the release's objects. commonLabels and podLabels
never override them.
*/}}
{{- define "platform-backup.selectorLabels" -}}
app.kubernetes.io/name: {{ include "platform-backup.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Labels for every object: selector labels, then commonLabels, then the standard
version-bearing labels.
*/}}
{{- define "platform-backup.labels" -}}
  {{- $selector := include "platform-backup.selectorLabels" . | fromYaml -}}
  {{- $standard := dict "helm.sh/chart" (include "platform-backup.chart" .) "app.kubernetes.io/managed-by" .Release.Service -}}
  {{- if .Chart.AppVersion -}}
    {{- $_ := set $standard "app.kubernetes.io/version" (.Chart.AppVersion | toString) -}}
  {{- end -}}
  {{- toYaml (merge $selector (deepCopy (.Values.commonLabels | default dict)) $standard) -}}
{{- end -}}

{{/*
Labels for the Jobs and their pods: selector labels, then podLabels, then
commonLabels. The version-bearing labels are left off, as on generic-app pods.
*/}}
{{- define "platform-backup.podLabels" -}}
  {{- $selector := include "platform-backup.selectorLabels" . | fromYaml -}}
  {{- toYaml (merge $selector (deepCopy (.Values.podLabels | default dict)) (deepCopy (.Values.commonLabels | default dict))) -}}
{{- end -}}

{{/*
================================================================================
IMAGE
================================================================================
*/}}

{{/*
<registry>/<engine>:<tag>[-<variant>]; the tag defaults to the chart appVersion.
*/}}
{{- define "platform-backup.image" -}}
  {{- $tag := default .Chart.AppVersion (.Values.image.tag | toString) -}}
  {{- if .Values.image.variant -}}
    {{- $tag = printf "%s-%s" $tag .Values.image.variant -}}
  {{- end -}}
  {{- printf "%s/%s:%s" (.Values.image.registry | trimSuffix "/") .Values.engine $tag -}}
{{- end -}}

{{/*
================================================================================
POD
================================================================================
*/}}

{{/*
Integer value as an env string. Values files hand numbers over as float64, so
convert before printing; and test for nil rather than using `default`, which
treats 0 as unset (KEEP_REMOTE=0 means "never prune", not "use the default").
*/}}
{{- define "platform-backup.intString" -}}
  {{- . | int64 | toString -}}
{{- end -}}

{{/*
Environment variables the chart sets itself; env and extraEnv may not repeat them.
*/}}
{{- define "platform-backup.managedEnv" -}}
- name: MODE
  value: backup
- name: S3_PREFIX
  value: {{ .Values.s3.prefix | quote }}
- name: KEEP_LOCAL
  value: {{ include "platform-backup.intString" .Values.keepLocal | quote }}
- name: KEEP_REMOTE
  value: {{ include "platform-backup.intString" .Values.s3.keepRemote | quote }}
- name: VERIFY_READBACK
  value: {{ .Values.verifyReadback | toString | quote }}
{{- if .Values.host }}
- name: BACKUP_HOST
  value: {{ .Values.host | quote }}
{{- end }}
{{- end -}}

{{/*
envFrom: the S3 Secret, then the target Secret when one is configured.
*/}}
{{- define "platform-backup.envFrom" -}}
{{- if .Values.s3.externalSecret.enabled }}
- secretRef:
    name: {{ include "platform-backup.s3SecretName" . }}
{{- else if .Values.s3.existingSecret }}
- secretRef:
    name: {{ .Values.s3.existingSecret }}
{{- end }}
{{- if .Values.target.externalSecret.enabled }}
- secretRef:
    name: {{ include "platform-backup.targetSecretName" . }}
{{- else if .Values.target.existingSecret }}
- secretRef:
    name: {{ .Values.target.existingSecret }}
{{- end }}
{{- end -}}

{{/*
Pod affinity: the user's affinity, plus, for a file store, a required term
that puts the pod on the node of the pod owning the claim (a ReadWriteOnce
volume is attached to one node at a time). The user's own required terms are
kept and the owner term appended.
*/}}
{{- define "platform-backup.affinity" -}}
  {{- $affinity := deepCopy (.Values.affinity | default dict) -}}
  {{- if .Values.fileStore.enabled -}}
    {{- $podAffinity := get $affinity "podAffinity" | default dict -}}
    {{- $required := get $podAffinity "requiredDuringSchedulingIgnoredDuringExecution" | default list -}}
    {{- $term := dict "labelSelector" (dict "matchLabels" .Values.fileStore.ownerSelector) "topologyKey" "kubernetes.io/hostname" -}}
    {{- $_ := set $podAffinity "requiredDuringSchedulingIgnoredDuringExecution" (append $required $term) -}}
    {{- $_ := set $affinity "podAffinity" $podAffinity -}}
  {{- end -}}
  {{- if $affinity -}}
    {{- toYaml $affinity -}}
  {{- end -}}
{{- end -}}

{{/*
================================================================================
VALIDATION
================================================================================
Included by cronjob.yaml, which every release renders. Only there: Helm stops at
the first failing template, so checks spread over several would be reported
against whichever template happened to render first.
*/}}
{{- define "platform-backup.validate" -}}
  {{- $fullname := include "platform-backup.fullname" . -}}
  {{- if not (contains "backup" $fullname) -}}
    {{- fail (printf "the release fullname %q must contain \"backup\": monitoring commonly selects backup CronJobs by name (cronjob=~\".*backup.*\"). Set fullnameOverride, nameOverride or the release name." $fullname) -}}
  {{- end -}}
  {{- if gt (len $fullname) 52 -}}
    {{- fail (printf "the release fullname %q is longer than the 52 characters a CronJob name allows. Set a shorter fullnameOverride." $fullname) -}}
  {{- end -}}
  {{- if not .Values.schedule -}}
    {{- fail "schedule is required, e.g. \"0 2 * * *\"" -}}
  {{- end -}}
  {{- if not .Values.s3.prefix -}}
    {{- fail "s3.prefix is required: the key prefix inside the bucket (S3_PREFIX)" -}}
  {{- end -}}
  {{- if kindIs "invalid" .Values.s3.keepRemote -}}
    {{- fail "s3.keepRemote is required: the number of runs kept in S3 (KEEP_REMOTE); 0 disables pruning" -}}
  {{- end -}}

  {{- $s3 := .Values.s3 -}}
  {{- if and $s3.existingSecret $s3.externalSecret.enabled -}}
    {{- fail "s3.existingSecret and s3.externalSecret.enabled are mutually exclusive: both would provide the S3 Secret" -}}
  {{- end -}}
  {{- if not (or $s3.existingSecret $s3.externalSecret.enabled) -}}
    {{- fail "the S3 settings need a Secret: set s3.existingSecret or enable s3.externalSecret" -}}
  {{- end -}}
  {{- if $s3.externalSecret.enabled -}}
    {{- if not $s3.externalSecret.secretStoreRef.name -}}
      {{- fail "s3.externalSecret.secretStoreRef.name is required when s3.externalSecret is enabled" -}}
    {{- end -}}
    {{- if not $s3.externalSecret.remoteKey -}}
      {{- fail "s3.externalSecret.remoteKey is required when s3.externalSecret is enabled" -}}
    {{- end -}}
    {{- if not (include "platform-backup.s3Properties" .) -}}
      {{- fail "s3.externalSecret.properties maps no property" -}}
    {{- end -}}
  {{- end -}}

  {{- $target := .Values.target -}}
  {{- if and $target.existingSecret $target.externalSecret.enabled -}}
    {{- fail "target.existingSecret and target.externalSecret.enabled are mutually exclusive: both would provide the target Secret" -}}
  {{- end -}}
  {{- if $target.externalSecret.enabled -}}
    {{- if not $target.externalSecret.secretStoreRef.name -}}
      {{- fail "target.externalSecret.secretStoreRef.name is required when target.externalSecret is enabled" -}}
    {{- end -}}
    {{- if not (or $target.externalSecret.data $target.externalSecret.dataFrom) -}}
      {{- fail "target.externalSecret needs data or dataFrom" -}}
    {{- end -}}
  {{- end -}}

  {{- if .Values.fileStore.enabled -}}
    {{- if not .Values.fileStore.claimName -}}
      {{- fail "fileStore.claimName is required when fileStore is enabled" -}}
    {{- end -}}
    {{- if not .Values.fileStore.ownerSelector -}}
      {{- fail "fileStore.ownerSelector is required when fileStore is enabled: the labels of the pod that owns the claim" -}}
    {{- end -}}
  {{- end -}}

  {{- $managed := list "MODE" "S3_PREFIX" "KEEP_LOCAL" "KEEP_REMOTE" "VERIFY_READBACK" "BACKUP_HOST" -}}
  {{- $names := keys (.Values.env | default dict) -}}
  {{- range (.Values.extraEnv | default list) -}}
    {{- $names = append $names .name -}}
  {{- end -}}
  {{- range $names -}}
    {{- if has . $managed -}}
      {{- fail (printf "%s is set by the chart; remove it from env/extraEnv and use the matching value (s3.prefix, keepLocal, s3.keepRemote, verifyReadback, host)" .) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
S3 ExternalSecret data entries, sorted by Secret key; null or empty properties
are left out.
*/}}
{{- define "platform-backup.s3Properties" -}}
  {{- $es := .Values.s3.externalSecret -}}
  {{- $properties := $es.properties | default dict -}}
  {{- range $key := keys $properties | sortAlpha }}
    {{- with get $properties $key }}
- secretKey: {{ $key }}
  remoteRef:
    key: {{ $es.remoteKey | quote }}
    property: {{ . | quote }}
    {{- end }}
  {{- end }}
{{- end -}}
