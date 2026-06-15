-- Replace `project.dataset.gcp_billing_export_v1_*` with your billing export table.

-- Daily cost trend by service.
SELECT
  DATE(usage_start_time) AS usage_date,
  service.description AS service_name,
  SUM(cost) AS total_cost
FROM `project.dataset.gcp_billing_export_v1_*`
GROUP BY usage_date, service_name
ORDER BY usage_date DESC, total_cost DESC;

-- Top namespaces by cluster label or namespace label when exported.
SELECT
  DATE(usage_start_time) AS usage_date,
  labels.value AS namespace,
  SUM(cost) AS total_cost
FROM `project.dataset.gcp_billing_export_v1_*`,
UNNEST(labels) AS labels
WHERE labels.key IN ("k8s-namespace", "namespace")
GROUP BY usage_date, namespace
ORDER BY usage_date DESC, total_cost DESC;

-- Resources with sustained spend over the last 7 days.
SELECT
  project.id AS project_id,
  sku.description AS sku_name,
  SUM(cost) AS total_cost
FROM `project.dataset.gcp_billing_export_v1_*`
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
GROUP BY project_id, sku_name
ORDER BY total_cost DESC;
