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