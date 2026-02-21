# EdgeRouter X Configuration

## SSH Listening Port

To enable SSH to only listen on the intenal IP, you can configure it using the CL as follows.

### 1.Enter Configuration Mode:
```bash
configure
```
### 2.Set the SSH Listen Address:
Replace 192.168.1.1 with your actual internal gateway IP:
```bash
set service ssh listen-address 192.168.1.1
```
### 3.Commit and Save:
```bash
commit
save
exit 
```
