# Private AKS Firewall Rules

## Show Cluster Info

```powershell
PS C:\Users\azureuser\Desktop> kubectl cluster-info
Kubernetes control plane is running at https://aks-aip-prod-twn-1otiwdz5.09185383-47e3-4381-8a0e-8446d6a35b05.privatelink.taiwannorth.azmk8s.io:443
CoreDNS is running at https://aks-aip-prod-twn-1otiwdz5.09185383-47e3-4381-8a0e-8446d6a35b05.privatelink.taiwannorth.azmk8s.io:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://aks-aip-prod-twn-1otiwdz5.09185383-47e3-4381-8a0e-8446d6a35b05.privatelink.taiwannorth.azmk8s.io:443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

PS C:\Users\azureuser\Desktop> nslookup aks-aip-prod-twn-1otiwdz5.09185383-47e3-4381-8a0e-8446d6a35b05.privatelink.taiwannorth.azmk8s.io
Server:  UnKnown
Address:  168.63.129.16

Non-authoritative answer:
Name:    aks-aip-prod-twn-1otiwdz5.09185383-47e3-4381-8a0e-8446d6a35b05.privatelink.taiwannorth.azmk8s.io
Address:  10.100.5.4
```

## Validate Private Traffic

```powershell
kubectl apply -f https://raw.githubusercontent.com/pichuang/debug-container/refs/heads/master/deployment-debug-container.yaml
kubectl exec -it <pod-name> -- /bin/bash

[root@debug-container ~]# curl ifconfig.me
<azfw publicip>

[root@debug-container ~]# curl google.com.tw
Action: Deny. Reason: No rule matched. Proceeding with default action.
```