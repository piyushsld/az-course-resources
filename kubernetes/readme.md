## Startup probes distinction  
```
Pod Lifecycle:
[ Startup Probe running ] → [ Startup PASSES ] → [ Liveness + Readiness active ]
     ↓ (30s slow boot)           ↓ (app ready)           ↓ (normal operation)
   Other probes DISABLED      Liveness: RESTART       Readiness: NO TRAFFIC
                             if hangs/crashes         if temporarily unhealthy
```
  
| Probe    | When Active | Failure Action | Traffic Impact | Pod Impact |
| -------- | -------- | -------- | -------- | -------- |
| Startup  | Only during boot     | DISABLE liveness/readiness     | None     | None (just waits)     |
| Liveness | After startup succeeds     | RESTART container     | Still receives traffic     | Container restarts     |
| Readiness| After startup succeeds     | Remove from Service     | No traffic     | Pod stays running     |
  

## Test readiness  
```
# Break readiness on pod 1
kubectl exec probe-demo-<random-id>-<random-id> -n demo -- mv /usr/share/nginx/html/ready /tmp/ready.broken

# Check Service endpoints
kubectl get endpoints probe-demo-service -n demo

# Expectation - pods should be removed from service
Fix: kubectl exec probe-demo-<random-id>-<random-id> -n demo -- mv /tmp/ready.broken /usr/share/nginx/html/ready
```
  
## Test liveness  
```
# Break liveness on pod 2  
kubectl exec probe-demo-<random-id>-<random-id> -n demo -- mv /usr/share/nginx/html/healthy /tmp/healthy.broken

# Watch restart
kubectl get pods -n demo -w
```
Expected: Container restarts automatically  
  
## Probe Behaviour Summary


| Probe | Purpose | Failure Action | Traffic |
| -------- | -------- | -------- | -------- |
| Startup    | “Is app fully booted?”     | DISABLE liveness/readiness     | No effect     |
| Readiness    | “Can serve traffic NOW?”     | Remove from Service     | ❌ No traffic     |
| Liveness    | “Is app alive?”     | RESTART container     | Still in Service     |  

# Test DB persistence
```
# 1. Write data to mysql-0
kubectl exec -it mysql-0 -n demo -- mysql -uroot -ppassword123 -e "CREATE DATABASE testdb; SHOW DATABASES;"

# 2. Delete pod (NOT PVC!)
kubectl delete pod mysql-0 -n demo

# 3. Watch recreation
kubectl get pod mysql-0 -n demo -w
kubectl get pvc mysql-data-mysql-0 -n demo  # Disk survives!

# 4. Data persists!
kubectl exec -it mysql-0 -n demo -- mysql -uroot -ppassword123 -e "SHOW DATABASES;"
# +--------------------+
# | Database           |
# | testdb             |  ✅ Data survives pod deletion!
```

## Observe scale up and scale down
```
# Scale to 5 → Creates mysql-data-mysql-{3,4} PVCs
kubectl scale statefulset mysql --replicas=5 -n demo

# Scale back → mysql-{3,4} PVCs survive
kubectl scale statefulset mysql --replicas=2 -n demo
kubectl get pvc -n demo  # Orphaned PVCs retained
```
