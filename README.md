# kind
Setup scripts for KIND K8s running on Ubuntu 20.04
Build a host VM with Ubuntu 20.04, assign max resources. Example 32 core/32G ram
Requires two network interfaces - one for Management - can be DHCP, the other as a Test Interface 20.0.0.0/16 using IP 20.0.0.20

Run SetupDocker.sh - this installs Docker in preparation for Kubernetes.
Run SetupKubernetes.sh - this installs K8s 1xMaster, 2xWorker nodes, CyPerf Client/Server Pods, NGINX Ingress controller.
Scripts for enableWAF.sh and disableWAF.sh modify the YAML on the CyPerf Server Pod to activate the WAF rules.

Internal Video Tutorial walking through the setup - 
https://keysighttech-my.sharepoint.com/:v:/g/personal/christopher_graham_keysight_com/EVPHIctfOEpPi866iodAzhgBIDnpqIhh19mV23tmKerRsQ?e=Ld1MbU
