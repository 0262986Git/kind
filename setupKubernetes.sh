
##### Installs kubectl version 1.24.0 

curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.24.0/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin

##### Intstalls Kind K8s

curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.14.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin

##### Downloads Example CyPerf Agent Configurations
git clone https://github.com/Keysight/cyperf.git

##### Builds A Kind K8s Cluster named kind-cluster with 1 Master and 2 Worker nodes

cat <<EOF | kind create cluster --config -

kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker

EOF

##### Deploys an NGINX Ingress Controller Daemonset
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml


##### Label each K8S Worker - One for Client and One for Server

kubectl label nodes kind-worker agenttype=client
kubectl label nodes kind-worker2 agenttype=server


##### Create CyPerf Server Agent configuration YAML thae will reside in user home directory with Ingress enabled but WAF Disabled. Note the configuration of the Agent Controller will need to be updated to reflect your environment.

cat <<EOF >$HOME/cyperf-agent-server-nowaf.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: cyperf-agent-server-deployment
spec:
    replicas: 1
    selector:
        matchLabels:
            app: cyperf-agent
            run: cyperf-agent-server
    template:
        metadata:
            labels:
                app: cyperf-agent
                run: cyperf-agent-server
        spec:
            containers:
                -   name: cyperf-agent-server
                    image: public.ecr.aws/keysight/cyperf-agent:latest
                    env:
                    -   name: AGENT_CONTROLLER
                        value: "192.168.2.20"
                    #   name: AGENT_MANAGEMENT_INTERFACE
                    #   value: "eth0"
                    #   name: AGENT_TEST_INTERFACE
                    #   value: "eth1"
                    -   name: AGENT_TAGS
                        value: "K8s-Group=CyPerf-Agent-Server,node-owner=User"
                    securityContext:
                        privileged: false
                        capabilities:
                          add: ["NET_ADMIN", "IPC_LOCK", "NET_RAW"]
                    #readinessProbe:
                    #   httpGet:
                    #        path: /CyPerfHTTPHealthCheck
                    #        port: 80
                    #    periodSeconds: 5
                    resources:
                        limits:
                            memory: "4Gi"
                            #cpu: "3.5"
                            ## skipping requests means limits=requests
                            ## with 3.5 for 8 core node it should be able to run 2 replicas
                            ## but experiments needed to see how other pods react for perf configs.
                        requests:
                            memory: "2Gi"

            nodeSelector:
                agenttype: server
            #affinity:
            #    podAntiAffinity:
            #        requiredDuringSchedulingIgnoredDuringExecution:
            #        - labelSelector:
            #            matchExpressions:
            #            - key: app
            #              operator: In
            #              values:
            #              - cyperf-agent
            #          topologyKey: "kubernetes.io/hostname"


---

apiVersion: v1
kind: Service
metadata:
    name: cyperf-agent-service
spec:
    type: ClusterIP
    #type: NodePort
    ports:
    - port: 80
      protocol: TCP
      name: http
      targetPort: 80
      #nodePort: 30080
    selector:
        run: cyperf-agent-server

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    ########## Configure ModSecurity #############
    #nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    #nginx.ingress.kubernetes.io/enable-owasp-core-rules: "true"
    #nginx.ingress.kubernetes.io/modsecurity-transaction-id: "$request_id"
    #nginx.ingress.kubernetes.io/modsecurity-snippet: |
      #SecRuleEngine On
  name: waf-example-ingress
spec:
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: cyperf-agent-service
            port:
              number: 80
---

EOF

##### Create CyPerf Server Agent Configuration YAML with Ingress and WAF enabled.

cat <<EOF >$HOME/cyperf-agent-server-waf.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
    name: cyperf-agent-server-deployment
spec:
    replicas: 1
    selector:
        matchLabels:
            app: cyperf-agent
            run: cyperf-agent-server
    template:
        metadata:
            labels:
                app: cyperf-agent
                run: cyperf-agent-server
        spec:
            containers:
                -   name: cyperf-agent-server
                    image: public.ecr.aws/keysight/cyperf-agent:latest
                    env:
                    -   name: AGENT_CONTROLLER
                        value: "192.168.2.20"
                    #   name: AGENT_MANAGEMENT_INTERFACE
                    #   value: "eth0"
                    #   name: AGENT_TEST_INTERFACE
                    #   value: "eth1"
                    -   name: AGENT_TAGS
                        value: "K8s-Group=CyPerf-Agent-Server,node-owner=User"
                    securityContext:
                        privileged: false
                        capabilities:
                          add: ["NET_ADMIN", "IPC_LOCK", "NET_RAW"]
                    #readinessProbe:
                    #   httpGet:
                    #        path: /CyPerfHTTPHealthCheck
                    #        port: 80
                    #    periodSeconds: 5
                    resources:
                        limits:
                            memory: "4Gi"
                            #cpu: "3.5"
                            ## skipping requests means limits=requests
                            ## with 3.5 for 8 core node it should be able to run 2 replicas
                            ## but experiments needed to see how other pods react for perf configs.
                        requests:
                            memory: "2Gi"

            nodeSelector:
                agenttype: server
            #affinity:
            #    podAntiAffinity:
            #        requiredDuringSchedulingIgnoredDuringExecution:
            #        - labelSelector:
            #            matchExpressions:
            #            - key: app
            #              operator: In
            #              values:
            #              - cyperf-agent
            #          topologyKey: "kubernetes.io/hostname"


---

apiVersion: v1
kind: Service
metadata:
    name: cyperf-agent-service
spec:
    type: ClusterIP
    #type: NodePort
    ports:
    - port: 80
      protocol: TCP
      name: http
      targetPort: 80
      #nodePort: 30080
    selector:
        run: cyperf-agent-server

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    ########## Configure ModSecurity #############
    nginx.ingress.kubernetes.io/enable-modsecurity: "true"
    nginx.ingress.kubernetes.io/enable-owasp-core-rules: "true"
    nginx.ingress.kubernetes.io/modsecurity-transaction-id: "$request_id"
    nginx.ingress.kubernetes.io/modsecurity-snippet: |
      SecRuleEngine On
  name: waf-example-ingress
spec:
  rules:
  - http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: cyperf-agent-service
            port:
              number: 80
---

EOF


##### Define Cyperf Agent Client Configuration File YAML that will reside in the Home Directory.

cat <<EOF >$HOME/cyperf-agent-client.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
    name: cyperf-agent-client-deployment
spec:
    replicas: 1
    selector:
        matchLabels:
            app: cyperf-agent
    template:
        metadata:
            labels:
                app: cyperf-agent
        spec:
            containers:
                -   name: cyperf-agent-client
                    image: public.ecr.aws/keysight/cyperf-agent:latest
                    env:
                    -   name: AGENT_CONTROLLER
                        value: "192.168.2.20"
                    #   name: AGENT_MANAGEMENT_INTERFACE
                    #   value: "eth0"
                    #   name: AGENT_TEST_INTERFACE
                    #   value: "eth1"
                    -   name: AGENT_TAGS
                        value: "K8s-Group=CyPerf-Agent-Client,node-owner=User"
                    securityContext:
                        privileged: false
                        capabilities:
                          add: ["NET_ADMIN", "IPC_LOCK", "NET_RAW"]
                    resources:
                        limits:
                            memory: "4Gi"
                            #cpu: "3.5"
                            ## skipping requests means limits=requests
                            ## with 3.5 for 8 core node it should be able to run 2 replicas
                            ## but experiments needed to see how other pods react for perf configs.
                        requests:
                            memory: "2Gi"

            nodeSelector:
                agenttype: client
            #affinity:
            #    podAntiAffinity:
            #        requiredDuringSchedulingIgnoredDuringExecution:
            #        - labelSelector:
            #            matchExpressions:
            #            - key: app
            #              operator: In
            #              values:
            #              - cyperf-agent
            #          topologyKey: "kubernetes.io/hostname"

---

EOF

##### Deploy the Agent and Server for a container - B2B Test

kubectl create -f cyperf-agent-client.yaml
kubectl create -f cyperf-agent-server-nowaf.yaml
