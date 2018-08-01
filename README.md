# Vault Creds

Program (and Docker container) to be run as a sidecar to your application- requesting dynamic credentials that will be leased while the application is active.

It implements authentication according to [Vault's Kubernetes Authentication flow](https://kubernetes.io/docs/admin/authentication/).

## Usage

This project is to be deployed in a Pod alongside the main application. When `vault-creds` starts it will request credentials at the path specified and continually renew their lease.

For example:

```sh
$ ./bin/vaultcreds \
  --vault-addr=https://vault:8200 \
  --login-path=kubernetes/cluster/login \
  --auth-role=service_account_role \
  --template=sample.database.yml \
  --secret-path=database/creds/database_role \
  --out=/etc/secrets/sample_database.yml
```

The template is applied to the latest credentials and written to `--out` (normally this would be a shared mount for the other containers read).

## Init Mode

If you run the container with the `--init` flag it will generate the database credentials and then exit allowing it to be used as an Init Container.
Vault-creds will also write out the lease and auth info to a file in the same directory as your database credentials, if a new Vault-creds container starts up it can read these and use them to renew your lease.
This means that you can have an init container generate your creds and then have a sidecar renew your credentials for you. Thus ensuring the credentials exist before your app starts up.

## Job Mode

Kubernetes doesn't handle sidecars in cronjobs/jobs very well as it has no understanding of the difference between the primary container and the sidecar, this means that if your primary process errors/completes the job will continue to run as the vault-creds sidecar will still be running.

To get around this you can run the sidecar with `--job` flag which will cause the vault-creds sidecar to watch the status of the other containers in the pod. If they error the vault-creds container will exit 1, if they complete the container will exit 0 thus getting around the sidecar problem.

To make this work you need to add the pod name and namespaces as env vars to the vault-creds container.

```yml
env:
- name: NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
```

Also ensure that the service account you use has permission to `GET` pods in its own namespace.

## Command-line arguments

The following command-line arguments are available:

`--help` show context-sensitive help and exit  
`--vault-addr=VAULT_ADDR` address of the vault server (defaults to `VAULT_ADDR` environment variable)  
`--login-path=VAULT_PATH` Vault path to use for login (required)  
`--auth-role=AUTH_ROLE` Vault role to authenticate as (required)  
`--secret-path=VAULT_PATH` Vault path to obtain secret from (required)  
`--template=PATH` path to template used to format the Vault results (required)  
`--out=PATH` path to write output to (defaults to STDOUT - normally required)  
`--ca-cert=PATH` path to certificate used to validate Vault server (optional)  
`--renew-interval=DURATION` interval to renew credentials (defaults to `15m`)  
`--lease-duration=DURATION` duration to lease credentials for (defaults to `1h`)   
`--token-file=PATH` path to the Kubernetes token file (defaults to `/var/run/secrets/kubernetes.io/serviceaccount/token`)  
`--completed-path=PATH` path where a completion file will be dropped (defaults to `/tmp/vault-creds/completed`)  
`--json-log` output logs in JSON format (defaults to `false`)  
`--job` run in cronjob mode (defaults to `false`)  
`--init` run in init mode (defaults to `false`)  

## Templates

Output is formatted using go's template engine.  The template is passed the full response returned by Vault in response to the secret retrieval request.

The credential information is returned as a map of key/value pairs in the `Data` element and so the template will typically index into this to obtain the secret information.

The template will, therefore, typically look something like:

```INI
[default]
aws_access_key_id={{index .Data "access_key"}}
aws_secret_access_key={{index .Data "secret_key"}}
```

## License

```
Copyright 2017 uSwitch
Copyright 2018 Dale Peakall

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
