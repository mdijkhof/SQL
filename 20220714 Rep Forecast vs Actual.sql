WITH
active_sales AS (
SELECT 
employee_sf_id
,employee_name
,manager_name
,specialization
,team
,snap_date
FROM sandbox.intl_active_sales 
	WHERE 1=1
	AND snap_date >= '2022-01-01'
),

unagi AS (
SELECT 
opportunity_id
,currency_code
,Sum ( CASE WHEN report_date < opportunity_launch_date_actual + 30 THEN gross_revenue_loc ELSE NULL END ) AS gr30_loc
FROM sandbox.unagi
GROUP BY 1,2
),

forecast AS (
SELECT 
id
,Projection_Variance_Notes AS rep_forecast
--,ZeroIfNull(RegExp_Replace(OReplace(Projection_Variance_Notes,',00',''),'[A-Za-z]','')) AS rep_forecast
From dwh_load_sf_view.sf_opportunity_1
)


SELECT
gbl.launch_date_actual
,gbl.contract_id AS opportunity_id
,gbl.merchant_name
,gbl.deal_title
,active_sales.employee_name AS opportunity_owner
,active_sales.manager_name
,unagi.currency_code
,unagi.gr30_loc
,forecast.rep_forecast

From sb_rmaprod.vw_gbl_contracts gbl
	LEFT JOIN active_sales
		ON 1=1
		AND active_sales.employee_sf_id = gbl.contract_owner_id
		AND active_sales.snap_date = gbl.launch_date_actual
	LEFT JOIN unagi
		ON 1=1
		AND unagi.opportunity_id = gbl.contract_id
	LEFT JOIN forecast
		ON 1=1
		AND forecast.id = gbl.contract_id

WHERE 1=1
	AND gbl.launch_date_actual BETWEEN Current_Date-37 AND Current_Date-30
	AND gbl.country_name IN ('UK','IE','DE','ES','FR','IT','PL','AU','AE','NL','BE')
	AND gbl.grt_l1_cat_description IN ('Local','Unknown')
	AND gbl.fin_category IN ('RF','New')
	AND gbl.deal_stage = 'Closed Won'
	AND active_sales.team = 'Local'
	AND active_sales.specialization IN ('Hunter','Inbound')
