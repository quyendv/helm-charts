{{/*
================================================================================
NAMING HELPERS
================================================================================
*/}}

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
Return the namespace
*/}}
{{- define "generic-app.namespace" -}}
  {{- default .Release.Namespace .Values.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
================================================================================
LABELS AND ANNOTATIONS HELPERS
================================================================================
*/}}

{{/*
Common labels.
commonLabels may override the standard labels, but never the selector labels:
those are immutable on workloads and must stay stable across upgrades.
*/}}
{{- define "generic-app.labels" -}}
  {{- $selector := include "generic-app.selectorLabels" . | fromYaml -}}
  {{- $standard := dict "helm.sh/chart" (include "generic-app.chart" .) "app.kubernetes.io/managed-by" .Release.Service -}}
  {{- if .Chart.AppVersion -}}
    {{- $_ := set $standard "app.kubernetes.io/version" (.Chart.AppVersion | toString) -}}
  {{- end -}}
  {{- $common := include "generic-app.tplvalues.render" (dict "value" (.Values.commonLabels | default dict) "context" .) | fromYaml -}}
  {{- toYaml (merge $selector $common $standard) -}}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "generic-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "generic-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Pod labels: selector labels, then podLabels, then commonLabels.
The version-bearing standard labels are left off on purpose so that a chart
upgrade alone does not roll the pods.
*/}}
{{- define "generic-app.podLabels" -}}
  {{- $selector := include "generic-app.selectorLabels" . | fromYaml -}}
  {{- $pod := include "generic-app.tplvalues.render" (dict "value" (.Values.podLabels | default dict) "context" .) | fromYaml -}}
  {{- $common := include "generic-app.tplvalues.render" (dict "value" (.Values.commonLabels | default dict) "context" .) | fromYaml -}}
  {{- toYaml (merge $selector $pod $common) -}}
{{- end -}}

{{/*
Resource annotations merged over commonAnnotations (both tpl-rendered). Emits
nothing when the result is empty, so callers can wrap it in `with`:
  {{- with include "generic-app.annotations" (dict "annotations" .Values.service.annotations "context" $) }}
  annotations: {{- . | nindent 4 }}
  {{- end }}
Merging (rather than concatenating) keeps a key set in both maps from being
emitted twice, which produced YAML with duplicate keys.
*/}}
{{- define "generic-app.annotations" -}}
  {{- $common := include "generic-app.tplvalues.render" (dict "value" (.context.Values.commonAnnotations | default dict) "context" .context) | fromYaml -}}
  {{- $own := include "generic-app.tplvalues.render" (dict "value" (.annotations | default dict) "context" .context) | fromYaml -}}
  {{- $merged := merge $own $common -}}
  {{- if $merged -}}
    {{- toYaml $merged -}}
  {{- end -}}
{{- end -}}

{{/*
================================================================================
SERVICE ACCOUNT HELPERS
================================================================================
*/}}

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
================================================================================
IMAGE HELPERS
================================================================================
*/}}

{{/*
Return the image reference: [registry/]repository[:tag][@digest].
The chart ships no default image, so repository and one of tag/digest are required.
*/}}
{{- define "generic-app.image" -}}
  {{- $registry := .Values.image.registry | default "" -}}
  {{- if and .Values.global .Values.global.imageRegistry -}}
    {{- $registry = .Values.global.imageRegistry -}}
  {{- end -}}
  {{- $repository := required "image.repository is required: this chart has no default image" .Values.image.repository -}}
  {{- $tag := default "" .Values.image.tag | toString -}}
  {{- $digest := default "" .Values.image.digest -}}
  {{- if and (not $tag) (not $digest) -}}
    {{- fail "image.tag or image.digest is required (an untagged image silently means :latest)" -}}
  {{- end -}}
  {{- $ref := $repository -}}
  {{- if $registry -}}
    {{- $ref = printf "%s/%s" $registry $repository -}}
  {{- end -}}
  {{- if $tag -}}
    {{- $ref = printf "%s:%s" $ref $tag -}}
  {{- end -}}
  {{- if $digest -}}
    {{- $ref = printf "%s@%s" $ref $digest -}}
  {{- end -}}
  {{- $ref -}}
{{- end -}}

{{/*
Return the image pull secrets list (global first), or nothing when there are none.
*/}}
{{- define "generic-app.imagePullSecrets" -}}
  {{- $pullSecrets := list -}}
  {{- if .Values.global -}}
    {{- range .Values.global.imagePullSecrets -}}
      {{- $pullSecrets = append $pullSecrets . -}}
    {{- end -}}
  {{- end -}}
  {{- range .Values.image.pullSecrets -}}
    {{- $pullSecrets = append $pullSecrets . -}}
  {{- end -}}
  {{- $refs := list -}}
  {{- range $pullSecrets | uniq -}}
    {{- $refs = append $refs (dict "name" .) -}}
  {{- end -}}
  {{- if $refs -}}
    {{- toYaml $refs -}}
  {{- end -}}
{{- end -}}

{{/*
================================================================================
PORT HELPERS
================================================================================
*/}}

{{/*
Ports of the main container as a YAML name -> number map (empty when none).
containerPorts wins; when it is empty the pod mirrors service.ports, but only
while the Service is enabled. Entries set to null are dropped.
Usage: {{- $ports := include "generic-app.containerPorts" . | fromYaml }}
*/}}
{{- define "generic-app.containerPorts" -}}
  {{- $ports := .Values.containerPorts | default dict -}}
  {{- if and (not $ports) .Values.service.enabled -}}
    {{- $ports = .Values.service.ports | default dict -}}
  {{- end -}}
  {{- $out := dict -}}
  {{- range $name, $port := $ports -}}
    {{- if not (kindIs "invalid" $port) -}}
      {{- $_ := set $out $name $port -}}
    {{- end -}}
  {{- end -}}
  {{- if $out -}}
    {{- toYaml $out -}}
  {{- end -}}
{{- end -}}

{{/*
Name of the service.ports entry that Ingress, HTTPRoute and NOTES route to.
Resolution: the explicit name -> "http" -> the only port -> fail.
Usage: {{ include "generic-app.service.portName" (dict "port" .Values.ingress.servicePort "field" "ingress.servicePort" "context" $) }}
*/}}
{{- define "generic-app.service.portName" -}}
  {{- $ports := .context.Values.service.ports | default dict -}}
  {{- $want := default "" .port | toString -}}
  {{- if $want -}}
    {{- if not (hasKey $ports $want) -}}
      {{- fail (printf "%s is %q, which is not a key of service.ports" .field $want) -}}
    {{- end -}}
    {{- $want -}}
  {{- else if hasKey $ports "http" -}}
    {{- print "http" -}}
  {{- else if eq (len $ports) 1 -}}
    {{- keys $ports | first -}}
  {{- else if eq (len $ports) 0 -}}
    {{- fail (printf "%s cannot be resolved: service.ports is empty" .field) -}}
  {{- else -}}
    {{- fail (printf "%s is required: service.ports has no \"http\" entry and %d ports to choose from (%s)" .field (len $ports) (keys $ports | sortAlpha | join ", ")) -}}
  {{- end -}}
{{- end -}}

{{/*
Headless Service name for the StatefulSet (63 char limit).
*/}}
{{- define "generic-app.headlessServiceName" -}}
  {{- printf "%s-headless" (include "generic-app.fullname" . | trunc 54 | trimSuffix "-") -}}
{{- end -}}

{{/*
Return true when a value is set: not null and not the empty string. Unlike a
plain `if`, this treats 0 and false as set.
Usage: {{- if include "generic-app.isSet" .Values.podDisruptionBudget.maxUnavailable }}
*/}}
{{- define "generic-app.isSet" -}}
  {{- if and (not (kindIs "invalid" .)) (ne (toString .) "") -}}true{{- end -}}
{{- end -}}

{{/*
================================================================================
GATEWAY API HELPERS
================================================================================
*/}}

{{/*
Effective HTTPRoute hostnames as JSON: httpRoute.hostnames plus gatewayApi.hostname.
Shared by the HTTPRoute, the redirect route and the Certificate.
Usage: {{- $hostnames := include "generic-app.gatewayApi.hostnames" . | fromJsonArray }}
*/}}
{{- define "generic-app.gatewayApi.hostnames" -}}
  {{- $hn := .Values.gatewayApi.httpRoute.hostnames | default list -}}
  {{- if .Values.gatewayApi.hostname -}}
    {{- $hn = concat $hn (list .Values.gatewayApi.hostname) -}}
  {{- end -}}
  {{- compact $hn | uniq | toJson -}}
{{- end -}}
{{/*
Return HTTPRoute apiVersion for Gateway API
*/}}
{{- define "generic-app.gatewayApi.httpRoute.apiVersion" -}}
  {{- if .Values.gatewayApi.apiVersion }}
    {{- .Values.gatewayApi.apiVersion }}
  {{- else }}
    {{- print "gateway.networking.k8s.io/v1" }}
  {{- end }}
{{- end }}

{{/*
TLS secret name for gatewayApi Certificate (63 char limit)
*/}}
{{- define "generic-app.gatewayApi.certificate.secretName" -}}
  {{- $root := .root }}
  {{- $dns := .dnsNames }}
  {{- if $root.Values.gatewayApi.certificate.secretName }}
    {{- $root.Values.gatewayApi.certificate.secretName | trunc 63 | trimSuffix "-" }}
  {{- else if $dns }}
    {{- printf "%s-tls" (first $dns) | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- printf "%s-gateway-tls" (include "generic-app.fullname" $root) | trunc 63 | trimSuffix "-" }}
  {{- end }}
{{- end }}

{{/*
================================================================================
GATEWAY API — NGINX GATEWAY FABRIC (NGF) HELPERS
================================================================================
*/}}

{{/*
Effective HTTPRoute metadata.name (same as templates/httproute.yaml).
*/}}
{{- define "generic-app.gatewayApi.httpRoute.resourceName" -}}
{{- default (include "generic-app.fullname" .) .Values.gatewayApi.httpRoute.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Shared SnippetsFilter name for this release (one CRD holds all snippet blocks).
*/}}
{{- define "generic-app.gatewayApi.nginxGatewayFabric.snippetsFilterName" -}}
{{- printf "%s-ngf-snippets" (include "generic-app.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
ClientSettingsPolicy name for NGF body size preset.
*/}}
{{- define "generic-app.gatewayApi.nginxGatewayFabric.clientSettingsPolicyName" -}}
{{- printf "%s-ngf-client-settings" (include "generic-app.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Emit "1" when the chart should inject SnippetsFilter ExtensionRef on the generated default HTTPRoute rule.
*/}}
{{- define "generic-app.gatewayApi.nginxGatewayFabric.injectSnippetExtensionRef" -}}
{{- $ngf := .Values.gatewayApi.nginxGatewayFabric | default dict -}}
{{- if and .Values.gatewayApi.enabled $ngf.enabled (eq (len (.Values.gatewayApi.httpRoute.rules | default list)) 0) -}}
{{- $t := $ngf.upstreamProxyTimeouts | default dict -}}
{{- $hasTimeout := or (ne (default "" $t.connect) "") (ne (default "" $t.read) "") (ne (default "" $t.send) "") -}}
{{- $snippets := $ngf.snippets | default dict -}}
{{- $extra := $snippets.extra | default list -}}
{{- if or $hasTimeout (gt (len $extra) 0) -}}1{{- end -}}
{{- end -}}
{{- end }}

{{/*
================================================================================
TEMPLATE RENDERING HELPERS
================================================================================
*/}}

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
================================================================================
STORAGE HELPERS
================================================================================
*/}}

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
================================================================================
VALIDATION HELPERS
================================================================================
Hard errors live in the template that owns the resource (fail/required); the
checks below are warnings printed in NOTES.txt.
*/}}

{{/*
Warn on mutable image tags.
*/}}
{{- define "generic-app.checkRollingTags" -}}
  {{- $tag := default "" .Values.image.tag | toString -}}
  {{- if and (not .Values.image.digest) (or (eq $tag "latest") (hasSuffix "-latest" $tag)) }}
WARNING: Rolling tag detected ({{ .Values.image.repository }}:{{ $tag }}). Pin an immutable tag or set image.digest: with a rolling tag, nodes run whichever image they pulled last.
  {{- end }}
{{- end -}}

{{/*
Warn when both Ingress and Gateway API are enabled (duplicate north–south paths).
*/}}
{{- define "generic-app.checkGatewayApiIngressConflict" -}}
  {{- if and .Values.ingress.enabled .Values.gatewayApi.enabled }}
WARNING: Both ingress.enabled and gatewayApi.enabled are true. In production, prefer a single entry path (Ingress or Gateway API) for the same hostname unless you intentionally split traffic.
  {{- end }}
{{- end -}}

{{/*
Warn when autoscaling is enabled for a DaemonSet (HPA does not apply).
*/}}
{{- define "generic-app.checkDaemonSetAutoscaling" -}}
  {{- if and (eq .Values.kind "DaemonSet") .Values.autoscaling.enabled }}
WARNING: autoscaling.enabled is true but kind is DaemonSet. HPA does not apply to DaemonSets and will not be created.
  {{- end }}
{{- end -}}

{{/*
Warn when the ServiceMonitor port is not a port of the Service.
*/}}
{{- define "generic-app.checkServiceMonitorPort" -}}
  {{- if and .Values.serviceMonitor.enabled .Values.service.enabled -}}
    {{- $names := keys (.Values.service.ports | default dict) -}}
    {{- range .Values.service.extraPorts -}}
      {{- if kindIs "map" . }}{{ $names = append $names (toString .name) }}{{ end -}}
    {{- end -}}
    {{- if not (has .Values.serviceMonitor.port $names) }}
WARNING: serviceMonitor.port "{{ .Values.serviceMonitor.port }}" is not a port of the Service (service.ports / service.extraPorts). The ServiceMonitor will not scrape anything until it is.
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Warn when a service port name has no matching container port.
The Service targets ports by NAME. A name missing from containerPorts can still
be valid when a sidecar declares it, so this is a warning rather than an error.
*/}}
{{- define "generic-app.checkServicePortNames" -}}
  {{- if and .Values.service.enabled .Values.containerPorts -}}
    {{- $missing := list -}}
    {{- range $name, $_ := .Values.service.ports -}}
      {{- if not (hasKey $.Values.containerPorts $name) -}}
        {{- $missing = append $missing $name -}}
      {{- end -}}
    {{- end -}}
    {{- if $missing }}
WARNING: service.ports name(s) "{{ join ", " $missing }}" have no matching entry in containerPorts. The Service targets ports by name, so it will not route to the pod unless containerPorts (or a sidecar) declares the same name(s).
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Warn about ExternalSecret settings that make the resource useless.
*/}}
{{- define "generic-app.checkExternalSecret" -}}
  {{- $msgs := list -}}
  {{- if .Values.externalSecret.enabled -}}
    {{- if not .Values.externalSecret.secretStoreRef.name -}}
      {{- $msgs = append $msgs "WARNING: externalSecret.enabled is true but externalSecret.secretStoreRef.name is empty. The ExternalSecret will not sync until a SecretStore/ClusterSecretStore is referenced." -}}
    {{- end -}}
    {{- if and (not .Values.externalSecret.data) (not .Values.externalSecret.dataFrom) -}}
      {{- $msgs = append $msgs "WARNING: externalSecret.enabled is true but neither externalSecret.data nor externalSecret.dataFrom is set. The resulting Secret will be empty." -}}
    {{- end -}}
  {{- end -}}
  {{- join "\n" $msgs -}}
{{- end -}}

{{/*
Warn when NGF presets are configured but cannot be attached to the route.
*/}}
{{- define "generic-app.checkNginxGatewayFabricRules" -}}
  {{- $ngf := .Values.gatewayApi.nginxGatewayFabric | default dict -}}
  {{- if and .Values.gatewayApi.enabled $ngf.enabled .Values.gatewayApi.httpRoute.rules -}}
    {{- $t := $ngf.upstreamProxyTimeouts | default dict -}}
    {{- $snippets := $ngf.snippets | default dict -}}
    {{- if or $t.connect $t.read $t.send $snippets.extra }}
WARNING: gatewayApi.httpRoute.rules is set, so the chart does not attach the NGF SnippetsFilter "{{ include "generic-app.gatewayApi.nginxGatewayFabric.snippetsFilterName" . }}" to the route. Reference it from your rules with an ExtensionRef filter, or the upstream timeouts/snippets have no effect.
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Warn when a ReadWriteOnce volume is shared by pods that may run on different nodes.
*/}}
{{- define "generic-app.checkSharedRwoVolume" -}}
  {{- if and .Values.persistence.enabled (ne .Values.kind "StatefulSet") (has "ReadWriteOnce" .Values.persistence.accessModes) -}}
    {{- $multi := or .Values.autoscaling.enabled (gt (int .Values.replicaCount) 1) (eq .Values.kind "DaemonSet") -}}
    {{- $rolling := and (eq .Values.kind "Deployment") (eq (default "RollingUpdate" .Values.updateStrategy.type) "RollingUpdate") -}}
    {{- if or $multi $rolling }}
WARNING: persistence uses a ReadWriteOnce claim shared by {{ ternary "several pods" "old and new pods during a rolling update" $multi }}. Pods scheduled on another node cannot attach it and stay Pending. Use kind=StatefulSet, a ReadWriteMany storage class, or updateStrategy.type=Recreate with a single replica.
    {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Warn when a Role is created but the pod cannot use it.
*/}}
{{- define "generic-app.checkRbacToken" -}}
  {{- if and .Values.rbac.create (not .Values.serviceAccount.automountServiceAccountToken) }}
WARNING: rbac.create is true but serviceAccount.automountServiceAccountToken is false, so the pod gets no API token to use the Role with. Set it to true, or mount a projected token yourself.
  {{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "generic-app.validateValues" -}}
  {{- $messages := list -}}
  {{- $messages = append $messages (include "generic-app.checkRollingTags" . | trim) -}}
  {{- $messages = append $messages (include "generic-app.checkGatewayApiIngressConflict" . | trim) -}}
  {{- $messages = append $messages (include "generic-app.checkDaemonSetAutoscaling" . | trim) -}}
  {{- $messages = append $messages (include "generic-app.checkServiceMonitorPort" . | trim) -}}
  {{- $messages = append $messages (include "generic-app.checkServicePortNames" . | trim) -}}
  {{- $messages = append $messages (include "generic-app.checkExternalSecret" . | trim) -}}
  {{- $messages = append $messages (include "generic-app.checkNginxGatewayFabricRules" . | trim) -}}
  {{- $messages = append $messages (include "generic-app.checkSharedRwoVolume" . | trim) -}}
  {{- $messages = append $messages (include "generic-app.checkRbacToken" . | trim) -}}
  {{- $messages = without $messages "" -}}
  {{- $message := join "\n" $messages -}}

  {{- if $message -}}
    {{- printf "\nVALUES VALIDATION:\n%s" $message -}}
  {{- end -}}
{{- end -}}

{{/*
================================================================================
POD HELPERS
================================================================================
*/}}

{{/*
Return the pod annotations: podAnnotations plus config checksums that roll the
pods when the chart-managed ConfigMap/Secret changes.
*/}}
{{- define "generic-app.podAnnotations" -}}
  {{- $annotations := include "generic-app.tplvalues.render" (dict "value" (.Values.podAnnotations | default dict) "context" .) | fromYaml -}}
  {{- if .Values.configMaps.enabled -}}
    {{- $_ := set $annotations "checksum/configmap" (include (print $.Template.BasePath "/configmap.yaml") . | sha256sum) -}}
  {{- end -}}
  {{- if .Values.secrets.enabled -}}
    {{- $_ := set $annotations "checksum/secret" (include (print $.Template.BasePath "/secret.yaml") . | sha256sum) -}}
  {{- end -}}
  {{- if $annotations -}}
    {{- toYaml $annotations -}}
  {{- end -}}
{{- end -}}
{{/*
================================================================================
AFFINITY HELPERS
================================================================================
*/}}

{{/*
Return podAffinity preset
Allows pods to be scheduled together on the same node
*/}}
{{- define "generic-app.affinities.podAffinity" -}}
  {{- if eq .Values.podAffinityPreset "soft" }}
preferredDuringSchedulingIgnoredDuringExecution:
  - podAffinityTerm:
      labelSelector:
        matchLabels: {{- (include "generic-app.selectorLabels" .) | nindent 10 }}
      namespaces:
        - {{ include "generic-app.namespace" . | quote }}
      topologyKey: kubernetes.io/hostname
    weight: 1
  {{- else if eq .Values.podAffinityPreset "hard" }}
requiredDuringSchedulingIgnoredDuringExecution:
  - labelSelector:
      matchLabels: {{- (include "generic-app.selectorLabels" .) | nindent 8 }}
    namespaces:
      - {{ include "generic-app.namespace" . | quote }}
    topologyKey: kubernetes.io/hostname
  {{- end }}
{{- end -}}

{{/*
Return podAntiAffinity preset
Prevents pods from being scheduled together on the same node
*/}}
{{- define "generic-app.affinities.podAntiAffinity" -}}
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

