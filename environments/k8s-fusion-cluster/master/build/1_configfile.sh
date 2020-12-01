echo "Installing Helm"
wget https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz
tar -zxf helm-v3.2.4-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64
rm -rf helm-v3.2.4-linux-amd64.tar.gz

echo "Checking out lucidworks from github"
git clone https://github.com/lucidworks/fusion-cloud-native.git /root/fusion-cloud-native

curl -L -o /opt/dataset.json.zip https://storage.googleapis.com/fusion-datasets/Shoes/dataset.json.zip
curl -L -o /opt/Online_Shoes.zip https://storage.googleapis.com/fusion-datasets/Shoes/Online_Shoes.zip
curl -L -o /opt/electronics.json.zip https://storage.googleapis.com/fusion-datasets/Electronics/electronics.json.zip
curl -L -o /opt/electronics_signals_aggr.json.zip https://storage.googleapis.com/fusion-datasets/Electronics/electronics_signals_aggr.json.zip
curl -L -o /opt/electronics_query_rewrite_staging.json.zip https://storage.googleapis.com/fusion-datasets/Electronics/electronics_query_rewrite_staging.json.zip
curl -L -o /opt/Electronics.zip https://storage.googleapis.com/fusion-datasets/Electronics/Electronics.zip
# curl -L -o /opt/fusion-5.1.2.tgz https://storage.googleapis.com/fusion-datasets/fusion-5.1.2.tgz
# curl -L -o /opt/lucidworks.fileupload-5.1.2.zip https://storage.googleapis.com/fusion-datasets/lucidworks.fileupload-5.1.2.zip


# The configure-environment is run when the environment starts.
cat <<EOF > /opt/k8s_kubernetes_f5_fusion_values.yaml
global:
  zkReplicaCount: 1
  logging:
    disablePulsar: true

solr:
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  updateStrategy:
    type: "RollingUpdate"
  javaMem: "-Xms1g -Xmx1696m"
  solrGcTune: "-XX:+UseG1GC -XX:-OmitStackTraceInFastThrow -XX:+UseStringDeduplication -XX:+PerfDisableSharedMem -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=250 -XX:+AlwaysPreTouch"
  volumeClaimTemplates:
    storageSize: "50Gi"
  replicaCount: 1
  resources:
    limits:
      cpu: "2"
      memory: "1952Mi"
    requests:
      cpu: "500m"
      memory: "1024Mi"
  exporter:
    enabled: false
    nodeSelector:
      cloud.google.com/gke-nodepool: default-pool

zookeeper:
  logstashEnabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  replicaCount: 1
  persistence:
    size: 15Gi
  resources:
    limits:
      cpu: "250m"
      memory: "512Mi"
    requests:
      cpu: "100m"
      memory: "256Mi"
  env:
    ZK_HEAP_SIZE: 1G
    ZK_PURGE_INTERVAL: 1

argo:
  ui:
    resources:
      requests:
        memory: "20Mi"
        cpu: "50m"
      limits:
        memory: "50Mi"
  controller:
    resources:
      requests:
        memory: "32Mi"
        cpu: "50m"
      limits:
        memory: "128Mi"

ambassador:
  resources:
    requests:
      memory: "50Mi"
      cpu: "100m"
    limits:
      memory: "128Mi"

ml-model-service:
  logstashEnabled: false
  image:
    imagePullPolicy: "IfNotPresent"
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  modelRepoImpl: fusion
  fs:
    enabled: true
  preinstall:
    resources:
      requests:
        memory: 64Mi
        cpu: 100m
      limits:
        memory: 128Mi
        cpu: 500m
  javaService:
    resources:
      requests:
        memory: 1Gi
        cpu: 500m
      limits:
        memory: 3Gi
        cpu: 1000m
  milvus:
    enabled: false
    image:
      resources:
        limits:
          memory: "6Gi"
          cpu: "2.0"
        requests:
          memory: "4Gi"
          cpu: "1.0"

fusion-admin:
  logstashEnabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  readinessProbe:
    initialDelaySeconds: 100
  jvmOptions: "-Xms512m -Xmx640m"
  resources:
    limits:
      cpu: "667m"
      memory: "768Mi"
    requests:
      cpu: "150m"
      memory: "512Mi"

fusion-indexing:
  logstashEnabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  readinessProbe:
    initialDelaySeconds: 100
  javaToolOptions: "-Xmx640m -Xms256m"
  resources:
    limits:
      cpu: "667m"
      memory: "768Mi"
    requests:
      cpu: "150m"
      memory: "384Mi"

fusion-log-forwarder:
  enabled: false
  resources:
    requests:
      cpu: "50m"
      memory: "5Mi"
    limits:
      cpu: 100m
      memory: "32Mi"

query-pipeline:
  logstashEnabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  javaToolOptions: "-Xms256m -Xmx512m -Djava.util.concurrent.ForkJoinPool.common.parallelism=1 -Dserver.jetty.max-threads=500 -Dhttp.maxConnections=1000 -XX:+ExitOnOutOfMemoryError"
  livenessProbe:
    failureThreshold: 10
    httpGet:
      path: /actuator/health
      port: jetty
      scheme: HTTP
    initialDelaySeconds: 45
    periodSeconds: 15
    successThreshold: 1
    timeoutSeconds: 3
  readinessProbe:
    failureThreshold: 10
    httpGet:
      path: /actuator/health
      port: jetty
      scheme: HTTP
    initialDelaySeconds: 45
    periodSeconds: 15
    successThreshold: 1
    timeoutSeconds: 3
  resources:
    limits:
      cpu: "667m"
      memory: "640Mi"
    requests:
      cpu: "100m"
      memory: "300Mi"

admin-ui:
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  resources:
    limits:
      cpu: "50m"
      memory: "30Mi"
    requests:
      cpu: "10m"
      memory: "5Mi"

api-gateway:
  logstashEnabled: false
  service:
    externalTrafficPolicy: "Local"
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  javaToolOptions: "-Xms256m -Xmx448m -Djwt.token.user-cache-size=100 -Dhttp.maxConnections=1000 -XX:+ExitOnOutOfMemoryError"
  resources:
    limits:
      cpu: "500m"
      memory: "512Mi"
    requests:
      cpu: "100m"
      memory: "256Mi"

auth-ui:
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  resources:
    limits:
      cpu: "50m"
      memory: "30Mi"
    requests:
      cpu: "10m"
      memory: "5Mi"

classic-rest-service:
  logstashEnabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  bootstrapEnabled: false
  javaToolOptions: "-Xms256m -Xmx768m"
  resources:
    limits:
      cpu: "630m"
      memory: "957Mi"
    requests:
      cpu: "200m"
      memory: "256Mi"

devops-ui:
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  resources:
    limits:
      cpu: "50m"
      memory: "30Mi"
    requests:
      cpu: "10m"
      memory: "5Mi"

job-launcher:
  logstashEnabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  sparkCleanup:
    resources:
      requests:
        cpu: "50m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
  argoCleanup:
    resources:
      requests:
        cpu: "50m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
  resources:
    requests:
      memory: 640Mi
      cpu: 200m
    limits:
      cpu: 1000m
      memory: 768Mi

job-rest-server:
  logstashEnabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  javaToolOptions: "-Xmx768m"
  resources:
    limits:
      cpu: "500m"
      memory: "896Mi"
    requests:
      cpu: "100m"
      memory: "100Mi"

pm-ui:
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  resources:
    limits:
      cpu: "50m"
      memory: "30Mi"
    requests:
      cpu: "25m"
      memory: "5Mi"

rest-service:
  logstashEnabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  javaToolOptions: "-Xms256m -Xmx448m"
  resources:
    limits:
      cpu: "500m"
      memory: "512Mi"
    requests:
      cpu: "150m"
      memory: "256Mi"

rules-ui:
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  resources:
    limits:
      cpu: "50m"
      memory: "30Mi"
    requests:
      cpu: "10m"
      memory: "5Mi"

pulsar:
  broker:
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "8080"
    configData:
      PULSAR_MEM: >
        -XX:+ExitOnOutOfMemoryError
        -Xms256m
        -Xmx512m
        -XX:MaxDirectMemorySize=512m
    resources:
      requests:
        cpu: 250m
        memory: 384Mi
      limits:
        memory: 640Mi

  bookkeeper:
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "8000"
    configData:
      PULSAR_MEM: >
        -XX:+ExitOnOutOfMemoryError
        -Xms256m
        -Xmx512m
        -XX:MaxDirectMemorySize=512m
      BOOKIE_MEM: >
        -Xms256m
        -Xmx512m
        -XX:MaxDirectMemorySize=512m
    resources:
      requests:
        cpu: 250m
        memory: 384Mi
      limits:
        memory: 640Mi


sql-service:
  enabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  replicaCount: 0
  service:
    thrift:
      type: "ClusterIP"

fusion-jupyter:
  enabled: false

logstash:
  enabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool

insights:
  enabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool

rpc-service:
  enabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool

webapps:
  enabled: false
  livenessProbe:
    initialDelaySeconds: 60
  javaToolOptions: "-Xmx1g -Dspring.zipkin.enabled=false -Dspring.sleuth.enabled=false -XX:+ExitOnOutOfMemoryError"
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool

templating:
  enabled: false
  nodeSelector:
    cloud.google.com/gke-nodepool: default-pool
  pod:
    annotations:
      prometheus.io/port: "5250"
      prometheus.io/scrape: "true"
      prometheus.io/path: "/actuator/prometheus"
EOF

cat <<EOF > /opt/configure-environment.sh
touch /root/fusion-status
export PROVIDER="k8s"
export CLUSTER="kubernetes"
export RELEASE="f5"
export MY_VALUES="/opt/\${PROVIDER}_\${CLUSTER}_\${RELEASE}_fusion_values.yaml"
export NAMESPACE=default

cd /root/fusion-cloud-native
git checkout 3b4af5760a2c2cb313e2b69b7b633d3d409ac59c
# echo "Building config yaml"
# ./customize_fusion_values.sh \${MY_VALUES} \
#  -c \$CLUSTER -r \$RELEASE \
#  --provider \$PROVIDER \
#  --num-solr 1 \
#  --node-pool "{}" \
#  --prometheus none

echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc

echo "Adding lucidworks to helm"
helm version --short
helm repo add lucidworks https://charts.lucidworks.com
helm repo update

echo "Installing lucidworks/fusion"
helm install \${RELEASE} lucidworks/fusion --timeout=240s --namespace "\${NAMESPACE}" --values "\${MY_VALUES}" --version 5.3.0

make_pv() {
    # make_pv logstash 2
    mkdir -p /opt/vol/\$1
    chmod 777 /opt/vol/\$1

    ssh -o "StrictHostKeyChecking no" node01 "mkdir -p /opt/vol/\$1; chmod 777 /opt/vol/\$1"
    cat <<EOT > \$1_pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: \$1
spec:
  capacity:
    storage: \${2}Gi
  accessModes:
    - ReadWriteOnce
    - ReadWriteMany
  claimRef:
    namespace: default
    name: \$1
  hostPath:
    path: "/opt/vol/\$1"
  persistentVolumeReclaimPolicy: Recycle
EOT
    echo "Creating Persistent \${2}Gi volume for \$1"
    kubectl create -f \$1_pv.yaml
}

echo "Creating Persistent Volumes"
# logstash needs 2Gi
# make_pv "data-f5-logstash-0" 2

# zookeeper needs 15Gi
make_pv "data-f5-zookeeper-0" 15

# solr needs 50Gi
make_pv "f5-solr-pvc-f5-solr-0" 50

# classic-rest needs 10Gi
make_pv "classic-rest-service-data-claim-f5-classic-rest-service-0" 10

echo "Rolling out deployment"
kubectl rollout status deployment/\${RELEASE}-api-gateway --timeout=600s --namespace "\${NAMESPACE}"


# Post-install setup. Hostname 'fusion-host' should be set in hosts or changed to an env variable.
HOST=\$(ping -c1 node01 | sed -nE 's/^PING[^(]+\(([^)]+)\).*/\1/p')


cat << SVCEOF > /opt/svc.yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/component: api-gateway
    app.kubernetes.io/instance: f5
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: api-gateway
    app.kubernetes.io/part-of: fusion
    app.kubernetes.io/version: 5.1.0
    helm.sh/chart: api-gateway-1.1.7
  name: proxy
  selfLink: /api/v1/namespaces/default/services/proxy
spec:
  externalTrafficPolicy: Cluster
  ports:
  - nodePort: 31209
    port: 6764
    protocol: TCP
    targetPort: 6764
  selector:
    app.kubernetes.io/component: api-gateway
    app.kubernetes.io/instance: f5
    app.kubernetes.io/part-of: fusion
  sessionAffinity: None
  type: LoadBalancer
status:
  loadBalancer: {}
SVCEOF

kubectl apply -f /opt/svc.yaml

sleep 1

PORT=\$(kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services proxy)

echo "Waiting for gateway to start"

while ! nc -z \$HOST \$PORT; do
  sleep 1
done

echo "Gateway started"
echo "gateway" >> /root/fusion-status

echo "Set admin password"
curl --connect-timeout 30 --retry 10 --retry-delay 20 -X POST -H 'content-type: application/json' http://\$HOST:\$PORT/api --data-binary '{"password": "password123"}'
echo "password" >> /root/fusion-status

kubectl rollout status deployment/\${RELEASE}-fusion-admin --timeout=600s --namespace "\${NAMESPACE}"
echo "admin" >> /root/fusion-status

echo "Upload shoes dataset"
curl --connect-timeout 30 --retry 5 --retry-delay 5 -X PUT -u admin:password123 -H 'Content-type: application/octet-stream' --data-binary @/opt/dataset.json.zip http://\$HOST:\$PORT/api/blobs/data.json.zip?resourceType=file
echo "shoe data" >> /root/fusion-status

echo "Upload Electronics dataset"
curl --connect-timeout 30 --retry 5 --retry-delay 5 -X PUT -u admin:password123 -H 'Content-type: application/octet-stream' --data-binary @/opt/electronics.json.zip http://\$HOST:\$PORT/api/blobs/electronics.json.zip?resourceType=file
echo "electronics data" >> /root/fusion-status

echo "Verify classic"
kubectl rollout status deployment/${RELEASE}-rest-service --timeout=600s --namespace "${NAMESPACE}"
echo "classic" >> /root/fusion-status

echo "Turn off quickstart"

curl -X PUT -u admin:password123 -H "Content-type: application/json" -d "false" "http://\$HOST:\$PORT/api/apollo/configurations/quickstart.enabled"

echo "connectors" >> /root/fusion-status

echo "Finished"

EOF

chmod +x /opt/configure-environment.sh

