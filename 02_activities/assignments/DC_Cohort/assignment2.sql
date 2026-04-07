/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
--QUERY 1
SELECT
    product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product;
--END QUERY


-- Windowed Functions
--QUERY 2
SELECT
    customer_id,
    market_date,
    DENSE_RANK() OVER (
        PARTITION BY customer_id
        ORDER BY market_date
    ) AS visit_number
FROM customer_purchases
WHERE market_date < '2022-04-29'
GROUP BY customer_id, market_date;
--END QUERY


--QUERY 3
SELECT *
FROM (
    SELECT
        customer_id,
        market_date,
        DENSE_RANK() OVER (
            PARTITION BY customer_id
            ORDER BY market_date DESC
        ) AS recent_visit_number
    FROM customer_purchases
    GROUP BY customer_id, market_date
) t
WHERE recent_visit_number = 1;
--END QUERY


--QUERY 4
SELECT
    customer_id,
    product_id,
    market_date,
    transaction_time,
    quantity,
    cost_to_customer_per_qty,
    COUNT(*) OVER (
        PARTITION BY customer_id, product_id
        ORDER BY market_date, transaction_time
    ) AS purchase_count_for_product
FROM customer_purchases
WHERE market_date < '2022-04-29';
--END QUERY


-- String manipulations
--QUERY 5
SELECT
    product_name,
    CASE
        WHEN INSTR(product_name, '-') > 0
        THEN TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
        ELSE NULL
    END AS description
FROM product;
--END QUERY


--QUERY 6
SELECT *
FROM product
WHERE product_size REGEXP '[0-9]';
--END QUERY




-- UNION
--QUERY 7
WITH sales_by_date AS (
    SELECT
        market_date,
        SUM(quantity * cost_to_customer_per_qty) AS total_sales
    FROM customer_purchases
    GROUP BY market_date
),
ranked_days AS (
    SELECT
        market_date,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS best_day_rank,
        RANK() OVER (ORDER BY total_sales ASC) AS worst_day_rank
    FROM sales_by_date
)
SELECT
    market_date,
    total_sales,
    'best day' AS day_type
FROM ranked_days
WHERE best_day_rank = 1

UNION

SELECT
    market_date,
    total_sales,
    'worst day' AS day_type
FROM ranked_days
WHERE worst_day_rank = 1;
--END QUERY



/* SECTION 3 */

-- Cross Join
--QUERY 8
WITH vendor_products AS (
    SELECT
        vi.vendor_id,
        v.vendor_name,
        vi.product_id,
        p.product_name,
        p.product_qty_type,
        p.product_size,
        vi.original_price
    FROM vendor_inventory vi
    JOIN vendor v
        ON vi.vendor_id = v.vendor_id
    JOIN product p
        ON vi.product_id = p.product_id
),
customer_count AS (
    SELECT COUNT(*) AS num_customers
    FROM customer
)
SELECT
    vp.vendor_name,
    vp.product_name,
    5 * cc.num_customers * vp.original_price AS total_revenue
FROM vendor_products vp
CROSS JOIN customer_count cc
ORDER BY vp.vendor_name, vp.product_name;
--END QUERY


-- INSERT
--QUERY 9
CREATE TABLE product_units AS
SELECT
    product.*,
    CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';
--END QUERY


--QUERY 10
INSERT INTO product_units (
    product_id,
    product_name,
    product_size,
    product_qty_type,
    snapshot_timestamp
)
VALUES (
    16,
    'Apple Pie',
    '9"',
    'unit',
    CURRENT_TIMESTAMP
);
--END QUERY


-- DELETE
--QUERY 11
DELETE FROM product_units
WHERE product_id = 16
  AND snapshot_timestamp < (
      SELECT MAX(snapshot_timestamp)
      FROM product_units
      WHERE product_id = 16
  );
--END QUERY


-- UPDATE
--QUERY 12
ALTER TABLE product_units
ADD current_quantity INT;

UPDATE product_units
SET current_quantity = COALESCE((
    SELECT vi.quantity
    FROM vendor_inventory vi
    WHERE vi.product_id = product_units.product_id
    ORDER BY vi.market_date DESC
    LIMIT 1
), 0);
--END QUERY