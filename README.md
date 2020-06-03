# api.croplands.org

api.croplands.org (and its server.croplands.org alias) runs on the 
[dk8s cluster](dmz-rancher.wr.usgs.gov) in the `croplands` namespace.

The kubernetes configuration contained in [k8s](./k8s/) does not include
3 secrets: server-croplands-tls and api-croplands-org-tls, which contain the TLS 
certificate pair for the site; and croplands-api, which contains the following 
environment variables:
```
GOOGLE_SERVICE_ACCOUNT_ENC
SQLALCHEMY_DATABASE_URI
REDIS_URL
POSTMARK_API_KEY
SECRET
SERVER_ADDRESS
DG_EV_CONNECT_ID
DG_EV_USERNAME
DG_EV_PASSWORD
GS_ACCESS_KEY
GS_SECRET
SSL_CERT_FILE
REQUESTS_CA_BUNDLE
```

To update the tls secret (**DO FOR api.croplands.org AND server.croplands.org**):

1. Obtain updated cert from digicert (api.croplands.org.crt here)
2. Grab the private key from the existing secret:
```
$ kubectl get secret api-croplands-org-tls -o jsonpath='{.data.tls\.key}' | base64 -d > tls.key
```
3. Careful, double check the previous command was successful. Then delete the existing
secret:
```
$ kubectl delete secret api-croplands-org-tls
```
4. Re-create the secret with the updated cert
```
$ kubectl create secret tls --key=tls.key --cert=api.croplands.org.crt
```
5. Restart the service
```
$ kubectl delete po -l app=croplands-api
```

To update the config:

1. Grab the existing config from the cluster
```
$ kubectl get secret croplands-api -o yaml > secret.yml
```
2. Base64-encode the new value. For example, changing REDIS_URL
```
$ printf 'redis://redis.my.domain:6379' | base64
cmVkaXM6Ly9yZWRpcy5teS5kb21haW46NjM3OQ==
```
3. Take the output from the previous command and update the value in secret.yml
```yaml
# secret.yml
apiVersion: v1
data:
...

  REDIS_URL: cmVkaXM6Ly9yZWRpcy5teS5kb21haW46NjM3OQ== 

...
kind: Secret
metadata:
  creationTimestamp: "2020-04-20T16:32:31Z"
  name: croplands-api
  namespace: croplands
  resourceVersion: "22676294"
  selfLink: /api/v1/namespaces/croplands/secrets/croplands-api
  uid: a1ebedcc-9ca1-4dc9-8c40-2c27d798c58d
type: Opaque
```
4. Update the secret on the cluster
```
$ kubectl apply -f secret.yml
```
5. Restart the service
```
$ kubectl delete po -l app=croplands-api
```
