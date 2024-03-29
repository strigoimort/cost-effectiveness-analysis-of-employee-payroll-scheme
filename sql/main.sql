WITH wow AS(
  WITH cte1 AS -- RATA-RATA SALARY PER BRANCH
  (
    SELECT
    branch_id,
    employe_id AS employe_1,
    salary,
    ROUND(AVG(salary) OVER(PARTITION BY branch_id)) AS avg_salary_per_branch,
    CASE
      WHEN salary < ((ROUND(AVG(salary) OVER(PARTITION BY branch_id))))  THEN 'Below Average'
      ELSE 'Above Average'
    END AS point_salary
    FROM `bitlabs-dab.I_CID_04.employees`
    GROUP BY 1,2,3
    ORDER BY branch_id
  ),
  cte2 AS  -- TOTAL HARI BEKERJA
  (
    WITH tabel AS(
      SELECT *,
      employe_id AS employe_2,
      CASE
        WHEN SAFE_CAST(resign_date AS DATE) IS NULL THEN '2023-05-17'
        ELSE resign_date
      END AS corrected_resign_date,
      FROM `bitlabs-dab.I_CID_04.employees`
    )
    SELECT *,
    DATE_DIFF(SAFE_CAST(corrected_resign_date AS DATE), SAFE_CAST(join_date AS DATE), day) AS hari_kerja
    FROM tabel
  ),
  cte3 AS  -- TOTAL JAM KERJA
  (
    SELECT
    DISTINCT employee_id AS employe_3,
    ABS(SUM(TIME_DIFF(checkout, checkin, hour)) OVER(PARTITION BY employee_id)) AS jam_kerja
    FROM `bitlabs-dab.I_CID_04.timesheets`
    ORDER BY employee_id
  ),
  cte4 AS  -- TOTAL BULAN BEKERJA
  (
    WITH tabel AS(
      SELECT *,
      employe_id AS employe_4,
      CASE
        WHEN SAFE_CAST(resign_date AS DATE) IS NULL THEN '2023-05-17'
        ELSE resign_date
      END AS corrected_resign_date,
      FROM `bitlabs-dab.I_CID_04.employees`
    )
    SELECT *,
    DATE_DIFF(SAFE_CAST(corrected_resign_date AS DATE), SAFE_CAST(join_date AS DATE), month) AS bulan_kerja
    FROM tabel
  )
  SELECT
  DISTINCT cte1.employe_1 AS employee,
  cte3.jam_kerja,
  cte2.hari_kerja,
  ROUND((cte1.salary*cte4.bulan_kerja)/cte3.jam_kerja) AS salary_per_hour,
  CASE
    WHEN jam_kerja < 845 THEN 10
    WHEN jam_kerja < 1690 THEN 20
    WHEN jam_kerja < 2535 THEN 30
    ELSE 40
  END AS poin_jam_kerja,
  CASE
    WHEN hari_kerja < 610 THEN 5
    WHEN hari_kerja < 1220 THEN 10
    WHEN hari_kerja < 1830 THEN 15
    ELSE 20
  END AS poin_hari_kerja,
  CASE
    WHEN ROUND((cte1.salary*cte4.bulan_kerja)/cte3.jam_kerja) < 8328000 THEN 40
    WHEN ROUND((cte1.salary*cte4.bulan_kerja)/cte3.jam_kerja) < 16640000 THEN 30
    WHEN ROUND((cte1.salary*cte4.bulan_kerja)/cte3.jam_kerja) < 24960000 THEN 20
    ELSE 10
  END AS poin_salary
  FROM cte1
  JOIN cte3 ON cte1.employe_1 = cte3.employe_3
  JOIN cte2 ON cte1.employe_1 = cte2.employe_2
  JOIN cte4 ON cte1.employe_1 = cte4.employe_4
  ORDER BY cte1.employe_1 ASC
)
SELECT *,
(poin_jam_kerja + poin_hari_kerja + poin_salary) AS poin_total
FROM wow