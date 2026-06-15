-- Who created or modified a resource in the last 24 hours?
SELECT
  timestamp,
  protopayload_auditlog.authenticationInfo.principalEmail AS principal_email,
  protopayload_auditlog.methodName AS method_name,
  resource.labels.project_id AS project_id,
  resource.type AS resource_type
FROM `PROJECT_ID.pulseguard_audit_logs.cloudaudit_googleapis_com_activity_*`
WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
ORDER BY timestamp DESC;

-- Which service account accessed Secret Manager?
SELECT
  timestamp,
  protopayload_auditlog.authenticationInfo.principalEmail AS principal_email,
  protopayload_auditlog.resourceName AS resource_name,
  protopayload_auditlog.methodName AS method_name
FROM `PROJECT_ID.pulseguard_audit_logs.cloudaudit_googleapis_com_data_access_*`
WHERE protopayload_auditlog.serviceName = "secretmanager.googleapis.com"
ORDER BY timestamp DESC;

-- Which IAM bindings were changed outside business hours?
SELECT
  timestamp,
  protopayload_auditlog.authenticationInfo.principalEmail AS principal_email,
  protopayload_auditlog.methodName AS method_name,
  protopayload_auditlog.resourceName AS resource_name
FROM `PROJECT_ID.pulseguard_audit_logs.cloudaudit_googleapis_com_activity_*`
WHERE protopayload_auditlog.methodName = "SetIamPolicy"
  AND EXTRACT(HOUR FROM timestamp) NOT BETWEEN 9 AND 18
ORDER BY timestamp DESC;
